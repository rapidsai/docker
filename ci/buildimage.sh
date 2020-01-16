#!/bin/bash
set +e

# Builds the Docker image specified in $1 and pushes it to DockerHub

echo ""
echo ">>>> BEGIN $0 <<<<"
cat $0
echo ">>>> END $0 <<<<"
echo ""

THISDIR=$(cd $(dirname $0); pwd)
RETRY=${THISDIR}/retry.sh
RAPIDSDEVTOOL=${THISDIR}/../rapidsdevtool.sh
IMAGE_TYPE=$1

# Assumes https://gpuci.gpuopenanalytics.com/ jenkins environment,
# described here: https://gpuci.gpuopenanalytics.com/env-vars.html
# as well as several other env vars defined in the calling job

# FIXME: should these be parameters (some optional) to the script instead?
if [[ ${IMAGE_TYPE} == "" ]]; then echo "must specify a valid image type"; exit 1; fi
if [[ ${VERSION} == "" ]]; then echo "VERSION is undefined"; exit 1; fi
if [[ ${CUDA_VERSION} == "" ]]; then echo "CUDA_VERSION is undefined"; exit 1; fi
if [[ ${LINUX_VERSION} == "" ]]; then echo "LINUX_VERSION is undefined"; exit 1; fi
if [[ ${PYTHON_VERSION} == "" ]]; then echo "PYTHON_VERSION is undefined"; exit 1; fi
if [[ ${CC_VERSION} == "" ]]; then echo "CC_VERSION is undefined"; exit 1; fi
if [[ ${PARALLEL_LEVEL} == "" ]]; then echo "PARALLEL_LEVEL is undefined"; exit 1; fi
if [[ ${TARGET_DOCKER_REPO} == "" ]]; then echo "TARGET_DOCKER_REPO is undefined"; exit 1; fi

TAG=${VERSION}-cuda${CUDA_VERSION}-devel-${LINUX_VERSION}-py${PYTHON_VERSION}

BUILD_ARGS=--build-arg CUDA_VERSION="$CUDA_VERSION" --build-arg LINUX_VERSION="$LINUX_VERSION" --build-arg CXX_VERSION="$CC_VERSION" --build-arg CC_VERSION="$CC_VERSION" --build-arg PYTHON_VERSION="$PYTHON_VERSION" --build-arg PARALLEL_LEVEL="$PARALLEL_LEVEL"

# create build context - Dockerfiles assume a "rapids" dir with specific content
mkdir -p rapids
${RAPIDSDEVTOOL} genCloneScript -o ./rapids/clone.sh
${RAPIDSDEVTOOL} genBuildScript -o ./rapids/build.sh
echo ""
echo ">>>> BEGIN rapids dir contents <<<<"
ls rapids
echo ">>>> END rapids dir contents <<<<"
echo ""

# Generate the Dockerfile
${RAPIDSDEVTOOL} genDockerfile -t ${LINUX_VERSION}-${IMAGE_TYPE}
echo ""
echo ">>>> BEGIN Dockerfile <<<<"
cat Dockerfile.${LINUX_VERSION}-${IMAGE_TYPE}
echo ">>>> END Dockerfile <<<<"
echo ""

# Build the Docker image w/out caching, retry with caching if failed
docker build --no-cache --pull -t ${TARGET_DOCKER_REPO}:${TAG} --squash ${BUILD_ARGS}
EXITCODE=$?
if (( ${EXITCODE} != 0 )); then
    ${RETRY} docker build -t ${TARGET_DOCKER_REPO}:${TAG} --squash ${BUILD_ARGS}
    EXITCODE=$?
    if (( ${EXITCODE} != 0 )); then
        exit ${EXITCODE}
    fi
fi

# Push - assume "docker login"/logout, etc. are being called outside this script
# if necessary
${RETRY} docker push ${TARGET_DOCKER_REPO}:${TAG}
