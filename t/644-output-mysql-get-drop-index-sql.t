#   $Id: 644-output-mysql-get-drop-index-sql.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 41;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::MySQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'mysql-myisam' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (mysql-myisam) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output');
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL');
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL::MyISAM');
can_ok($output, 'get_constraints_drop');
my $drop_constraints = $output->get_constraints_drop();

#diag($drop_constraints);

# indices
like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iimd5 \s+ on \s+ imageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iiid \s+ on \s+ imageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siiid \s+ on \s+ subImageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siips \s+ on \s+ subImageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iclidnm \s+ on \s+ imageCategoryList \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uinm \s+ on \s+ userInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiid \s+ on \s+ userInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uauiid \s+ on \s+ userAttribute \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiruid \s+ on \s+ userImageRating \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_acid \s+ on \s+ attributeCategory \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_usmd5 \s+ on \s+ userSession \s* (;)?
.*/six);

# do it all again this time for InnoDB

$diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'mysql-innodb' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});
$output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (mysql-innodb) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output');
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL');
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL::InnoDB');
can_ok($output, 'get_constraints_drop');
$drop_constraints = $output->get_constraints_drop();

#diag($drop_constraints);

# indices
like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iimd5 \s+ on \s+ imageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iiid \s+ on \s+ imageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siiid \s+ on \s+ subImageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siips \s+ on \s+ subImageInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iclidnm \s+ on \s+ imageCategoryList \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uinm \s+ on \s+ userInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiid \s+ on \s+ userInfo \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uauiid \s+ on \s+ userAttribute \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiruid \s+ on \s+ userImageRating \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_acid \s+ on \s+ attributeCategory \s* (;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_usmd5 \s+ on \s+ userSession \s* (;)?
.*/six);




__END__


