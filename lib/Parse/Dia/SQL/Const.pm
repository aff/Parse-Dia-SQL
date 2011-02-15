package Parse::Dia::SQL::Const;

# $Id: Const.pm,v 1.8 2009/04/01 07:31:10 aff Exp $

=pod

=head1 NAME

Parse::Dia::SQL::Const - Constants and lookup methods

=head1 SYNOPSIS

    use Parse::Dia::SQL::Const;
    my $const = Parse::Dia::SQL::Const->new();
    my @rdbms = $const->get_rdbms();

=head1 DESCRIPTION

This module contains constants and related lookup methods.

=cut


use warnings;
use strict;

use lib q{lib};
use Parse::Dia::SQL::Logger;

# List of supported relational database management systems
my @RDBMS = qw (
  db2
  informix
  ingres
  innodb
  mssql
  mysql-myisam
  mysql-innodb
  oracle
  postgres
  sas
  sybase
  sqlite3
);

my %OUTPUT_CLASS = (
  'db2'          => 'Parse::Dia::SQL::Output::DB2',
  'informix'     => 'Parse::Dia::SQL::Output::Informix',
  'ingres'       => 'Parse::Dia::SQL::Output::Ingres',
  'innodb'       => 'Parse::Dia::SQL::Output::InnoDB',
  'mssql'        => 'Parse::Dia::SQL::Output::MSSQL',
  'mysql-innodb' => 'Parse::Dia::SQL::Output::MySQL::InnoDB',
  'mysql-myisam' => 'Parse::Dia::SQL::Output::MySQL::MyISAM',
  'oracle'       => 'Parse::Dia::SQL::Output::Oracle',
  'postgres'     => 'Parse::Dia::SQL::Output::Postgres',
  'sas'          => 'Parse::Dia::SQL::Output::SAS',
  'sybase'       => 'Parse::Dia::SQL::Output::Sybase',
  'sqlite3'      => 'Parse::Dia::SQL::Output::SQLite3',
);

# Each statement type must be generated in correct order
my @SMALL_PACK_GEN_SEQ = qw (
  pre
  post
  table
  pk
  columns
  index
  typemap
  macropre
  macropost
);


=head2 new

The constructor.  No arguments.

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  bless( $self, $class );
  return $self;
}

=head2 get_rdbms

Return list of supported databases.

=cut

sub get_rdbms {
  my $self = shift;
  return @RDBMS;
}

=head2 get_small_pack_gen_seq

Return list with sequence for small packages processing.

=cut

sub get_small_pack_gen_seq {
  my $self = shift;
  return @SMALL_PACK_GEN_SEQ;
}


=head2 get_class_name

Database to class lookup. Used by Output->new.

=cut

sub get_class_name {
  my ($self, $db) = @_;
  if (exists($OUTPUT_CLASS{$db})) {
		return $OUTPUT_CLASS{$db};
  } else {
		return;
  }
}

1;

__END__
