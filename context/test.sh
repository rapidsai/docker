#!/bin/bash

RAPIDS_DIR=/rapids
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
LIBCUDF_KERNEL_CACHE_PATH=${WORKSPACE}/.jitcache
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks

# Add notebooks that should be skipped here
# (space-separated list of filenames without paths)
SKIPNBS="cuml_benchmarks.ipynb"

## Check env
env

EXITCODE=0

# Always run nbtest in NOTEBOOKS_DIR, set EXITCODE to failure if any run fails
cd ${NOTEBOOKS_DIR}

# Every repo is submoduled into "repos/<repo>" and notebooks have been stored
# into a "notebooks" dir, this loop finds all notebooks specifically added to CI
for nb in $(find repos/*/notebooks/* -name *.ipynb); do
    nbBasename=$(basename ${nb})
    # Output of find command looks like this: ./repos/<repo>/notebooks/<notebook> -name
    # This grabs the <repo> element, skip CLX notebooks as they are not part of the runtime images yet
    nbRepo=$(echo ${nb} | awk -F/ '{print $2}')

    echo "========================================"
    echo "REPO: ${nbRepo}"
    echo "========================================"

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
    elif [[ ${nbRepo} == "clx" ]]; then
        echo "--------------------------------------------------------------------------------"
        echo "SKIPPING: ${nb} (CLX notebook)"
        echo "--------------------------------------------------------------------------------"
    else
        # All notebooks are run from the directory in which they are contained.
        # This makes operations that assume relative paths easiest to understand
        # and maintain, since most users assume relative paths are relative to
        # the location of the notebook itself. After a run, the CWD must be
        # returned to NOTEBOOKS_DIR, since the find operation returned paths
        # relative to that dir.
        cd $(dirname ${nb})
        nvidia-smi
        ${NBTEST} ${nbBasename}
        EXITCODE=$((EXITCODE | $?))
        rm -rf ${LIBCUDF_KERNEL_CACHE_PATH}/*
        cd ${NOTEBOOKS_DIR}
    fi
done

nvidia-smi

exit ${EXITCODE}
