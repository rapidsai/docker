#!/bin/bash

# Build both base & notebook images, tag them, and upload to S3
# Requires environment variables:
#    TAG
#    CUDA_VER
#    LINUX_VER
#    PYTHON_VER
#    RAPIDS_VER
#    DASK_SQL_VER
# Example Usage:
#   ./ci/build_and_tag_images.sh

set -euox pipefail

BUILD_ARGS=(
    "--build-arg" "CUDA_VER=$CUDA_VER"
    "--build-arg" "LINUX_VER=$LINUX_VER"
    "--build-arg" "PYTHON_VER=$PYTHON_VER"
    "--build-arg" "RAPIDS_VER=$RAPIDS_VER"
    "--build-arg" "DASK_SQL_VER=$DASK_SQL_VER"
)

docker_build() {
    target="$1"
    repo="$2"

    docker buildx build --pull --load \
        -f Dockerfile \
        --target "$target" \
        "${BUILD_ARGS[@]}" \
        -t "$repo:$TAG" \
        ./context
}

docker_build base rapidsai/rapidsai
docker_build notebooks rapidsai/rapidsai-notebooks
