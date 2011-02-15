#   $Id: 400-parse-typemap.t,v 1.4 2010/02/01 20:45:40 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 6;

use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::Postgres');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data rt53783.dia)), db => 'postgres');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{_parse_typemap});


my $typemap_hr_input = {
   'postgres:typemap' => 'UUID: uuid; string: varchar; TIMESTAMP: timestamp(3);',
	 'sqlite3:typemap' => 'UUID: text(36);
string: text;
TIMESTAMP: text(14);'
};

my $typemap_hr_output =   {
    'postgres' => {
      'string'    => ['varchar'],
      'UUID'      => ['uuid'],
      'TIMESTAMP' => ['timestamp', '(3)'],
    },
    'sqlite3' => {
      'string'    => ['text'],
      'UUID'      => ['text','(36)'],
      'TIMESTAMP' => ['text','(14)'],
    }
  };

is_deeply($diasql->_parse_typemap($typemap_hr_input), $typemap_hr_output, q[typemap hashref]) or diag "got ". Dumper ( $typemap_hr_input);

__END__

=pod

Test typemap parsing.

=cut 



=pod


=head1 SAMPLE DATASTRUCTURE FOR TYPEMAP

  {
    'postgresql' => {
      'string'    => 'varchar',
      'UUID'      => 'uuid',
      'TIMESTAMP' => 'timestamp(3)'
    },
    'sqlite' => {
      'string'    => 'text',
      'UUID'      => 'text(36)',
      'TIMESTAMP' => 'text(14)'
    }
  };

=head1 SAMPLE DIA FILE

Add a SmallPackage with stereotype I<postgres:typemap>.  Then one each
line add entries on the form C<from: to;>, e.g.

  UUID: uuid;
  string: varchar; 
  TIMESTAMP: timestamp;  

=head2 Replacement options

Handle mappings that allow the SQL side to replace only the type name,
leaving the size unchanged, or to add a size if it's not specified by
the user.

So, with

		integer: number(10);
		string: varchar2;
		
		a	integer,	  # allowed -> number(10)
		b	integer(10)	# allowed -> number(10)
		c	integer(5)	# not allowed
		d	string(80)	# allowed -> varchar2(80)
		e	string		  # allowed -> varchar2

See also I<rt53783.dia> in the C<t/data> directory.

=cut

