package Parse::Dia::SQL::Output::MySQL::InnoDB;

# $Id: InnoDB.pm,v 1.4 2009/03/13 16:05:59 aff Exp $

=pod

=head1 NAME 

Parse::Dia::SQL::Output::MySQL::InnoDB - Create SQL for MySQL InnoDB.

=head1 DESCRIPTION

Note that MySQL has support for difference storage engines.  Each
storage engine has its' own properties and the respective SQL differs.

=head1 SEE ALSO

 Parse::Dia::SQL::Output
 Parse::Dia::SQL::Output::MySQL
 Parse::Dia::SQL::Output::MySQL::InnoDB

=cut

use warnings;
use strict;

use Data::Dumper;
use File::Spec::Functions qw(catfile);

use lib q{lib};
use base q{Parse::Dia::SQL::Output::MySQL};    # extends

require Parse::Dia::SQL::Logger;
require Parse::Dia::SQL::Const;

=head2 new()

The constructor.

=cut

sub new {
  my ($class, %param) = @_;
  my $self = {};

  $param{db}                    = q{mysql-innodb};
  $param{table_postfix_options} = [ 'ENGINE=InnoDB', 'DEFAULT CHARSET=latin1' ],
    $self                       = $class->SUPER::new(%param);

  bless($self, $class);

  #die "backticks:" . $self->{backticks};

  # MySQL-InnoDB only
  $self->{BACKTICK_CHAR} = q{`};

  return $self;
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

    $sqlstr .=
        qq{alter table $table_name drop foreign key $constraint_name }
      . $self->{end_of_statement}
      . $self->{newline};
  }
  return $sqlstr;
}

# Difference from Parse::Dia::SQL::Output::_get_create_table_sql
#
# If option 'backticks' is true, then add BACKTICK_CHAR before and after
# - table name
# - column names
#
sub _get_create_table_sql {
  my ($self, $table) = @_;
  my @columns      = ();
  my @primary_keys = ();
  my @comments     = ();

  # Save the original table name (in case backticks are added)
  my $original_table_name = $table->{name};

  # Sanity checks on table ref
  return unless $self->_check_attlist($table);

  # Add backticks to table name if option is enabled
  if ($self->{backticks}) {
    $table->{name} =
      $self->{BACKTICK_CHAR} . $table->{name} . $self->{BACKTICK_CHAR};
  }

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
	if ($self->{backticks}) {
	  $col_name =
		$self->{BACKTICK_CHAR} . $col_name . $self->{BACKTICK_CHAR};
	}

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

1;

__END__

