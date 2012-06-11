#   $Id: 500-get-associations.t,v 1.4 2011/02/15 20:15:54 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 57;

use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Const');

# Get list of supported databases
my $const = Parse::Dia::SQL::Const->new();
isa_ok($const, q{Parse::Dia::SQL::Const});
my @rdbms = $const->get_rdbms();
undef $const;

foreach my $db (@rdbms) {
  my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => $db );
  isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

  is($diasql->convert(), 1, q{Expect convert to return 1});

  my $association_arrayref = $diasql->get_associations_ref();
  #diag(Dumper($association_arrayref));

  my $expected = [
				  [ 'subImageInfo',      'fk_iisii', 'imageInfo_id', 'imageInfo', 'id', '' ],
				  [ 'imageCategoryList', 'fk_iiicl', 'imageInfo_id', 'imageInfo', 'id', '' ],
				  [ 'imageAttribute',    'fk_iiia',  'imageInfo_id', 'imageInfo', 'id', '' ],
				  [
				   'userImageRating', 'fk_uiuir',
				   'userInfo_id',     'userInfo',
				   'id',              'on delete cascade'
				  ],
				  [
				   'userAttribute', 'fk_uiua',
				   'userInfo_id',   'userInfo',
				   'id',            'on delete cascade'
				  ],
				  [
				   'userSession', 'fk_uius', 'userInfo_id', 'userInfo',
				   'id',          'on delete cascade'
				  ],
				  [
				   'imageAttribute',       'fk_iaac',
				   'attributeCategory_id', 'attributeCategory',
				   'id',                   ''
				  ],
				  [
				   'userAttribute',        'fk_acua',
				   'attributeCategory_id', 'attributeCategory',
				   'id',                   ''
				  ]
				 ];

  cmp_ok(scalar(@$association_arrayref), q{==}, scalar(@$expected), qq{Check number of foreign keys (db=$db)});

  is_deeply($association_arrayref, $expected, qq{get_associations_ref for db=$db});
  undef $diasql;
}

# ------- many-to-many relations -------
my $diasql_many_to_many =  Parse::Dia::SQL->new( file => catfile(qw(t data many_to_many.dia)), db => 'db2' );
isa_ok($diasql_many_to_many, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# TODO: Add test on return value - call wrapper
$diasql_many_to_many->convert();

my $association_many_to_many_arrayref = $diasql_many_to_many->get_associations_ref();
#diag("association_many_to_many_arrayref: ".Dumper($association_many_to_many_arrayref));

my $expected_many_to_many =  [
          [
            'student_course',
            'stdn_crs_fk_StntSn',
            'ssn',
            'student',
            'ssn',
            'on delete cascade'
          ],
          [
            'student_course',
            'lTeT8iBKfXObJYiSrq',
            'course_id',
            'course',
            'course_id',
            'on delete cascade'
          ]
        ];


is_deeply( $association_many_to_many_arrayref, $expected_many_to_many, 'expected_many_to_many' );

#   or diag( q{association_many_to_many_arrayref: }
#     . Dumper($association_many_to_many_arrayref)
#     . q{ expected }
#     . Dumper($expected_many_to_many) );

__END__
