#   $Id: 620-output-get-schema-create-db-model.t,v 1.2 2010/04/16 05:07:34 aff Exp $

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

# 1. parse input
my $db = 'db2';
my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data nullable.dia)), db => $db );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert to return 1});

my $classes       = $diasql->get_classes_ref();

# check parsed content
ok(defined($classes) && ref($classes) eq q{ARRAY} && scalar(@$classes), q{Non-empty array ref});

# 2. get output instance
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
#diag $create_table;

like($create_table, qr|.*
  create \s+ table \s+ bar \s* \(
     \s* id \s+ int \s+ not \s+ null \s* , 
     \s* col1_nullable \s+ int \s* ,
     \s* col2_nullable \s+ int not \s+ null \s* ,
     \s* constraint \s+ pk_\w+ \s+ primary \s+ key \s* \(id\) \s*
  \) \s* (;)?
.*|six, q{Check syntax for sql create table bar});


__END__

=pod

=head1 SUMMARY

Related to bug submitted by 'jochenberger' on github.com

=cut
