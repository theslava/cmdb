#!/usr/bin/perl

use strict;
use FindBin::libs qw( base=local subdir=lib/perl5 );

use Mojolicious::Lite;
use JSON;

get '/' => sub {
    my $c = shift;
    $c->render(text=>"hello world");
};

app->start;
