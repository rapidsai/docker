#!/bin/bash
set -ex

RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh

# Test script used by Jenkins to check that builds are ready to publish

## Check env
env

## Activate conda env
source activate rapids

# Test cuML notebooks
# nbtest always tests all NBs passed to it, but exit code of nbtest is
# non-zero if any NB fails.
cd ${NOTEBOOKS_DIR}/cuml
${NBTEST} *.ipynb 2>&1 | tee nbtestresults.txt
