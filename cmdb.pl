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
    { RaiseError => 1, PrintError => 1 },
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

get '/schema' => sub {
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

get '/properties' => sub {
    my $c = shift;
    $c->render( 
        template => 'properties',
        metaclass => $classes{ $c->req->param('class') },
    );
};

get '/' => sub {
    my $c = shift;
    $c->render( template => 'index', classes => [ keys %classes ] );
};

post '/' => sub {
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
        $c->render( text => $obj->freeze );
    }
};

get '/ci/:uuid' => sub {
    my $c = shift;
    $c->render( text => join q{}, Dumper( CMDB::BaseCI->load( $c->db, $c->param('uuid') ) ) );
};

app->log->info("Starting main loop");
app->start;

sub load_class {
    my ($class) = @_;
    return unless $class;
    return if (exists ($classes{ $class->{name} }));

    if ( exists $class->{superclass} ) {
        load_class( $cim->{classes}->{ lc( $class->{superclass} ) } );
    }
    $classes{ $class->{name} } = Moose::Meta::Class->create(
        $class->{name} => (
            'superclasses' => [
                'CMDB::BaseCI',
                $class->{superclass},
            ],
            'attributes' => [
                map { Moose::Meta::Attribute->new( $_, is => 'rw', documentation => $class->{properties}->{$_}->{name} )} keys %{ $class->{properties} }
            ],
        )
    );
    $classes{ $class->{name} }->make_immutable;
    app->log->debug("Created class: ".$class->{name});
}

__END__
