#   $Id: 671-output-get-post-sql.t,v 1.4 2009/02/25 08:43:31 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 11;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

my $diasql =  Parse::Dia::SQL->new( files => [catfile(qw(t data TestERD.dia))], db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# Parse and convert
cmp_ok($diasql->convert(), q{==}, 1,q{Expect convert to return 1});

my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));

can_ok($output, 'get_smallpackage_post_sql');
my $postsql = $output->get_smallpackage_post_sql();
is($postsql,q[-- statements to do AFTER creating
-- the tables (schema)
--drop trigger . . . .
--create trigger . . . .]);


__END__
