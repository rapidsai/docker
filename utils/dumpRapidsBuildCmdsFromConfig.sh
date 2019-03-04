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
#
awk --assign debug=${DEBUG} '
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
       # Assume repo is a URL similar to https://github.com/rapidsai/cudf.git
       split($0, fields, "/")
       last = fields[length(fields)]
       split(last, fields, ".")
       comp = fields[1]
       rapidscomps[comp] = 1
       next
    }
    END {
       split("cudf cuml xgboost dask-xgboost dask-cudf dask-cuda", buildorder)
       for (i in buildorder) {
          comp = buildorder[i]
          if (comp in rapidscomps) {
             printf("build-%s.sh\n", comp)
          }
       }
    }
    ' ${CONFIGFILE}
