#   $Id: 704-utils-split-type.t,v 1.1 2010/01/22 21:33:15 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 7;

use lib q{lib};
use_ok ('Parse::Dia::SQL::Utils');

# Need to specify database for make_name to pass
my $utils = Parse::Dia::SQL::Utils->new( db => 'db2' );
isa_ok($utils, 'Parse::Dia::SQL::Utils');

# make_name
my @arr = $utils->split_type("integer(4)");
is_deeply(\@arr, ["integer", "(4)"], "integer(4)");

@arr = $utils->split_type("string(80)");
is_deeply(\@arr, ["string", "(80)"], "string(80)");

@arr = $utils->split_type("string");
is_deeply(\@arr, ["string"], "string");

ok (! $utils->split_type(""), "empty");
ok (! $utils->split_type(), "undef");

__END__
