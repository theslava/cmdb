#!/usr/bin/perl

use strict;
use FindBin::libs qw( base=moosex-storage-dbi-pgdoc );
use FindBin::libs;

use Data::Dumper;

# Mojolicious: where the magic happens
use Mojolicious::Lite;

# Set up the data
use JSON;
app->log->info("Loading schema");

my $cim = eval {
    local $/ = undef;
    open my $fh, q{<}, 'etc/dmtf_cim_schema_2.44.1.json';
    my $ret = <$fh>;
    close $fh;
    return decode_json($ret);
};

app->log->info("Schema loaded, ready to process requests");

get '/' => sub {
    my $c = shift;
    $c->render(text=> join q{, },  keys %{$cim});
};

app->start;
