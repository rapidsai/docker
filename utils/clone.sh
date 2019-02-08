#!/bin/bash
set -e
# File downloads latest versions of git repos and packages them for importing
# into Docker image to reduce build times and to make sure content is consistent

# CONFIG
CUDF_REPO="https://github.com/rapidsai/cudf.git"
CUDF_BRANCH=branch-0.5
CUDF_DIR=cudf

CUML_REPO="https://github.com/rapidsai/cuml.git"
CUML_BRANCH=branch-0.5
CUML_DIR=cuml

XGBOOST_REPO="https://github.com/rapidsai/xgboost.git"
XGBOOST_BRANCH=cudf-mnmg
XGBOOST_DIR=xgboost

DASK_XGBOOST_REPO="https://github.com/rapidsai/dask-xgboost.git"
DASK_XGBOOST_BRANCH=dask-cudf
DASK_XGBOOST_DIR=dask-xgboost

DASKCUDF_REPO="https://github.com/rapidsai/dask-cudf.git"
DASKCUDF_BRANCH=master
DASKCUDF_DIR=dask-cudf

DASKCUDA_REPO=https://github.com/rapidsai/dask-cuda.git
DASKCUDA_DIR=dask-cuda

NOTE_REPO="https://github.com/rapidsai/notebooks.git"
NOTE_DIR=notebooks

WORK_DIR=`pwd`

# Logger function
function logger() {
    TS=`date`
    echo "[$TS] $@"
}

function clone() {
  repo=$1
  directory=$2
  rm -rf $directory
  
  if [ $# -eq 2 ]; then
    logger "Cloning $repo"
    git clone --depth 1 --recurse-submodules $repo $directory
  else
    branch=$3
    logger "Cloning '$branch' branch of $repo"
    git clone --depth 1 --recurse-submodules --single-branch -b $branch $repo $directory
  fi
  cd $WORK_DIR/$directory
  echo "$repo" > current-commit.hash
  git rev-parse HEAD >> current-commit.hash
  cd $WORK_DIR
}

# Clean up
rm -f Miniconda*.sh

# Get repos
clone $CUDF_REPO $CUDF_DIR $CUDF_BRANCH
clone $CUML_REPO $CUML_DIR $CUML_BRANCH
clone $XGBOOST_REPO $XGBOOST_DIR $XGBOOST_BRANCH
clone $DASK_XGBOOST_REPO $DASK_XGBOOST_DIR $DASK_XGBOOST_BRANCH
clone $DASKCUDF_REPO $DASKCUDF_DIR $DASKCUDF_BRANCH
clone $DASKCUDA_REPO $DASKCUDA_DIR
clone $NOTE_REPO $NOTE_DIR

logger "Done"
