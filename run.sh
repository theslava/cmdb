#!/bin/bash

exec carton exec ./cmdb.pl daemon > log/$(date +%Y%m%d-%H%M).log
