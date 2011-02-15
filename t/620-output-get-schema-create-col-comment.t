#   $Id: 620-output-get-schema-create-col-comment.t,v 1.2 2009/02/27 08:59:15 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 10;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

# Check that table column comments are prefixed by comment character
my $db = 'db2';
my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data table.col.comment.dia)), db => $db );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert to return 1});

my $subclass   = undef;
lives_ok(sub { $subclass = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($subclass, 'Parse::Dia::SQL::Output')
  or diag(Dumper($subclass));
isa_ok($subclass, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($subclass));
can_ok($subclass, 'get_schema_create');

# 3. create sql
my $create_table = $subclass->get_schema_create();

like($create_table, qr| \s*
create \s+ table \s+ table_col_comment \s* \(
 \s* id \s+ integer \s+ not \s+ null \s* ,
 \s* type \s+ varchar \s*  \(32\) \s* , \s* -- \s+ This \s+ should \s+ be \s+ prefixed \s+ by \s+ comment \s+ character. \s*
 \s* constraint \s+ \w+ \s+ primary \s+ key \s+ \(id\) \s*
\) \s* ;
.s*
|six, q{Check syntax for sql create table imageInfo});

__END__

