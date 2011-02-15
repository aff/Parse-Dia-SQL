# $Id: 901-pod-coverage.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catdir);
use lib catdir qw ( blib lib );

BEGIN {
  plan( skip_all => 'AUTHOR_TEST must be set for pod coverage test; skipping' )
    if ( !$ENV { 'AUTHOR_TEST' } );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();

__END__
