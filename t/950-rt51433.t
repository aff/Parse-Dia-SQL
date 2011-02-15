#   $Id: 950-rt51433.t,v 1.1 2009/11/11 10:31:40 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 7;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::Postgres');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data rt51433.dia)), db => 'postgres');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});
my $sql = $diasql->get_sql();

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::Postgres},
  q{Expect Parse::Dia::SQL::Output::Postgres to be used as back-end}
);

like($sql, qr/.*
alter \s+ table \s+ tbl_detail \s+ add \s+ constraint \s+ fk_detail_main \s+ 
    foreign \s+ key \s+ \( \s* fk_main \s* \) \s+ 
    references \s+ tbl_main \s+ \( \s* pk_main \s* \) \s+ ON \s+ DELETE \s+ CASCADE \s* ;
.*/six);


__END__
