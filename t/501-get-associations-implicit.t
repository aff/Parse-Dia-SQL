#   $Id: 501-get-associations-implicit.t,v 1.1 2009/03/30 05:39:58 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 4;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data implicit_role.dia)), db => 'db2' );

isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
ok $diasql->convert();

my $association_arrayref = $diasql->get_associations_ref();
my $expected = [ [ 'emp', 'emp_fk_Dept_id', 'dept_id', 'dept', 'id','' ] ];

is_deeply($association_arrayref, $expected)
  or diag Dumper ($association_arrayref);
undef $diasql;

__END__

