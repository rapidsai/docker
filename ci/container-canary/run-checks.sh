#!/bin/sh

set -e -u

IMAGE_URI="${1}"

# pre-pull
docker pull "${IMAGE_URI}"

# using a config checked in here
container-canary validate \
    --file ./ci/container-canary/rapids.yml \
    ubuntu:latest

# # usage a config from the container-canary repo
# container-canary validate \
#     --file https://raw.githubusercontent.com/NVIDIA/container-canary/main/examples/databricks.yaml \
#     "${IMAGE_URI}"
