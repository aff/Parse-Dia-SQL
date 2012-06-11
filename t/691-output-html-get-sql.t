#   $Id: 691-output-html-get-sql.t,v 1.2 2009/04/01 08:14:19 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 6;

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

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::HTML},
  q{Expect Parse::Dia::SQL::Output::HTML to be used as back-end}
);

diag(q{TODO: Add checks of the html});

__END__
