# $Id: 000-load.t,v 1.3 2009/04/01 07:22:14 aff Exp $

use warnings;
use strict;

use Test::More tests => 16;
use Config;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

BEGIN {
  use_ok( 'Parse::Dia::SQL' );
  use_ok( 'Parse::Dia::SQL::Const' );
  use_ok( 'Parse::Dia::SQL::Logger' );
  use_ok( 'Parse::Dia::SQL::Output' );
  use_ok( 'Parse::Dia::SQL::Output::DB2' );
  use_ok( 'Parse::Dia::SQL::Output::Informix' );
  use_ok( 'Parse::Dia::SQL::Output::Ingres' );
  use_ok( 'Parse::Dia::SQL::Output::MySQL' );
  use_ok( 'Parse::Dia::SQL::Output::MySQL::InnoDB' );
  use_ok( 'Parse::Dia::SQL::Output::MySQL::MyISAM' );
  use_ok( 'Parse::Dia::SQL::Output::Oracle' );
  use_ok( 'Parse::Dia::SQL::Output::Postgres' );
  use_ok( 'Parse::Dia::SQL::Output::SQLite3' );
  use_ok( 'Parse::Dia::SQL::Output::Sas' );
  use_ok( 'Parse::Dia::SQL::Output::Sybase' );
  use_ok( 'Parse::Dia::SQL::Utils' );
}

diag( "Testing Parse::Dia::SQL $Parse::Dia::SQL::VERSION, Perl $], $^X, archname=$Config{archname}, byteorder=$Config{byteorder}" );

__END__
