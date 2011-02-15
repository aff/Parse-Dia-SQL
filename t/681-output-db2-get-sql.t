#   $Id: 681-output-db2-get-sql.t,v 1.2 2009/02/26 19:58:37 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 5;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'db2');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

my $sql = $diasql->get_sql;

# ------ check statement sequence -------

diag("TODO: Get monk help with this regex..");

like($sql, qr/.*

(alter \s+ table \s+ \w+ \s+ drop \s+ constraint \s+ \w+ \s* ; \s*) +? \s* 

.*?

(drop \s+ index \s+ \w+ \s* ; \s*) +? \s* 

.*?

(revoke \s+ \w+ \s+ on \s+ \w+ \s+ from \s+ \w+ \s* ; \s*) +? \s*

.*?

(drop \s+ sequence \s+ \w+ \s* ; \s*) *? \s* 

.*?

(create \s+ sequence \s+ \w+ \s* ; \s*) *? \s* 

.*?

(drop \s+ view \s+ \w+ \s* ; \s*) *? \s* 

.*?

(--drop \s+ trigger .* ) *? \s* 
(--create \s+ trigger .* ) *? \s* 

.*?

(grant \s+ \w+ \s+ on \s+ \w+ \s+ to \s+ \w+ \s* ; \s*) *? \s* 

.*?

(insert \s+ into \s+ \w+ \s+ values \s+ \w+ \s* ; \s*) *? \s* 

.*?

(create \s+ (unique)? \s+ index \s+ \w+ \s+ on \s+ \w+ \s* ; \s*) *? \s* 

.*?

(alter \s+ table \s+ \w+ \s+ 
  add \s+ constraint \s+ \w+ \s+ 
  foreign \s+ key \s+ \w+ \s+ 
  vreferences \s+ \w+ \s* ; \s*) *? \s* 

.*/six, q{check sequence of statements});

__END__

