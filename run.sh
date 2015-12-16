#!/bin/bash

exec carton exec morbo -v ./cmdb.pl daemon > log/$(date +%Y%m%d-%H%M).log
