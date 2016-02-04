#!/usr/bin/perl

use strict;
use FindBin::libs qw( base=moosex-storage-dbi-pgdoc subdir=lib subonly );
use FindBin::libs qw( base=local subdir=lib/perl5 subonly );
use FindBin::libs;

use CMDB::BaseCI;
use DBI;
use Data::Dumper;
use JSON;
use Moose;

with 'MooseX::Getopt';

has 'save' => (
    is => 'ro',
);

has 'load' => (
    is => 'ro',
    isa => 'Str',
);

has 'list' => (
    is => 'ro',
);

sub run {
    my $self = shift;
    my $dbh = DBI->connect_cached(
        'dbi:Pg:db=cmdb;host=localhost;port=5432',
        'cmdb',
        'cmdb',
    );
    die $DBI::errstr unless $dbh;

    if ($self->list) {
        my $data = $dbh->selectall_arrayref(q{select data from data});
        print Dumper $data;
    }
    elsif ($self->load) {
        my $obj = CMDB::BaseCI->load($dbh, $self->load);
        print Dumper $obj;
    }
    elsif ($self->save) {
        CMDB::BaseCI->new()->store($dbh);
    }
    else {
        die $self->usage;
    }

    return;
}

main->new_with_options->run;
