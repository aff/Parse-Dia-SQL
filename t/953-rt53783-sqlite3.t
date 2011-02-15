#   $Id: 953-rt53783-sqlite3.t,v 1.2 2010/02/05 19:30:13 aff Exp $

use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Exception;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 8;
 
use lib q{lib};
use_ok ('Parse::Dia::SQL');
use_ok ('Parse::Dia::SQL::Output');
use_ok ('Parse::Dia::SQL::Output::SQLite3');

my $diasql =
  Parse::Dia::SQL->new(file => catfile(qw(t data typemap.dia)), db => 'sqlite3');
isa_ok($diasql, q{Parse::Dia::SQL}, q{Expect a Parse::Dia::SQL object});
can_ok($diasql, q{get_sql});

my $sql = $diasql->get_sql();

isa_ok(
  $diasql->get_output_instance(),
  q{Parse::Dia::SQL::Output::SQLite3},
  q{Expect Parse::Dia::SQL::Output::SQLite3 to be used as back-end}
);

# diag $sql;

like($sql, qr/.*
create \s* table \s* Item \s* \( \s* 
 \s* id \s* text \s* \( \s* 36 \s* \)  \s* not \s* null, \s* -- \s* Primary \s* key
 \s* timeModified \s* text \s* \( \s* 14 \s* \)  \s* ,
 \s* timeCreated \s* text \s* \( \s* 14 \s* \)  \s* ,
 \s* personModified \s* text \s* \( \s* 128 \s* \) \s* ,
.*/six);

like($sql, qr/.*
create \s* table \s* Item \s* \( \s* 
 \s* id \s* text \s* \( \s* 36 \s* \)  \s* not \s* null, \s* -- \s* Primary \s* key
 \s* timeModified \s* text \s* \( \s* 14 \s* \)  \s* ,
 \s* timeCreated \s* text \s* \( \s* 14 \s* \)  \s* ,
 \s* personModified \s* text \s* \( \s* 128 \s* \) \s* ,
 \s* personCreated \s* text \s* \( \s* 128 \s* \) \s* ,
 \s* stateID \s* text \s* \( \s* 36 \s* \)  \s* , \s* -- \s* - \s* In \s* active \s* storage \s* - 
 \s* Disposed\/destroyed \s* - 
 \s* Handovered \s* back \s* to \s* owner \s* organization
 \s* projectID \s* text \s* \( \s* 36 \s* \)  \s* ,
 \s* descriptionID \s* text \s* \( \s* 36 \s* \)  \s* ,
 \s* constraint \s* pk_Item \s* primary \s* key \s* \( \s* id \s* \) \s* 
 \s* \) \s* ;
.*/six);

__END__


=pod


=head1 SAMPLE DATASTRUCTURE FOR TYPEMAP

  {
    'postgresql' => {
      'string'    => 'varchar',
      'UUID'      => 'uuid',
      'TIMESTAMP' => 'timestamp(3)'
    },
    'sqlite3' => {
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

