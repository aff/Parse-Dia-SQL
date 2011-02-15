#   $Id: 670-output-get-pre-sql.t,v 1.5 2009/02/27 08:59:42 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 19;

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

can_ok($output, 'get_smallpackage_pre_sql');
my $presql = $output->get_smallpackage_pre_sql();
is($presql,q[-- statements to do BEFORE creating
-- the tables (schema)
drop sequence imageInfo_id;
create sequence imageInfo_id;]);


# ------------------------------------------------------------------

# Check that Output doesn't put comma between multiple smallpackage statements

my $diasql2 =  Parse::Dia::SQL->new( files => [catfile(qw(t data db2.pre.dupe.dia))], db => 'db2' );
isa_ok($diasql2, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

# Parse and convert
cmp_ok($diasql2->convert(), q{==}, 1,q{Expect convert to return 1});

my $output2   = undef;
isa_ok($diasql2, 'Parse::Dia::SQL');
lives_ok(sub { $output2 = $diasql2->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output2, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output2));
isa_ok($output2, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output2));

can_ok($output2, 'get_smallpackage_pre_sql');
my $presql2 = $output2->get_smallpackage_pre_sql();

# make sure each statement starts on a separate line
like($presql2,qr/ \s*
^ drop \s+ sequence \s+ foo_id_seq; \s* 
^ create \s+ sequence \s+ foo_id_seq \s+ as \s+ bigint
 \s+ start \s+ with \s+ 1 \s+ increment \s+ by \s+ 1 \s+ no \s+ maxvalue \s+ no \s+ cycle \s+ cache \s+ 20; \s*
^drop \s+ sequence \s+ bar_id_seq; \s*
^create \s+ sequence \s+ bar_id_seq \s+ as \s+ bigint
 \s+ start \s+ with \s+ 1 \s+ increment \s+ by \s+ 1 \s+ no \s+ maxvalue \s+ no \s+ cycle \s+ cache \s+ 20;
\s*/mix, q{Check that there is no comma between statements});
#diag($presql2);

__END__
