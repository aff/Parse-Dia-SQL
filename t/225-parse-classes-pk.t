#   $Id: 225-parse-classes-pk.t,v 1.1 2010/04/10 12:59:11 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 8;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data rt56357.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# TODO: Add test on return value - call wrapper
$diasql->convert();

my $classes = $diasql->get_classes_ref();

# Expect an array ref with 1 elements
isa_ok($classes, 'ARRAY');
cmp_ok(scalar(@$classes), q{==}, 1, q{Expect 1 class});

# Hash with class/view names as keys and primary key as (hashref) elements
my %pk = (
    bar => [ [ 'foo', 'int', '', '2', '' ] ],
);


# Check that each class has of the expected pk attributes
foreach my $class (@$classes) {
  isa_ok($class, 'HASH', q{Expect HASH ref});
  ok(exists($pk{$class->{name}})) or
	diag(q{Unexpected class name: }. $class->{name});

  # diag($class->{name} . ' pk :' . Dumper($class->{pk}));

  # check contents
  is_deeply(
 			$class->{pk},
 			$pk{ $class->{name} },
 			q{pk for } . $class->{name}
 		   );

  # remove class from hash
  delete $pk{$class->{name}};
} 

# Expect no classes left now
cmp_ok(scalar(keys %pk), q{==}, 0, q{Expect 0 classes left});

__END__

