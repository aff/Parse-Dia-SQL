package Parse::Dia::SQL::Output::Ingres;

# $Id: Ingres.pm,v 1.2 2009/03/02 13:41:39 aff Exp $

=pod

=head1 NAME 

Parse::Dia::SQL::Output::Ingres - Create SQL for Ingres.

=head1 SEE ALSO

 Parse::Dia::SQL::Output

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

The constructor.  Arguments:

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  # Set defaults for ingres
  $param{db}                     = q{ingres};
  $param{object_name_max_length} = $param{object_name_max_length} || 30;
  $param{end_of_statement}       = $param{end_of_statement} || "\n\\g";

  $self = $class->SUPER::new(%param);
  bless( $self, $class );

  return $self;
}

=head2 _get_drop_index_sql

create drop index for index on table with given name. 

  drop index idx_foo for ingres

=cut

sub _get_drop_index_sql {
  my ( $self, $tablename, $indexname ) = @_;
  return qq{drop index $indexname for } 
    . $self->{db}
    . $self->{end_of_statement}
    . $self->{newline};
}



1;

__END__

