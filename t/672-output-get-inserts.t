#   $Id: 672-output-get-inserts.t,v 1.2 2009/02/24 05:44:27 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 20;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});

my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));

can_ok($output, 'get_inserts');
my $inserts = $output->get_inserts();

like($inserts, qr/.*
insert \s+ into \s+ categoryNames \s+ values \s* \( \s* 'Buildings' \s* \) \s*  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ categoryNames \s+ values \s* \( \s*  'Landscapes'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ categoryNames \s+ values \s* \( \s*  'Nudes'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ categoryNames \s+ values \s* \( \s*  'Life \s+ Studies'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ categoryNames \s+ values \s* \( \s*  'Portraits'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ categoryNames \s+ values \s* \( \s*  'Abstracts'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ attributeCategory \s+ values \s* \( \s*  1 \s* , \s* 'Blurriness'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ attributeCategory \s+ values \s* \( \s*  2 \s* , \s* 'Contrastiness'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ attributeCategory \s+ values \s* \( \s*  3 \s* , \s* 'Saturation'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ attributeCategory \s+ values \s* \( \s*  4 \s* , \s* 'Size'  \s* \)  \s* ;
.*/six);

like($inserts, qr/.*
insert \s+ into \s+ attributeCategory \s+ values \s* \( \s*  5 \s* , \s* 'Relevence'  \s* \)  \s* ;
.*/six);


__END__
