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

my %classes;
for my $class (values %{ $cim->{classes} }) {
    $classes{ $class->{name} } = Moose::Meta::Class->create(
        $class->{name} => (
            'superclasses' => [
                'CMDB::BaseCI',
                $class->{superclasses},
            ],
            'attributes' => [
                map { Moose::Meta::Attribute->new( $_, is => 'rw' )} keys %{ $class->{properties} }
            ],
        )
    );
    $classes{ $class->{name} }->make_immutable;
    app->log->debug("Created class: ".$class->{name});
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

get '/classes' => sub {
    my $c = shift;
    $c->render(text => join q{<br/>}, Dumper $classes{$c->req->param('class')});
};

app->log->info("Starting main loop");
app->start;

__END__
