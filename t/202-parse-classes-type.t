#   $Id: 202-parse-classes-type.t,v 1.2 2009/02/26 13:49:07 aff Exp $

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

# List of objects and types
my %classname = (
    imageInfo         => 'table',
    subImageInfo      => 'table',
    imageCategoryList => 'table',
    categoryNames     => 'table',
    imageAttribute    => 'table',
    userInfo          => 'table',
    userAttribute     => 'table',
    userImageRating   => 'table',
    attributeCategory => 'table',
    userSession       => 'table',
    extremes          => 'table',
    ratings_view      => 'view',
    whorated_view     => 'view',
    users_view        => 'view',
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

__END__

