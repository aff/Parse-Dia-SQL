package Parse::Dia::SQL::Output::MySQL;

# $Id: MySQL.pm,v 1.5 2009/03/02 13:41:39 aff Exp $

=pod

=head1 NAME 

Parse::Dia::SQL::Output::MySQL - Create SQL for MySQL base class

=head1 DESCRIPTION

Note that MySQL has support for difference storage engines.  Each
storage engine has its' own properties and the respective SQL differs.

=head1 SEE ALSO

 Parse::Dia::SQL::Output::MySQL::MyISAM
 Parse::Dia::SQL::Output::MySQL::InnoDB

=cut

use warnings;
use strict;

use Data::Dumper;
use File::Spec::Functions qw(catfile);

use lib q{lib};
use base q{Parse::Dia::SQL::Output}; # extends

require Parse::Dia::SQL::Logger;
require Parse::Dia::SQL::Const;

=head2 new

The constructor.

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  # Set defaults for MySQL (common for all storage engines)
  $param{object_name_max_length} = $param{object_name_max_length} || 64;
  $self = $class->SUPER::new(%param);

  bless( $self, $class );
  return $self;
}

=head2 _get_drop_index_sql

create drop index for index on table with given name.  Note that the
tablename is not used here, but many of the overriding subclasses use
it, so we include both the tablename and the indexname as arguments to
keep the interface consistent.

=cut

sub _get_drop_index_sql {
  my ( $self, $tablename, $indexname ) = @_;
  return qq{drop index $indexname on $tablename}
    . $self->{end_of_statement}
    . $self->{newline};
}

=head2 get_schema_drop

create drop table for all tables using MySQL syntax:

  drop table t if exists

=cut

sub get_schema_drop {
  my $self   = shift;
  my $sqlstr = '';

	return unless $self->_check_classes();

 CLASS:
  foreach my $object (@{ $self->{classes} }) {
		next CLASS if ($object->{type} ne q{table});

		# Sanity checks on internal state
		if (!defined($object) || ref($object) ne q{HASH} || !exists( $object->{name} )) {
			$self->{log}->error( q{Error in table input - cannot create drop table sql!} );
			next;
		}

		$sqlstr .= qq{drop table if exists }
    . $object->{name}
    . $self->{end_of_statement}
    . $self->{newline};
  }

  return $sqlstr;
}


1;

__END__

