#   $Id: 100-parse-small-packages.t,v 1.2 2009/02/26 13:46:44 aff Exp $

use warnings;
use strict;

use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );
use Data::Dumper;

plan tests => 7;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( files => [catfile(qw(t data TestERD.dia))], db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# Parse and convert
cmp_ok($diasql->convert(), q{==}, 1,q{Expect convert to return 1});

# check that nodelists returns array of XML::DOM::NodeList
my $nodelists = $diasql->_get_nodelists();
foreach my $nodelist (@{$nodelists}){
  isa_ok($nodelist, q{XML::DOM::NodeList});
}

my $expected = [
  {
    'oracle,postgres,db2:pre' => '-- statements to do BEFORE creating
-- the tables (schema)
drop sequence imageInfo_id;
create sequence imageInfo_id;'
  },
  {
    'oracle,postgres,db2:post' => '-- statements to do AFTER creating
-- the tables (schema)
--drop trigger . . . .
--create trigger . . . .'
  },
  ];

# Check contents of small packages
my $smallpackages_ref = $diasql->get_smallpackages_ref();
#diag(Dumper($smallpackages_ref));

isa_ok($smallpackages_ref, 'ARRAY');
is_deeply($smallpackages_ref, $expected, q{Expect arrayref of hashrefs});



__END__

