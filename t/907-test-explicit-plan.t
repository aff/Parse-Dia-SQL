
# $Id: 907-test-explicit-plan.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use File::Find;
use Fatal qw (open close);

BEGIN {
	if ( !$ENV { 'AUTHOR_TEST' } ) {
		plan( skip_all => 'AUTHOR_TEST must be set for explicit plan test; skipping' );
	} else {
		plan tests => 1;  #  Obey the rule :)
	}
}

my @violations = ();

find(
  sub {
		return unless -f && -r;
		return unless m/\.t$/;
		return if m/test-explicit-plan/; # Do not test this file
		my $file = $_;
		my $FH = undef;
		open ($FH, "<", $file);
		#diag(qq{Checking $file for missing plan});
		while (<$FH>) {
			push @violations, $file if m/plan.*no_plan/;
		}
		close $FH;		
  },
  q{t}
);

# Report violations if any
cmp_ok( scalar(@violations), q{==}, 0,
  q{Expect 0 violations of 'no_plan' rule} )
  or diag( Dumper(@violations) );

__END__


=pod

Ensure all tests have an explicit plan (i.e. disallow "plan
'no_plan'").

Search the test directory for test files (t/*.t) and report fail if
any file contains the 'no_plan' keyword on a line that is not a
comment.

 TODO: Get rid of false positives that are commented out.

=cut
