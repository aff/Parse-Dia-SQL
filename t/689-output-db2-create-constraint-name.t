#  $Id: 689-output-db2-create-constraint-name.t,v 1.3 2009/03/16 08:45:03 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 39;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::DB2');

# 1. parse input - although it is not used here
my $db = 'db2';
my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data long_fk_name.dia)), db => $db );
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql->convert(), 1, q{Expect convert to return 1});

# 2. output
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');
lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output));
isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));

can_ok($output, '_create_constraint_name');


my $OBJECT_NAME_MAX_LENGTH = 18;

# Check tablename of various length - the pk should be $OBJECT_NAME_MAX_LENGTH chars or less (DB2)

ok(!defined($output->_create_constraint_name()), q{return undef on undef});
ok(!defined($output->_create_constraint_name('')), q{return undef on empty});

is($output->_create_constraint_name(q{less_than_18}), q{less_than_18}, q{Expect 'less_than_18'});
is($output->_create_constraint_name(q{fk_rule_rule_type_id}), q{fk_rl_rl_typ_d}, q{Expect 'fk_rl_rl_typ_d'});

foreach my $fk (
  qw(
     fk_rule_rule_type_id
     fk_prof_auth_container_id
	 fk_prof_pres_container_id
	 fk_prof_cb_container_id
	 fk_prof_retr_container_id
	 fk_workflow_type_id
	 fk_wf_datasrc_type_id
     very_very_very_very_very_very_very_very_very_very_very_long_string
     )) {

  cmp_ok(length($output->_create_constraint_name($fk)),
    q{<=}, $OBJECT_NAME_MAX_LENGTH,
    qq{$fk Expect length below or equal to $OBJECT_NAME_MAX_LENGTH});

  #diag ($fk . " -> " . $output->_create_constraint_name($fk) ); ## uncomment to se the conversion
}

undef $diasql; 
undef $output; 

# No switch to a non-DB2 database and expect constraint_name to be preserved 
my $diasql2 =  Parse::Dia::SQL->new( file => catfile(qw(t data long_fk_name.dia)), db => 'mysql-innodb' );
isa_ok($diasql2, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
is($diasql2->convert(), 1, q{Expect convert to return 1});

# 2. output
my $output2   = undef;
isa_ok($diasql2, 'Parse::Dia::SQL');
lives_ok(sub { $output2 = $diasql2->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output2, 'Parse::Dia::SQL::Output')
  or diag(Dumper($output2));
isa_ok($output2, 'Parse::Dia::SQL::Output::MySQL::InnoDB')
  or diag(Dumper($output2));

can_ok($output2, '_create_constraint_name');

# Check tablename of various length - the pk should be preserved (MySQL InnoDB)
ok(!defined($output2->_create_constraint_name()), q{return undef on undef});
ok(!defined($output2->_create_constraint_name('')), q{return undef on empty});

foreach my $fk (
  qw(
     fk_rule_rule_type_id
     fk_prof_auth_container_id
	 fk_prof_pres_container_id
	 fk_prof_cb_container_id
	 fk_prof_retr_container_id
	 fk_workflow_type_id
	 fk_wf_datasrc_type_id
     very_very_very_very_very_very_very_very_very_very_very_long_string
     )) {

  is($output2->_create_constraint_name($fk),
    $fk,
    qq{$fk Expect output equal to input});

  #diag ($fk . " -> " . $output2->_create_constraint_name($fk) ); ## uncomment to se the conversion
}



__END__
