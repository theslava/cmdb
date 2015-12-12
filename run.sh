#!/bin/bash

exec carton exec ./cmdb.pl daemon > log/$(date +%y%m%d%H%M).log
