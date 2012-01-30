package Parse::Dia::SQL::Output;

# $Id: Output.pm,v 1.33 2011/02/16 10:23:11 aff Exp $

=pod

=head1 NAME

Parse::Dia::SQL::Output - Create SQL base class.

=head1 SYNOPSIS

    use Parse::Dia::SQL;
    my $dia = Parse::Dia::SQL->new(...);
    my $output = $dia->get_output_instance();
    print $output->get_sql();

=head1 DESCRIPTION

This is the base sql formatter class for creating sql. It contains
basic functionality, which can be overridden in subclasses, one for
each RDBMS.

=head1 SEE ALSO

  Parse::Dia::SQL::Output::DB2
  Parse::Dia::SQL::Output::Oracle

=cut

use warnings;
use strict;
use open qw/:std :utf8/;

use Text::Table;
use Data::Dumper;
use Config;

use lib q{lib};
use Parse::Dia::SQL::Utils;
use Parse::Dia::SQL::Logger;
use Parse::Dia::SQL::Const;

=head1 METHODS

=over

=item new()

The constructor.  Arguments:

  db    - the target database type

=cut

sub new {
  my ($class, %param) = @_;

  my $self = {

    # command line options
    files       => $param{files}       || [],       # dia files
    db          => $param{db}          || undef,
    uml         => $param{uml}         || undef,
    fk_auto_gen => $param{fk_auto_gen} || undef,
    pk_auto_gen => $param{pk_auto_gen} || undef,
    default_pk  => $param{default_pk}  || undef,    # opt_p

    # formatting options
    indent           => $param{indent}           || q{ } x 3,
    newline          => $param{newline}          || "\n",
    end_of_statement => $param{end_of_statement} || ";",
    column_separator => $param{column_separator} || ",",
    sql_comment      => $param{sql_comment}      || "-- ",

    # sql options
    index_options          => $param{index_options}          || [],
    object_name_max_length => $param{object_name_max_length} || undef,
    table_postfix_options  => $param{table_postfix_options}  || [],
    table_postfix_options_separator => $param{table_postfix_options_separator}
      || ' ',

    # parsed datastructures
    associations   => $param{associations}   || [],      # foreign keys, indices
    classes        => $param{classes}        || [],      # tables and views
    components     => $param{components}     || [],      # insert statements
    small_packages => $param{small_packages} || [],
    typemap        => $param{typemap}        || {},      # custom type mapping
    loglevel       => $param{loglevel}       || undef,
    backticks      => $param{backticks}      || undef,   # MySQL-InnoDB only

    # references to components
    log   => undef,
    const => undef,
    utils => undef,
  };
  bless($self, $class);

  $self->_init_log();
  $self->_init_const();
  $self->_init_utils(loglevel => $param{loglevel});

  return $self;
}

# Initialize logger
sub _init_log {
  my $self = shift;
  my $logger = Parse::Dia::SQL::Logger::->new(loglevel => $self->{loglevel});
  $self->{log} = $logger->get_logger(__PACKAGE__);
  return 1;
}

# Initialize Constants component
sub _init_const {
  my $self = shift;
  $self->{const} = Parse::Dia::SQL::Const::->new();
  return 1;
}

# Initialize Parse::Dia::SQL::Utils class.
sub _init_utils {
  my $self = shift;
  $self->{utils} = Parse::Dia::SQL::Utils::->new(
    db       => $self->{db},
    loglevel => $self->{loglevel},
  );
  return 1;
}

# Return string with comment containing target database, $VERSION, time
# and list of files etc.
sub _get_comment {
  my $self = shift;
  my $files_word =
    (scalar(@{ $self->{files} }) > 1)
    ? q{Input files}
    : q{Input file};

  my @arr = (
    [ q{Parse::SQL::Dia}, qq{version $Parse::Dia::SQL::VERSION} ],
    [ q{Documentation},   q{http://search.cpan.org/dist/Parse-Dia-SQL/} ],
    [ q{Environment},     qq{Perl $], $^X} ],
    [ q{Architecture},    qq{$Config{archname}} ],
    [ q{Target Database}, $self->{db} ],
    [ $files_word,     join(q{, }, @{ $self->{files} }) ],
    [ q{Generated at}, scalar localtime() ],
  );

  # Add typemap for given database
  my $typemap_str = "not found in input file";
  if (exists($self->{typemap}->{ $self->{db} })) {
    $typemap_str = "found in input file";
  }
  push @arr, [ "Typemap for " . $self->{db}, $typemap_str ];

  # Add the sql_comment to first sub-element of all elements
  @arr = map { $_->[0] = $self->{sql_comment} . $_->[0]; $_ } @arr;

  my $tb = Text::Table->new();
  $tb->load(@arr);

  return scalar $tb->table();
}

=item get_sql()

Return all sql.  The sequence of statements is as follows:

  constraints drop
  permissions drop
  view drop
  schema drop
  smallpackage pre sql
  schema create
  view create
  permissions create
  inserts
  smallpackage post sql
  associations create  (indices first, then foreign keys)

=cut

sub get_sql {
  my $self = shift;

  ## No critic (NoWarnings)
  no warnings q{uninitialized};
  return
      $self->_get_comment()
    . $self->{newline}
    . "-- get_constraints_drop "
    . $self->{newline}
    . $self->get_constraints_drop()
    . $self->{newline}
    . "-- get_permissions_drop "
    . $self->{newline}
    . $self->get_permissions_drop()
    . $self->{newline}
    . "-- get_view_drop"
    . $self->{newline}
    . $self->get_view_drop()
    . $self->{newline}
    . "-- get_schema_drop"
    . $self->{newline}
    . $self->get_schema_drop()
    . $self->{newline}
    . "-- get_smallpackage_pre_sql "
    . $self->{newline}
    . $self->get_smallpackage_pre_sql()
    . $self->{newline}
    . "-- get_schema_create"
    . $self->{newline}
    . $self->get_schema_create()
    . $self->{newline}
    . "-- get_view_create"
    . $self->{newline}
    . $self->get_view_create()
    . $self->{newline}
    . "-- get_permissions_create"
    . $self->{newline}
    . $self->get_permissions_create()
    . $self->{newline}
    . "-- get_inserts"
    . $self->{newline}
    . $self->get_inserts()
    . $self->{newline}
    . "-- get_smallpackage_post_sql"
    . $self->{newline}
    . $self->get_smallpackage_post_sql()
    . $self->{newline}
    . "-- get_associations_create"
    . $self->{newline}
    . $self->get_associations_create();
}

# Return insert statements. These are based on content of the
# I<components>, and split on the linefeed character ("\n").
#
# Add $self->{end_of_statement} to each statement.
sub get_inserts {
  my $self   = shift;
  my $sqlstr = '';

  # Expect array ref of hash refs
  return unless $self->_check_components();

  $self->{log}->debug(Dumper($self->{components}))
    if $self->{log}->is_debug;

  foreach my $component (@{ $self->{components} }) {
    foreach my $vals (split("\n", $component->{text})) {

      $sqlstr .=
          qq{insert into }
        . $component->{name}
        . qq{ values($vals) }
        . $self->{end_of_statement}
        . $self->{newline};
    }
  }

  return $sqlstr;
}

# Drop all constraints (e.g. foreign keys and indices)
#
# This sub is split into two parts to make it easy sub subclass either.
sub get_constraints_drop {
  my $self = shift;

  # Allow undefined values
  no warnings q[uninitialized];
  return $self->_get_fk_drop() . $self->_get_index_drop();
}

# Drop all foreign keys
sub _get_fk_drop {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_associations();

  # drop fk
  foreach my $association (@{ $self->{associations} }) {
    my ($table_name, $constraint_name, undef, undef, undef, undef) =
      @{$association};

    # Shorten constraint name, if necessary (DB2 only)
    $constraint_name = $self->_create_constraint_name($constraint_name);

    $sqlstr .=
        qq{alter table $table_name drop constraint $constraint_name }
      . $self->{end_of_statement}
      . $self->{newline};
  }
  return $sqlstr;
}

# Drop all indices
sub _get_index_drop {
  my $self   = shift;
  my $sqlstr = q{};

  return unless $self->_check_classes();

  # drop index
  foreach my $table (@{ $self->{classes} }) {

    foreach my $operation (@{ $table->{ops} }) {

      if (ref($operation) ne 'ARRAY') {
        $self->{log}->error(
          q{Error in ops input - expect an ARRAY ref, got } . ref($operation));
        next OPERATION;
      }

      my ($opname, $optype) = ($operation->[0], $operation->[1]);

      # 2nd element can be index, unique index, grant, etc
      next if ($optype !~ qr/^(unique )?index$/i);

      $sqlstr .= $self->_get_drop_index_sql($table->{name}, $opname);
    }
  }
  return $sqlstr;
}

# Create drop index for index on table with given name.  Note that the
# tablename is not used here, but many of the overriding subclasses use
# it, so we include both the tablename and the indexname as arguments to
# keep the interface consistent.
sub _get_drop_index_sql {
  my ($self, $tablename, $indexname) = @_;

  return
      qq{drop index $indexname}
    . $self->{end_of_statement}
    . $self->{newline};
}

# Create drop view for all views
sub get_view_drop {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_classes();

CLASS:
  foreach my $object (@{ $self->{classes} }) {
    next CLASS if ($object->{type} ne q{view});

    # Sanity checks on internal state
    if (!defined($object)
      || ref($object) ne q{HASH}
      || !exists($object->{name}))
    {
      $self->{log}
        ->error(q{Error in table input - cannot create drop table sql!});
      next;
    }

    $sqlstr .=
        qq{drop view }
      . $object->{name}
      . $self->{end_of_statement}
      . $self->{newline};
  }

  return $sqlstr;

}

# Sanity check on internal state.
#
# Return true if and only if
#
#   $self->{components} should be a defined array ref with 1 or more
#   hash ref elements having two keys 'name' and 'text'
#
# otherwise false.
sub _check_components {
  my $self = shift;

  # Sanity checks on internal state
  if (!defined($self->{components})) {
    $self->{log}->warn(q{no components in schema});
    return;
  } elsif (ref($self->{components}) ne 'ARRAY') {
    $self->{log}->warn(q{components is not an ARRAY ref});
    return;
  } elsif (scalar(@{ $self->{components} } == 0)) {
    $self->{log}->info(q{components is an empty ARRAY ref});
    return;
  }

  foreach my $comp (@{ $self->{components} }) {
    if (ref($comp) ne q{HASH}) {
      $self->{log}->warn(q{component element must be a HASH ref});
      return;
    }
    if ( !exists($comp->{text})
      || !exists($comp->{name}))
    {
      $self->{log}->warn(
        q{component element must be a HASH ref with elements 'text' and 'name'}
      );
      return;
    }
  }

  return 1;
}

# Sanity check on internal state.
#
# Return true if and only if
#
#  $self->{classes} should be a defined array ref with 1 or more
#  elements, all of which must be defined
#
# otherwise false.
sub _check_classes {
  my $self = shift;

  # Sanity checks on internal state
  if (!defined($self->{classes})) {
    $self->{log}->warn(q{no classes in schema});
    return;
  } elsif (ref($self->{classes}) ne 'ARRAY') {
    $self->{log}->warn(q{classes is not an ARRAY ref});
    return;
  } elsif (scalar(@{ $self->{classes} } == 0)) {
    $self->{log}->info(q{classes is an empty ARRAY ref});
    return;
  }

  if (grep(!defined($_), (@{ $self->{classes} }))) {
    $self->{log}
      ->warn(q{the classes array reference contains an undefined element!});
    return;
  }

  return 1;
}

# Sanity check on internal state.
#
# Return true if and only if
#
#   $self->{associations} should be a defined array ref with 1 or more
#   elements
#
# otherwise false.
sub _check_associations {
  my $self = shift;

  # Sanity checks on internal state
  if (!defined($self->{associations})) {
    $self->{log}->warn(q{no associations in schema});
    return;
  } elsif (ref($self->{associations}) ne 'ARRAY') {
    $self->{log}->warn(q{associations is not an ARRAY ref});
    return;
  } elsif (scalar(@{ $self->{associations} } == 0)) {
    $self->{log}->info(q{associations is an empty ARRAY ref});
    return;
  }

  return 1;
}

# Sanity check on given reference.
#
# Return true if and only if
#
#   $arg should be a defined hash ref with 1 or more elements
#   $arg->{name} exists and is a defined scalar
#   $arg->{attList} exists and is a defined array ref.
#
# otherwise false.
sub _check_attlist {
  my $self = shift;
  my $arg  = shift;

  # Sanity checks on internal state
  if (!defined($arg) || ref($arg) ne q{HASH} || !exists($arg->{name})) {
    $self->{log}->error(q{Error in ref input!});
    return;
  }
  if (!exists($arg->{attList}) || ref($arg->{attList}) ne 'ARRAY') {
    $self->{log}->error(q{Error in ref attList input!});
    return;
  }
  return 1;
}

sub _check_small_packages {
  my $self = shift;

  # Sanity checks on internal state
  if (!defined($self->{small_packages})
    || ref($self->{small_packages}) ne q{ARRAY})
  {
    $self->{log}->error(q{small_packages error});
    return;
  }
  my %seen = ();    # Check for duplicate entries

  foreach my $sp (@{ $self->{small_packages} }) {
    if (ref($sp) ne 'HASH') {
      $self->{log}->error(q{Error in small_package input!});
      return;
    }
    ++$seen{$_} for (keys %{$sp});
  }
  foreach my $key (keys %seen) {
    $self->{log}->info(qq{Duplicate entry in small_package for key '$key' (}
        . $seen{$key}
        . q{ times)})
      if $seen{$key} > 1;
  }

  return 1;
}

# create drop table for all tables
#
# TODO: Consider rename to get_table[s]_drop
sub get_schema_drop {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_classes();

CLASS:
  foreach my $object (@{ $self->{classes} }) {
    next CLASS if ($object->{type} ne q{table});

    # Sanity checks on internal state
    if (!defined($object)
      || ref($object) ne q{HASH}
      || !exists($object->{name}))
    {
      $self->{log}
        ->error(q{Error in table input - cannot create drop table sql!});
      next;
    }

    $sqlstr .=
        qq{drop table }
      . $object->{name}
      . $self->{end_of_statement}
      . $self->{newline};
  }

  return $sqlstr;

}

# Create revoke sql
sub get_permissions_drop {
  my $self   = shift;
  my $sqlstr = '';

  # Check classes
  return unless $self->_check_classes();

  # loop through classes looking for grants
  foreach my $table (@{ $self->{classes} }) {

    foreach my $operation (@{ $table->{ops} }) {

      if (ref($operation) ne 'ARRAY') {
        $self->{log}->error(
          q{Error in ops input - expect an ARRAY ref, got } . ref($operation));
        next OPERATION;
      }

      my ($opname, $optype, $colref) =
        ($operation->[0], $operation->[1], $operation->[2]);

      # 2nd element can be index, unique index, grant, etc
      next if ($optype ne q{grant});

      $sqlstr .=
          qq{revoke $opname on }
        . $table->{name}
        . q{ from }
        . join(q{,}, @{$colref})
        . $self->{end_of_statement}
        . $self->{newline};
    }
  }

  return $sqlstr;

}

# Create grant sql
sub get_permissions_create {
  my $self   = shift;
  my $sqlstr = '';

  # Check classes
  return unless $self->_check_classes();

  # loop through classes looking for grants
  foreach my $table (@{ $self->{classes} }) {

    foreach my $operation (@{ $table->{ops} }) {

      if (ref($operation) ne 'ARRAY') {
        $self->{log}->error(
          q{Error in ops input - expect an ARRAY ref, got } . ref($operation));
        next OPERATION;
      }

      my ($opname, $optype, $colref) =
        ($operation->[0], $operation->[1], $operation->[2]);

      # 2nd element can be index, unique index, grant, etc
      next if ($optype ne q{grant});

      $sqlstr .=
          qq{$optype $opname on }
        . $table->{name} . q{ to }
        . join(q{,}, @{$colref})
        . $self->{end_of_statement}
        . $self->{newline};
    }
  }

  return $sqlstr;
}

# Create associations statements:
#
# This includes the following elements, in the following sequence
#
#   - index (unique and non-unique)
#   - foreign key
sub get_associations_create {
  my $self   = shift;
  my $sqlstr = '';

  # Check both ass. (fk) and classes (index) before operating on the
  # array refs.

  # indices
  if ($self->_check_classes()) {
    foreach my $object (@{ $self->{classes} }) {
      $sqlstr .= $self->_get_create_index_sql($object);
    }
  }

  # foreign keys
  if ($self->_check_associations()) {
    foreach my $object (@{ $self->{associations} }) {
      $sqlstr .= $self->_get_create_association_sql($object);
    }
  }

  return $sqlstr;
}

# Create table statements
sub get_schema_create {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_classes();

CLASS:
  foreach my $object (@{ $self->{classes} }) {
    next CLASS if ($object->{type} ne q{table});
    $sqlstr .= $self->_get_create_table_sql($object);
  }

  return $sqlstr;
}

# Create view statements
sub get_view_create {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_classes();

VIEW:
  foreach my $object (@{ $self->{classes} }) {
    next VIEW if ($object->{type} ne q{view});
    $sqlstr .= $self->_get_create_view_sql($object);
  }

  return $sqlstr;
}

# Create primary key clause, e.g.
#
#   constraint pk_<tablename> primary key (<column1>,..,<columnN>)
#
# Returns undefined if list of primary key is empty (i.e. if there are
# no primary keys on given table).
sub _create_pk_string {
  my ($self, $tablename, @pks) = @_;

  if (!$tablename) {
    $self->{log}
      ->error(q{Missing argument tablename - cannot create pk string!});
    return;
  }

  # Return undefined if list of primary key is empty
  if (scalar(@pks) == 0) {
    $self->{log}->debug(qq{table '$tablename' has no primary keys});
    return;
  }

  return qq{constraint pk_$tablename primary key (} . join(q{,}, @pks) . q{)};
}

# Create sql for given table.  Use _format_columns() to
# format columns nicely (without the comment column)
sub _get_create_table_sql {
  my ($self, $table) = @_;
  my @columns      = ();
  my @primary_keys = ();
  my @comments     = ();

  # Sanity checks on table ref
  return unless $self->_check_attlist($table);

  # Save the original table name (in case backticks are added)
  my $original_table_name = $table->{name};

  # Add backticks if option is set and dbtype is correct
  $table->{name} = $self->_quote_identifier($table->{name});

  # Check not null and primary key property for each column. Column
  # visibility is given in $columns[3]. A value of 2 in this field
  # signifies a primary key (which also must be defined as 'not null'.
  foreach my $column (@{ $table->{attList} }) {

    if (ref($column) ne 'ARRAY') {
      $self->{log}
        ->error(q{Error in view attList input - expect an ARRAY ref!});
      next COLUMN;
    }

    # Don't warn on uninitialized values here since there are lots
    # of them.

    ## no critic (ProhibitNoWarnings)
    no warnings q{uninitialized};

    $self->{log}->debug("column before: " . join(q{,}, @$column));

    # Field sequence:
    my ($col_name, $col_type, $col_val, $col_vis, $col_com) = @$column;

    # Add 'not null' if field is primary key
    if ($col_vis == 2) {
      $col_val = 'not null';
    }

    # Add column name to list of primary keys if $col_vis == 2
    push @primary_keys, $col_name if ($col_vis == 2);

    # Add 'default' keyword to defined values different from (not)
    # null when the column is not a primary key:
    # TODO: Special handling for SAS (in subclass)
    if ($col_val ne q{} && $col_val !~ /^(not )?null$/i && $col_vis != 2) {
      $col_val = qq{ default $col_val};
    }

    # Prefix non-empty comments with the comment character
    $col_com = $self->{sql_comment} . qq{ $col_com} if $col_com;

    if (!$self->{typemap}) {
      $self->{log}->debug("no typemap");
    }

    if (exists($self->{typemap}->{ $self->{db} })) {
      # typemap replace
      $col_type = $self->map_user_type($col_type);
    } else {
      $self->{log}->debug("no typemap for " . $self->{db});
    }

    # Add backticks to column name if option is enabled
    $col_name = $self->_quote_identifier($col_name);

    $self->{log}->debug(
      "column after : " . join(q{,}, $col_name, $col_type, $col_val, $col_com));

    # Create a line with out the comment
    push @columns, [ $col_name, $col_type, $col_val ];

    # Comments are added separately *after* comma on each line
    push @comments, $col_com;    # possibly undef
  }
  $self->{log}->warn("No columns in table") if !scalar @columns;

  # Format columns nicely (without the comment column)
  @columns = $self->_format_columns(@columns);
  $self->{log}->debug("columns:" . Dumper(\@columns));
  $self->{log}->debug("comments:" . Dumper(\@comments));

  # Add comma + newline + indent between the lines.
  # Note that _create_pk_string can return undef.
  @columns = (
    split(
      /$self->{newline}/,
      join(
        $self->{column_separator} . $self->{newline} . $self->{indent},
        @columns, $self->_create_pk_string($original_table_name, @primary_keys)
      )
    )
  );

  # Add the comment column, ensure the comma comes before the comment (if any)
  {
    ## no critic (ProhibitNoWarnings)
    no warnings q{uninitialized};
    @columns = map { $_ . shift(@comments) } @columns;
  }
  $self->{log}->debug("columns:" . Dumper(\@columns));

  # Add custom table postfix options if 'comment' section is defined
  $self->{log}->debug("table comment:" . Dumper($table->{comment}));
  if ($table->{comment}) {

    # Use comment only if it starts with given database type:
    if ($table->{comment} =~ m/^$self->{db}:\s*(.*)$/) {

      # Remove db-type
      my $table_comment = $1;

      # TODO: Add error checks on 'comment' input
      $self->{table_postfix_options} = [$table_comment];
    }

  }

  return
      qq{create table }
    . $table->{name} . " ("
    . $self->{newline}
    . $self->{indent}
    . join($self->{newline}, @columns)
    . $self->get_smallpackage_column_sql($table->{name})
    . $self->{newline} . ")"
    . $self->{indent}
    . join(
    $self->{table_postfix_options_separator},
    @{ $self->{table_postfix_options} }
    )
    . $self->{end_of_statement}
    . $self->{newline};
}

# Format columns in tabular form using Text::Table.
#
#  Input:  arrayref of arrayrefs
#  Output: arrayref of arrayrefs
sub _format_columns {
  my ($self, @columns) = @_;
  my @columns_out = ();

  $self->{log}->debug("input: " . Dumper(\@columns))
    if $self->{log}->is_debug();

  my $tb = Text::Table->new();
  $tb->load(@columns);

  # Take out one by one the formatted columns, remove newline character
  push @columns_out, map { s/\n//g; $_ } $tb->body($_)
    for (0 .. $tb->body_height());

  $self->{log}->debug("output: " . Dumper(@columns_out))
    if $self->{log}->is_debug();
  return @columns_out;
}

# Create sql for given view.
#
# Similar to _get_create_table_sql, but must handle
#   'from',
#   'where',
#   'order by',
#   'group by',
#
# TODO: ADD support for 'having' clause.
sub _get_create_view_sql {
  my ($self, $view) = @_;
  my @columns = ();
  my @from    = ();
  my @where   = ();
  my @orderby = ();
  my @groupby = ();

  # Sanity checks on view ref
  return unless $self->_check_attlist($view);

COLUMN:
  foreach my $column (@{ $view->{attList} }) {
    $self->{log}->debug(q{column: } . Dumper($column));

    if (ref($column) ne 'ARRAY') {
      $self->{log}
        ->error(q{Error in view attList input - expect an ARRAY ref, got }
          . ref($column));
      next COLUMN;
    }

    my $col_name = $column->[0];    # Pick first column
    $self->{log}->debug(qq{col_name: $col_name});

    push @columns, join(q{ }, $col_name);    # TODO: remove trailing whitespace
  }

OPERATION:
  foreach my $operation (@{ $view->{ops} }) {
    $self->{log}->debug($view->{name} . q{: operation: } . Dumper($operation));

    if (ref($operation) ne 'ARRAY') {
      $self->{log}
        ->error(q{Error in view attList input - expect an ARRAY ref, got }
          . ref($operation));
      next OPERATION;
    }

    my ($opname, $optype) = ($operation->[0], $operation->[1]);

    # skip grants
    next OPERATION if $optype eq q{grant};
    if ($optype eq q{from}) {
      push @from, $opname;
    } elsif ($optype eq q{where}) {
      push @where, $opname;
    } elsif ($optype eq q{order by}) {
      push @orderby, $opname;
    } elsif ($optype eq q{group by}) {
      push @groupby, $opname;
    } else {

      # unsupported view operation type
      $self->{log}->warn(qq{ unsupported view operation type '$optype'});
    }
  }

  my $retval =
      qq{create view }
    . $view->{name}
    . q{ as select }
    . $self->{newline}
    . $self->{indent}
    . join($self->{column_separator}, @columns)
    . $self->{newline}
    . $self->{indent}
    . q{ from }
    . join($self->{column_separator}, @from)
    . $self->{newline}
    . $self->{indent};

  # optional values
  $retval .=
      q{ where }
    . join($self->{newline} . $self->{indent}, @where)
    . $self->{newline}
    . $self->{indent}
    if (scalar(@where));
  $retval .= q{ group by } . join($self->{column_separator}, @groupby)
    if (scalar(@groupby));
  $retval .= q{ order by } . join($self->{column_separator}, @orderby)
    if (scalar(@orderby));

  # add semi colon or equivalent
  $retval .= $self->{end_of_statement} . $self->{newline};
  if ($self->{log}->is_debug()) {
    $self->{log}->debug(q{view: $retval});
  }
  return $retval;
}

# Create sql for given association.
sub _get_create_association_sql {
  my ($self, $association) = @_;

  # Sanity checks on input
  if (ref($association) ne 'ARRAY') {
    $self->{log}
      ->error(q{Error in association input - cannot create association sql!});
    return;
  }

  my (
    $table_name, $constraint_name, $key_column,
    $ref_table,  $ref_column,      $constraint_action
  ) = @{$association};

  # Shorten constraint name, if necessary (DB2 only)
  $constraint_name = $self->_create_constraint_name($constraint_name);

  # Add backticks to column name if option is enabled
  $ref_table = $self->_quote_identifier($ref_table);

  return
      qq{alter table $table_name add constraint $constraint_name }
    . $self->{newline}
    . $self->{indent}
    . qq{ foreign key ($key_column)}
    . $self->{newline}
    . $self->{indent}
    . qq{ references $ref_table ($ref_column) $constraint_action}
    . $self->{end_of_statement}
    . $self->{newline};
}

# Added only so that it can be overridden (e.g. in DB2.pm)
sub _create_constraint_name {
  my ($self, $tablename) = @_;
  return if !$tablename;
  return $tablename;
}

# Create sql for all indices for given table.
sub _get_create_index_sql {
  my ($self, $table) = @_;
  my $sqlstr = q{};

  # Sanity checks on input
  if (ref($table) ne 'HASH') {
    $self->{log}->error(q{Error in table input - cannot create index sql!});
    return;
  }

OPERATION:
  foreach my $operation (@{ $table->{ops} }) {

    if (ref($operation) ne 'ARRAY') {
      $self->{log}->error(
        q{Error in ops input - expect an ARRAY ref, got } . ref($operation));
      next OPERATION;
    }

    # Extract elements (the stereotype is not in use)
    my ($opname, $optype, $colref, $opstereotype, $opcomment) = (
      $operation->[0], $operation->[1], $operation->[2],
      $operation->[3], $operation->[4]
    );

    # 2nd element can be index, unique index, grant, etc.
    # Accept "index" only in this context.
    if ($optype !~ qr/^(unique )?index$/i) {
      $self->{log}->debug(qq{Skipping optype '$optype' - not (unique) index});
      next OPERATION;
    }

    # Use operation comment as index option if defined, otherwise
    # use default (if any)
    my $idx_opt =
      (defined $opcomment && $opcomment ne q{})
      ? $opcomment
      : join(q{,}, @{ $self->{index_options} });

    $sqlstr .=
        qq{create $optype $opname on }
      . $table->{name} . q{ (}
      . join(q{,}, @{$colref}) . q{) }
      . $idx_opt
      . $self->{end_of_statement}
      . $self->{newline};
  }
  return $sqlstr;
}

# Common function for all smallpackage statements. Returns statements
# for the parsed small packages that matches both db name and the
# given keyword (e.g. 'post').
sub _get_smallpackage_sql {
  my ($self, $keyword, $table_name) = @_;

  my @statements = ();
  return unless $self->_check_small_packages();

  # Each small package is a hash ref
  foreach my $sp (@{ $self->{small_packages} }) {

    # Foreach key in hash, pick those values whose
    # keys that contains db name and 'keyword':
    if ($table_name) {
      push @statements,
        map { $sp->{$_} }
        grep(/$self->{db}.*:\s*$keyword\s*\($table_name\)/, keys %{$sp});
    } else {
      push @statements,
        map { $sp->{$_} } grep(/$self->{db}.*:\s*$keyword/, keys %{$sp});
    }
  }
  return join($self->{newline}, @statements);

}

# Add SQL statements BEFORE generated code
sub get_smallpackage_pre_sql {
  my $self = shift;
  return $self->_get_smallpackage_sql(q{pre});
}

# Add SQL statements AFTER generated code
sub get_smallpackage_post_sql {
  my $self = shift;
  return $self->_get_smallpackage_sql(q{post});
}

# SQL clauses to add at the end of the named table definitions
sub get_smallpackage_table_sql {
  my $self = shift;
  return $self->{log}->logdie("NOTIMPL");
}

# SQL clauses to add at the end of the named table primary key
# constraints
sub get_smallpackage_pk_sql {
  my $self = shift;
  return $self->{log}->logdie("NOTIMPL");
}

# SQL clauses to add at the end of the named table column definitions
sub get_smallpackage_column_sql {
  my $self = shift;
  my ($table_name) = @_;

  my $clause = $self->_get_smallpackage_sql(q{columns}, $table_name);

  if ($clause ne '') {
    $clause =~ s/\n(.*?)/\n$self->{indent}$1/g;
    $clause = ',' . $self->{newline} . $self->{indent} . $clause;
    return $clause;
  }
  return '';
}

# SQL clauses to add at the end of the named table index definitions
sub get_smallpackage_index_sql {
  my $self = shift;
  return $self->{log}->logdie("NOTIMPL");
}

# store macro for generating statements BEFORE generated code
sub get_smallpackage_macropre_sql {
  my $self = shift;
  return $self->{log}->logdie("NOTIMPL");
}

# store macro for generating statements AFTER generated code
sub get_smallpackage_macropost_sql {
  my $self = shift;
  return $self->{log}->logdie("NOTIMPL");
}

# typemap replace
sub map_user_type {
  my ($self, $col_type) = @_;

  return $col_type if !$self->{typemap};
  return $col_type if !exists($self->{typemap}->{ $self->{db} });

  #$self->{log}->debug("typemap: " . Dumper($self->{typemap}));

  my ($orgname, $orgsize) = $self->{utils}->split_type($col_type);

  #return $col_type if !exists( $self->{typemap}->{ $self->{db} }->{$orgname} );

  if (exists($self->{typemap}->{ $self->{db} }->{$orgname})) {

    my $arref = $self->{typemap}->{ $self->{db} }->{$orgname};

    no warnings q[uninitialized];
    my ($newname, $newsize) = @$arref;

    #$self->{log}->debug("typemap arref match: " . Dumper($arref));

    # return newname + newsize if orgsize is undef
    return $newname . $newsize if !$orgsize;

    # return newname + newsize if orgsize equals newsize
    return $newname . $newsize if $orgsize eq $newsize;

    # return newname + orgsize if newsize is undef
    return $newname . $orgsize if !$newsize;

    # else error
    $self->{log}
      ->error(qq[Error in typemap usage: Cannot map from $col_type to $newname]
        . $newsize);
  }

  # Return the original type is we can't find a typemap replacement
  return $col_type;
}

# Add quotes (backticks) to identifier if option is set and db-type
# supports it (i.e. mysql-innodb).  See also Output/MySQL/InnoDB.pm
sub _quote_identifier {
  my ($self, $identifier) = @_;
  return $identifier;
}

1;

__END__

=back


