#!/bin/bash

RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
NOTEBOOK_DIR_NAMES="cuml cugraph cudf xgboost tutorials"

SKIPNBS="kmeans_demo_mnmg.ipynb random_forest_mnmg_demo.ipynb"
## Check env
env

EXITCODE=0

# Always run nbtest in all NOTEBOOK_DIR_NAMES, set EXITCODE to failure
# if any run fails
for nbdirname in ${NOTEBOOK_DIR_NAMES}; do
    echo "========================================"
    echo "  ${nbdirname}"
    echo "========================================"
    pushd ${NOTEBOOKS_DIR}/${nbdirname} > /dev/null
    for nb in $(ls *.ipynb); do
        if (echo " ${SKIPNBS} " | grep -q " ${nb} "); then
            echo "SKIPPING ${nb}"
        else
            ${NBTEST} ${nb}
            EXITCODE=$((EXITCODE | $?))
        fi
    done
    popd > /dev/null
done

exit ${EXITCODE}
