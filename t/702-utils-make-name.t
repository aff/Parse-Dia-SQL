#   $Id: 702-utils-make-name.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 9;

use lib q{lib};
use_ok ('Parse::Dia::SQL::Utils');

# Need to specify database for make_name to pass
my $utils = Parse::Dia::SQL::Utils->new( db => 'db2' );
isa_ok($utils, 'Parse::Dia::SQL::Utils');

# make_name
is($utils->make_name(0, qw(One two three)), q{OneTwoThree});
is($utils->make_name(1, qw(one two three)), q{oneTwoThree});
is($utils->make_name(1, qw(student_course _fk_ course course_id)), q{lTeT8iBKfXObJYiSrq});
is($utils->make_name(0, qw(student_course _fk_ course course_id)), q{lTeT8iBKfXObJYiSrq});
is($utils->make_name(0, qw(course course_id)), q{courseCourse_id});
is($utils->make_name(0, qw(course course_id foo)), q{courseCourse_idFoo});
is($utils->make_name(0, qw(course course_id foo bar tze)), q{crsCrs_dFooBarTze});

__END__
