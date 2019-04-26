#!/bin/bash

# TODO: This script is almost identical to dumpRapidsBuildScriptsFromConfig.sh -
# consider refactoring

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
# Extract the URLs
#
awk -v "debug=${DEBUG}" \
    -v "utilsDir=${UTILS_DIR}" '
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
       numFields = split($0, fields, "/")
       last = fields[numFields]
       split(last, fields, ".")
       comp = fields[1]
       rapidscomps[comp] = 1
       next
    }
    END {
       # Generate the individual Docker "RUN" calls based on the RAPIDS comps in
       # config, which are now saved in rapidscomps

       # Enforce a specific build order
       # FIXME: change script to allow for comps that are not in this
       # list. For those, simply do them in any order afterwards. Otherwise
       # this list will need to be updated when new RAPIDS comps are added.
       split("rmm custrings cudf cuml cugraph xgboost dask-xgboost dask-cudf dask-cuda", buildorder)
       for (i in buildorder) {
          comp = buildorder[i]
          if (comp in rapidscomps) {
             script = utilsDir "/build-" comp ".sh"
             # Not all comps have a build script, so skip if script DNE
             if (system("ls " script ">/dev/null 2>&1") != 0) {
                continue
             }
             printf("RUN source activate rapids && cd ${RAPIDS_SRC_DIR} && \\\n")
             printf("    ./build.sh " comp " && \\\n")
             printf("    cd " comp " && git clean -xdff\n")
          }
       }
    }
    ' ${CONFIG_FILE_NAME}
