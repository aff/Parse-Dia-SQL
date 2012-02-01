#   $Id: 660-output-get-create-permissions-sql.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 23;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'mysql-innodb', backticks => 1 );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});

# 2. output
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (mysql-innodb) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::MySQL::InnoDB')
  or diag(Dumper($output));

can_ok($output, 'get_permissions_create');
my $permissions_create = $output->get_permissions_create();

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+  `imageInfo` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ select \s+ on \s+  `imageInfo` \s+ to \s+ public \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `subImageInfo` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `imageCategoryList` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ select \s+ on \s+ `categoryNames` \s+ to \s+ public \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `categoryNames` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `imageAttribute` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `userInfo` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `userAttribute` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `userImageRating` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `attributeCategory` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `userSession` \s+ to \s+ fmorg \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ select \s+ on \s+ `extremes` \s+ to \s+ public \s* (;)?
.*/six);

like($permissions_create, qr/.*
grant \s+ all \s+ on \s+ `extremes` \s+ to \s+ fmorg \s* (;)?
.*/six);


__END__
