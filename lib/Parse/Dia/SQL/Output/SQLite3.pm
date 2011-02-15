package Parse::Dia::SQL::Output::SQLite3;

# $Id: SQLite3.pm,v 1.5 2009/05/14 09:42:47 aff Exp $

=pod

=head1 NAME

Parse::Dia::SQL::Output::SQLite3 - Create SQL for SQLite version 3.

=head1 SYNOPSIS

    use Parse::Dia::SQL;
    my $dia = Parse::Dia::SQL->new(file => 'foo.dia', db => 'sqlite3');
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
  $param{db} = q{sqlite3};
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

=head2 get_schema_drop

Generate drop table statments for all tables using SQLite syntax:

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

Generate drop view statments for all tables using SQLite syntax:

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

Drop foreign key enforcement triggers using SQLite syntax:

  drop trigger {foo} if exists
  
The automatically generated foreign key enforcement triggers are:

See L<"_get_create_association_sql"> for more details.

=over

=item I<constraint_name>_bi_tr

=item I<constraint_name>_bu_tr

=item I<constraint_name>_buparent_tr

=item I<constraint_name>_bdparent_tr

=back

=cut

# Drop all foreign keys
sub _get_fk_drop {
  my $self   = shift;
  my $sqlstr = '';
  my $temp;

  return unless $self->_check_associations();

  # drop fk
  foreach my $association ( @{ $self->{associations} } ) {
    my ( $table_name, $constraint_name, undef, undef, undef, undef ) =
      @{$association};

    $temp = $constraint_name . "_bi_tr";
    $sqlstr .=
        qq{drop trigger if exists $temp}
      . $self->{end_of_statement}
      . $self->{newline};

    $temp = $constraint_name . "_bu_tr";
    $sqlstr .=
        qq{drop trigger if exists $temp}
      . $self->{end_of_statement}
      . $self->{newline};

    $temp = $constraint_name . "_buparent_tr";
    $sqlstr .=
        qq{drop trigger if exists $temp}
      . $self->{end_of_statement}
      . $self->{newline};

    $temp = $constraint_name . "_bdparent_tr";
    $sqlstr .=
        qq{drop trigger if exists $temp}
      . $self->{end_of_statement}
      . $self->{newline};

    $sqlstr .= $self->{newline};

  }
  return $sqlstr;
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

SQLite doesn't support permissions, so supress this output.

=cut

sub get_permissions_create {
  return '';
}

=head2 get_permissions_drop

SQLite doesn't support permissions, so supress this output.

=cut

sub get_permissions_drop {
  return '';
}

=head2 _get_create_association_sql

Create the foreign key enforcement triggers using SQLite syntax:

  create trigger {fkname}[_bi_tr|_bu_tr|_bdparent_tr|_buparent_tr]

Because SQLite doesn't natively enforce foreign key constraints (see L<http://www.sqlite.org/omitted.html>), 
we use triggers to emulate this behaviour.

The trigger names are the default contraint name (something like I<child_table>_fk_I<child_fkcolumn>) with suffixes described below.

=over

=item I<{constraint_name}> is the name of the association, either specified or generated.

=item I<{child_table}> is the name of the dependent or child table.

=item I<{child_fkcolumn}> is the field in the dependent table that hold the foreign key.

=item I<{parent_table}> is the name of the parent table.

=item I<{parent_key}> is the key field of the parent table.

=back

=head3 Before insert - Dependent Table

I<constraint_name>_bi_tr

Before insert on the child table require that the parent key exists.

  create trigger {constraint_name}_bi_tr before insert on {child_table}
    for each row 
      begin 
        select 
          raise(abort, 'insert on table {child_table} violates foreign key constraint {constraint_name}')
          where new.{child_fkcolumn} is not null and (select {parent_key} from {parent_table} where {parent_key}=new.{child_fkcolumn}) is null;
      end;

=head3 Before update - Dependent Table

I<constraint_name>_bu_tr

Before update on the child table require that the parent key exists.

  create trigger {constraint_name}_bu_tr before update on {table_name} 
    for each row 
      begin 
        select raise(abort, 'update on table {child_table} violates foreign key constraint {constraint_name}') 
        where new.{child_fkcolumn} is not null and (select {parent_key} from {parent_table} where {parent_key}=new.{child_fkcolumn}) is null;
      end;


=head3 Before update - Parent Table

I<constraint_name>_buparent_tr

Before update on the primary key of the parent table ensure that there are no dependent child records.
Note that cascading updates B<don't work>.

  create trigger {constraint_name}_buparent_tr before update on {parent_table}
    for each row when new.{parent_key} <> old.{parent_key}
      begin 
        select raise(abort, 'update on table {parent_table} violates foreign key constraint {constraint_name} on {child_table}') 
        where (select {child_fkcolumn} from {child_table} where {child_fkcolumn}=old.{parent_key}) is not null;
      end;

=head3 Before delete - Parent Table

I<constraint_name>_bdparent_tr

The default behaviour can be modified through the contraint (in the multiplicity field) of the association.

=head4 Default (On Delete Restrict)

Before delete on the parent table ensure that there are no dependent child records.

  create trigger {constraint_name}_bdparent_tr before delete on {parent_table}
    for each row 
      begin 
        select raise(abort, 'delete on table {parent_table} violates foreign key constraint {constraint_name} on {child_table}') 
        where (select {child_fkcolumn} from {child_table} where {child_fkcolumn}=old.{parent_key}) is not null;
      end;

=head4 On Delete Cascade

Before delete on the parent table delete all dependent child records.

  create trigger {constraint_name}_bdparent_tr before delete on {parent_table} 
    for each row 
      begin 
        delete from {child_table} where {child_table}.{child_fkcolumn}=old.{parent_key};
      end;

=head4 On Delete Set Null

Before delete on the parent table set the foreign key field(s) in all dependent child records to NULL.

  create trigger {constraint_name}_bdparent_tr before delete on {parent_table} 
    for each row 
      begin 
        update {child_table} set {child_table}.{child_fkcolumn}=null where {child_table}.{child_fkcolumn}=old.{parent_key};
      end;

=cut

# Create sql for given association.
sub _get_create_association_sql {
  my ( $self, $association ) = @_;
  my $sqlstr = '';
  my $temp;

  # Sanity checks on input
  if ( ref( $association ) ne 'ARRAY' ) {
    $self->{log}
      ->error( q{Error in association input - cannot create association sql!} );
    return;
  }

  # FK constraints are implemented as triggers in SQLite

  my (
    $table_name, $constraint_name, $key_column,
    $ref_table,  $ref_column,      $constraint_action
  ) = @{$association};

  # Shorten constraint name, if necessary (DB2 only)
  $constraint_name = $self->_create_constraint_name( $constraint_name );

  $temp = $constraint_name . "_bi_tr";
  $sqlstr .=
qq{create trigger $temp before insert on $table_name for each row begin select raise(abort, 'insert on table $table_name violates foreign key constraint $constraint_name') where new.$key_column is not null and (select $ref_column from $ref_table where $ref_column=new.$key_column) is null;end}
    . $self->{end_of_statement}
    . $self->{newline};

  $temp = $constraint_name . "_bu_tr";
  $sqlstr .=
qq{create trigger $temp before update on $table_name for each row begin select raise(abort, 'update on table $table_name violates foreign key constraint $constraint_name') where new.$key_column is not null and (select $ref_column from $ref_table where $ref_column=new.$key_column) is null;end}
    . $self->{end_of_statement}
    . $self->{newline};

  # note that the before delete triggers are on the parent ($ref_table)
  $temp = $constraint_name . "_bdparent_tr";
  if ( $constraint_action =~ /on delete cascade/i ) {
    $sqlstr .=
qq{create trigger $temp before delete on $ref_table for each row begin delete from $table_name where $table_name.$key_column=old.$ref_column;end}
      . $self->{end_of_statement}
      . $self->{newline};
  } elsif ( $constraint_action =~ /on delete set null/i ) {
    $sqlstr .=
qq{create trigger $temp before delete on $ref_table for each row begin update $table_name set $key_column=null where $table_name.$key_column=old.$ref_column;end}
      . $self->{end_of_statement}
      . $self->{newline};
  } else    # default on delete restrict
  {
    $sqlstr .=
qq{create trigger $temp before delete on $ref_table for each row begin select raise(abort, 'delete on table $ref_table violates foreign key constraint $constraint_name on $table_name') where (select $key_column from $table_name where $key_column=old.$ref_column) is not null;end}
      . $self->{end_of_statement}
      . $self->{newline};
  }

  # Cascade updates doesn't work, so we always restrict
  $temp = $constraint_name . "_buparent_tr";
  $sqlstr .=
qq{create trigger $temp before update on $ref_table for each row when new.$ref_column <> old.$ref_column begin select raise(abort, 'update on table $ref_table violates foreign key constraint $constraint_name on $table_name') where (select $key_column from $table_name where $key_column=old.$ref_column) is not null;end}
    . $self->{end_of_statement}
    . $self->{newline};

  $sqlstr .= $self->{newline};

  return $sqlstr;
}

1;

=head1 TODO

Things that might get added in future versions:

=head3 Mandatory constraints

The current foreign key triggers allow NULL in the child table. This might use a keyword in the 
multiplicity field (perhaps 'required') or could check the 'not null' state of the child fkcolumn.

=head3 Views

Views haven't been tested. They might already work, but who knows...

=head3 Other stuff

Bugs etc

=cut

__END__


