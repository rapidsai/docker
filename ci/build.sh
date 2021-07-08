#!/bin/bash

echo "start script: $1"
env
echo "end script"

# Handle $1 var input (i.e core, std, clx)
case $1 in
  core)
    echo "Building core image"
    BUILD_IMAGE="rapidsai/rapidsai-core"
    TARGET_STAGE="rapids-core"
    ;;

  std)
    echo "Building std image"
    BUILD_IMAGE="rapidsai/rapidsai"
    TARGET_STAGE="rapids-std"
    ;;

  clx)
    echo "Building clx image"
    BUILD_IMAGE="rapidsai/rapidsai-clx"
    TARGET_STAGE="rapids-clx"
    ;;

  *)
    echo "Use one of: core, std, clx. (i.e. build.sh core)"
    exit
    ;;
esac

BUILD_ARGS="--no-cache \
  --squash \
  --build-arg CUDA_VER=${CUDA_VER} \
  --build-arg LINUX_VER=${LINUX_VER} \
  --build-arg PYTHON_VER=${PYTHON_VER} \
  --build-arg RAPIDS_VER=${RAPIDS_VER}"

# Handle devel images args/suffixes
if [ "${IMAGE_TYPE}" = "devel" ]; then
  BUILD_IMAGE+="-dev"
  BUILD_ARGS+=" --build-arg UCX_PY_VER=${UCX_PY_VER}"
fi

# Handle nightly vs. stable builds
if [ "${CHANGE_TARGET}" = "main" ]; then
  BUILD_ARGS+=" --build-arg BUILD_BRANCH=main"
else
  BUILD_IMAGE+="-nightly"
fi

DOCKERFILE="${LINUX_VER}-${IMAGE_TYPE}.Dockerfile"
BUILD_TAG="${RAPIDS_VER}-cuda${CUDA_VER}-${IMAGE_TYPE}-${LINUX_VER}-py${PYTHON_VER}"

echo "BUILD_IMAGE: $BUILD_IMAGE"
echo "BUILD_TAG: $BUILD_TAG"
echo "DOCKERFILE: $DOCKERFILE"
echo "TARGET_STAGE: $TARGET_STAGE"
echo "BUILD_ARGS: $BUILD_ARGS"

# docker build \
#   --pull \
#   -t ${BUILD_IMAGE}:${BUILD_TAG} \
#   --target ${TARGET_STAGE}
#   ${BUILD_ARGS} \
#   -f generated-dockerfiles/${DOCKERFILE} \
#   context/

# docker images ${BUILD_IMAGE}:${BUILD_TAG}
