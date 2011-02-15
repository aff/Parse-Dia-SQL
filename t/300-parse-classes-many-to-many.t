#   $Id: 300-parse-classes-many-to-many.t,v 1.2 2009/02/26 13:49:07 aff Exp $

# NOTE: This files has all the tests crammed together as opposed to
# the others that are using TestERD.dia - consider doing it more
# consistently..

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 34;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data many_to_many.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# parse and convert document
is($diasql->convert(), 1, q{Expect convert() to return 1});

my $docs = $diasql->_get_docs();
foreach my $doc (@{$docs}){
  isa_ok($doc, q{XML::DOM::Document});
}

# check that nodelists returns array of XML::DOM::NodeList
my $nodelists = $diasql->_get_nodelists();
foreach my $nodelist (@{$nodelists}){
  isa_ok($nodelist, q{XML::DOM::NodeList});
}

my $classes = $diasql->get_classes_ref(); # no parsing

# Expect an array ref with 3 elements
isa_ok($classes, 'ARRAY');
cmp_ok(scalar(@$classes), q{==}, 3, q{Expect 3 classes});

# List of classes in the dia file
my %classname = map { $_ => 1 } qw (
  student
  course
  student_course
);

foreach my $class(@$classes) {
  isa_ok($class, 'HASH');
  if (exists($classname{$class->{name}})) {
	delete $classname{$class->{name}};
	ok(1);
	#diag(q{Found class }. $class->{name})
  } else {
	fail();
	diag(q{Unknown class: }. $class->{name});
  }
}

# Expect no classes left now
cmp_ok(scalar(keys %classname), q{==}, 0, q{Expect 0 classes});


$classes = $diasql->get_classes_ref(); # no parsing
# List of objects and types
%classname = map { $_ => 'table' } qw (
  student
  course
  student_course
);

# Check that each class is of the expected type (table or view)
foreach my $class (@$classes) {
  isa_ok($class, 'HASH');
  ok(exists($classname{$class->{name}}));
  is($class->{type}, $classname{$class->{name}}, $class->{name}
          . q{ is of type }
          . $class->{type}
          . q{ expected }
          . $classname{ $class->{name}});
  delete $classname{$class->{name}};
}

# Expect no classes left now
cmp_ok(scalar(keys %classname), q{==}, 0, q{Expect 0 classes});

# Hash with class/view names as keys and attribute list as (hashref) elements
my %attList = (
  student => [
    [ 'ssn',  'int',          '',         '2', '' ],
    [ 'name', 'varchar(256)', 'not null', '0', '' ]
  ],
  course => [
    [ 'course_id',   'int',         '',         '2', '' ],
    [ 'desc',        'varchar(64)', 'not null', '0', '' ],
    [ 'day_of_week', 'int',         'not null', '0', '' ],
    [ 'starttime',   'timestamp',   'not null', '0', '' ],
    [ 'endtime',     'timestamp',   '',         '0', '' ]
  ],
  student_course =>
    [ [ 'ssn', 'int', '', 2, '' ], [ 'course_id', 'int', '', 2, '' ] ],
);

$classes = $diasql->get_classes_ref(); # no parsing
# Check that each class has of the expected attList attributes
foreach my $class (@$classes) {
  isa_ok($class, 'HASH');
  ok(exists($attList{$class->{name}}));
  #diag($class->{name} . ": " . Dumper($class->{attList}));

  # check contents
  is_deeply(
			$class->{attList},
			$attList{ $class->{name} },
			q{attList for } . $class->{name}
		   );

  # remove key-value pair from hash
  delete $attList{$class->{name}};
}


__END__

