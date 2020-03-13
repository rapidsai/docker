#!/bin/bash

RAPIDS_DIR=/rapids
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
LIBCUDF_KERNEL_CACHE_PATH=${WORKSPACE}/.jitcache

cd ${RAPIDS_DIR}

# Add notebooks that should be skipped here
# (space-separated list of filenames without paths)

SKIPNBS=""

## Check env
env

EXITCODE=0

# Always run nbtest in all TOPLEVEL_NB_FOLDERS, set EXITCODE to failure
# if any run fails
for nb in $(find repos/*/notebooks/* -name *.ipynb); do
    nbBasename=$(basename ${nb})
    # Skip all NBs that use dask (in the code or even in their name)
    if ((echo ${nb}|grep -qi dask) || \
        (grep -q dask ${nb})); then
        echo "--------------------------------------------------------------------------------"
        echo "SKIPPING: ${nb} (suspected Dask usage, not currently automatable)"
        echo "--------------------------------------------------------------------------------"
    elif (echo " ${SKIPNBS} " | grep -q " ${nbBasename} "); then
        echo "--------------------------------------------------------------------------------"
        echo "SKIPPING: ${nb} (listed in skip list)"
        echo "--------------------------------------------------------------------------------"
    else 
        cd $(dirname ${nb})
        nvidia-smi
        ${NBTEST} ${nbBasename}
        EXITCODE=$((EXITCODE | $?))
        rm -rf ${LIBCUDF_KERNEL_CACHE_PATH}/*
        cd ${RAPIDS_DIR}/${folder}
    fi
done

nvidia-smi

exit ${EXITCODE}
