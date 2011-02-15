#   $Id: 600-output-load.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 1;

use lib q{lib};
use_ok ('Parse::Dia::SQL::Output');

__END__
