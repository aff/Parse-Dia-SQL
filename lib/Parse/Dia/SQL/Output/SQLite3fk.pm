package Parse::Dia::SQL::Output::SQLite3fk;

# $Id: SQLite3.pm,v 1.5 2009/05/14 09:42:47 aff Exp $

=pod

=head1 NAME

Parse::Dia::SQL::Output::SQLite3fk - Create SQL for SQLite version 3, with foreign key support

=head1 SYNOPSIS

    use Parse::Dia::SQL;
    my $dia = Parse::Dia::SQL->new(file => 'foo.dia', db => 'sqlite3fk');
    print $dia->get_sql();

=head1 DESCRIPTION

This sub-class creates SQL for the SQLite database version 3.

=cut

use warnings;
use strict;

use Data::Dumper;
use File::Spec::Functions qw(catfile);

use lib q{lib};
use base q{Parse::Dia::SQL::Output};    # extends

require Parse::Dia::SQL::Logger;
require Parse::Dia::SQL::Const;

=head2 new

The constructor. 

Object names in SQLite have no inherent limit. 60 has been arbitrarily chosen.

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  # Set defaults for sqlite
  $param{db} = q{sqlite3fk};
  $param{object_name_max_length} = $param{object_name_max_length} || 60;

  $self = $class->SUPER::new( %param );
  bless( $self, $class );

  return $self;
}

=head2 _get_create_table_sql

Generate create table statement for a single table using SQLite
syntax:

Includes class comments before the table definition.

Includes autoupdate triggers based on the class comment.

Includes foreign key support of the form

  foreign key(thisColumn)  references thatTable(thatColumn) {action}
  
Where {action} is the optional contraint condition, such as 'on delete cascade' exactly as entered in the diagram.

=head3 autoupdate triggers

If the class comment includes a line like:

<autoupdate:I<foo>/>

Then an 'after update' trigger is generated for this table which
executes the statement I<foo> for the updated row.

Examples of use include tracking record modification dates
(C<<autoupdate:dtModified=datetime('now')/>>) or deriving a value from
another field (C<<autoupdate:sSoundex=soundex(sName)/>>)

=cut

sub _get_create_table_sql {

  my ( $self, $table ) = @_;
  my $sqlstr = '';
  my $temp;
  my $comment;
  my $tablename;
  my $trigger = '';
  my $update;
  my $primary_keys = '';

  my @columns      = ();
  my @primary_keys = ();
  my @comments     = ();

  # Sanity checks on table ref
  return unless $self->_check_attlist($table);

  
  # include the comments before the table creation
  $comment = $table->{comment};
  if ( !defined( $comment ) ) { $comment = ''; }
  $tablename = $table->{name};
  $sqlstr .= $self->{newline};
  if ( $comment ne "" ) {
    $temp = "-- $comment";
    $temp =~ s/\n/\n-- /g;
    $temp =~ s/^-- <autoupdate(\s*)(.*):(.*)\/>$//mgi;
    if ( $temp ne "" ) {
      if ( $temp !~ /\n$/m ) { $temp .= $self->{newline}; }
      $sqlstr .= $temp;
    }
  }

  # Call the base class to generate the main create table statements
  $sqlstr .= $self->SUPER::_get_create_table_sql( $table );

  # Generate update triggers if required
  if ( $comment =~ /<autoupdate(\s*)(.*):(.*)\/>/mi ) {
    $update  = $3;    # what we will set it to
    $trigger = $2;    # the trigger suffix to use (optional)
    $trigger = $tablename . "_autoupdate" . $trigger;

    # Check that the column exists
    foreach $temp ( @{ $table->{attList} } ) {

      # build the two primary key elements
      if ( $$temp[3] == 2 ) {
        if ( $primary_keys ) { $primary_keys .= " and "; }
        $primary_keys .= $$temp[0] . "=OLD." . $$temp[0];
      }
    }

    $sqlstr .=
        "drop trigger if exists $trigger"
      . $self->{end_of_statement}
      . $self->{newline};

    $sqlstr .=
"create trigger $trigger after update on $tablename begin update $tablename set $update where $primary_keys;end"
      . $self->{end_of_statement}
      . $self->{newline};

    $sqlstr .= $self->{newline};
  }

  return $sqlstr;
}

=head2 _create_pk_string

Override default function to include foreign key clauses

=cut

sub _create_pk_string {
  my ($self, $tablename, @pks) = @_;
  my $sqlstr = '';
  my $sep = '';

  $sqlstr .= $self->SUPER::_create_pk_string($tablename, @pks);

   my $fk = '';
  # Find the foriegn keys for this table
  if ($self->_check_associations()) {
    foreach my $object (@{ $self->{associations} }) {
        my ( $table_name, $constraint_name, $key_column, $ref_table, $ref_column, $constraint_action ) = @{$object};
        if ( $table_name eq $tablename ) {
            #print "ref from " . $table_name . "." . $key_column . " to " . $ref_table . "." . $ref_column ." as " . $constraint_name . " with action " . $constraint_action . ".\n";
            $fk .= $self->{newline}
                 . $self->{indent}
                 . qq{foreign key} . '('
                 . $key_column . ') '
                 . qq{references }
                 . $ref_table . '(' . $ref_column .') '
                 . $constraint_action
                 . ',';
        }
    }
  }
  
  # Trim the last comma
  $fk =~ s/,$//;
  # If we have both PK and FK cluases, we need a comma separator
  if ($fk and $sqlstr) {
    $sqlstr .= ',';
  }
  return $sqlstr . $fk;
}


=head2 get_schema_drop

Generate drop table statements for all tables using SQLite syntax:

  drop table {foo} if exists

=cut

sub get_schema_drop {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_classes();

CLASS:
  foreach my $object ( @{ $self->{classes} } ) {
    next CLASS if ( $object->{type} ne q{table} );

    # Sanity checks on internal state
    if (!defined( $object )
      || ref( $object ) ne q{HASH}
      || !exists( $object->{name} ) )
    {
      $self->{log}
        ->error( q{Error in table input - cannot create drop table sql!} );
      next;
    }

    $sqlstr .=
        qq{drop table if exists }
      . $object->{name}
      . $self->{end_of_statement}
      . $self->{newline};
  }

  return $sqlstr;
}

=head2 get_view_drop

Generate drop view statements for all tables using SQLite syntax:

  drop view {foo} if exists

=cut

# Create drop view for all views
sub get_view_drop {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_classes();

CLASS:
  foreach my $object ( @{ $self->{classes} } ) {
    next CLASS if ( $object->{type} ne q{view} );

    # Sanity checks on internal state
    if (!defined( $object )
      || ref( $object ) ne q{HASH}
      || !exists( $object->{name} ) )
    {
      $self->{log}
        ->error( q{Error in table input - cannot create drop table sql!} );
      next;
    }

    $sqlstr .=
        qq{drop view if exists }
      . $object->{name}
      . $self->{end_of_statement}
      . $self->{newline};
  }

  return $sqlstr;

}

=head2 _get_fk_drop

Foreign key enforcement is embedded in the table definitions for SQLite, so no output is required here.

=cut

# Drop all foreign keys
sub _get_fk_drop {
  my $self   = shift;

  return '';
 }

=head2 _get_drop_index_sql

drop index statement using SQLite syntax:

  drop index {foo} if exists

=cut

sub _get_drop_index_sql {
  my ( $self, $tablename, $indexname ) = @_;
  return
      qq{drop index if exists $indexname}
    . $self->{end_of_statement}
    . $self->{newline};
}

=head2 get_permissions_create

SQLite doesn't support permissions, so suppress this output.

=cut

sub get_permissions_create {
  return '';
}

=head2 get_permissions_drop

SQLite doesn't support permissions, so suppress this output.

=cut

sub get_permissions_drop {
  return '';
}

=head2 _get_create_association_sql

Foreign key enforcement is embedded in the table definitions for SQLite, so no output is required here.

=cut

# Create sql for given association.
sub _get_create_association_sql {
  my ( $self, $association ) = @_;

  return '';
}

1;

=head1 TODO

Things that might get added in future versions:

=head3 Views

Views haven't been tested. They might already work, but who knows...

=head3 Other stuff

Bugs etc

=cut

__END__


