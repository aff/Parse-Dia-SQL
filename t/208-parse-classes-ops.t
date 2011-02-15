#   $Id: 208-parse-classes-ops.t,v 1.3 2009/03/30 10:57:44 aff Exp $

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

# Hash with class/view names as keys and operations (if any) as
# (hashref) elements
my %ops = (
    imageInfo => [
        [ 'idx_iimd5', 'unique index', [ 'md5sum' ], '', '' ],
        [ 'idx_iiid',  'index',        [ 'id' ],     '', '' ],
        [ 'all',       'grant',        [ 'fmorg' ],  '', '' ],
        [ 'select',    'grant',        [ 'public' ], '', '' ]
    ],
    subImageInfo => [
        [ 'idx_siiid', 'index', [ 'imageInfo_id' ], '', '' ],
        [ 'idx_siips', 'index', [ 'pixSize' ],      '', '' ],
        [ 'all',       'grant', [ 'fmorg' ],        '', '' ]
    ],
    imageCategoryList => [
        [ 'idx_iclidnm', 'index', [ 'imageInfo_id', 'name' ], '', '' ],
        [ 'all', 'grant', [ 'fmorg' ], '', '' ]
    ],
    categoryNames => [
        [ 'select', 'grant', [ 'public' ], '', '' ],
        [ 'all',    'grant', [ 'fmorg' ],  '', '' ]
    ],
    imageAttribute => [ [ 'all', 'grant', [ 'fmorg' ], '', '' ] ],
    userInfo => [
        [ 'idx_uinm', 'unique index', [ 'name', 'md5sum' ], '', '' ],
        [ 'idx_uiid', 'index', [ 'id' ],    '', '' ],
        [ 'all',      'grant', [ 'fmorg' ], '', '' ]
    ],
    userAttribute => [
        [ 'idx_uauiid', 'index', [ 'userInfo_id' ], '', '' ],
        [ 'all',        'grant', [ 'fmorg' ],       '', '' ]
    ],
    userImageRating => [
        [ 'idx_uiruid', 'index', [ 'userInfo_id' ], '', '' ],
        [ 'all',        'grant', [ 'fmorg' ],       '', '' ]
    ],
    attributeCategory => [
        [ 'idx_acid', 'index', [ 'id' ],    '', '' ],
        [ 'all',      'grant', [ 'fmorg' ], '', '' ]
    ],
    userSession => [
        [ 'idx_usmd5', 'index', [ 'md5sum' ], '', '' ],
        [ 'all',       'grant', [ 'fmorg' ],  '', '' ]
    ],
    extremes => [
        [ 'select', 'grant', [ 'public' ], '', '' ],
        [ 'all',    'grant', [ 'fmorg' ],  '', '' ]
    ],
    ratings_view => [
        [ 'userImageRating a',                     'from',     [], '', '' ],
        [ 'userImageRating z',                     'from',     [], '', '' ],
        [ 'userInfo b',                            'from',     [], '', '' ],
        [ 'imageInfo c',                           'from',     [], '', '' ],
        [ '(((a.userInfo_id = b.id)',              'where',    [], '', '' ],
        [ 'and (a.imageInfo_id = c.id)',           'where',    [], '', '' ],
        [ 'and (a.userInfo_id = z.userInfo_id))',  'where',    [], '', '' ],
        [ 'and (a.userInfo_id <> z.userInfo_id))', 'where',    [], '', '' ],
        [ 'c.md5sum,b.name,a.rating',              'order by', [], '', '' ]
    ],
    whorated_view => [
        [ 'userInfo a',             'from',     [], '', '' ],
        [ 'userImageRating b',      'from',     [], '', '' ],
        [ '(a.id = b.userInfo_id)', 'where',    [], '', '' ],
        [ 'a.name',                 'group by', [], '', '' ]
    ],
    users_view => [
        [ 'userInfo',      'from',     [], '', '' ],
        [ 'userInfo.name', 'order by', [], '', '' ]
    ],
);


# Check that each class has of the expected ops attributes
foreach my $class (@$classes) {
  isa_ok($class, 'HASH');
  ok(exists($ops{$class->{name}})) or
	diag($class->{name} . ' ops :' . Dumper($class->{ops}));

  # check contents
  is_deeply(
 			$class->{ops},
 			$ops{ $class->{name} },
 			q{ops for } . $class->{name}
 		   );

  # remove class from hash
  delete $ops{$class->{name}};
} 

# Expect no classes left now
cmp_ok(scalar(keys %ops), q{==}, 0, q{Expect 0 classes left});

__END__

