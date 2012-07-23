#   $Id:  $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use HTML::Lint;
use lib catdir qw ( blib lib );

plan tests => 8;

diag 'HTML support is experimental';

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::HTML');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data TestERD.dia)), db => 'html');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});

my $sql = $diasql->get_sql();
# diag($sql);

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::HTML},
  q{Expect Parse::Dia::SQL::Output::HTML to be used as back-end}
);

# Replace &nbsp; with &#160; (because the latter is valid XML, while
# the former isn't - even though it's fine as HTML)
my $xml = $sql;
$xml =~ s/&nbsp;/&#160;/gi;

# Check the XML with XML::DOM::Parser
my $parser = new XML::DOM::Parser;
eval { my $doc = $parser->parse($xml); };
($@)
  ? fail("Failed test using XML::DOM::Parser - invalid XML")
  : pass("Passed test using XML::DOM::Parser - valid XML");

# Check the HTML with HTML::Lint
my $lint = HTML::Lint->new;
$lint->parse( $sql );
my $error_count = $lint->errors;
($error_count > 0)
  ? fail("Failed test using HTML::Lint - invalid HTML")
  : pass("Passed test using HTML::Lint - valid HTML");

# Print each error message
foreach my $error ($lint->errors) {
  diag(q{HTML-Lint: } . Dumper($error));
}

__END__
