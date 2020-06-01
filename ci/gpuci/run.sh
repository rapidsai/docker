#!/bin/bash
set -e

# Overwrite HOME to WORKSPACE
export HOME=$WORKSPACE

# Set BUILD_IMAGE (the destination) based on RAPIDS_CHANNEL
export BUILD_IMAGE="rapidsai/${RAPIDS_CHANNEL}"

# Install gpuCI tools
curl -s https://raw.githubusercontent.com/rapidsai/gpuci-tools/master/install.sh | bash
source ~/.bashrc
cd ~

# Show env
gpuci_logger "Exposing current environment..."
env

# Login to docker
gpuci_logger "Logging into Docker..."
echo $DH_TOKEN | docker login --username $DH_USER --password-stdin

# Install Jinja deps
gpuci_logger "Install Jinja and PyYAML..."
python3.7 -m pip install --user Jinja2 PyYAML
python3.7 --version

# Generate dockerfiles
gpuci_logger "Generating dockerfiles..."
python3.7 generate_dockerfiles.py

# Select dockerfile based on matrix var
if (echo ${LINUX_VERSION} | grep -i ubuntu); then
    DOCKERFILE=ubuntu18.04-${IMAGE_TYPE}.Dockerfile
else
    DOCKERFILE=centos7-${IMAGE_TYPE}.Dockerfile
fi

# Debug output selected dockerfile
gpuci_logger ">>>> BEGIN Dockerfile <<<<"
cat build/${DOCKERFILE}
gpuci_logger ">>>> END Dockerfile <<<<"

# Get build info ready
gpuci_logger "Preparing to build..."
BUILD_TAG="${CUDA_VER}-${IMAGE_TYPE}-${LINUX_VER}"
BUILD_ARGS="--squash --build-arg FROM_IMAGE=$FROM_IMAGE --build-arg CUDA_VER=$CUDA_VER --build-arg IMAGE_TYPE=$IMAGE_TYPE --build-arg LINUX_VER=$LINUX_VER"
# Check if PYTHON_VER is set
if [ -z "$PYTHON_VER" ] ; then
  gpuci_logger "PYTHON_VER is not set, skipping..."
else
  gpuci_logger "PYTHON_VER is set to '$PYTHON_VER', adding to build args/tag..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg PYTHON_VER=${PYTHON_VER}"
  BUILD_TAG="${BUILD_TAG}-py${PYTHON_VER}"
fi
# Check if DRIVER_VER is set
if [ -z "$DRIVER_VER" ] ; then
  gpuci_logger "DRIVER_VER is not set, skipping..."
else
  gpuci_logger "DRIVER_VER is set to '$DRIVER_VER', adding to build args..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg DRIVER_VER=${DRIVER_VER}"
fi
# Check if RAPIDS_VER is set
if [ -z "$RAPIDS_VER" ] ; then
  gpuci_logger "RAPIDS_VER is not set, skipping..."
else
  gpuci_logger "RAPIDS_VER is set to '$RAPIDS_VER', adding to build args..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg RAPIDS_VER=${RAPIDS_VER}"
  BUILD_TAG="${RAPIDS_VER}-${BUILD_TAG}" #pre-prend version number
fi
# Check if RAPIDS_CHANNEL is set
if [ -z "$RAPIDS_CHANNEL" ] ; then
  gpuci_logger "RAPIDS_CHANNEL is not set, skipping..."
else
  gpuci_logger "RAPIDS_CHANNEL is set to '$RAPIDS_CHANNEL', adding to build args..."
  BUILD_ARGS="${BUILD_ARGS} --build-arg RAPIDS_CHANNEL=${RAPIDS_CHANNEL}"
fi

# Ouput build config
gpuci_logger "Build config info..."
echo "Build image and tag: ${BUILD_IMAGE}:${BUILD_TAG}"
echo "Build args: ${BUILD_ARGS}"
echo "Docker build command:"
echo "docker build --no-cache --pull -t ${BUILD_IMAGE}:${BUILD_TAG} ${BUILD_ARGS} -f build/${DOCKERFILE} context/"

# Build image
gpuci_logger "Starting build..."
#docker build --no-cache --pull -t ${BUILD_IMAGE}:${BUILD_TAG} ${BUILD_ARGS} -f build/${DOCKERFILE} context/

# List image info
#docker images ${BUILD_IMAGE}:${BUILD_TAG}

# Upload image
gpuci_logger "Starting upload..."
GPUCI_RETRY_MAX=5
GPUCI_RETRY_SLEEP=120
#gpuci_retry docker push ${BUILD_IMAGE}:${BUILD_TAG}
