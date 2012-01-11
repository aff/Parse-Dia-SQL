#   $Id:  $

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
  Parse::Dia::SQL->new(file => catfile(qw(t data table_output_options.dia)), db => 'mysql-innodb');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});
my $sql = $diasql->get_sql();

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::MySQL::InnoDB},
  q{Expect Parse::Dia::SQL::Output::MySQL::InnoDB to be used as back-end}
);

#diag($sql);

like(
  $sql,
  qr/ENGINE=InnoDB, DEFAULT CHARSET=latin1, PARTITION BY range \('blah','foo'\)/,
  q{Expect sql to contain ENGINE=InnoDB, DEFAULT CHARSET=latin1, PARTITION BY range ('blah','foo')}
);

__END__
