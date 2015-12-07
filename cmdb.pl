#!/usr/bin/perl

use strict;

use FindBin::libs qw( base=local subdir=lib/perl5 );

use DMTF::CIM;
use Data::Dumper;

my $cim = DMTF::CIM->new();
$cim->parse_mof('etc/dmtf_cim_scema_2.44.1/cim_schema_2.44.1.mof');
print Dumper keys %{$cim->{MODEL}};
