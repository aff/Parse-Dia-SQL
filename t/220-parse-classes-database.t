#   $Id: 220-parse-classes-database.t,v 1.1 2010/04/10 12:59:11 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 11;

use_ok('Parse::Dia::SQL');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data rt56357.dia)), db => 'db2');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# parse and convert
is($diasql->convert(), 1, q{Expect convert() to return 1});

my $docs = $diasql->_get_docs();
foreach my $doc (@{$docs}) {
  isa_ok($doc, q{XML::DOM::Document});
}

# check that nodelists returns array of XML::DOM::NodeList
my $nodelists = $diasql->_get_nodelists();
foreach my $nodelist (@{$nodelists}) {
  isa_ok($nodelist, q{XML::DOM::NodeList});
}

my $classes = $diasql->get_classes_ref();

#diag(Dumper($classes));

# Expect an array ref with 1 elements
isa_ok($classes, 'ARRAY');
cmp_ok(scalar(@$classes), q{==}, 1, q{Expect 1 classes});

# List of classes in the dia file
my %classname = map { $_ => 1 } qw (
  bar
);

foreach my $class (@$classes) {
  isa_ok($class, 'HASH');
  if (exists($classname{ $class->{name} })) {
    delete $classname{ $class->{name} };
    ok(q{Found class } . $class->{name});
  } else {
    fail(q{Unknown class: } . $class->{name});
  }
}

# Expect no classes left now
cmp_ok(scalar(keys %classname), q{==}, 0, q{Expect 0 classes});

__END__

