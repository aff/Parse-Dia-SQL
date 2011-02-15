
#   $Id: 962-rt57842-postsgres-int.t,v 1.1 2010/05/27 09:21:47 aff Exp $

use warnings;
use strict;

use locale;
use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 6;
 
use lib q{lib};
use_ok ('Parse::Dia::SQL');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data rt57842.dia)), db => 'postgres');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});

my $sql = undef;
lives_ok(
		 sub {  $sql = $diasql->get_sql() },
		 q{get_sql should live on supported model type 'Database - Table'}
		);


my $outputter = $diasql->get_output_instance();
can_ok($outputter, q{get_associations_create});

my $association_str = $outputter->get_associations_create();

like($association_str, qr|.*
alter \s+ table \s+ sales \s+ add \s+ constraint \s+ sales_fk_User_id \s+ 
     foreign \s+ key \s* \( \s* user_id \s* \) \s+ 
     references \s+ users \s* \( \s* user_id \s* \) .*
|six, q{Expect constraint on sales});


__END__


=pod

=head1 DESCRIPTION

 https://rt.cpan.org/Public/Bug/Display.html?id=57182

=cut

