#   $Id: 203-parse-classes-attlist.t,v 1.4 2009/04/01 08:10:43 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 47;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# TODO: Add test on return value - call wrapper
$diasql->convert();

my $classes = $diasql->get_classes_ref();

# Expect an array ref with 14 elements
isa_ok($classes, 'ARRAY');
cmp_ok(scalar(@$classes), q{==}, 14, q{Expect 14 classes});

# Hash with class/view names as keys and attribute list as (hashref) elements
my %attList = (
    imageInfo => [
        [ 'id',            'numeric (18)',  '',                    '2', '' ],
        [ 'insertionDate', 'timestamp',     'not null',      '0', '' ],
        [ 'md5sum',        'char (32)',     'not null',            '0', '' ],
        [ 'binaryType',    'varchar (16)',  '\'jpg\' null',        '0', '' ],
        [ 'name',          'varchar (64)',  'not null',            '0', '' ],
        [ 'locationList',  'varchar (128)', '\'//imgserver.org\'', '0', '' ],
        [ 'description',   'varchar (128)', 'null',                '0', '' ]
    ],
    users_view => [
        [ 'id',                                        '', '', '0', '' ],
        [ 'birthDate',                                 '', '', '0', '' ],
        [ 'name ||\'<\'|| email ||\'>\' as whoIsThis', '', '', '0', '' ],
        [ 'currentCategory',                           '', '', '0', '' ],
        [ 'acctBalance',                               '', '', '0', '' ],
        [ 'active',                                    '', '', '0', '' ]
    ],
    whorated_view => [
        [ 'a.name',                  '', '', '0', '' ],
        [ 'count (*) as numRatings', '', '', '0', '' ]
    ],
    ratings_view => [
        [ 'b.name',   '', '', '0', '' ],
        [ 'c.md5sum', '', '', '0', '' ],
        [ 'a.rating', '', '', '0', '' ]
    ],
    extremes => [
        [ 'name',    'varchar (32)', '', '2', '' ],
        [ 'colName', 'varchar (64)', '', '0', '' ],
        [ 'minVal',  'numeric (15)', '', '0', '' ],
        [ 'maxVal',  'numeric (15)', '', '0', '' ]
    ],
    userSession => [
        [ 'userInfo_id',   'numeric (18)', '', '2', '' ],
        [ 'md5sum',        'char (32)',    '', '2', '' ],
        [ 'insertionDate', 'timestamp',    '', '0', '' ],
        [ 'expireDate',    'timestamp',    '', '0', '' ],
        [ 'ipAddress',     'varchar (24)', '', '0', '' ]
    ],
    attributeCategory => [
        [ 'id',            'numeric (18)',  '', '2', '' ],
        [ 'attributeDesc', 'varchar (128)', '', '0', '' ]
    ],
    userImageRating => [
        [ 'userInfo_id',  'numeric (18)', '', '2', '' ],
        [ 'imageInfo_id', 'numeric (15)', '', '2', '' ],
        [ 'rating',       'integer',      '', '0', '' ]
    ],
    userAttribute => [
        [ 'userInfo_id',          'numeric (18)',  '', '2', '' ],
        [ 'attributeCategory_id', 'numeric (18)',  '', '2', '' ],
        [ 'numValue',             'numeric (5,4)', '', '0', '' ]
    ],
    userInfo => [
        [ 'id',              'numeric (18)',   '', '2', '' ],
        [ 'insertionDate',   'timestamp',      '', '0', '' ],
        [ 'md5sum',          'char (32)',      '', '0', '' ],
        [ 'birthDate',       'timestamp',      '', '0', '' ],
        [ 'gender',          'char (1)',       '', '0', '' ],
        [ 'name',            'varchar (32)',   '', '0', '' ],
        [ 'email',           'varchar (96)',   '', '0', '' ],
        [ 'currentCategory', 'varchar (32)',   '', '0', '' ],
        [ 'lastDebitDate',   'timestamp',      '', '0', '' ],
        [ 'acctBalance',     'numeric (10,2)', '', '0', '' ],
        [ 'active',          'integer',        '', '0', '' ]
    ],
    imageAttribute => [
        [ 'imageInfo_id',         'numeric (18)', '', '2', '' ],
        [ 'attributeCategory_id', 'numeric (18)', '', '2', '' ],
        [ 'numValue',             'numeric (8)',  '', '0', '' ],
        [ 'category',             'numeric (4)',  '', '0', '' ]
    ],
    categoryNames => [ [ 'name', 'varchar (32)', '', '2', '' ] ],
    imageCategoryList => [
        [ 'imageInfo_id', 'numeric (18)', '', '2', '' ],
        [ 'name',         'varchar (32)', '', '2', '' ]
    ],
    subImageInfo => [
        [ 'imageInfo_id', 'numeric (18)', '', '2', '' ],
        [ 'pixSize',      'integer',      '', '2', '' ]
    ],
);

# Check that each class has of the expected attList attributes
foreach my $class (@$classes) {
  #diag (Dumper($class));

  isa_ok($class, 'HASH');
  ok(exists($attList{$class->{name}}));

  # check contents
  is_deeply(
			$class->{attList},
			$attList{ $class->{name} },
			q{attList for } . $class->{name}
		   );

  # remove key-value pair from hash
  delete $attList{$class->{name}};
} 

# Expect no classes left now
cmp_ok(scalar(keys %attList), q{==}, 0, q{Expect 0 classes});

__END__

