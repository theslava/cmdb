#!/usr/bin/perl

use strict;
use FindBin::libs qw( base=moosex-storage-dbi-pgdoc );
use FindBin::libs;

use Mojolicious::Lite;
use JSON;

get '/' => sub {
    my $c = shift;
    $c->render(text=>"hello world");
};

app->start;
