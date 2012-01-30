#   $Id: 640-output-get-schema-drop-sql.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 21;

use_ok ('Parse::Dia::SQL');
my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'mysql-innodb', backticks => 1 );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});
my $classes       = $diasql->get_classes_ref();
ok(defined($classes) && ref($classes) eq q{ARRAY} && scalar(@$classes), q{Non-empty array ref});


# 2. output
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output');
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL');
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL::InnoDB');

can_ok($output, 'get_schema_drop');
my $drop_table = $output->get_schema_drop();

#diag($drop_table);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `imageInfo` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `subImageInfo` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `imageCategoryList` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `categoryNames` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `imageAttribute` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `userInfo` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `userAttribute` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `userImageRating` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `attributeCategory` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `userSession` \s* ;/six);
like($drop_table, qr/.*drop \s+ table \s+ if \s+ exists \s+ `extremes` \s* ;/six);

__END__
