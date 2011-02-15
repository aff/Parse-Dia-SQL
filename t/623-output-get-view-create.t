#   $Id: 623-output-get-view-create.t,v 1.1 2009/02/23 07:36:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 14;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

# 1. parse input
my $db = 'db2';
my $diasql = Parse::Dia::SQL->new(file => catfile(qw(t data TestERD.dia)), db => $db);
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert to return 1});

# 2. Check parsed content
my $classes = $diasql->get_classes_ref();
ok(defined($classes) && ref($classes) eq q{ARRAY} && scalar(@$classes),
  q{Non-empty array ref});

# 3. output
my $output = undef;

isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(
  sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die}
);

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));
can_ok($output, 'get_view_create');

# 4. check view sql
my $create_view = $output->get_view_create();

# -- ratings_view
like($create_view, qr|
.*
create \s+ view \s+ ratings_view \s+ as
 \s+ select \s+ b.name \s* , \s* c.md5sum \s* , \s*a.rating
 \s+ from \s+ userImageRating \s+ a \s* , 
 \s* userImageRating \s+ z \s* , 
 \s* userInfo \s+ b \s* , 
 \s* imageInfo \s+ c
 \s+ where \s+ \(\(\(a.userInfo_id  \s* = \s*  b.id\)
 \s+ and \s+ \(a.imageInfo_id  \s* = \s*  c.id\)
 \s+ and \s+ \(a.userInfo_id  \s* = \s*  z.userInfo_id\)\)
 \s+ and \s+ \(a.userInfo_id \s* <> \s* z.userInfo_id\)\)
 \s+ order \s+ by \s+ c.md5sum \s* , \s* b.name \s* , \s* a.rating
 \s* (;)?
.*
|six, q{Check syntax for sql create view ratings_view});


# -- whorated_view
like($create_view, qr|
.*
create \s+ view \s+ whorated_view \s+ as
 \s+ select \s+ a.name \s* ,  \s* count \s* \( \s* \* \s* \) \s+ as \s+ numRatings
 \s+ from \s+ userInfo \s+ a,
 \s* userImageRating \s+ b
 \s+ where  \s* \(  \s* a.id \s* = \s* b.userInfo_id \s* \)
 \s+ group \s+ by \s+ a.name
 \s* (;)?
.*
|six, q{Check syntax for sql create view whorated_view});

# -- users_view
like($create_view, qr|
.*
create \s+ view \s+ users_view \s+ as
 \s+ select \s+ id \s* , \s* birthDate \s* , \s* name \s+ \|\|'\<'\|\| \s+ email \s+ \|\|'\>' \s+ as \s+ whoIsThis \s* , \s* currentCategory \s* , \s* acctBalance \s* , \s* active
 \s+ from \s+ userInfo
 \s+ order \s+ by \s+ userInfo.name
 \s* (;)?
.*
|six, q{Check syntax for sql create view users_view});



__END__
