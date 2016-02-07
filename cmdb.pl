#!/usr/bin/perl

use strict;
use FindBin::libs qw( base=moosex-storage-dbi-pgdoc subdir=lib subonly );
use FindBin::libs;

use CMDB::BaseCI;
use DBI;
use Data::Dumper;
use JSON;
use Mojolicious::Lite;
use Moose;

my $dbh = DBI->connect_cached(
    'dbi:Pg:db=cmdb;host=localhost;port=5432',
    'cmdb',
    'cmdb',
);
die $DBI::errstr unless $dbh;
helper db => sub { $dbh };

# Set up the data
app->log->info("Schema: loading");

use CMDB::Schema;
my $cmdb_schema = CMDB::Schema->new({ files => [ glob "$FindBin::Bin/etc/*.json" ] });
$cmdb_schema->load_class($_) for (keys %{ $cmdb_schema->schema->{classes} });

app->log->info("Schema: loaded");
app->log->info("Setting up routes");

get '/cmdb/schema' => sub {
    my $c = shift;
    my $pointer = $c->cim;
    for my $key (split /:/, $c->req->param('path')) {
        $pointer = $pointer->{$key};
    }
    if (ref $pointer eq 'HASH') {
        $c->render(text => join q{<br/>}, Dumper keys %{$pointer});
    }
    else {
        $c->render(text => join q{<br/>}, Dumper $pointer);
    }
};

get '/cmdb/get_properties' => sub {
    my $c = shift;
    my $class = $c->req->param('class');
    $c->render( 
        template => 'properties',
        metaclass => eval { "$class"->meta },
    );
};

get '/cmdb/:uuid' => { uuid => undef } => sub {
    my $c = shift;
    if (defined $c->param('uuid')) {
        $c->render(
            template => 'ci',
            ci => CMDB::BaseCI->load( $c->db, encode_json( { uuid => $c->param('uuid') } ) ),
        );
    }
    else {
        $c->render( template => 'index', classes => [ keys %{ $cmdb_schema->schema->{classes} } ], uuids => $c->db->selectall_arrayref(q{select uuid from data}) );
    }
};

post '/cmdb/:uuid' => { uuid => undef } => sub {
    my $c = shift;
    my %params = %{$c->req->params->to_hash};
    app->log->debug(Dumper \%params);
    my $class = delete $params{_class};
    my %init = ();
    for my $key (keys %params) {
        if ($params{$key} ne q{}) {
            $init{$key} = $params{$key};
        }
    }
    my $obj = eval "$class->new(%init)";
    if ($@) {
        $c->render( text => $@ );
    }
    else {
        $obj->store($c->db);
        $c->redirect_to('/cmdb/'.$obj->uuid);
    }
};

app->log->info("Starting main loop");
app->start;

