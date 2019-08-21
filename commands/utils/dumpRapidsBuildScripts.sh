#!/bin/bash

# Copyright (c) 2019, NVIDIA CORPORATION.

USAGE="
USAGE: $0
"

if (( $# > 0 )); then
    echo "${USAGE}"
    exit 1
fi

THISDIR=$(cd $(dirname $0); pwd)
RAPIDSDEVTOOL_DIR=${THISDIR}/../..
source ${THISDIR}/common.sh

#
# awk script processes repoSettings file line-by-line.
# Extract the URLs
#
awk -v "debug=${DEBUG}" \
    -v "utilsDir=${UTILS_DIR}" '
    /^[a-zA-Z0-9_\-]+_REPO=.+$/ {
       # Assume repo is a URL similar to https://github.com/rapidsai/cudf.git
       numFields = split($0, fields, "/")
       last = fields[numFields]
       split(last, fields, ".")
       comp = fields[1]
       rapidscomps[comp] = 1
       next
    }
    END {
       # Generate the build script using the components discovered in the
       # config, which are now saved in rapidscomps
       printf("NUMARGS=$#\n")
       printf("ARGS=$*\n")
       printf("# This assumes this script resides in the rapids dir that contains the cloned repos!\n")
       printf("# NOTE: this script should only be used if the repo does not contain a \"build.sh\".\n")
       printf("cd $(dirname $0)\n")
       printf("\n")
       printf("function shouldBuild {\n    (( ${NUMARGS} == 0 )) || (echo \" ${ARGS} \" | grep -q \" $1 \")\n}\n\n")

       # Enforce a specific build order
       # FIXME: change script to allow for comps that are not in this
       # list. For those, simply do them in any order afterwards. Otherwise
       # this list will need to be updated when new RAPIDS comps are added.
       split("xgboost dask-xgboost dask-cuda", buildorder)
       for (i in buildorder) {
          comp = buildorder[i]
          if (comp in rapidscomps) {
             script = utilsDir "/build-" comp ".sh"
             # Not all comps have a build script, so skip if script DNE
             if (system("ls " script ">/dev/null 2>&1") != 0) {
                continue
             }
             printf("####################\n# %s\n", comp)
             printf("if shouldBuild " comp "; then\n")
             printf("    pushd ${RAPIDS_DIR}\n")
             while ((getline line < script) > 0) {
                # Only print lines not starting with #!
                if (index(line, "#!") == 1) {
                   continue
                }
                   printf("    %s\n", line)
             }
             printf("\n    exitCode=$?\n")
             printf("    if (( ${exitCode} != 0 )); then\n        exit ${exitCode}\n    fi\n")
             printf("    popd\n")
             printf("fi\n")
          }
       }
    }
    ' ${REPOSETTINGS_FILE_NAME}
