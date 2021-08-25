#!/bin/bash
set -e

env
echo ""

IMAGE_STAGES='[
  "rapidsai-core",
  "rapidsai",
  "rapidsai-clx"
]'
FINAL_IMAGE_STAGE=$(echo "$IMAGE_STAGES"| jq -r '.[-1]')

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

# Build Entire Dockerfile (i.e. all stages)
echo ""
echo "Build Dockerfile stage: $FINAL_IMAGE_STAGE"
echo ""

BUILD_ARGS=$(echo $ALL_BUILD_ARGS | jq -r 'join(" ")')
set -x
docker build \
  --pull \
  -t "$(get_img_name $FINAL_IMAGE_STAGE):${BUILD_TAG}" \
  ${BUILD_ARGS} \
  -f generated-dockerfiles/${DOCKERFILE} \
  context/
set +x
docker history --no-trunc "$(get_img_name $FINAL_IMAGE_STAGE):${BUILD_TAG}"
echo ""


# Tag Intermediate Stages
# Remove "--no-cache" build argument since all stages were built without cache immediately prior
BUILD_ARGS=$(echo $ALL_BUILD_ARGS | jq -r '.[1:] | join(" ")')

for STAGE in $(echo "$IMAGE_STAGES" | jq -r '.[0:-1][]'); do
  echo ""
  echo "Build Dockerfile stage: $STAGE"
  echo ""

  set -x
  docker build \
    -t "$(get_img_name $STAGE):${BUILD_TAG}" \
    --target ${STAGE} \
    ${BUILD_ARGS} \
    -f generated-dockerfiles/${DOCKERFILE} \
    context/
  set +x
done

# Show all Docker Image Information
echo ""
echo "Show Docker info"
echo ""
for STAGE in $(echo "$IMAGE_STAGES" | jq -r '.[]'); do
  docker images "$(get_img_name $STAGE):${BUILD_TAG}"
  echo ""
  docker history --no-trunc "$(get_img_name $STAGE):${BUILD_TAG}"
  echo ""
done



