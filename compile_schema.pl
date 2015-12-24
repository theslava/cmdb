#!/usr/bin/perl

use strict;

use FindBin::libs;
use FindBin::libs qw( base=local subdir=lib/perl5 );

use DMTF::CIM::MOF;
use JSON;

open my $fh, q{>}, 'etc/dmtf_cim_schema_2.44.1.json' or die $!;
my $schema = DMTF::CIM::MOF::parse_MOF('etc/dmtf_cim_schema_2.44.1/cim_schema_2.44.1.mof');
print $fh JSON->new->encode($schema);
close $fh;
