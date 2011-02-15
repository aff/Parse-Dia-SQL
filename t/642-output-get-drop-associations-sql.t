#   $Id: 642-output-get-drop-associations-sql.t,v 1.2 2009/03/16 07:27:17 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 37;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert() to return 1});

# 2. output
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));

can_ok($output, 'get_constraints_drop');
my $drop_constraints = $output->get_constraints_drop();

#diag($drop_constraints);

# indices
like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iimd5(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iiid(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siiid(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_siips(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_iclidnm(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uinm(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiid(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uauiid(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_uiruid(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_acid(;)?
.*/six);

like($drop_constraints, qr/.*
drop \s+ index \s+ idx_usmd5(;)?
.*/six);

# foreign keys
like($drop_constraints, qr/.* 
alter \s+ table \s+ subImageInfo \s+ drop \s+ constraint \s+ fk_iisii \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ imageCategoryList \s+ drop \s+ constraint \s+ fk_iiicl \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ imageAttribute \s+ drop \s+ constraint \s+ fk_iiia \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ userImageRating \s+ drop \s+ constraint \s+ fk_uiuir \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ userAttribute \s+ drop \s+ constraint \s+ fk_uiua \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ userSession \s+ drop \s+ constraint \s+ fk_uius \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ imageAttribute \s+ drop \s+ constraint \s+ fk_iaac \s* (;)?
.*/six);

like($drop_constraints, qr/.* 
alter \s+ table \s+ userAttribute \s+ drop \s+ constraint \s+ fk_acua \s* (;)?
.*/six);


##################################################################

my $OBJECT_NAME_MAX_LENGTH_DB2 = 18;

my $diasql2 =  Parse::Dia::SQL->new( file => catfile(qw(t data long_fk_name.dia)), db => 'db2' );
isa_ok($diasql2, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql2->convert(), 1, q{Expect convert() to return 1});

# 2. output
my $output2   = undef;
isa_ok($diasql2, 'Parse::Dia::SQL');
lives_ok(sub { $output2 = $diasql2->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output2, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output2));
isa_ok($output2, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output2));

can_ok($output2, 'get_constraints_drop');
my $drop_constraints2 = $output2->get_constraints_drop();
# diag($drop_constraints2);

$drop_constraints2 =~ m/alter \s+ table \s+ \w+ \s+ drop \s+ constraint \s+ (\w+) \s+ .* $/six;
my $constraint_name2 = $1;
# diag($constraint_name2);

ok(defined($constraint_name2), q{Expect a defined name})
  or diag($constraint_name2);
cmp_ok(length($constraint_name2),
	   q{<=}, $OBJECT_NAME_MAX_LENGTH_DB2,
	   qq{$constraint_name2 Expect length below or equal to $OBJECT_NAME_MAX_LENGTH_DB2}) 
  or diag($constraint_name2);


__END__


=pod

=head1 SEE ALSO 

689-output-db2-create-constraint-name.t

=cut

