#!/usr/bin/perl

use strict;
use FindBin::libs qw( base=moosex-storage-dbi-pgdoc subdir=lib subonly );
use FindBin::libs;

use Data::Dumper;
use CMDB::BaseCI;
use Moose;

# Mojolicious: where the magic happens
use Mojolicious::Lite;

# Set up the data
use JSON;
app->log->info("Schema: loading");

our $cim = eval {
    local $/ = undef;
    open my $fh, q{<}, 'etc/dmtf_cim_schema_2.44.1.json';
    my $ret = <$fh>;
    close $fh;
    return decode_json($ret);
};

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
    my $pointer = $cim;
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
        properties => [ $classes{ $c->req->param('class') }->get_attribute_list ],
    );
};

get '/' => sub {
    my $c = shift;
    $c->render( template => 'index', classes => [ keys %classes ] );
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
                map { Moose::Meta::Attribute->new( $_, is => 'rw' )} keys %{ $class->{properties} }
            ],
        )
    );
    $classes{ $class->{name} }->make_immutable;
    app->log->debug("Created class: ".$class->{name});
}

__END__
