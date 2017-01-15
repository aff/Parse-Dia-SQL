
#   $Id: 961-rt57182-charset.t,v 1.2 2011/02/15 20:15:54 aff Exp $

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
  Parse::Dia::SQL->new(file => catfile(qw(t data non-latin1-chars.dia)), db => 'postgres');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});

my $sql = undef;
lives_ok(
		 sub {  $sql = $diasql->get_sql() },
		 q{get_sql should live on supported model type 'Database - Table'}
		);

my $components = $diasql->get_components_ref();
# diag(Dumper($components));

my $expected = [
				{
				 'text' => "'fjallg\x{f6}nguma\x{f0}ur'",
				 'name' => 'words'
				}
			   ];

is_deeply($components, $expected, q{Expect arrayref with text/name hash pairs});

my $outputter = $diasql->get_output_instance();
my $inserts = $outputter->get_inserts();

like($inserts, qr/.* fjallg\x{f6}nguma\x{f0}ur .*/x, q{Icelandic word for mountaineer});

#diag $inserts;
#print $inserts;

__END__


=pod

=head1 DESCRIPTION

 https://rt.cpan.org/Public/Bug/Display.html?id=57182

=cut

