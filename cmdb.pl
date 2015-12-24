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

my $dbh = DBI->connect(
    'dbi:Pg:db=json;host=localhost;port=5432',
    'json',
    'json',
);
die $DBI::errstr unless $dbh;
helper db => sub { $dbh };

# Set up the data
app->log->info("Schema: loading");

my $cim = eval {
    local $/ = undef;
    open my $fh, q{<}, 'etc/dmtf_cim_schema_2.44.1.json';
    my $ret = <$fh>;
    close $fh;
    return decode_json($ret);
};
helper cim => sub { $cim };

app->log->info("Schema: loaded");
app->log->info("Classes: creating");

our %classes;
for my $class (values %{ $cim->{classes} }) {
    load_class($class);
}

app->log->info("Classes: created");
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
    $c->render( 
        template => 'properties',
        metaclass => $classes{ $c->req->param('class') },
    );
};

get '/cmdb/:uuid' => { uuid => undef } => sub {
    my $c = shift;
    if (defined $c->param('uuid')) {
        my $ci = CMDB::BaseCI->load( $c->db, $c->param('uuid') );
        app->log->debug(Dumper $ci);
        $c->render(
            template => 'ci',
            ci => $ci,
        );
    }
    else {
        $c->render( template => 'index', classes => [ keys %classes ] );
    }
};

post '/cmdb/:uuid' => { uuid => undef } => sub {
    my $c = shift;
    my %params = %{$c->req->params->to_hash};
    my $class = delete $params{ci_class};
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

sub load_class {
    my ($class) = @_;
    return unless $class;
    return if (exists ($classes{ $class->{name} }));

    my $superclass = 'CMDB::BaseCI';
    if ( exists $class->{superclass} ) {
        load_class( $cim->{classes}->{ lc( $class->{superclass} ) } );
        $superclass = $class->{superclass};
    }
    $classes{ $class->{name} } = Moose::Meta::Class->create(
        $class->{name} => (
            'superclasses' => [
                $superclass,
            ],
            'attributes' => [
                map { Moose::Meta::Attribute->new( $_, is => 'rw', documentation => $class->{properties}->{$_}->{name} )} keys %{ $class->{properties} }
            ],
        )
    );
    $classes{ $class->{name} }->make_immutable;
    app->log->debug("Created class: ".$class->{name});
}

