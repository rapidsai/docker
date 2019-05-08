#!/bin/bash

RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
NOTEBOOK_DIR_NAMES="cuml cugraph"

## Check env
env

## Activate conda env
source activate rapids

EXITCODE=0

# Always run nbtest in all NOTEBOOK_DIR_NAMES, set EXITCODE to failure
# if any run fails
for nbdirname in ${NOTEBOOK_DIR_NAMES}; do
    cd ${NOTEBOOKS_DIR}/${nbdirname}
    ${NBTEST} *.ipynb
    EXITCODE=$((EXITCODE | $?))
done

exit ${EXITCODE}
