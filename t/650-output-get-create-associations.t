#   $Id: 650-output-get-create-associations.t,v 1.3 2009/10/01 18:22:46 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 21;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

ok $diasql->convert();

# Output
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));

can_ok($output, 'get_associations_create');

# associations = foreign keys + indices
my $association_str = $output->get_associations_create();

# unique index
like($association_str, qr|.*
create \s+ unique \s+ index \s+ idx_iimd5 \s+ on \s+ imageInfo 
  \s* \( \s* md5sum \s* \) \s* allow \s+ reverse \s+ scans \s* (;)?
.*
|six, q{Expect unique index on imageInfo});

like($association_str, qr|.*
create \s+ unique \s+ index \s+ idx_uinm \s+ on \s+ userInfo \s* \(name,md5sum\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect unique index});

like($association_str, qr|.*
create \s+ unique \s+ index \s+ idx_iimd5 \s+ on \s+ imageInfo \s* \(md5sum\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect unique index});

# index
like($association_str, qr|.*
create \s+ index \s+ idx_iiid \s+ on \s+ imageInfo \s* \(id\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_siiid \s+ on \s+ subImageInfo \s* \(imageInfo_id\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_siips \s+ on \s+ subImageInfo \s* \(pixSize\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_iclidnm \s+ on \s+ imageCategoryList \s* \(imageInfo_id,name\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_uiid \s+ on \s+ userInfo \s* \(id\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_uauiid \s+ on \s+ userAttribute \s* \(userInfo_id\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_uiruid \s+ on \s+ userImageRating \s* \(userInfo_id\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_acid \s+ on \s+ attributeCategory \s* \(id\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

like($association_str, qr|.*
create \s+ index \s+ idx_usmd5 \s+ on \s+ userSession \s* \(md5sum\) \s* allow \s+ reverse \s+ scans \s* (;)?
|six, q{Expect index});

# foreign keys
like($association_str, qr|.*
alter \s+ table \s+ subImageInfo \s+ add \s+ constraint \s+ fk_iisii
  \s+ foreign \s+ key \s* \( \s* imageInfo_id \s* \) \s* 
  \s+ references \s+ imageInfo \s* \( \s* id \s* \) \s* 
(;)?
.*
|six, q{Expect foreign key fk_iisii on subImageInfo});

diag(q{TODO: add all foreign keys});
undef $diasql;


__END__
