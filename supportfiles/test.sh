#!/bin/bash

RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
NOTEBOOK_DIR_NAMES="cudf cuml cugraph xgboost tutorials"

SKIPNBS="kmeans_demo_mnmg.ipynb random_forest_mnmg_demo.ipynb"
## Check env
env

EXITCODE=0

# Always run nbtest in all NOTEBOOK_DIR_NAMES, set EXITCODE to failure
# if any run fails
for nbdirname in ${NOTEBOOK_DIR_NAMES}; do
    echo "========================================"
    echo "FOLDER: ${nbdirname}"
    echo "========================================"
    pushd ${NOTEBOOKS_DIR}/${nbdirname} > /dev/null
    for nb in $(ls *.ipynb); do
        if (echo " ${SKIPNBS} " | grep -q " ${nb} "); then
            echo --------------------------------------------------------------------------------
            echo "SKIPPING: ${nb}"
            echo --------------------------------------------------------------------------------
        else
            nvidia-smi
            ${NBTEST} ${nb}
            EXITCODE=$((EXITCODE | $?))
        fi
    done
    popd > /dev/null
done

nvidia-smi

exit ${EXITCODE}
