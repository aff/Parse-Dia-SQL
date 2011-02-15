#   $Id: 610-output-getinstance.t,v 1.3 2009/02/28 06:54:57 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;  # test code that dies
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 8;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Logger');

my $diasql = undef;

# Test that lives - db => 'db2'
$diasql = Parse::Dia::SQL->new(db => 'db2');
isa_ok($diasql, 'Parse::Dia::SQL');

# Fool Parse::Dia::SQL into thinking convert() was called
$diasql->{converted} = 1; 

my $subclass = undef;
lives_ok(
  sub { $subclass = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die}
);
isa_ok($subclass, 'Parse::Dia::SQL::Output::DB2');

# Test that dies - db => 'foo'
undef $diasql;
ok(Parse::Dia::SQL::Logger::log_off());
throws_ok(
  sub { $diasql = Parse::Dia::SQL->new(db => 'foo'); },
  qr/Unsupported database/i,
  q{new(foo) should die}
);
ok(Parse::Dia::SQL::Logger::log_on());

__END__
