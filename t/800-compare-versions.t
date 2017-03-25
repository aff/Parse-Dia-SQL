use warnings;
use strict;

use Test::More;
use File::Spec::Functions;
use File::Glob ':bsd_glob';

use_ok( 'Parse::Dia::SQL' );

my @v097    = bsd_glob( catfile( qw[ t data *.097.dia ] ) );
my @base    = map { ( my $f = $_ ) =~ s/\.097//; $f } @v097;

my $db = 'db2';
my $loglevel = 'ERROR';

while ( @base ) {

    my $base = shift @base;
    my $v097 = shift @v097;

    my $sql_base = Parse::Dia::SQL->new( file => $base, db => $db, loglevel => $loglevel )->get_sql();
    my $sql_v097 = Parse::Dia::SQL->new( file => $v097, db => $db, loglevel => $loglevel )->get_sql();

    for ( $sql_base, $sql_v097 ) {
      s/.*Generated.*//;
      s/.*Input file.*//;
    }

    use IO::All;
    is( $sql_v097, $sql_base, $v097 )
      or do { $base =~ s/\.dia$/\.sql/; io( $base )->print( $sql_base );
	      $v097 =~ s/\.dia$/\.sql/; io( $v097 )->print( $sql_v097 );
	    };
}

done_testing;
