use strict;
use warnings;

require 5.006;

use ExtUtils::MakeMaker;

my %args = (
  NAME          => 'Parse::Dia::SQL',
  AUTHOR        => 'Andreas Faafeng <aff@cpan.org>',
  VERSION_FROM  => 'lib/Parse/Dia/SQL.pm',
  ABSTRACT_FROM => 'lib/Parse/Dia/SQL.pm',
  EXE_FILES     => ['bin/parsediasql'],
  PL_FILES      => {},
  LICENSE       => 'gpl',
  META_MERGE    => {
    resources =>
      { repository => 'https://github.com/aff/Parse-Dia-SQL', },
    keywords => [
      qw [Parse Dia SQL DDL RDBMS DB2 Informix Ingres InnoDB MyISAM MySQL Oracle Postgres SQLite3 Sas Sybase]
    ],
  },
  BUILD_REQUIRES => { 'CPAN::Meta' => 0, },

  PREREQ_PM => {
    'Data::Dumper'              => 0,
    'Digest::MD5'               => 0,
    'Fatal'                     => 0,
    'File::Find'                => 0,
    'File::Spec::Functions'     => 0,
    'File::Temp'                => 0,
    'Getopt::Long'              => 0,
    'HTML::Lint'                => 0,
    'IO::All'                   => 0,
    'IO::Uncompress::Gunzip'    => 0,
    'Log::Log4perl'             => 0,
    'POSIX'                     => 0,
    'Test::Exception'           => 0,
    'Test::More'                => 0,
    'Text::Table'               => 0,
    'XML::DOM'                  => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Parse-Dia-SQL-*' },
);

# Use args according to installed version of ExtUtils::MM
my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);


delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
