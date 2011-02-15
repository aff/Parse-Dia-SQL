#   $Id: 650-output-get-create-associations-many-to-many-097.t,v 1.2 2011/02/15 20:15:54 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 19;

use_ok ('Parse::Dia::SQL');

# ------- many-to-many relations -------

my $diasql_m2m =  Parse::Dia::SQL->new( file => catfile(qw(t data many_to_many.097.dia)), db => 'db2' );
isa_ok($diasql_m2m, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

ok $diasql_m2m->convert();

my $association_m2m_arrayref = $diasql_m2m->get_associations_ref();
#diag("association_m2m_arrayref: ".Dumper($association_m2m_arrayref));

my $expected_m2m =  [
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


is_deeply( $association_m2m_arrayref, $expected_m2m );

#   or diag( q{association_m2m_arrayref: }
#     . Dumper($association_m2m_arrayref)
#     . q{ expected }
#     . Dumper($expected_m2m) );
my $output_m2m   = undef;
isa_ok($diasql_m2m, 'Parse::Dia::SQL');
lives_ok(sub { $output_m2m = $diasql_m2m->get_output_instance(); },
				 q{get_output_instance (db2) should not die});

isa_ok($output_m2m, 'Parse::Dia::SQL::Output')
	or diag(Dumper($output_m2m));
isa_ok($output_m2m, 'Parse::Dia::SQL::Output::DB2')
	or diag(Dumper($output_m2m));

can_ok($output_m2m, 'get_associations_create');

# associations = foreign keys + indices
my $association_str_m2m = $output_m2m->get_associations_create();

# check 2 foreign keys
like($association_str_m2m, qr/.*
			      alter \s+ table \s+ student_course \s+ add \s+ constraint \s+ stdn_crs_fk_StntSn \s+ foreign \s+ key \s* \( \s* ssn \s* \) \s+ references \s+ student \s* \( \s* ssn \s* \) \s* on \s+ delete \s+ cascade
			      .*/six);

like($association_str_m2m, qr/.*
			      alter \s+ table \s+ student_course \s+ add \s+ constraint \s+ lTeT8iBKfXObJYiSrq \s+ foreign \s+ key \s* \( \s* course_id \s* \) \s* references \s+ course \s+ \s* \( \s* course_id \) \s* on \s+ delete \s+ cascade
			      .*/six);

# ------ implicit role ------
my $diasql_ir =  Parse::Dia::SQL->new( file => catfile(qw(t data implicit_role.dia)), db => 'db2' );
isa_ok($diasql_ir, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

ok $diasql_ir->convert();

my $output_ir   = undef;
isa_ok($diasql_ir, 'Parse::Dia::SQL');
lives_ok(sub { $output_ir = $diasql_ir->get_output_instance(); },
				 q{get_output_instance (db2) should not die});

isa_ok($output_ir, 'Parse::Dia::SQL::Output')
	or diag(Dumper($output_ir));
isa_ok($output_ir, 'Parse::Dia::SQL::Output::DB2')
	or diag(Dumper($output_ir));

can_ok($output_ir, 'get_associations_create');

# associations = foreign keys + indices
my $association_str_ir = $output_ir->get_associations_create();
#diag $association_str_ir;

like($association_str_ir, qr/.*
			     alter \s+ table \s+ emp \s+ add \s+ constraint \s+ emp_fk_Dept_id 
			     \s+ foreign \s+ key \s+ \( \s* dept_id \s* \)
			     \s+ references \s+ dept \s+ \( \s* id \s* \) \s+ ;
			     .*/six);


__END__
