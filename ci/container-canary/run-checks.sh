#!/bin/bash
# Copyright (c) 2025, NVIDIA CORPORATION.

set -e -E -u -o pipefail

# expect the image URI to be the final argument
IMAGE_URI="${*: -1}"

NUMARGS=$#
ARGS=$*

function hasArg {
    (( NUMARGS != 0 )) && (echo " ${ARGS} " | grep -q " $1 ")
}

# pre-pull
docker pull "${IMAGE_URI}"

check_configs=(
    ./ci/container-canary/base.yml
)

if hasArg '--notebooks'; then
    check_configs+=(./ci/container-canary/notebooks.yml)
fi

if hasArg '--dask-scheduler'; then
    check_configs+=(https://raw.githubusercontent.com/NVIDIA/container-canary/main/examples/dask-scheduler.yaml)
fi

for check_config in "${check_configs[@]}"; do
    echo "checking '${IMAGE_URI}' with '${check_config}'"
    container-canary validate \
        --file "${check_config}" \
        --startup-timeout 60 \
        "${IMAGE_URI}"
done

echo "done checking '${IMAGE_URI}' with container-canary"
