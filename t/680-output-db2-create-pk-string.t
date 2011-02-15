#   $Id: 680-output-db2-create-pk-string.t,v 1.2 2009/02/26 19:58:02 aff Exp $

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
use_ok ('Parse::Dia::SQL::Output::DB2');

# 1. parse input
my $db = 'db2';
my $diasql =  Parse::Dia::SQL->new( file => catfile(qw(t data TestERD.dia)), db => $db );
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

can_ok($output, '_create_pk_string');

# Should return undefined when pk list is empty or undefined
ok(!defined($output->_create_pk_string(q{shorttable}, ())), q{Expect undef on empty list});

# Check tablename of various length - the pk should be 18 chars or less (DB2)
is($output->_create_pk_string(q{shorttable}, qw(one two three)), q{constraint pk_shorttable primary key (one,two,three)});
is($output->_create_pk_string(q{ImageInfo}, qw(id)), q{constraint pk_ImageInfo primary key (id)});
is($output->_create_pk_string(q{SubImageInfo}, qw(imageInfo_id pixSize)), q{constraint pk_SubImageInfo primary key (imageInfo_id,pixSize)});
is($output->_create_pk_string(q{ImageCategoryList}, qw(imageInfo_id name)), q{constraint pk_ImageCaoryList primary key (imageInfo_id,name)});
is($output->_create_pk_string(q{CategoryNames}, qw(name)), q{constraint pk_CategoryNames primary key (name)});
is($output->_create_pk_string(q{ImageAttribute}, qw(imageInfo_id attributeCategory_id)), q{constraint pk_ImageAttribute primary key (imageInfo_id,attributeCategory_id)});
is($output->_create_pk_string(q{UserInfo}, qw(id)), q{constraint pk_UserInfo primary key (id)});
is($output->_create_pk_string(q{UserAttribute}, qw(userInfo_id attributeCategory_id)), q{constraint pk_UserAttribute primary key (userInfo_id,attributeCategory_id)});
is($output->_create_pk_string(q{UserImageRating}, qw(userInfo_id imageInfo_id)), q{constraint pk_UserImaeRating primary key (userInfo_id,imageInfo_id)});
is($output->_create_pk_string(q{AttributeCategory}, qw(id)), q{constraint pk_Attribuategory primary key (id)});
is($output->_create_pk_string(q{UserSession}, qw(userInfo_id md5sum)), q{constraint pk_UserSession primary key (userInfo_id,md5sum)});
is($output->_create_pk_string(q{Extremes}, qw(name)), q{constraint pk_Extremes primary key (name)});


__END__

