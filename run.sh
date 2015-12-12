#!/bin/bash

exec carton exec ./cmdb.pl daemon > log/$(date +%D%m%d-%H%M).log
