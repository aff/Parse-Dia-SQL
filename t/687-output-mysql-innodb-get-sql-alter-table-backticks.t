#   $Id: 687-output-mysql-innodb-get-sql.t,v 1.5 2009/09/28 19:12:06 aff Exp $

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
use_ok ('Parse::Dia::SQL::Output::MySQL');
use_ok ('Parse::Dia::SQL::Output::MySQL::InnoDB');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data TestERD.dia)), db => 'mysql-innodb', backticks => 1);
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

can_ok($diasql, q{get_sql}), # object should have method get_sql()
my $sql = $diasql->get_sql();

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::MySQL::InnoDB},
  q{Expect Parse::Dia::SQL::Output::MySQL::InnoDB to be used as back-end}
);

#diag($sql);

# Check for backticks:
like($sql, qr/.*
alter \s+ table \s+ `userAttribute` \s+ add \s+ constraint \s+ fk_acua  \s+ 
    foreign \s+ key \s+ \( \s* attributeCategory_id \s* \) \s+ 
    references \s+ `attributeCategory` \s+ \( \s* id \s* \) \s* ;
.*/six);




__END__
