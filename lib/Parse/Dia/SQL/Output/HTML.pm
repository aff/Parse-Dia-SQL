package Parse::Dia::SQL::Output::HTML;

# $Id: $

=pod

=head1 NAME

Parse::Dia::SQL::Output::HTML - Create HTML documentation.

=head1 SYNOPSIS

    use Parse::Dia::SQL;
    my $dia = Parse::Dia::SQL->new(file => 'foo.dia', db => 'html'[, format=>{formatfile}]);
    print $dia->get_sql();

=head1 DESCRIPTION

This sub-class creates HTML formatted database documentation.

HTML formatting is controlled by templates selected with the optional
I<format> parameter which supplies a format file. See L</"HTML
formats"> for more.

The generated HTML is intended to be useful rather than beautiful.

This sub-class follows the same structure as the rdbms output
sub-classes with the intent of maintaining consistency, even though
this give less than optimum efficiency.

=cut

use warnings;
use strict;

use Text::Table;
use Data::Dumper;
use File::Spec::Functions qw(catfile);

use lib q{lib};
use base q{Parse::Dia::SQL::Output};    # extends
use Config;

require Parse::Dia::SQL::Logger;
require Parse::Dia::SQL::Const;


=head2 new

The constructor.

Object names in HTML have no inherent limit. 64 has been arbitrarily chosen.

=cut

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  # Set defaults for sqlite
  $param{db} = q{html};
  $param{object_name_max_length} = $param{object_name_max_length} || 64;
  $param{htmlformat} = $param{htmlformat} || '';

  $self = $class->SUPER::new( %param );
  bless( $self, $class );

  $self->{dbdata} = {}; # table data, keyed by tablename
  $self->{htmltemplate} = {}; # html template elements
  $self->set_html_template($param{htmlformat}); # find the template elements based on the selected format

  return $self;
}

=head2 get_sql

Return all sql documentation.

First build the data structures:

  schema create
  view create
  permissions create
  inserts
  associations create  (indices first, then foreign keys)

Then generate the output:

  html start
  html comments
  body start
  generate main html
  body end
  html end

=cut

sub get_sql {
  my $self = shift;

  ## no critic (NoWarnings)
  no warnings q{uninitialized};

  $self->get_schema_create();
  $self->get_view_create();
  $self->get_permissions_create();
  $self->get_inserts();
  $self->get_associations_create();

  my $html = ''
  . $self->_get_preamble()
  . $self->_get_comment()
  . $self->get_smallpackage_pre_sql()
  . $self->generate_html()
  . $self->get_smallpackage_post_sql()
  . $self->_get_postscript()
  ;

  return $html;
}

=head2 _get_preamble

HTML Header

=cut
sub _get_preamble {
  my $self = shift;
  my $files_word =
    (scalar(@{ $self->{files} }) > 1)
    ? q{Input files}
    : q{Input file};

  my $data = $self->{htmltemplate}{htmlpreamble};

  # File name
  my $value = $self->{files}[0];
  $data =~ s/{filename}/$value/mgi;

  # todo: meta tags?
  return $data
}


=head2 _get_comment

Comment for HTML Header

=cut

sub _get_comment {
  my $self = shift;
  my $files_word =
    (scalar(@{ $self->{files} }) > 1)
    ? q{Input files}
    : q{Input file};

  $self->{gentime} = scalar localtime();

  my @arr = (
    [ q{Parse::SQL::Dia}, qq{version $Parse::Dia::SQL::VERSION} ],
    [ q{Documentation},   q{http://search.cpan.org/dist/Parse-Dia-SQL/} ],
    [ q{Environment},     qq{Perl $], $^X} ],
    [ q{Architecture},    qq{$Config{archname}} ],
    [ q{Target Database}, $self->{db} ],
    [ $files_word,     join(q{, }, @{ $self->{files} }) ],
    [ q{Generated at}, $self->{gentime} ],
  );

  $self->{filename} = join(q{, }, @{ $self->{files} });

  my $value = '';
  my $data = $self->{htmltemplate}{htmlcomment};
  my $tb = Text::Table->new();
  $tb->load(@arr);

  $value = scalar $tb->table();
  $data =~ s/{htmlcomment}/$value/mgi;

  return $data;
}

=head2 get_smallpackage_pre_sql

HTML Body start

=cut
sub get_smallpackage_pre_sql {
  my $self = shift;
  my $data;

  $data = $self->{htmltemplate}{htmlstartbody};

  return $data
}

=head2 get_smallpackage_post_sql

HTML Body close

=cut
sub get_smallpackage_post_sql {
  my $self = shift;
  my $data;

  $data = $self->{htmltemplate}{htmlendbody};
  $data =~ s/{gentime}/$self->{gentime}/mgi;

  return $data
}

=head2 _get_postscript

HTML close

=cut

sub _get_postscript {
  my $self = shift;
  my $data = '';

  $data = $self->{htmltemplate}{htmlend};

  return $data
}

=head2 _get_create_table_sql

Extracts the documentation details for a single table.

=cut

sub _get_create_table_sql {
  my ( $self, $table ) = @_;
  #my $sqlstr = '';
  my $temp;
  my $comment;
  my $tablename;
  my $update;
  my $primary_keys = '';
  my $order = 0;

  my $tabletemplate = '';
  my $tablerowemplate = '';
  my $tabledata = '';
  my $tablerowdata = '';

  # Table name
  $tablename = $table->{name};
  $self->{'dbdata'}{$tablename} = {};

  # Comments 1 - strip the autoupdate bits
  $comment = $table->{comment};
  if ( !defined( $comment ) ) { $comment = ''; }
  if ( $comment ne '' ) {
    $comment =~ s/\n/<br\/>/g;
    $comment =~ s/<autoupdate(\s*)(.*):(.*)>//mgi;
  }

  # Comments 2 - just the autoupdate bits
  $update = $table->{comment};
  if ( !defined( $update ) ) { $update = ''; }
  if ( $update =~ /<autoupdate(\s*)(.*):(.*)\/>/mi ) {
    $update  = $3;    # update code
    }

  # Set up build the table documentation
  $self->{'dbdata'}{$tablename}{'name'} = $tablename;
  $self->{'dbdata'}{$tablename}{'comment'} = $comment;
  $self->{'dbdata'}{$tablename}{'autoupdate'} = $update;
  $self->{'dbdata'}{$tablename}{'fields'} = {}; # field list, keyed by field name
  $self->{'dbdata'}{$tablename}{'keyfields'} = {}; # primary key fields
  $self->{'dbdata'}{$tablename}{'ref_by'} = {}; # tables that use this as a FK
  $self->{'dbdata'}{$tablename}{'ref_to'} = {}; # tables that this uses for FK
  $self->{'dbdata'}{$tablename}{'permissions'} = []; # permissions array
  $self->{'dbdata'}{$tablename}{'indices'} = {}; # indices keyed by index name

  # Fields
  # Check not null and primary key property for each column. Column
  # visibility is given in $columns[3]. A value of 2 in this field
  # signifies a primary key (which also must be defined as 'not null'.
  $tablerowdata = '';
  foreach my $column (@{ $table->{attList} }) {

    if (ref($column) ne 'ARRAY') {
      $self->{log}
        ->error(q{Error in view attList input - expect an ARRAY ref!});
      next COLUMN;
    }

    # Don't warn on uninitialized values here since there are lots
    # of them.

    ## no critic (ProhibitNoWarnings)
    no warnings q{uninitialized};

    # Field sequence:
    my ($col_name, $col_type, $col_val, $col_vis, $col_com) = @{$column};
    $self->{'dbdata'}{$tablename}{'fields'}{$col_name} = {
        'name'    => $col_name,
        'type'    => $col_type,
        'default' => $col_val,
        'comment' => $col_com,
        'order'   => $order,
    };
    $order ++;

    ## Add 'not null' if field is primary key
    if ($col_vis == 2) {
      $self->{'dbdata'}{$tablename}{'fields'}{$col_name}{'default'} = 'not null';
      $self->{'dbdata'}{$tablename}{'keyfields'}{$col_name} = 1;
    }
  }

  return '';
}

=head2 get_schema_drop

Do nothing

=cut

sub get_schema_drop {
  return '';
}

=head2 get_view_drop

Do nothing

=cut

sub get_view_drop {
 return '';
}

=head2 _get_fk_drop

Do nothing

=cut

sub _get_fk_drop {
  return '';
}

=head2 _get_drop_index_sql

Do nothing

=cut

sub _get_drop_index_sql {
  return '';
}

=head2 get_permissions_create

Permissions are formatted as C<{type} {name} to {list of roles}> where:

C<type> is the operation C<GRANT>, C<REVOKE> etc

C<name> is the permission name C<SELECT>, C<INSERT> etc

C<list of roles> is the set of datbase roles affected.

=head3 Warning

Permissions are at best lightly tested (ie potentially buggy)

=cut

sub get_permissions_create {
  my $self   = shift;
  #my $sqlstr = '';
  #my $temparrayref;

  # Check classes
  return unless $self->_check_classes();

  # loop through classes looking for grants
  foreach my $table (@{ $self->{classes} }) {

    foreach my $operation (@{ $table->{ops} }) {

      if (ref($operation) ne 'ARRAY') {
        $self->{log}->error(
          q{Error in ops input - expect an ARRAY ref, got } . ref($operation));
        next OPERATION;
      }

      my ($opname, $optype, $colref) =
        ($operation->[0], $operation->[1], $operation->[2]);

      # 2nd element can be index, unique index, grant, etc
      next if (lc($optype) ne q{grant} and lc($optype) ne q{revoke} );
      # TODO:BUG in core code - should accecpt revoke or grant, not just grant

      # Add backticks if option is set and dbtype is correct
      my $tablename = $self->_quote_identifier($table->{name});

      my $temp = qq{$optype $opname to } . join(q{,}, @{$colref});
      push @{ $self->{'dbdata'}{$tablename}{'permissions'} }, $temp;
    }
  }

  return '';
}

=head2 get_permissions_drop

Do nothing

=cut

sub get_permissions_drop {
  return '';
}

=head2 _get_create_association_sql

Extracts the documentation for table relationships.

=cut

# Create sql for given association.
sub _get_create_association_sql {
  my ( $self, $association ) = @_;
  my $temp;

  # Sanity checks on input
  if ( ref( $association ) ne 'ARRAY' ) {
    $self->{log}
      ->error( q{Error in association input - cannot create association sql!} );
    return;
  }

  my (
    $table_name, $constraint_name, $key_column,
    $ref_table,  $ref_column,      $constraint_action
  ) = @{$association};

  $self->{'dbdata'}{$ref_table}{'ref_by'}{$constraint_name} = {'table' => $table_name, 'key' => $key_column, 'fk' => $ref_column, 'action' => $constraint_action};
  $self->{'dbdata'}{$table_name}{'ref_to'}{$constraint_name} = {'table' => $ref_table, 'key' => $ref_column, 'fk' => $key_column, 'action' => $constraint_action};

  return '';
}


=head2 _get_create_index_sql

Extracts the documentation for table indices.

=cut

# Create sql for all indices for given table.
sub _get_create_index_sql {
  my ($self, $table) = @_;
  my $sqlstr = q{};

  # Sanity checks on input
  if (ref($table) ne 'HASH') {
    $self->{log}->error(q{Error in table input - cannot create index sql!});
    return;
  }

OPERATION:
  foreach my $operation (@{ $table->{ops} }) {

    if (ref($operation) ne 'ARRAY') {
      $self->{log}->error(
        q{Error in ops input - expect an ARRAY ref, got } . ref($operation));
      next OPERATION;
    }

    # Extract elements (the stereotype is not in use)
    my ($opname, $optype, $colref, $opstereotype, $opcomment) = (
      $operation->[0], $operation->[1], $operation->[2],
      $operation->[3], $operation->[4]
    );

    # 2nd element can be index, unique index, grant, etc.
    # Accept "index" only in this context.
    if ($optype !~ qr/^(unique )?index$/i) {
      $self->{log}->debug(qq{Skipping optype '$optype' - not (unique) index});
      next OPERATION;
    }

    my $idx_opt =
      (defined $opcomment && $opcomment ne q{})
      ? $opcomment
      : join(q{,}, @{ $self->{index_options} });

    $optype =~ s/index(\w*)//; # remove the 'index' word, leaving unique
    $self->{'dbdata'}{$table->{name}}{'indices'}{$opname} = {'columns' => join(q{, }, @{$colref}), 'comment' => $idx_opt, 'type' => $optype};
    # Use operation comment as index option if defined, otherwise
    # use default (if any)
  }
  return '';
}


=head2 generate_html

Do the output

=cut

sub generate_html {
  my $self = shift;
  my $html = '';
  my $table = '';
  my $tabledata = '';
  my $rowdata = '';
  my $field = '';
  my $temp = '';
  my $value = '';
  my $sep  = '';
  #my $temparray;
  my $fieldblank = $self->{htmltemplate}{fieldblank};

  $html = '';
  $sep = '';
  $rowdata = '';
  # Table list
  foreach $table (sort keys %{$self->{'dbdata'}}) {
    $tabledata = $self->{htmltemplate}{tablelistitem};

    # Table name
    $temp = $self->{'dbdata'}{$table}{'name'} || $fieldblank;
    $tabledata =~ s/{tablename}/$temp/mgi;

    # Table comment
    $value = $self->{'dbdata'}{$table}{'comment'};
    if ( $value) {
      $temp = $self->{htmltemplate}{tablecommentlist};
      $temp =~ s/{comment}/$value/mgi;
    }
    else {
      $temp = $fieldblank; # list context
    }
    $tabledata =~ s/{tablecomment}/$temp/mgi;

    $rowdata .= $sep . $tabledata;
    $sep = $self->{htmltemplate}{tablelistsep};
  }
  $temp = $self->{htmltemplate}{tablelist};
  $temp =~ s/{tablelist}/$rowdata/mgi;
  $value = $self->{filename};
  $temp =~ s/{filename}/$value/mgi;
  $html .= $temp;

 
  # Table details
  $temp = $self->{htmltemplate}{tablestart};
  $html .= $temp;
  foreach $table (sort keys %{$self->{'dbdata'}}) {
    $tabledata = $self->{htmltemplate}{table};

    # Table name
    $temp = $self->{'dbdata'}{$table}{'name'};
    $tabledata =~ s/{tablename}/$temp/mgi;

    # Table comment
    $value = $self->{'dbdata'}{$table}{'comment'};
    if ( $value) {
      $temp = $self->{htmltemplate}{tablecomment};
      $temp =~ s/{comment}/$value/mgi;
    }
    else {
      $temp = '';
    }
    $tabledata =~ s/{tablecomment}/$temp/mgi;

    # Autoupdate
    $value = $self->{'dbdata'}{$table}{'autoupdate'};
    if ( $value) {
      $temp = $self->{htmltemplate}{autoupdate};
      $temp =~ s/{autoupdate}/$value/mgi;
    }
    else {
      $temp = '';
    }
    $tabledata =~ s/{autoupdate}/$temp/mgi;

    # Field data
    $rowdata = '';
    # PK fields first - in diagram order
    foreach $field (sort {$self->{'dbdata'}{$table}{'fields'}{$a}{'order'} <=> $self->{'dbdata'}{$table}{'fields'}{$b}{'order'}} keys %{$self->{'dbdata'}{$table}{'keyfields'}}) {
      $temp = $self->{htmltemplate}{tablekeyrow};
      $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'name'} || $fieldblank;
      $temp =~ s/{name}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'type'} || $fieldblank;
      $temp =~ s/{type}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'default'} || $fieldblank;
      $temp =~ s/{default}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'comment'} || $fieldblank;
      $value =~ s/\n/<br\/>/gmi;
      $temp =~ s/{comment}/$value/mgi;
      $rowdata .= $temp;
    }

    # Other fields - in diagram order
    foreach $field (sort {$self->{'dbdata'}{$table}{'fields'}{$a}{'order'} <=> $self->{'dbdata'}{$table}{'fields'}{$b}{'order'}} keys %{$self->{'dbdata'}{$table}{'fields'}}) {
      if ( not defined($self->{'dbdata'}{$table}{'keyfields'}{$field})){
        $temp = $self->{htmltemplate}{tablerow};
        $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'name'} || $fieldblank;
        $temp =~ s/{name}/$value/mgi;
        $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'type'} || $fieldblank;
        $temp =~ s/{type}/$value/mgi;
        $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'default'} || $fieldblank;
        $temp =~ s/{default}/$value/mgi;
        $value = $self->{'dbdata'}{$table}{'fields'}{$field}{'comment'} || $fieldblank;
        $value =~ s/\n/<br\/>/gmi;
        $temp =~ s/{comment}/$value/mgi;
        $rowdata .= $temp;
      }
    }
    $tabledata =~ s/{tablerowdata}/$rowdata/mgi;

    # References
    $rowdata = '';
    $sep = '';
    foreach $field (sort keys %{$self->{'dbdata'}{$table}{'ref_by'}}) {
      $temp = $self->{htmltemplate}{refbyitem};
      $value = $self->{'dbdata'}{$table}{'ref_by'}{$field}{'table'};
      $temp =~ s/{tablename}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'ref_by'}{$field}{'key'};
      $temp =~ s/{key}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'ref_by'}{$field}{'fk'};
      $temp =~ s/{fk}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'ref_by'}{$field}{'action'};
      $temp =~ s/{action}/$value/mgi;
      $temp =~ s/{refname}/$field/mgi;
      $rowdata .= $sep . $temp;
      $sep = $self->{htmltemplate}{refbysep};
    }
    if ( $rowdata ) {
        $temp = $self->{htmltemplate}{refby};
        $temp =~ s/{refbylist}/$rowdata/mgi;
        $tabledata =~ s/{refby}/$temp/mgi;
    }
    else {
      $tabledata =~ s/{refby}//mgi;
    }

    $rowdata = '';
    $sep = '';
    foreach $field (sort keys %{$self->{'dbdata'}{$table}{'ref_to'}}) {
      $temp = $self->{htmltemplate}{reftoitem};
      $value = $self->{'dbdata'}{$table}{'ref_to'}{$field}{'table'};
      $temp =~ s/{tablename}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'ref_to'}{$field}{'key'};
      $temp =~ s/{key}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'ref_to'}{$field}{'fk'};
      $temp =~ s/{fk}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'ref_to'}{$field}{'action'};
      $temp =~ s/{action}/$value/mgi;
      $temp =~ s/{refname}/$field/mgi;
      $rowdata .= $sep . $temp;
      $sep = $self->{htmltemplate}{refbysep};
    }
    if ( $rowdata ) {
        $temp = $self->{htmltemplate}{refto};
        $temp =~ s/{reftolist}/$rowdata/mgi;
        $tabledata =~ s/{refto}/$temp/mgi;
    }
    else {
      $tabledata =~ s/{refto}//mgi;
    }

    # Indices
    $rowdata = '';
    $sep = '';
    foreach $field (sort keys %{$self->{'dbdata'}{$table}{'indices'}}) {
      $temp = $self->{htmltemplate}{indexitem};
      $temp =~ s/{tablename}/$table/mgi;
      $value = $self->{'dbdata'}{$table}{'indices'}{$field}{'columns'};
      $temp =~ s/{columns}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'indices'}{$field}{'comment'};
      $temp =~ s/{comment}/$value/mgi;
      $value = $self->{'dbdata'}{$table}{'indices'}{$field}{'type'};
      $temp =~ s/{type}/$value/mgi;
      $temp =~ s/{indexname}/$field/mgi;
      $rowdata .= $sep . $temp;
      $sep = $self->{htmltemplate}{indexsep};
    }
    if ( $rowdata ) {
        $temp = $self->{htmltemplate}{indices};
        $temp =~ s/{indexlist}/$rowdata/mgi;
        $tabledata =~ s/{indices}/$temp/mgi;
    }
    else {
      $tabledata =~ s/{indices}//mgi;
    }

    # Permissions
    $rowdata = '';
    $sep = '';
    if (scalar(@{ $self->{'dbdata'}{$table}{'permissions'} })) {
      foreach $field (@{ $self->{'dbdata'}{$table}{'permissions'} }) {
        $temp = $self->{htmltemplate}{permissionitem};
        $temp =~ s/{permission}/$field/mgi;
        $rowdata .= $sep . $temp;
        $sep = $self->{htmltemplate}{permissionsep};
      }
    }
    if ( $rowdata ) {
        $temp = $self->{htmltemplate}{permission};
        $temp =~ s/{permissionlist}/$rowdata/mgi;
        $tabledata =~ s/{permissions}/$temp/mgi;
    }
    else {
      $tabledata =~ s/{permissions}//mgi;
    }

    $html .= $tabledata;

  }

  return $html;
}



=head2 set_html_template

Set up the formatting template

Template elements use C<{placeholders}> to identify how the document should be built.

=cut

sub set_html_template {
  my $self = shift;
  my $format = shift;

  $format = lc($format);

  # Standard HTML bits
  $self->{htmltemplate}{htmlpreamble} = "<html><head>\n<title>Database documentation: {filename}</title>";
  $self->{htmltemplate}{htmlcomment} = "\n<!-- {htmlcomment} -->\n";
  $self->{htmltemplate}{htmlstartbody} = '<body>';
  $self->{htmltemplate}{htmlendbody} = '<p style="font-size:75%">Generated at {gentime}.</p></body>';
  $self->{htmltemplate}{htmlend} = '</body></html>';

  # List of tables
  $self->{htmltemplate}{tablelist} = <<"END";

<h1>Data Dictionary for {filename}</h1>
<h2>List of Tables</h2>
{tablelist}
<hr width='80%'/>

END

  $self->{htmltemplate}{tablestart} =  "<h2>Table details</h2>\n";
  $self->{htmltemplate}{tablelistitem} =  "<a href='#{tablename}'>{tablename}</a>";
  $self->{htmltemplate}{tablelistsep} = ', ';

  # Table: a single table details, mostly placeholders for individual elements
  $self->{htmltemplate}{table} = <<"END";
<h3>Table: {tablename}<a name='{tablename}'/></h3>
{tablecomment}
{refto}
{refby}
<table border='1' cellspacing='0' cellpadding='1'>
<tr><td>Field</td><td>Type</td><td>Default</td><td>Description</td></tr>
{tablerowdata}
</table>
{autoupdate}
{indices}
{permissions}
<hr width='80%'/>
END

  # tablekeyrowtemplate - a single Primary Key row
  $self->{htmltemplate}{tablekeyrow} = '<tr><td><b>{name}</b></td><td>{type}</td><td>{default}</td><td>{comment}</td></tr>';

  # tablerowtemplate - a single non-Key row
  $self->{htmltemplate}{tablerow} = '<tr><td>{name}</td><td>{type}</td><td>{default}</td><td>{comment}</td></tr>';

  # comment - for the table comments (if any)
  $self->{htmltemplate}{tablecomment} = '<p>{comment}</p>';
  $self->{htmltemplate}{tablecommentlist} = '{comment}';

  # autoupdate
  $self->{htmltemplate}{autoupdate} = '<p>Automatically set:{autoupdate}</p>';

  # References - a list of tables that refer to this one via foreign keys
  # Each is formatted with 'refbyitem', separated by 'refbysep'.
  $self->{htmltemplate}{refby} = '<p>Referenced by: {refbylist}</p>';
  $self->{htmltemplate}{refbyitem} = "<a href='#{tablename}'>{tablename}</a>"; #"<a href='#{tablename}'>{tablename}</a>[{key}]";
  $self->{htmltemplate}{refbysep} = ', ';

  # References - a similar list of tables which which this one refers
  # Each is formatted with 'reftoitem', separated by 'reftosep'.
  $self->{htmltemplate}{refto} = '<p>References: {reftolist}</p>';
  $self->{htmltemplate}{reftoitem} = "<a href='#{tablename}'>{tablename}</a>"; # "<a href='#{tablename}'>{tablename}</a>[{key}] ({fk}, {action})";
  $self->{htmltemplate}{reftosep} = ', '; # '<br/>';

  # Permissions - a list of permissions on this table
  # Each is formatted with 'permissionitem', separated by 'permissionsep'.
  $self->{htmltemplate}{permission} = '<h4>Permissions</h4><p>{permissionlist}</p>';
  $self->{htmltemplate}{permissionitem} = '{permission}';
  $self->{htmltemplate}{permissionsep} = '<br/>';

  # Indices - a list of indices on this table
  # Each is formatted with 'indexitem', separated by 'indexsep'.
  $self->{htmltemplate}{indices} = '<h4>Indices</h4><p>{indexlist}</p>';
  $self->{htmltemplate}{indexitem} = '{indexname}: {type} on {columns} {comment}'; 
  $self->{htmltemplate}{indexsep} = '<br/>';
  
  $self->{htmltemplate}{fieldblank} = '&nbsp;';

  # If we have a format parameter, try to read that HTML template elements from it, overriding the defaults

  if ( $format) {
    local $/=undef; # so we can slurp the whole file as one lump
    open my $fh, '<', $format or die "Couldn't open format file: '$format' $!\n";
    my $contents = $fh;
    close $fh;
    my $tag;
    my $htmlelement;
    while ($contents =~ m/\{(?:def\:)(.*?)(?:})(.*?)\{.def\:(\g1)/gsi ) {
      $tag = $1;
      $htmlelement = $2;
      $htmlelement =~s/\\n/\n/g; # Replace \n's with \n's
      $self->{htmltemplate}{$tag} = $htmlelement
   }
  }

  return;
}

1;

=head1 HTML Formats

The default format may be all you need.
If you want to create different HTML formats for different uses, create a format file
with template elements defined between C<{def:element}> and C<{/def:element}> markers.
You only need to define those elements that you want to be I<different> from the defaults.

Any text outside the C<{def:element}> and C<{/def:element}> is ignored, so you can add comments without affecting the output.

Any C<\n> literals in the format file are replaced with newlines; although newlines in the generated HTML typically have
no effect on the layout, they can make the output easier for humans to read.


=head2 Template elements

=head3 htmlpreamble

The start of the html document.

I<Placeholders>: filename

I<Default>: <html><head>\n<title>Database documentation: {filename}</title>

=head3 htmlcomment

A generated comment at the start of the html document. This is the standard comment at the start of the SQL script.

I<Placeholders>: htmlcomment

I<Default>: \n<!-- {htmlcomment} -->\n


=head3 htmlstartbody

The start body html tag.

I<Default>: <body>


=head3 htmlendbody

The end body html tag.

I<Placeholders>: gentime

I<Default>: <p style="font-size:75%">Generated at {gentime}.</p></body>


=head3 htmlend

The end html tag.

I<Default>: </html>


=head3 tablelist

The bit at the top of the page which lists all the tables.
Each is formatted with L</tablelistitem>, separated by L</tablelistsep>.

I<Placeholders>: tablelist (the assembled list of table), filename

I<Default>:

 <h1>Data Dictionary for {filename}</h1>
 <h2\>List of Tables</h2>
 {tablelist}
 <hr width='80%'/>


=head3 tablelistitem

An individual element (table) in the table list

I<Placeholders>: tablename, tablecomment

I<Default>: <a href='#{tablename}'>{tablename}</a>


=head3 tablelistsep

Separator between individual elements in the table list.

I<Default>: C<, >


=head3 tablestart

Introduction to the table details

I<Default>: <h2>Table details</h2>

=head3 table

Details of one table.

I<Placeholders>: tablename, comment, refto, refby, tablerowdata, autoupdate, indices, permissions.

I<Default>:

 <h3>Table: {tablename}<a name='{tablename}'/></h3>
 {comment}
 {refto}
 {refby}
 <table border='1' cellspacing='0' cellpadding='1'>
 <tr><td>Field</td><td>Type</td><td>Default</td><td>Description</td></tr>
 {tablerowdata}
 </table>
 {autoupdate}
 {indices}
 {permissions}
 <hr width='80%'/>

=head3 tablekeyrow, tablerow

Details of an individual field (column) from the (table) in the table detail.

tablekeyrow is used for primary key fields, tablerow for other fields.

I<Placeholders>: name, type, default, comment.

I<Default> B<tablekeyrow>: <tr><td><b>{name}</b></td><td>{type}</td><td>{default}</td><td>{comment}</td></tr>

I<Default> B<tablerow>: <tr><td>{name}</td><td>{type}</td><td>{default}</td><td>{comment}</td></tr>


=head3 tablecomment

Table comments/description.

I<Placeholders>: comment

I<Default>: <p>{comment}</p>

=head3 tablecommentlist

Table comments/description in a list context

I<Placeholders>: comment

I<Default>: {comment}

=head3 autoupdate

Auto update code, if used.

I<Placeholders>: autoupdate

I<Default>: <p>Automatically set:{autoupdate}</p>


=head3 refby, refto

References by - a list of tables that refer to this one via foreign keys.

References to - a list of tables to which this table refers via foreign keys.

The whole section is omitted if there are no references (including any static text).

I<Placeholders>: refbylist, reftolist respectively.

I<Default>: B<refby> <p>Referenced by: {refbylist}</p>

I<Default>: B<refto> <p>References: {reftolist}</p>


=head3 refbyitem, reftoitem

A single item in the reference by list

I<Placeholders>: tablename, key, fk, action, refname

Here I<tablename> is the other table, I<key> is the field in this table, I<fk> is the field in the other table,
I<action> in the action on update/delete (such as cascade or update) and I<refname> is the name of the constraint.

I<Default>: <a href='#{tablename}'>{tablename}</a>


=head3 refbysep, reftosep

Separator between references.

I<Default>: C<, >

=head3 indices

List of indices on this tables.

The whole section is omitted if there are no indices (including any static text).

I<Placeholders>: indexlist

I<Default>: <h4>Indices</h4><p>{indexlist}</p>

=head3 indexitem

A single item in the index list

I<Placeholders>: tablename, columns, comment, type, indexname

Here I<tablename> is the indexed (ie current) table, I<columns> is the set of columns in the index, I<comment> is the index comment if any,
I<type> is 'unique' (or blank) and I<indexname> is the name of the index.

I<Default>: {indexname}: {type} on {columns} {comment}

=head3 indexsep

Separator between indices.

I<Default>: C<<br\>>


=head3 permission

A list of permissions granted on this table.

I<Placeholders>: permissionlist

I<Default>: <h4>Permissions</h4><p>{permissionlist}</p>


=head3 permissionitem

A single permission in the list

I<Placeholders>: permission

I<Default>: {permission}


=head3 permissionsep

Separator between permissions.

I<Default>: <br/>


=head3 fieldblank

Replacement character(s) for blank values. Default value is empty.


=head2 Sample format file

This format file generates vertical lists of tables and references rather than single paragraph, comma separated
lists (which is the default).

 {def:tablelist}
 <h1>List of Tables</h1>
 <table border='1' cellspacing='0' cellpadding='2'>
 <tr><td><b>Name</b></td><td><b>Description</b></td></tr>
 {tablelist}
 </table>

 <hr width='80%'/>
 {/def:tablelist}

 {def:tablelistitem}<tr><td><a href='#{tablename}'>{tablename}</a></td><td>{tablecomment}</td></tr> {/def:tablelistitem}
 {def:tablelistsep}\n{/def:tablelistsep}

 {def:refby}<p><b>Referenced by:</b> <br/>{refbylist}</p>{/def:refby}
 {def:refbyitem}{fk}=<a href='#{tablename}'>{tablename}</a>.{key} {action}{/def:refbyitem}
 {def:refbysep} <br/>{/def:refbysep}

 {def:refto}<p><b>References:</b> <br/>{reftolist}</p>{/def:refto}
 {def:reftoitem} {fk}=<a href='#{tablename}'>{tablename}</a>.{key} {action}{/def:reftoitem}
 {def:reftosep}<br/>{/def:reftosep}

 # Comments don't matter
 {def:permission}<h4>Permissions</h4><p>{permissionlist}</p>{/def:permission}
 {def:permissionitem}{permission}{/def:permissionitem}
 {def:permissionsep}<br/>{/def:permissionsep}

Note that comments or other text outside the {def:}
The other template elements are the same as the default.


=head1 TODO

Things that might get added in future versions:

Better templating mechanism.

Views are not currently documented.

Bugs etc

=cut

__END__


