#!/bin/bash
set -ex

RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
NBDIRS="cuml cugraph"

## Check env
env

## Activate conda env
source activate rapids

EXITCODE=0

# Always run nbtest in all NBDIRS, set EXITCODE to failure if any run
# fails
for nbdirname in ${NBDIRS}; do
    cd ${NOTEBOOKS_DIR}/${nbdirname}
    ${NBTEST} *.ipynb
    EXITCODE=$((EXITCODE | $?))
done

exit ${EXITCODE}
