#!/usr/bin/perl

use strict;

use FindBin::libs qw( base=local subdir=lib/perl5 );

use DMTF::CIM;
use JSON;

open my $fh, q{>}, 'etc/dmtf_cim_schema_2.44.1.json' or die $!;
my $cim = DMTF::CIM->new();
$cim->parse_mof('etc/dmtf_cim_schema_2.44.1/cim_schema_2.44.1.mof');
print $fh encode_json($cim->{MODEL});
close $fh;
