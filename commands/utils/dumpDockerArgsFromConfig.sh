#!/bin/bash

USAGE="
USAGE: $0
"

if (( $# > 0 )); then
    echo "${USAGE}"
    exit 1
fi

THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/../..
source ${THISDIR}/common.sh

#
# awk script processes config file line-by-line.
# Look for a specific section marker, then dump each line encountered
# after it as-is unitl a different section marker or EOF.
# Ignore blank lines.
#
awk -v "debug=${DEBUG}" '
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
    /^[^\ \t\#]+$/ {
       if (inSectionToDump) {
          printf( "ARG %s\n", $0 )
       }
    }
    ' ${CONFIG_FILE_NAME}
