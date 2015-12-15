CMDB project

Ultimate goal is to provide a CMDB that is horizontally scalable and easily extendible.

This CMDB project aims to provide a simple JSON API (with DSP0020 support later on)
that uses PostgreSQL as the storage backend (and its jsonb datatype). This should
allow a PostgreSQL cluster to horizontally scale CMDB to expand read/write performance

CMDB schema comes from MOF files produced by DMTF and can be extended with additional
MOF files that acompiled (parsed into a hash with DMTF::CIM and dumped into JSON.
