#!/bin/bash

set -e -u -o pipefail

IMAGE_URI="${1}"

# using a config checked in here
canary validate \
    --file ./ci/container-canary/rapids.yml \
    "${IMAGE_URI}"

# usage a config from the container-canary repo
canary validate \
    --file https://raw.githubusercontent.com/NVIDIA/container-canary/main/examples/databricks.yaml \
    "${IMAGE_URI}"
