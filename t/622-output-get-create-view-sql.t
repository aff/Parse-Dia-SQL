#   $Id: 622-output-get-create-view-sql.t,v 1.2 2009/02/28 06:54:57 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 9;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

# 1. pre-parsed input for simplicity and speed.
# $view is here a array ref containing one view ('ratings_view')

my $view = {
  'name' => 'ratings_view',
  'type' => 'view',
  'atts' => {
    'c.md5sum' => [ 'c.md5sum', '', '', '0', undef ],
    'a.rating' => [ 'a.rating', '', '', '0', undef ],
    'b.name'   => [ 'b.name',   '', '', '0', undef ]
  },
  'ops' => [
    [ 'userImageRating a',                     'from',     [], '', undef ],
    [ 'userImageRating z',                     'from',     [], '', undef ],
    [ 'userInfo b',                            'from',     [], '', undef ],
    [ 'imageInfo c',                           'from',     [], '', undef ],
    [ '(((a.userInfo_id = b.id)',              'where',    [], '', undef ],
    [ 'and (a.imageInfo_id = c.id)',           'where',    [], '', undef ],
    [ 'and (a.userInfo_id = z.userInfo_id))',  'where',    [], '', undef ],
    [ 'and (a.userInfo_id <> z.userInfo_id))', 'where',    [], '', undef ],
    [ 'c.md5sum,b.name,a.rating',              'order by', [], '', undef ]
  ],
  'uindxn'  => {},
  'pk'      => [],
  'uindxc'  => {},
  'attList' => [
    [ 'b.name',   '', '', '0', undef ],
    [ 'c.md5sum', '', '', '0', undef ],
    [ 'a.rating', '', '', '0', undef ],
  ],
};

# 2. output
my $diasql = Parse::Dia::SQL->new(db => 'db2');
my $output   = undef;

isa_ok($diasql, 'Parse::Dia::SQL');

# Fool Parse::Dia::SQL into thinking convert() was called
$diasql->{converted} = 1; 

lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));
can_ok($output, 'get_schema_create');

my $create_view = $output->_get_create_view_sql($view);
#diag($create_view);

like($create_view, qr|
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
|six, q{Check syntax for sql create view ratings_view});


__END__
