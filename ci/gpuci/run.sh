#!/bin/bash
set -e

# Overwrite HOME to WORKSPACE
export HOME=$WORKSPACE

# Install gpuCI tools
curl -s https://raw.githubusercontent.com/rapidsai/gpuci-tools/main/install.sh | bash
source ~/.bashrc
cd ~

# Show env
gpuci_logger "Exposing current environment..."
env

# Login to docker
gpuci_logger "Logging into Docker..."
echo $DH_TOKEN | docker login --username $DH_USER --password-stdin

# Select dockerfile based on matrix var
if [ "${LINUX_VER}" == "ubuntu16.04" ]; then
  # ubuntu16.04 uses ubuntu18.04's Dockerfile
  DOCKERFILE="ubuntu18.04-${IMAGE_TYPE}.Dockerfile"
else
  # ubuntu18.04 & centos7 use their variables to select the Dockerfile
  DOCKERFILE="${LINUX_VER}-${IMAGE_TYPE}.Dockerfile"
fi
gpuci_logger "Using Dockerfile: generated-dockerfiles/${DOCKERFILE}"

# Debug output selected dockerfile
gpuci_logger ">>>> BEGIN Dockerfile <<<<"
cat generated-dockerfiles/${DOCKERFILE}
gpuci_logger ">>>> END Dockerfile <<<<"

# Get build info ready
gpuci_logger "Preparing build config..."
BUILD_TAG="cuda${CUDA_VER}-${IMAGE_TYPE}-${LINUX_VER}"
BUILD_ARGS="--squash --build-arg FROM_IMAGE=$FROM_IMAGE --build-arg CUDA_VER=$CUDA_VER --build-arg IMAGE_TYPE=$IMAGE_TYPE --build-arg LINUX_VER=$LINUX_VER"
# Check if PYTHON_VER is set
if [ -z "$PYTHON_VER" ] ; then
  echo "PYTHON_VER is not set, skipping..."
else
  echo "PYTHON_VER is set to '$PYTHON_VER', adding to build args/tag..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg PYTHON_VER=${PYTHON_VER}"
  BUILD_TAG="${BUILD_TAG}-py${PYTHON_VER}"
fi
# Check if RAPIDS_VER is set
if [ -z "$RAPIDS_VER" ] ; then
  echo "RAPIDS_VER is not set, skipping..."
else
  echo "RAPIDS_VER is set to '$RAPIDS_VER', adding to build args..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg RAPIDS_VER=${RAPIDS_VER}"
  BUILD_TAG="${RAPIDS_VER}-${BUILD_TAG}" #pre-prend version number
fi
# Check if RAPIDS_CHANNEL is set
if [ -z "$RAPIDS_CHANNEL" ] ; then
  echo "RAPIDS_CHANNEL is not set, skipping..."
else
  echo "RAPIDS_CHANNEL is set to '$RAPIDS_CHANNEL', adding to build args..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg RAPIDS_CHANNEL=${RAPIDS_CHANNEL}"
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

# Upload image
gpuci_logger "Starting upload..."
GPUCI_RETRY_MAX=5
GPUCI_RETRY_SLEEP=120
gpuci_retry docker push ${BUILD_IMAGE}:${BUILD_TAG}
