#!/bin/bash

USAGE="
USAGE: $0
"

if (( $# > 0 )); then
    echo "${USAGE}"
    exit 1
fi

CONFIGFILE=$(dirname $0)/../config

#
# awk script processes config file line-by-line.
# Look for a specific section marker, then dump each line encountered
# after it as-si unitl a different section marker or EOF.
# Ignore blank lines.
#
awk --assign debug=${DEBUG} '
    BEGIN {
       inSectionToDump = 0
    }
    /^# SECTION: DEPENDENCIES.*$/ {
       inSectionToDump = 1
       next
    }      
    /^# SECTION: .*$/ {
       inSectionToDump = 0
       next
    }      
    /^[^\ \t]+$/ {
       if (inSectionToDump) {
          printf( "ARG %s\n", $0 )
       }
    }
    ' ${CONFIGFILE}
