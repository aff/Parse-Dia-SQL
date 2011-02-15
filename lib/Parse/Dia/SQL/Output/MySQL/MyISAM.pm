package Parse::Dia::SQL::Output::MySQL::MyISAM;

# $Id: MyISAM.pm,v 1.4 2009/03/02 13:41:39 aff Exp $

=pod

=head1 NAME 

Parse::Dia::SQL::Output::MySQL::MyISAM - Create SQL for MySQL MyISAM.

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
use base q{Parse::Dia::SQL::Output::MySQL}; # extends

require Parse::Dia::SQL::Logger;
require Parse::Dia::SQL::Const;

=head2 new

The constructor.

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  $param{db} = q{mysql-myisam};    
  $param{table_postfix_options} = ['ENGINE=MyISAM','DEFAULT CHARSET=latin1'],
  $self = $class->SUPER::new(%param);

  bless( $self, $class );
  return $self;
}

=head2 get_view_create

Views are not supported on MyISAM.  Warn and return undef.

=cut

sub get_view_create {
  my $self   = shift;
	$self->{log}->error(q{Views are not supported on MyISAM - Views not created.});
	return;
}

=head2 get_view_drop

Views are not supported on MyISAM.  Warn and return undef.

=cut

sub get_view_drop {
  my $self   = shift;  
	$self->{log}->error(q{Views are not supported on MyISAM - Views not dropped.});
	return;
}

1;

__END__

