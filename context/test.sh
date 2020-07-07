#!/bin/bash

RAPIDS_DIR=/rapids
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh
LIBCUDF_KERNEL_CACHE_PATH=${WORKSPACE}/.jitcache
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks
BLAZING_NOTEBOOKS_DIR=/blazing/Welcome_to_BlazingSQL_Notebooks

# Add notebooks that should be skipped here
# (space-separated list of filenames without paths)
SKIPNBS="cuml_benchmarks.ipynb"

## Check env
env

EXITCODE=0

# Find all notebooks to run in both the RAPIDS notebook repo and the Blazing
# "welcome" NB repo.
NOTEBOOKS="$(find ${NOTEBOOKS_DIR}/repos/*/notebooks/* -name *.ipynb) \
           ${BLAZING_NOTEBOOKS_DIR}/welcome.ipynb"

for nb in ${NOTEBOOKS}; do
    nbBasename=$(basename ${nb})

    # Notebook paths can look like the following:
    # "/rapids/notebooks/repos/<repo>/notebooks/<notebook>" or
    # "/blazing/Welcome_to_BlazingSQL_Notebooks/welcome.ipynb"
    # The repo name is extracted by pulling out a specific field in the path.
    # For Blazing, simply use the blazing "root" dir.
    if [[ ${nb:0:8} == "/blazing" ]]; then
        nbRepo="blazing"
    else
        nbRepo=$(echo ${nb} | awk -F/ '{print $5}')
    fi

    # Output the name of the repo.  This is needed for the nbtestlog2junitxml
    # script, as well as to improve output readability.
    echo "========================================"
    echo "REPO: ${nbRepo}"
    echo "========================================"

    # Skip all NBs that use dask (in the code or even in their name).
    # Blazing has a comment that mentions dask, so allow blazing to run
    if [[ ${nbRepo} != "blazing" ]] \
        && ((echo ${nb}|grep -qi dask) \
            || (grep -q dask ${nb})); then
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
