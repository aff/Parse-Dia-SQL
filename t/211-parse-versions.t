#   $Id: 211-parse-versions.t,v 1.1 2009/06/21 13:24:37 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 7;

use_ok ('Parse::Dia::SQL');

# supported
my $pds = Parse::Dia::SQL->new( file => catfile(qw(t data version.supported.dia)), db => 'db2' );
isa_ok($pds, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# parse and convert
is($pds->convert(), 1, q{Expect convert() to return 1});

my $classes = $pds->get_classes_ref();
#diag(Dumper($classes));
cmp_ok (scalar @$classes, q[==], 14, q{Expect an array ref with 14 elements});

# unsupported
undef $pds;
undef $classes;
$pds = Parse::Dia::SQL->new( file => catfile(qw(t data version.unsupported.dia)), db => 'db2' );
isa_ok($pds, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# parse and convert
is($pds->convert(), 1, q{Expect convert() to return 1});

$classes = $pds->get_classes_ref();
#diag(Dumper($classes));
is_deeply ($classes, [], q{Expect an empty array ref});

__END__

=pod

=head1 Test of XML object versions.

=cut


