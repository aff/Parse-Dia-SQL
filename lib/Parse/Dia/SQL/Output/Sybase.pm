package Parse::Dia::SQL::Output::Sybase;

# $Id: Sybase.pm,v 1.2 2009/03/02 13:41:39 aff Exp $

=pod

=head1 NAME 

Parse::Dia::SQL::Output::Sybase - Create SQL for Sybase.

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

  # Set defaults for sybase
  $param{db}                     = q{sybase};
  $param{object_name_max_length} = $param{object_name_max_length} || 30;
  $param{end_of_statement}       = $param{end_of_statement} || "\ngo";

  $self = $class->SUPER::new(%param);
  bless( $self, $class );

	$self->{log}->warn(qq{Using object_name_max_length }. $param{object_name_max_length});

  return $self;
}

=head2 _get_drop_index_sql

create drop index for index on table with given name. 

=cut

sub _get_drop_index_sql {
  my ( $self, $tablename, $indexname ) = @_;
  return qq{drop index $tablename.$indexname}
    . $self->{end_of_statement}
    . $self->{newline};
}




1;

__END__

