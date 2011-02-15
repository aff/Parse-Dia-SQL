#   $Id: 204-parse-classes-atts.t,v 1.4 2009/04/01 08:10:43 aff Exp $

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
my %atts = (

    imageInfo => {
        'binarytype' =>
          [ 'binaryType', 'varchar (16)', '\'jpg\' null', '0', '' ],
        'name' => [ 'name', 'varchar (64)', 'not null', '0', '' ],
        'description' => [ 'description', 'varchar (128)', 'null', '0', '' ],
        'md5sum'       => [ 'md5sum', 'char (32)', 'not null', '0', '' ],
        'fmorg'        => [],
        'locationlist' => [
            'locationList', 'varchar (128)', '\'//imgserver.org\'', '0', ''
        ],
        'public' => [],
        'id'     => [ 'id', 'numeric (18)', '', '2', '' ],
        'insertiondate' =>
          [ 'insertionDate', 'timestamp', 'not null', '0', '' ]
    },
    subImageInfo => {
        'fmorg'        => [],
        'pixsize'      => [ 'pixSize', 'integer', '', '2', '' ],
        'imageinfo_id' => [ 'imageInfo_id', 'numeric (18)', '', '2', '' ]
    },
    imageCategoryList => {
        'fmorg'        => [],
        'imageinfo_id' => [ 'imageInfo_id', 'numeric (18)', '', '2', '' ],
        'name'         => [ 'name', 'varchar (32)', '', '2', '' ]
    },
    categoryNames => {
        'fmorg'  => [],
        'public' => [],
        'name'   => [ 'name', 'varchar (32)', '', '2', '' ]
    },
    imageAttribute => {
        'numvalue' => [ 'numValue', 'numeric (8)', '', '0', '' ],
        'fmorg'    => [],
        'attributecategory_id' =>
          [ 'attributeCategory_id', 'numeric (18)', '', '2', '' ],
        'imageinfo_id' => [ 'imageInfo_id', 'numeric (18)', '', '2', '' ],
        'category'     => [ 'category',     'numeric (4)',  '', '0', '' ]
    },
    userInfo => {
        'currentcategory' =>
          [ 'currentCategory', 'varchar (32)', '', '0', '' ],
        'birthdate'     => [ 'birthDate',     'timestamp',    '', '0', '' ],
        'active'        => [ 'active',        'integer',      '', '0', '' ],
        'name'          => [ 'name',          'varchar (32)', '', '0', '' ],
        'md5sum'        => [ 'md5sum',        'char (32)',    '', '0', '' ],
        'email'         => [ 'email',         'varchar (96)', '', '0', '' ],
        'fmorg'         => [],
        'lastdebitdate' => [ 'lastDebitDate', 'timestamp',    '', '0', '' ],
        'acctbalance' => [ 'acctBalance', 'numeric (10,2)', '', '0', '' ],
        'id'          => [ 'id',          'numeric (18)',   '', '2', '' ],
        'insertiondate' => [ 'insertionDate', 'timestamp', '', '0', '' ],
        'gender'        => [ 'gender',        'char (1)',  '', '0', '' ]
    },
    userAttribute => {
        'numvalue' => [ 'numValue', 'numeric (5,4)', '', '0', '' ],
        'fmorg'    => [],
        'attributecategory_id' =>
          [ 'attributeCategory_id', 'numeric (18)', '', '2', '' ],
        'userinfo_id' => [ 'userInfo_id', 'numeric (18)', '', '2', '' ]
    },
    userImageRating => {
        'fmorg'        => [],
        'imageinfo_id' => [ 'imageInfo_id', 'numeric (15)', '', '2', '' ],
        'userinfo_id'  => [ 'userInfo_id', 'numeric (18)', '', '2', '' ],
        'rating'       => [ 'rating', 'integer', '', '0', '' ]
    },
    attributeCategory => {
        'attributedesc' => [ 'attributeDesc', 'varchar (128)', '', '0', '' ],
        'fmorg'         => [],
        'id'            => [ 'id',            'numeric (18)',  '', '2', '' ]
    },
    userSession => {
        'fmorg'         => [],
        'userinfo_id'   => [ 'userInfo_id', 'numeric (18)', '', '2', '' ],
        'expiredate'    => [ 'expireDate', 'timestamp', '', '0', '' ],
        'ipaddress'     => [ 'ipAddress', 'varchar (24)', '', '0', '' ],
        'md5sum'        => [ 'md5sum', 'char (32)', '', '2', '' ],
        'insertiondate' => [ 'insertionDate', 'timestamp', '', '0', '' ]
    },
    extremes => {
        'maxval'  => [ 'maxVal',  'numeric (15)', '', '0', '' ],
        'fmorg'   => [],
        'minval'  => [ 'minVal',  'numeric (15)', '', '0', '' ],
        'public'  => [],
        'name'    => [ 'name',    'varchar (32)', '', '2', '' ],
        'colname' => [ 'colName', 'varchar (64)', '', '0', '' ]
    },
    ratings_view => {
        'c.md5sum' => [ 'c.md5sum', '', '', '0', '' ],
        'a.rating' => [ 'a.rating', '', '', '0', '' ],
        'b.name'   => [ 'b.name',   '', '', '0', '' ]
    },
    whorated_view => {
        'count (*) as numratings' =>
          [ 'count (*) as numRatings', '', '', '0', '' ],
        'a.name' => [ 'a.name', '', '', '0', '' ]
    },
    users_view => {
        'name ||\'<\'|| email ||\'>\' as whoisthis' =>
          [ 'name ||\'<\'|| email ||\'>\' as whoIsThis', '', '', '0', '' ],
        'acctbalance'     => [ 'acctBalance',     '', '', '0', '' ],
        'currentcategory' => [ 'currentCategory', '', '', '0', '' ],
        'birthdate'       => [ 'birthDate',       '', '', '0', '' ],
        'active'          => [ 'active',          '', '', '0', '' ],
        'id'              => [ 'id',              '', '', '0', '' ]
    },
);


# Check that each class has of the expected atts attributes
foreach my $class (@$classes) {
  isa_ok($class, 'HASH');
  ok(exists($atts{$class->{name}})) or
	diag(q{Unexpected class name: }. $class->{name});

  # check contents
  is_deeply(
			$class->{atts},
			$atts{ $class->{name} },
			q{atts for } . $class->{name}
		   );

  # remove class from hash
  delete $atts{$class->{name}};
} 

# Expect no classes left now
cmp_ok(scalar(keys %atts), q{==}, 0, q{Expect 0 classes});

__END__

