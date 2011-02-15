#   $Id: 621-output-get-create-table-sql.t,v 1.4 2009/02/28 06:54:57 aff Exp $

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
# $table is here a hash ref containing one class ('extremes')
my $table =
  {
    'name' => 'extremes',
    'type' => 'table',
    'atts' => {
      'maxval'  => [ 'maxVal',  'numeric (15)', '', '0', undef ],
      'fmorg'   => [],
      'minval'  => [ 'minVal',  'numeric (15)', '', '0', undef ],
      'public'  => [],
      'name'    => [ 'name',    'varchar (32)', '', '2', undef ],
      'colname' => [ 'colName', 'varchar (64)', '', '0', undef ]
    },
    'ops' => [
      [ 'select', 'grant', ['public'], '', undef ],
      [ 'all',    'grant', ['fmorg'],  '', undef ]
    ],
    'uindxn'  => {},
    'pk'      => [ [ 'name', 'varchar (32)', '', '2', undef ], ],
    'uindxc'  => {},
    'attList' => [
      [ 'name',    'varchar (32)', '', '2', undef ],
      [ 'colName', 'varchar (64)', '', '0', undef ],
      [ 'minVal',  'numeric (15)', '', '0', undef ],
      [ 'maxVal',  'numeric (15)', '', '0', undef ]
    ],
  };

my $diasql = Parse::Dia::SQL->new(db => 'db2');
my $output   = undef;
isa_ok($diasql, 'Parse::Dia::SQL');

# Fool Parse::Dia::SQL into thinking convert() was called
$diasql->{converted} = 1; 

lives_ok(sub { $output = $diasql->get_output_instance(); },
  q{get_output_instance (db2) should not die});

isa_ok($output, 'Parse::Dia::SQL::Output::DB2')
  or diag(Dumper($output));
can_ok($output, 'get_schema_create');

my $create_table = $output->_get_create_table_sql($table);
#diag($create_table);

like($create_table, qr|.*
create \s+ table \s+ extremes \s* \(
    \s+ name \s+ varchar \s* \(32\) \s+ not \s+ null \s* ,
    \s+ colName \s+ varchar \s* \(64\) \s* ,
    \s+ minVal \s+ numeric \s* \(15\) \s* ,
    \s+ maxVal \s+ numeric \s* \(15\) \s* ,
		\s+ constraint \s+ pk_\w+ \s+ primary \s+ key  \s* \(name\)
    \s* \) \s* (;)?
.*|six, q{Check syntax for sql create table extremes});


# Test for table where column ('host') is both pk and marked 'not null':
my $table2 =
  {
    'atts' => {
      'nrecv'  => [ 'nrecv',  'integer',     '0',        '0', '' ],
      'level'  => [ 'level',  'integer',     '0',        '0', '' ],
      'status' => [ 'status', 'varchar(20)', '',         '0', '' ],
      'time'   => [ 'time',   'timestamp',   'not null', '0', '' ],
      'host'   => [ 'host',   'varchar(20)', 'not null', '2', '' ],
      'gui'    => [ 'gui',    'integer',     '0',        '0', '' ],
      'rate'   => [ 'rate',   'timestamp',   'not null', '0', '' ],
      'nsent'  => [ 'nsent',  'integer',     '0',        '0', '' ],
      'id'     => [ 'id',     'bigint',      'not null', '0', '' ]
    },
    'ops' => [
      [ 'idx_node_id', 'index', ['id'], '', '' ],
      [ 'idx_node_host_rate', 'index', [ 'host', 'rate' ], '', '' ]
    ],
    'uindxn'  => {},
    'pk'      => [ [ 'host', 'varchar(20)', 'not null', '2', '' ] ],
    'name'    => 'node',
    'uindxc'  => {},
    'attList' => [
      [ 'id',     'bigint',      'not null', '0', '' ],
      [ 'host',   'varchar(20)', 'not null', '2', '' ],
      [ 'time',   'timestamp',   'not null', '0', '' ],
      [ 'level',  'integer',     '0',        '0', '' ],
      [ 'gui',    'integer',     '0',        '0', '' ],
      [ 'rate',   'timestamp',   'not null', '0', '' ],
      [ 'nrecv',  'integer',     '0',        '0', '' ],
      [ 'nsent',  'integer',     '0',        '0', '' ],
      [ 'status', 'varchar(20)', '',         '0', '' ],
    ],
    'type' => 'table'
};

my $create_table2 = $output->_get_create_table_sql($table2);
#diag($create_table2);

like($create_table2, qr|.*
create \s+ table \s+ node \s* \(
 \s* id \s+ bigint \s+ not \s+ null \s* ,
 \s+ host \s+ varchar \s* \( \s* 20 \s* \) \s*  \s+ not \s+ null \s* ,
 \s+ time \s+ timestamp \s+ not \s+ null \s* ,
 \s+ level \s+ integer \s+ default \s+ 0 \s* ,
 \s+ gui \s+ integer \s+ default \s+ 0 \s* ,
 \s+ rate \s+ timestamp \s+ not \s+ null \s* ,
 \s+ nrecv \s+ integer \s+ default \s+ 0 \s* ,
 \s+ nsent \s+ integer \s+ default \s+ 0 \s* ,
 \s+ status \s+ varchar \s* \( \s* 20 \s* \) \s*  \s* ,
 \s+ constraint \s+ pk_node \s+ primary \s+ key \s+  \s* \( \s* host \s* \) \s* 
\) \s* (;)?
.*|six, q{Check syntax for column both pk and marked 'not null':});


__END__
