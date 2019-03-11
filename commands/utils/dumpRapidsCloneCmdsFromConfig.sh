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
#
awk -v "debug=${DEBUG}" '
    BEGIN {
       inRapidsSection = 0
    }
    /^# SECTION: RAPIDS.*$/ {
       inRapidsSection = 1
       next
    }
    /^# SECTION: .*$/ {
       inRapidsSection = 0
       next
    }
    /^[a-zA-Z0-9_\-]+_REPO=.+$/ {
       if (inRapidsSection == 0) {
          next
       }
       split($0, fields, "=")
       var = fields[1]
       url = fields[2] # Assume url is similar to https://github.com/rapidsai/cudf.git
       repo = substr(var, 1, length(var)-length("_REPO"))
       split(url, fields, "/")
       last = fields[length(fields)]
       split(last, fields, ".")
       dir = fields[1]
       repourls[repo] = url
       repodirs[repo] = dir
       next
    }
    /^[a-zA-Z0-9_\-]+_BRANCH=.+$/ {
       if (inRapidsSection == 0) {
          next
       }
       split($0, fields, "=")
       var = fields[1]
       branch = fields[2]
       repo = substr(var, 1, length(var)-length("_BRANCH"))
       repobranches[repo] = branch
       next
    }
    END {
       for (repo in repourls) {
          url = repourls[repo]
          dir = repodirs[repo]
          branch = repobranches[repo]
          printf("clone %s %s %s\n",url, dir, branch)
       }
    }
    ' ${CONFIG_FILE_NAME}
