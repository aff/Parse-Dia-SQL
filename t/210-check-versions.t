#   $Id: 210-check-versions.t,v 1.2 2009/06/23 19:54:29 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 15;

use_ok ('Parse::Dia::SQL::Utils');

my $pds = Parse::Dia::SQL::Utils->new();
isa_ok($pds, q{Parse::Dia::SQL::Utils}, q{Expect a Parse::Dia::SQL::Utils object});

# negative tests
ok(!defined $pds->_check_object_version('foo', 0), q{unknown object type});
ok(!defined $pds->_check_object_version('', 0), q{missing object type});

# positive tests
ok(defined $pds->_check_object_version('UML - Association', '01'), q{UML - Association 01});
ok(defined $pds->_check_object_version('UML - Association', '02'), q{UML - Association 02});

ok(defined $pds->_check_object_version('UML - Class', 0), q{UML - Class 0});
ok(defined $pds->_check_object_version('UML - Component', 0), q{UML - Component 0});
ok(defined $pds->_check_object_version('UML - Note', 0), q{UML - Note 0});
ok(defined $pds->_check_object_version('UML - SmallPackage', 0), q{UML - SmallPackage 0});

# negative tests - unsupported versions
ok(!defined $pds->_check_object_version('UML - Association', 3), q{UML - Association 3});

ok(!defined $pds->_check_object_version('UML - Class', 1), q{UML - Class 1});
ok(!defined $pds->_check_object_version('UML - Component', 1), q{UML - Component 1});
ok(!defined $pds->_check_object_version('UML - Note', 1), q{UML - Note 1});
ok(!defined $pds->_check_object_version('UML - SmallPackage', 1), q{UML - SmallPackage 1});


__END__

=pod

=head1 Test of XML object versions.

List of supported object versions

    <dia:object type="UML - Association"  version="1" id="XX">
    <dia:object type="UML - Association"  version="2" id="XX">
    <dia:object type="UML - Class"        version="0" id="XX">
    <dia:object type="UML - Component"    version="0" id="XX">
    <dia:object type="UML - Note"         version="0" id="XX">
    <dia:object type="UML - SmallPackage" version="0" id="XX">

=cut


