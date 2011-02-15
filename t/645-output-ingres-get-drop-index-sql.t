#   $Id: 645-output-ingres-get-drop-index-sql.t,v 1.1 2009/02/23 07:36:17 aff Exp $

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
use_ok ('Parse::Dia::SQL::Output::Ingres');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'ingres' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');

# suppress warning Using object_name_max_length 30 
ok(Parse::Dia::SQL::Logger::log_off());
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (ingres) should not die});
ok(Parse::Dia::SQL::Logger::log_on());

isa_ok($output, 'Parse::Dia::SQL::Output');
isa_ok($output, 'Parse::Dia::SQL::Output::Ingres');
can_ok($output, 'get_constraints_drop');
my $drop_constraints = $output->get_constraints_drop();

#diag($drop_constraints);

# indices
like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iimd5 \s+ for \s+ ingres \s+ \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iiid \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siiid \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siips \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iclidnm \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uinm \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiid \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uauiid \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiruid \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_acid \s+ for \s+ ingres \s* \\g
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_usmd5 \s+ for \s+ ingres \s* \\g
.*/six);

__END__


