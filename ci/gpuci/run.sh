#!/bin/bash
set -e

# Overwrite HOME to WORKSPACE
export HOME="$WORKSPACE"

# Install gpuCI tools
curl -s https://raw.githubusercontent.com/rapidsai/gpuci-tools/main/install.sh | bash
source ~/.bashrc
cd ~

# Show env
gpuci_logger "Exposing current environment..."
env

# Login to docker
gpuci_logger "Logging into Docker..."
echo $DH_TOKEN | docker login --username $DH_USER --password-stdin &> /dev/null

# Select dockerfile based on matrix var
DOCKERFILE="${DOCKER_PREFIX}_${LINUX_VER}-${IMAGE_TYPE}.Dockerfile"
gpuci_logger "Using Dockerfile: generated-dockerfiles/${DOCKERFILE}"

# Debug output selected dockerfile
gpuci_logger ">>>> BEGIN Dockerfile <<<<"
cat generated-dockerfiles/${DOCKERFILE}
gpuci_logger ">>>> END Dockerfile <<<<"

# Get build info ready
gpuci_logger "Preparing build config..."
BUILD_TAG="cuda${CUDA_VER}-${IMAGE_TYPE}-${LINUX_VER}"
# Check if PR build and modify BUILD_IMAGE and BUILD_TAG
if [ ! -z "$PR_ID" ] ; then
  echo "PR_ID is set to '$PR_ID', updating BUILD_IMAGE..."
  BUILD_REPO=`echo $BUILD_IMAGE | tr '/' ' ' | awk '{ print $2 }'`
  BUILD_IMAGE="rapidsaitesting/${BUILD_REPO}-pr${PR_ID}"
  # Check if FROM_IMAGE to see if it is a root build
  if [[ "$FROM_IMAGE" == "gpuci/rapidsai" ]] ; then
    echo ">> No need to update FROM_IMAGE, using external image..."
  else
    echo ">> Need to update FROM_IMAGE to use PR's version for testing..."
    FROM_REPO=`echo $FROM_IMAGE | tr '/' ' ' | awk '{ print $2 }'`
    FROM_IMAGE="rapidsaitesting/${FROM_REPO}-pr${PR_ID}"
  fi
fi
# Setup initial BUILD_ARGS
BUILD_ARGS="--no-cache \
  --squash \
  --build-arg FROM_IMAGE=${FROM_IMAGE} \
  --build-arg CUDA_VER=${CUDA_VER} \
  --build-arg IMAGE_TYPE=${IMAGE_TYPE} \
  --build-arg LINUX_VER=${LINUX_VER} \
  --build-arg UCX_PY_VER=${UCX_PY_VER}"
# Add BUILD_BRANCH arg for 'main' branch only
if [ "${BUILD_BRANCH}" = "main" ]; then
  BUILD_ARGS+=" --build-arg BUILD_BRANCH=${BUILD_BRANCH}"
fi
# Check if PYTHON_VER is set
if [ -z "$PYTHON_VER" ] ; then
  echo "PYTHON_VER is not set, skipping..."
else
  echo "PYTHON_VER is set to '$PYTHON_VER', adding to build args/tag..."
  BUILD_ARGS+=" --build-arg PYTHON_VER=${PYTHON_VER}"
  BUILD_TAG="${BUILD_TAG}-py${PYTHON_VER}"
fi
# Check if RAPIDS_VER is set
if [ -z "$RAPIDS_VER" ] ; then
  echo "RAPIDS_VER is not set, skipping..."
else
  echo "RAPIDS_VER is set to '$RAPIDS_VER', adding to build args..."
  BUILD_ARGS+=" --build-arg RAPIDS_VER=${RAPIDS_VER}"
  BUILD_TAG="${RAPIDS_VER}-${BUILD_TAG}" #pre-prend version number
fi

# Ouput build config
gpuci_logger "Build config info..."
echo "Build image and tag: ${BUILD_IMAGE}:${BUILD_TAG}"
echo "Build args: ${BUILD_ARGS}"
gpuci_logger "Docker build command..."
echo "docker build --pull -t ${BUILD_IMAGE}:${BUILD_TAG} ${BUILD_ARGS} -f generated-dockerfiles/${DOCKERFILE} context/"

# Build image
gpuci_logger "Starting build..."
docker build --pull -t ${BUILD_IMAGE}:${BUILD_TAG} ${BUILD_ARGS} -f generated-dockerfiles/${DOCKERFILE} context/

# List image info
gpuci_logger "Displaying image info..."
docker images ${BUILD_IMAGE}:${BUILD_TAG}

# Check image for default conda packages
gpuci_logger "Checking conda environment for defaults pkgs..."
docker run ${BUILD_IMAGE}:${BUILD_TAG} /bin/bash -c "conda list && if [[ $(conda list | awk '{ print $4 }' | grep conda-forge | wc -l) -ne 0 ]]; then echo 'ERROR: Packages from the default conda channel detected'; exit 1; fi"

# Upload image
gpuci_logger "Starting upload..."
GPUCI_RETRY_MAX=5
GPUCI_RETRY_SLEEP=120
gpuci_retry docker push ${BUILD_IMAGE}:${BUILD_TAG}
