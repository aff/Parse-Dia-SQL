#   $Id: 952-rt52755.t,v 1.1 2009/12/18 07:02:56 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 8;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::Postgres');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data rt52755.dia)), db => 'postgres');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});
my $sql = $diasql->get_sql();

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::Postgres},
  q{Expect Parse::Dia::SQL::Output::Postgres to be used as back-end}
);

# diag $sql;

like($sql, qr/.*
create \s+ table \s+ users \s* \(
 \s* id \s+ serial \s* ,
 \s* first \s+ TEXT \s+ not \s+ null \s*,
 \s+ last \s+ TEXT \s* ,
 \s+ UNIQUE \s* \( \s* first \s*, \s* last \s* \) \s* ,
 \s+ UNIQUE \s* \( \s* first \s* \) \s*
\) \s* ;
.*/six);

like($sql, qr/.*
create \s+ table \s+ testimonies \s+ \(
 \s+ id \s+ serial \s* ,
 \s+ from \s+ integer \s+ not \s+ null \s* ,
 \s+ to \s+ integer \s+ not \s+ null \s* ,
 \s+ subject \s+ text \s* ,
 \s+ comment \s+ text \s+ not \s+ null \s* ,
 \s+ UNIQUE \s+ \( \s* id \s* , \s* from \s* \) \s*
\) \s* ;
.*/six);

__END__


