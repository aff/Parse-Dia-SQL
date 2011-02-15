#   $Id: 620-output-get-schema-create.t,v 1.2 2009/04/01 08:10:43 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 23;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

# 1. parse input
my $db = 'db2';
my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => $db );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert to return 1});

my $classes       = $diasql->get_classes_ref();
my $associations  = $diasql->get_associations_ref();
my $smallpackages = $diasql->get_smallpackages_ref();

# check parsed content
ok(defined($classes) && ref($classes) eq q{ARRAY} && scalar(@$classes), q{Non-empty array ref});
ok(defined($associations) && ref($associations) eq q{ARRAY} && scalar(@$associations), q{Non-empty array ref});
ok( defined($smallpackages) && ref($smallpackages) eq q{ARRAY} && scalar(@$smallpackages),
  q{Non-empty array ref} );

# 2. get output instance
my $subclass   = undef;
lives_ok(sub { $subclass = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($subclass, 'Parse::Dia::SQL::Output')
  or diag(Dumper($subclass));
isa_ok($subclass, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($subclass));
can_ok($subclass, 'get_schema_create');

# 3. create sql
my $create_table = $subclass->get_schema_create();

# TODO: Notice that the primary key name can be any key starting with
# 'pk_'. This has to be changed for the DB2 support (18 char limit)

like($create_table, qr|.*
  create \s+ table \s+ imageInfo \s* \(
     \s* id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
     \s* insertionDate \s+ timestamp \s+ not \s+ null \s* ,
     \s* md5sum \s+ char \s* \(32\) \s+ not \s+ null \s* ,
     \s* binaryType \s+ varchar \s* \(16\) \s+ default \s+ 'jpg' \s+ null \s* ,
     \s* name \s+ varchar \s* \(64\) \s+ not \s+ null \s* ,
     \s* locationList \s+ varchar \s* \(128\) \s+ default \s+ '//imgserver.org' \s* ,
     \s* description \s+ varchar \s* \(128\) \s+ null \s* ,
     \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(id\) \s*
  \) \s* (;)?
.*|six, q{Check syntax for sql create table imageInfo});

like($create_table, qr|.*
  create \s+ table \s+ subImageInfo \s* \(
     \s* imageInfo_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
     \s* pixSize \s+ integer \s+ not \s+ null \s* ,
     \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(imageInfo_id \s* , \s* pixSize\) 
     \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table SubimageInfo});

like($create_table, qr|.*
  create \s+ table \s+ imageCategoryList \s* \(
    \s* imageInfo_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* name \s+ varchar \s* \(32\) \s+ not \s+ null \s* ,
    \s* constraint \s+ \w+ \s+ primary \s+ key \s* \(imageInfo_id \s* , \s* name\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table imageCategoryList});

like($create_table, qr|.*
  create \s+ table \s+ categoryNames \s* \(
    \s* name \s+ varchar \s* \(32\) \s+ not \s+ null \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(name\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table categoryNames});

like($create_table, qr|.*
  create \s+ table \s+ imageAttribute \s* \(
    \s* imageInfo_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* attributeCategory_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* numValue \s+ numeric \s* \(8\) \s* ,
    \s* category \s+ numeric \s* \(4\) \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(imageInfo_id,attributeCategory_id\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table imageAttribute});

like($create_table, qr|.*
  create \s+ table \s+ userInfo \s* \(
    \s* id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* insertionDate \s+ timestamp \s* ,
    \s* md5sum \s+ char \s* \(32\) \s* ,
    \s* birthDate \s+ timestamp \s* ,
    \s* gender \s+ char \s* \(1\) \s* ,
    \s* name \s+ varchar \s* \(32\) \s* ,
    \s* email \s+ varchar \s* \(96\) \s* ,
    \s* currentCategory \s+ varchar \s* \(32\) \s* ,
    \s* lastDebitDate \s+ timestamp \s* ,
    \s* acctBalance \s+ numeric \s* \(10,2\) \s* ,
    \s* active \s+ integer \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(id\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table userInfo});

like($create_table, qr|.*
  create \s+ table \s+ userAttribute \s* \(
    \s* userInfo_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* attributeCategory_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* numValue \s+ numeric \s* \(5,4\) \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(userInfo_id,attributeCategory_id\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table userAttribute});

like($create_table, qr|.*
  create \s+ table \s+ userImageRating \s* \(
    \s* userInfo_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* imageInfo_id \s+ numeric \s* \(15\) \s+ not \s+ null \s* ,
    \s* rating \s+ integer \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(userInfo_id,imageInfo_id\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table userAttribute});


like($create_table, qr|.*
  create \s+ table \s+ attributeCategory \s* \(
    \s* id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* attributeDesc \s+ varchar \s* \(128\) \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(id\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table userAttribute});

like($create_table, qr|.*
  create \s+ table \s+ userSession \s* \(
    \s* userInfo_id \s+ numeric \s* \(18\) \s+ not \s+ null \s* ,
    \s* md5sum \s+ char \s* \(32\) \s+ not \s+ null \s* ,
    \s* insertionDate \s+ timestamp \s* ,
    \s* expireDate \s+ timestamp \s* ,
    \s* ipAddress \s+ varchar \s* \(24\) \s* ,
    \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(userInfo_id,md5sum\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table userAttribute});

like($create_table, qr|.*
create \s+ table \s+ extremes \s* \(
    \s+ name \s+ varchar \s* \(32\) \s+ not \s+ null \s* ,
    \s+ colName \s+ varchar \s* \(64\) \s* ,
    \s+ minVal \s+ numeric \s* \(15\) \s* ,
    \s+ maxVal \s+ numeric \s* \(15\) \s* ,
		\s+ constraint \s+ pk_\w+ \s+ primary \s+ key  \s* \(name\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table extremes});

__END__
