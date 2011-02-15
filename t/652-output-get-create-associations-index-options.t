#   $Id: 652-output-get-create-associations-index-options.t,v 1.2 2009/05/16 12:24:28 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 10;

use_ok ('Parse::Dia::SQL');

my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data index.option.dia)), db => 'db2' );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});

ok $diasql->convert();

# Output
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));

can_ok($output, 'get_associations_create');

# associations = foreign keys + indices
my $association_str = $output->get_associations_create();

# Check for index option 
like($association_str, qr|.*
create \s+ index \s+ \w+ \s+ on \s+ foo  
  \s* \( \s* \w+, \w+ \s* \) \s* disallow \s+ reverse \s+ scans \s* (;)?
.*
|six, q{Expect index option "disallow reverse scans" on table foo});


like($association_str, qr|.*
create \s+ index \s+ \w+ \s+ on \s+ bar 
  \s* \( \s* \w+, \w+ \s* \) \s* allow \s+ reverse \s+ scans \s* (;)?
.*
|six, q{Expect default index option "allow reverse scans" on table bar});

__END__
