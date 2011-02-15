#   $Id: 502-get-associations_version_2.t,v 1.1 2009/06/21 13:24:37 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 51;

use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Const');

# Get list of supported databases
my $const = Parse::Dia::SQL::Const->new();
isa_ok($const, q{Parse::Dia::SQL::Const});
my @rdbms = $const->get_rdbms();
undef $const;

foreach my $db (@rdbms) {
  my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data association_dia_0_97.dia)), db => $db );
  isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

  is($diasql->convert(), 1, q{Expect convert to return 1});

  my $association_arrayref = $diasql->get_associations_ref();
  #diag(Dumper($association_arrayref));

  my $expected = [ [ 'dog', 'fk_dog_owner', 'owner_id', 'owner', 'id', '' ] ];

  cmp_ok(scalar(@$association_arrayref), q{==}, scalar(@$expected), qq{Check number of foreign keys (db=$db)});

  is_deeply($association_arrayref, $expected, qq{get_associations_ref for db=$db});
  undef $diasql;
}

__END__
