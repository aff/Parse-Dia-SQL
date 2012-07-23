package Parse::Dia::SQL::Utils;

# $Id: Utils.pm,v 1.13 2011/02/16 10:23:11 aff Exp $

=pod

=head1 NAME

Parse::Dia::SQL::Utils - Helper class for Parse::Dia::SQL.

=head1 SYNOPSIS

  Not to be used directly.

=head1 DESCRIPTION

Utility functions for Parse::Dia::SQL.

=cut

use warnings;
use strict;

use Data::Dumper;
use XML::DOM;
use Digest::MD5 qw(md5_base64);

use lib q{.};
use Parse::Dia::SQL::Logger;

# TODO: Move constants to a separate module
my %MAX_NAME_LEN = (
  default   => 30,
  db2       => 18,
  html      => 64,
  innodb    => 64,
  mysql     => 64,
  oracle    => 30,
  postgres  => 63,
  sas       => 32,
  sqlite3   => 60,
  sqlite3fk => 60,
);

# TODO: Make this a object variable
my $DEFAULT_PK = [];

=head2 set_default_pk

Define primary key column names and types for automatic generation of
primary keys in tables that need them, but do not have them defined.

=cut

sub set_default_pk {
  my $self = shift;
  if ( $self->{default_pk} ) {
    my @defPK = split /\s*:\s*/, $self->{default_pk};
    die "Bad definition of default primary key: $self->{default_pk}\n"
      if ( @defPK != 2 || $defPK[0] eq '' || $defPK[1] eq '' );
    my @pkNames = split /\s*,\s*/, $defPK[0];
    my @pkTypes = split /\s*,\s*/, $defPK[1];
    die
"Number of default primary key names and types don't match in $self->{default_pk}\n"
      if ( @pkNames != @pkTypes );
    foreach my $i ( 0 .. $#pkNames ) {
      my ( $name, $type ) = ( $pkNames[$i], $pkTypes[$i] );
      die "Null primary key name in " . $self->{default_pk} if ( !$name );
      die "Null primary key type in " . $self->{default_pk} if ( !$type );
      push @$DEFAULT_PK, [ $name, $type, 'not null', 2, '' ];
    }
  }
  return 1;
}


=head2 new

The constructor.  No arguments.

=cut

=head2 new


=cut

sub new {
  my ($class, %param) = @_;
  my $self = {
    log        => undef,
    db         => $param{db} || undef,
    default_pk => $param{default_pk} || undef,
    loglevel   => $param{loglevel} || undef,
  };

  bless($self, $class);

  # init logger
  my $logger = Parse::Dia::SQL::Logger::->new(loglevel => $self->{loglevel});
  $self->{log} = $logger->get_logger(__PACKAGE__);

  return $self;
}

=head2 get_node_attribute_values

Given a node with dia:attribute nodes inside it, go through the
dia:attribute nodes with attribute "name='...'" and return the string
values

@infosToGet is an array of strings, where the first character is the
data type to get, and the remaining characters are the name to parse
for. first character legal values are:

   a = alpha
   9 = numeric
   b = boolean

example:   aname, 9dollars, bkillOrNot

=cut

sub get_node_attribute_values {
  my ($self, $nodeList, @infosToGet) = @_;

  # TODO check datatype of nodeList

  my ( $currentNode, $nodeAttrName, $i );
  my %return;

  my $emptyValueString  = "__undef_string__";
  my $emptyValueNumber  = "__undef_numeric__";
  my $emptyValueBoolean = "__undef_boolean__";

  # initialise it to a bunch of empty values, this will also allow
  # us to know which attribute name values to parse out of the
  # dia:attribute nodelist
  foreach my $singleInfo (@infosToGet) {
    if ( $singleInfo =~ /^a(.+)/ ) {
      $return{$1} = $emptyValueString;
    }
    elsif ( $singleInfo =~ /^9(.+)/ ) {
      $return{$1} = $emptyValueNumber;
    }
    elsif ( $singleInfo =~ /^b(.+)/ ) {
      $return{$1} = $emptyValueBoolean;
    }
  }

  # we're interested in everything that's a dia:attribute
  my $attrNodeList = $nodeList->getElementsByTagName('dia:attribute');

  for ( $i = 0 ; $i < $attrNodeList->getLength ; $i++ ) {
    $currentNode  = $attrNodeList->item($i);
    $nodeAttrName = $currentNode->getAttribute('name');

    next if ( !$nodeAttrName || !$return{$nodeAttrName} );

    # test if this is a value we're interested in and if it's currently empty
    if ( $return{$nodeAttrName} eq $emptyValueString ) {

      # a text node gives us text
      $return{$nodeAttrName} = $self->get_string_from_node($currentNode);
    }
    elsif ( $return{$nodeAttrName} eq $emptyValueNumber ) {
      $return{$nodeAttrName} = $self->get_num_from_node($currentNode);
    }
    elsif ( $return{$nodeAttrName} eq $emptyValueBoolean ) {
      $return{$nodeAttrName} = $self->get_bool_from_node($currentNode);
    }
  }

	{
		no warnings q{uninitialized};
		$self->{log}->debug( "$nodeAttrName:" . $return{$nodeAttrName} );
	} 

  # don't return some fake value for bits we didn't parse,
  # return undef which means it wasn't there
  foreach my $singleInfo (@infosToGet) {
    if (
         $singleInfo
      && $return{$singleInfo}
      && ( $return{$singleInfo} eq $emptyValueString
        || $return{$singleInfo} eq $emptyValueNumber
        || $return{$singleInfo} eq $emptyValueBoolean )
      )
    {
      $return{$singleInfo} = undef;
    }
  }

  return %return;
}


=head2 get_string_from_node

If it looks like <thingy><dia:string>value</dia:string></thingy> then
we will get the 'value' part out given the node is 'thingy'.

=cut

sub get_string_from_node {
  my $self = shift;
  my $node = shift;

  my $retval;

  my $stringVal;

  foreach my $stringNode ($node->getElementsByTagName('dia:string')) {
    if ($stringVal = $stringNode->getFirstChild) {
      $retval = $stringVal->toString;
    } else {
      $retval = "";
    }
  }

	return if !$retval; # Skip escaping if empty

  #	$retval =~ s/^#?(.*)#?$/$1/g;
  $retval =~ s/^#//;
  $retval =~ s/#$//;

  # TODO use HTML::Entities;
  # drTAE: also, XML files must escape certain sequences...
  $retval =~ s/&lt;/</g;
  $retval =~ s/&amp;/&/g;
  $retval =~ s/&gt;/>/g;
  $retval =~ s/&quot;/"/g;

  return $retval;
}

=head2 get_value_from_object

Given an object, node name, attribute name, attribute value, and value
to retrieve type, find the info and return it.

=cut

sub get_value_from_object {
  my $self                = shift;
  my $object              = shift;
  my $getNodeName         = shift;
  my $getNodeAttribute    = shift;
  my $getNodeAttributeVal = shift;
  my $infoToRetrieveType  = shift;

  my $parsedValue;
  my $currNode;

  if (
    $currNode = $self->get_node_from_object(
      $object,              $getNodeName, $getNodeAttribute,
      $getNodeAttributeVal
    )
    )
  {
    if ($infoToRetrieveType eq 'string') {
      $parsedValue = $self->get_string_from_node($currNode);
    } elsif ($infoToRetrieveType eq 'number') {
      $parsedValue = $self->get_num_from_node($currNode);
    } elsif ($infoToRetrieveType eq 'boolean') {
      $parsedValue = $self->get_bool_from_node($currNode);
    }

    return $parsedValue;
  } else {
    return;
  }
}

=head2 get_node_from_object

Given an object, node name, attribute name, and attribute value,
return the node that has all these things.

=cut

sub get_node_from_object {
  my $self                = shift;
  my $object              = shift;
  my $getNodeName         = shift;
  my $getNodeAttribute    = shift;
  my $getNodeAttributeVal = shift;

  my $k;
  my $doneParsing;
  my $parsedValue;

  my @nodeList = $object->getElementsByTagName($getNodeName);

  # search @nodeList for a getNodeAttribute="getNodeAttributeVal"
  foreach my $currNode (@nodeList) {
    if ($currNode->getNodeName eq $getNodeName) {
      my $attrPtr = $currNode->getAttributes;

      $k = 0;
      while (($k < $attrPtr->getLength) && !$doneParsing) {
        $parsedValue = $attrPtr->item($k)->toString;
        if ($parsedValue =~ /$getNodeAttribute="$getNodeAttributeVal"/) {
          return $currNode;
        }
        $k++;
      }
    }
  }

  # Not all nodes contain the wanted attribute
  return;
}

=head2 name_case

Transform case for name comparisons to that of the database; leave
unchanged if -C (preserve case) is in effect. Only sybase is known to
be case sensitive.

=cut

sub name_case {
  my ($self, $value) = @_;
  return '' unless $value;
  return $value if ($self->{opt_C} || $self->{db} eq 'sybase');
  return lc($value);    # Assumes that all other DBMSs ignore case of names!
}

=head2 get_num_from_node

Return value part of <dia:enum val="value"></thingy>.

=cut

sub get_num_from_node {
  my ($self, $node) = @_;
	my $enumNode = shift @{$node->getElementsByTagName('dia:enum')};
	return $enumNode->getAttribute('val');
}

=head2 get_bool_from_node

Return value part of <thingy><dia:boolean val="value"></thingy>.

=cut

sub get_bool_from_node {
  my ($self, $node) = @_;
	my $enumNode = shift @{$node->getElementsByTagName('dia:boolean')};
	return $enumNode->getAttribute('val');
}


=head2 classify_multiplicity

Look at a multiplicity descriptor and classify it as 'one' (1, or
1..1), 'zone' (0..1), 'many' (n..m, n..*, where n > 1, m >= n) and
'zmany' (0..n, 0..*, where n > 1)

=cut

sub classify_multiplicity {
  my $self    = shift;
  my $multStr = shift;
  return 'none'  if ( ! $multStr );
  $multStr =~ s/\s//g;
  my @mult = split( /\.\./, $multStr );
  return 'none'  if ( @mult == 0 );
  return 'undef' if ( @mult > 2 );
  push @mult, $mult[0] if ( @mult == 1 );
  foreach my $m (@mult) {
    return 'undef' if ( $m !~ /^\d+$/ && $m ne '*' );
  }
  $mult[0] = 0            if ( $mult[0] eq '*' );
  $mult[1] = $mult[0] + 2 if ( $mult[1] eq '*' ); # ensure $mult[1] > 1 for 0..*
  return 'one'  if ( $mult[0] == 1 && $mult[1] == 1 );    # 1..1
  return 'zone' if ( $mult[0] == 0 && $mult[1] == 1 );    # 0..1
  return 'many'
    if (
    $mult[0] >= 1 && $mult[1] > 1                         # n..m, n..*,
    && $mult[0] <= $mult[1]
    );                                                    # n > 0, m > 1, m >= n
  return 'zmany' if ( $mult[0] == 0 && $mult[1] > 1 );    # 0..n, 0..*, n > 1
  return 'undef';
}


# =head2 parseExtras

# Parse the name of a Small Package that contains extra SQL clauses for
# the generated SQL, and add the SmallPackage text to the appropriate
# %tableExtras table for the type of extra clause (table, pk, index).

# =cut

# sub parseExtras {
#   my $self   = shift;
#   my $type   = shift;
#   my $params = shift;
#   my $dbText = shift;

#   my ($dbNames, $args) = split /\s*:\s*/, $params;
#   my $warns = 0;

#   return 0 if (!$args);

#   $args =~ s/\s//g;
#   $args =~ s/^[^(]*\(//;
#   $args =~ s/\)$//;

#   my @args = split /\s*,\s*/, $args;

#   if ($dbNames =~ /$opt_t/) {
#     foreach my $arg (@args) {
#       if (!$arg) {
#         warn "Null parameter in $params\n";
#         $warns++;
#         $errors++;
#         next;
#       }

#       if ($type =~ /^macro(.+)/) {
#         my $when = $1;
#         $macros{$arg} = { when => $when, sql => $dbText, used => 0 };
#         #if ($verbose) { print "Added $when Macro $arg\n"; }
#       } else {
#         my $dowarn = $tableExtras{$type}->{$arg};
#         if ($dowarn) {
#           warn "SQL clause for $type $arg redefined from\n"
#             . addExtraClauses('', $tableExtras{$type}->{$arg}, '    ');
#         }

#         $tableExtras{$type}->{$arg} = { sql => $dbText, used => 0 };
#         if ($dowarn) {
#           warn "to\n"
#             . addExtraClauses('', $tableExtras{$type}->{$arg}, '    ');
#         }
#       }
#     }
#   }

#   return $warns == 0;
# }

=head2 attlist_from_names

Generate a list of attributes from a comma-separated list of names by
looking up a class' attribute table.

=cut

sub attlist_from_names {
  my $self        = shift;
  my $classLookup = shift;
  my $nameStr     = shift;

  my @names = split /\s*,\s*/, $nameStr;
  my $attList = [];
  foreach my $n (@names) {
    my $a = $classLookup->{atts}{ $self->name_case($n) };
    push @$attList, $a if ($a);
  }
  return $attList;
}

=head2 names_from_attlist

Generate a comma-separated list of attribute names from a list of
attributes.

=cut

sub names_from_attlist {
  my $self = shift;
  my $atts = shift;
  return join ',', map { $_->[0] } @$atts;
}

=head2 check_att_list_types

Check that a list of primary key attributes has types corresponding to
the types in a list of foreign key attributes

=cut

sub check_att_list_types {
  my $self          = shift;
  my $assocName     = shift;
  my $classPKLookup = shift;
  my $classFKLookup = shift;
  my $PKatts        = shift;
  my $FKatts        = shift;
  my $db            = shift; # Parse::Dia::SQL::db

  if ( @$PKatts == 0 || @$PKatts != @$FKatts ) {
    $self->{log}->warn( "Attribute list empty or lengths don't match in"
      . " $assocName ($classPKLookup->{name},$classFKLookup->{name})");
    return 0;
  }
  my $mismatches = 0;

  # The types only exist if the classes are tables, not views
  if ( $classPKLookup->{type} eq 'table' && $classFKLookup->{type} eq 'table' )
  {
    foreach my $i ( 0 .. $#{$PKatts} ) {
	my $pktype = $self->get_base_type( $self->name_case( $PKatts->[$i][1] ), $db );
	my $fktype = $self->get_base_type( $self->name_case( $FKatts->[$i][1] ), $db );
      if ( $pktype ne $fktype )
      {
        $self->{log}->warn( "Attribute types"
          . " ($PKatts->[$i][0] is $PKatts->[$i][1],"
          . " $FKatts->[$i][0] is $FKatts->[$i][1])"
          . " don't match in $assocName"
          . " ($classPKLookup->{name},$classFKLookup->{name})");
        $mismatches++;
      }
    }
  }

  return $mismatches == 0;
}

=head2 get_base_type

Check that a list of primary key attributes has types corresponding to
the types in a list of foreign key attributes.

Returns base type of some DMBS specific types (eg in PostgreSQL serial
is integer).

AFF note:  This is better implemented in each sql formatter class.

=cut

sub get_base_type {
  my $self     = shift;
  my $typeName = shift;
  my $db       = shift;
  if ( $db eq 'postgres' ) {

    # handle PostgreSQL database type
    if ( lc($typeName) eq 'serial' or lc($typeName) eq 'int4' or lc($typeName) eq 'int') {
			$self->{log}->info(qq{Replaced $typeName with integer}) if $self->{log}->is_info();
      return 'integer';
    }
    if ( lc($typeName) eq 'int2' ) {
			$self->{log}->info(qq{Replaced $typeName with smallint}) if $self->{log}->is_info();
      return 'smallint';
    }
    if ( lc($typeName) eq 'int8' ) {
			$self->{log}->info(qq{Replaced $typeName with bigint}) if $self->{log}->is_info();
      return 'bigint';
    }

    return $typeName;
  }
  elsif ( $db eq 'templateDBMStype' ) {

    # handle this database type
    if ( $typeName eq 'templateDatatype' ) {
      return 'templateReturn';
    }
    return $typeName;
  }
  else {

    # all unhandled RDBMS types just return the typeName
    return $typeName;
  }
}



=head2 make_name

Generate a longer name from parts supplied. Except for the first part,
the first letter of each part is capitalised. If lcFirstWord is set,
then any initial string of capitals in the first part is made lower
case; otherwise the first part is left unchanged.

Dies if $self->{db} is not set.

The @parts_org values are save for "Desperation time" :)

=cut

sub make_name {
  my ( $self, $lcFirstWord, @parts_org ) = @_;
	my @parts =  @parts_org;  
  my $namelen = undef;

  $self->{log}->logdie(q{Missing argument 'db'}) unless $self->{db};
  $self->{log}->debug(q{Make name from parts: } . join(q{,},@parts));

  if ( exists( $MAX_NAME_LEN{$self->{db}} ) ) {
    $namelen = $MAX_NAME_LEN{$self->{db}};
  }
  else {
    $namelen = $MAX_NAME_LEN{default};
    $self->{log}->warn(
      "The maximum name length for $self->{db} is not set - using default $namelen");
  }
	$self->{log}->debug("Using namelen $namelen");

  my $len = 0;
  foreach my $p (@parts) { $len += length($p); }

  # If maxNameLen is non-zero, then trim names down
  if ($namelen) {
    foreach my $p (@parts) {
      last if ( $len <= $namelen );
      $len -= length($p);

      # eliminate vowels
      while ( $p =~ /(.)[aeiouAEIOU]/ ) {
        $p =~ s/(.)[aeiouAEIOU]/$1/g;
      }
      while ( $p =~ /(.)\1/ ) {
        $p =~ s/(.)\1/$1/g;    # eliminate doubled letters
      }
      $len += length($p);
    }

    # This part cribbed from mangleName
    if ( $len > $namelen ) {
      my $frac = ( $namelen - $len + @parts ) / $namelen;
      foreach my $p (@parts) {
        last if ( $len <= $namelen );
        my $l    = length($p);
        my $skip = int( $frac * $l + 0.5 );
        my $pos  = int( ( $l - $skip ) / 2 + 0.5 );
        if ($skip) {
          $len -= $l;
          $p = substr( $p, 0, $pos ) . substr( $p, $pos + $skip );
          $len += length($p);
        }
      }
    }
    if ( $len > $namelen ) {

      # Desperation time!
      my $base64 = $self->name_scramble( join '', @parts_org );
			my $retval = substr( $base64, 0, $namelen );
			$self->{log}->debug(qq{Made name : $retval (premature return)});
      return $retval;
    }
  }

  # Remove dot, alows using postgres sql schemas - table name like shop.product
  if ( $self->{db} eq "postgres" ) {
    foreach my $p (@parts) {
      $p =~ s/\.//g;
    }
  }

  # Handle the lowercasing of the first part of the n ame

  if ($lcFirstWord) {
    $parts[0] =~ /([A-Z]*)(.*)/;
    my ( $firstPart, $lastPart ) = ( $1, $2 );
    if ($firstPart) {
      my $recapLast = length($firstPart) > 1
        && substr( $firstPart, -1 ) =~ /[A-Z]/
        && $parts[0] =~ /[a-z]/;
      $parts[0] = lc($firstPart);
      if ($recapLast) {
        $parts[0] = substr( $parts[0], 0, -1 ) . uc( substr( $parts[0], -1 ) );
      }
    }
    else {
      $parts[0] = '';
    }
    $parts[0] .= $lastPart if ($lastPart);
  }
  foreach my $p ( @parts[ 1 .. $#parts ] ) {
    $p = ucfirst($p);
  }

  $self->{log}->debug(q{Made name : } . join(q{},@parts));
  return join '', @parts;
}

=head2 name_scramble

PSuda: Name scrambling helper function, for code which auto-generates
names.  Takes one arg, which is string to use for md5 hashing. This
returns names which consist entirely of underscores and alphanumeric
characters, and starts with one or more alpha characters.

=cut

sub name_scramble {
  my $self = shift;
  my $base64 = md5_base64(shift);

  # Change non alphanumeric characters to underscores.
  $base64 =~ s/[^A-Za-z0-9_]/_/g;

  # Trim off numbers at the start, so that we don't wind up with names
  # that start with numbers. This is a problem in some instances in
  # MySQL.

  $base64 =~ s/^[^a-zA-Z]+//g;
  return $base64;
}


=head2 mangle_name

Get a name to mangle and mangle it to the length
specified -- avoid too much manglification if the
name is only slightly long, but mangle lots if it's
a lot longer than the specified length.

=cut

sub mangle_name {
  my $self           = shift;
  my $nameToMangle   = shift;
  my $sizeToMangleTo = shift;

  if (!(defined($nameToMangle) and defined($sizeToMangleTo) and $sizeToMangleTo =~ m/^\d+$/)){
    $self->{log}->error("Need a string and a positive integer");
    return;  
  }

  # if it's already okay, just return it
  if ( length($nameToMangle) <= $sizeToMangleTo ) {
    return $nameToMangle;
  }

  my $newName;
  my $base64;

  # if it's a real long name, then we mangle it plenty
  if ( length($nameToMangle) > $sizeToMangleTo + 6 ) {
    $base64 = $self->name_scramble($nameToMangle);

    # ensure we have enough garbage
    while ( length($base64) < $sizeToMangleTo ) {
      $base64 .= $self->name_scramble ( $nameToMangle . $base64 );
    }

    $newName = substr( $base64, 0, $sizeToMangleTo );
  }
  elsif ( length($nameToMangle) > $sizeToMangleTo ) {

    # if it's just a little bit long, then mangle it less
    # (remove some chars from the middle)
    my $sizeDiv2  = $sizeToMangleTo / 2;
    my $mangleLen = length($nameToMangle);

    $newName = substr( $nameToMangle, 0, $sizeDiv2 );
    $newName .= substr( $nameToMangle, $mangleLen - $sizeDiv2, $sizeDiv2 );
  }

  return $newName;
}

=head2 add_default_pk

For -p - add a default primary key to a parsed table definition

TODO : Add a meaningful return value.

=cut

sub add_default_pk {
  my $self    = shift;
  my $pkClass = shift;
  my $pkStr   = shift;
  my $defPK   = [];

  if ($pkStr) {

    # If PK names are given, then use those names rather than
    # the default names; but take the types from the defaults
    my @pkNames = split /\s*,\s*/, $pkStr;
    if ( @pkNames == @$DEFAULT_PK ) {
      foreach my $i ( 0 .. $#pkNames ) {
        my $n      = $pkNames[$i];
        my $pkAtts = [ @{ $DEFAULT_PK->[$i] } ];
        $pkAtts->[0] = $n;
        push @$defPK, $pkAtts;
      }
    }
    else {
      warn
"Number of names in $pkStr does not match number of default PK attributes\n";
#      $errors++;
    }
  }
  else {

    # Otherwise just use the default names and types for the PK
    $defPK = $DEFAULT_PK;
  }

  # Add the PK attributes to the class; but complain if an attribute
  # is already defined; The PK fields are added at the beginning of the
  # list of attributes
  for ( my $i = $#{$defPK} ; $i >= 0 ; $i-- ) {
    my $pkAtts = $defPK->[$i];
    my $n      = $pkAtts->[0];
    if ( $pkClass->{atts}{ $self->name_case($n) } ) {
      warn
"In $pkClass->{name} $n is already an attribute; can't redefine it as a default primary key\n";
#      $errors++;
      next;
    }
    unshift @{ $pkClass->{attList} }, $pkAtts;
    $pkClass->{atts}{ $self->name_case($n) } = $pkAtts;
  }
  $pkClass->{pk} = $defPK;

	return 1; # Explicit return is a good practice 
}

=head2 add_default_fk

For -f - add missing parts of a default foreign key to a parsed table
definition.

=cut

sub add_default_fk {
  my $self          = shift;
  my $fkClassLookup = shift;
  my $fkStr         = shift;
  my $fkAtts        = shift;
  my $pkAtts        = shift;
  my $nullClause    = shift;

  # Foreign key attributes may exist already; only create entries
  # for those not already there
  my @fkNames = split /\s*,\s*/, $fkStr;
  foreach my $i ( 0 .. $#{@fkNames} ) {
    if ( !$fkAtts->[$i]
      || $self->name_case( $fkAtts->[$i][0] ) ne $self->name_case( $fkNames[$i] ) )
    {

      # New FK has supplied name & supplied null clause,
      # and its other attributes (esp type) copied from its
      # corresponding primary key.
      my $newFK = [
        $fkNames[$i], $pkAtts->[$i][1],
        $nullClause, 0, @{$pkAtts}[ 4 .. $#{ $pkAtts->[$i] } ]
      ];
      splice @$fkAtts, $i, 0, $newFK;

      # add the new FK column to the end of the list of column defs
      push @{ $fkClassLookup->{attList} }, $newFK;
      $fkClassLookup->{atts}{ $self->name_case( $fkNames[$i] ) } = $newFK;
    }
  }
  return $fkAtts;
}


# Check that the given object and version is supported.  Return true
# on pass, undef on fail.
sub _check_object_version {
  my $self    = shift;
  my $type    = shift;
  my $version = int shift;    # can be zero, can have leading zeros
  
  if (!$type || !defined $version) {
    $self->{log}->error(qq{Need 2 args: type and version});
    return;
  }

  my %object_v = (
                  "UML - Association"  => [1,2],
                  "UML - Class"        => [0],
                  "UML - Component"    => [0],
                  "UML - Note"         => [0],
                  "UML - SmallPackage" => [0],
                 );

  $self->{log}->debug(qq{type:'$type' version:$version});

  if (!exists($object_v{$type})) {
    $self->{log}->debug(qq{type:'$type' unknown});
    return;
  }

  if (! grep(/^$version$/, @{$object_v{$type}})) {
    $self->{log}->debug(qq{type:'$type' version:$version unsupported});
    return;
  }

  return 1;
}

# Split a type definition 'type(nn)' into 'type', '(nn)'
sub split_type {
	my $self = shift;
	my $type = shift;

	if(!$type) {
		$self->{log}->warn("Missing type");
		return;
	}

	$type =~ m/^([^(]*)(\([^)]+\))?$/;
	my ($name, $size) = ($1, $2);
	if(!$name) {
		$self->{log}->warn("Malformed type name $type");
		return;
	}

	if ($size) {
		return ($name,$size);
	} else {
		return ($name);
	}
}

# =head2 parseExtras

# Parse the name of a Small Package that contains extra SQL clauses for
# the generated SQL, and add the SmallPackage text to the appropriate
# %tableExtras table for the type of extra clause (table, pk, index).

# =cut

# sub parseExtras {
#   my $self   = shift;
#   my $type   = shift;
#   my $params = shift;
#   my $dbText = shift;

#   my ($dbNames, $args) = split /\s*:\s*/, $params;
#   my $warns = 0;

#   return 0 if (!$args);

#   $args =~ s/\s//g;
#   $args =~ s/^[^(]*\(//;
#   $args =~ s/\)$//;

#   my @args = split /\s*,\s*/, $args;

#   if ($dbNames =~ /$opt_t/) {
#     foreach my $arg (@args) {
#       if (!$arg) {
#         warn "Null parameter in $params\n";
#         $warns++;
#         $errors++;
#         next;
#       }

#       if ($type =~ /^macro(.+)/) {
#         my $when = $1;
#         $macros{$arg} = { when => $when, sql => $dbText, used => 0 };
#         #if ($verbose) { print "Added $when Macro $arg\n"; }
#       } else {
#         my $dowarn = $tableExtras{$type}->{$arg};
#         if ($dowarn) {
#           warn "SQL clause for $type $arg redefined from\n"
#             . addExtraClauses('', $tableExtras{$type}->{$arg}, '    ');
#         }

#         $tableExtras{$type}->{$arg} = { sql => $dbText, used => 0 };
#         if ($dowarn) {
#           warn "to\n"
#             . addExtraClauses('', $tableExtras{$type}->{$arg}, '    ');
#         }
#       }
#     }
#   }

#   return $warns == 0;
# }

1;

__END__

# End of Parse::Dia::SQL::Utils
