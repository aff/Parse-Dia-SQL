#   $Id: 703-utils-get-base-name.t,v 1.1 2009/11/17 11:15:46 aff Exp $

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
my $utils = Parse::Dia::SQL::Utils->new( db => 'postgres' );
isa_ok($utils, 'Parse::Dia::SQL::Utils');

# make_name
is($utils->get_base_type('int2', 'postgres'),  'smallint');
is($utils->get_base_type('int4', 'postgres'),  'integer');
is($utils->get_base_type('serial', 'postgres'),  'integer');
is($utils->get_base_type('int8', 'postgres'),  'bigint');

is($utils->get_base_type('int2', 'mysql-myisam'),  'int2');

__END__
