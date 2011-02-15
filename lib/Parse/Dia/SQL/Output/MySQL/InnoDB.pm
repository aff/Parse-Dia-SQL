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
use base q{Parse::Dia::SQL::Output::MySQL}; # extends

require Parse::Dia::SQL::Logger;
require Parse::Dia::SQL::Const;

=head2 new()

The constructor.

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  $param{db} = q{mysql-innodb};    
  $param{table_postfix_options} = ['ENGINE=InnoDB','DEFAULT CHARSET=latin1'],
  $self = $class->SUPER::new(%param);

  bless( $self, $class );
  return $self;
}

# Drop all foreign keys
sub _get_fk_drop {
  my $self   = shift;
  my $sqlstr = '';

  return unless $self->_check_associations();

	# drop fk
  foreach my $association ( @{ $self->{associations} } ) {
    my ( $table_name, $constraint_name, undef, undef, undef, undef ) =
      @{$association};

    $sqlstr .=
        qq{alter table $table_name drop foreign key $constraint_name }
      . $self->{end_of_statement}
      . $self->{newline};
  }
  return $sqlstr;
}


1;

__END__

