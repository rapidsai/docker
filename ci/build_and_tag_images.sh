#!/bin/bash

# Build both base & notebook images, tag them, and upload to S3
# Requires environment variables:
#    CUDA_VER
#    LINUX_VER
#    PYTHON_VER
#    RAPIDS_VER
#    DASK_SQL_VER
# Example Usage:
#   ./ci/build_and_tag_images.sh

set -euox pipefail

TAG="$RAPIDS_VER-cuda$CUDA_VER-$LINUX_VER-py$PYTHON_VER"

BUILD_ARGS=(
    "--build-arg" "CUDA_VER=$CUDA_VER"
    "--build-arg" "LINUX_VER=$LINUX_VER"
    "--build-arg" "PYTHON_VER=$PYTHON_VER"
    "--build-arg" "RAPIDS_VER=$RAPIDS_VER"
    "--build-arg" "DASK_SQL_VER=$DASK_SQL_VER"
)

docker buildx build --pull -f Dockerfile \
    --target base \
    "${BUILD_ARGS[@]}" \
    -t "rapidsai/rapidsai:$TAG" \
    ./context

docker buildx build --pull -f Dockerfile \
    --target notebooks \
    "$BUILD_ARGS[@]" \
    -t "rapidsai/rapidsai-notebooks:$TAG" \
    ./context

rapids-upload-docker-to-s3 "rapidsai/rapidsai:$TAG"
rapids-upload-docker-to-s3 "rapidsai/rapidsai-notebooks:$TAG"