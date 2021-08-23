#!/bin/bash

env
echo "end env"
echo ""

IMAGE_STAGES='[
  "rapidsai-core",
  "rapidsai",
  "rapidsai-clx"
]'
FINAL_IMAGE_STAGE=$(echo "$IMAGE_STAGES"| jq '.[-1]')

ALL_BUILD_ARGS=$(
  jq -n \
    '[
      "--no-cache",
      "--squash",
      "--build-arg CUDA_VER=" + $ENV.CUDA_VER,
      "--build-arg LINUX_VER=" + $ENV.LINUX_VER,
      "--build-arg PYTHON_VER=" + $ENV.PYTHON_VER,
      "--build-arg RAPIDS_VER=" + $ENV.RAPIDS_VER
    ]'
)

# Handle extra build arguments
if [ "${CHANGE_TARGET}" = "main" ]; then
  ALL_BUILD_ARGS=$(echo $ALL_BUILD_ARGS | jq '. + ["--build-arg BUILD_BRANCH=main"]')
fi
if [ "${IMAGE_TYPE}" = "devel" ]; then
  ALL_BUILD_ARGS=$(echo $ALL_BUILD_ARGS | jq '. + ["--build-arg UCX_PY_VER=" + $ENV.UCX_PY_VER]')
fi

# Returns image name with appropriate suffixes
function get_img_name() {
  local STAGE_NAME="$1"

  if [ "${IMAGE_TYPE}" = "devel" ]; then
    STAGE_NAME+="-dev"
  fi

  if [ "${CHANGE_TARGET}" != "main" ]; then
    STAGE_NAME+="-nightly"
  fi

  echo "rapidsai/${STAGE_NAME}"
}


DOCKERFILE="${LINUX_VER}-${IMAGE_TYPE}.Dockerfile"
BUILD_TAG="${RAPIDS_VER}-cuda${CUDA_VER}-${IMAGE_TYPE}-${LINUX_VER}-py${PYTHON_VER}"

echo "BUILD_TAG: $BUILD_TAG"
echo "DOCKERFILE: $DOCKERFILE"


# Build entire Dockerfile (i.e. all stages)
BUILD_ARGS=$(echo $ALL_BUILD_ARGS | jq -r 'join(" ")')
set -x
echo "docker build \
  --pull \
  -t "$(get_img_name $FINAL_IMAGE_STAGE):${BUILD_TAG}" \
  ${BUILD_ARGS} \
  -f generated-dockerfiles/${DOCKERFILE} \
  context/"
set +x


# Build/Tag intermediate stages

for STAGE in $(echo "$IMAGE_STAGES" | jq -r '.[0:-1][]'); do
  echo "$(get_img_name $STAGE)"

  # Remove "--no-cache" build argument since all stages were built without cache immediately prior
  BUILD_ARGS=$(echo $ALL_BUILD_ARGS | jq -r '.[1:] | join(" ")')
  set -x
  echo "docker build \
    --pull \
    -t "$(get_img_name $STAGE):${BUILD_TAG}" \
    --target ${STAGE}
    ${BUILD_ARGS} \
    -f generated-dockerfiles/${DOCKERFILE} \
    context/"
  set +x
done



# docker images ${BUILD_IMAGE}:${BUILD_TAG}
