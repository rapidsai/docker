#!/bin/bash

set -eEuo pipefail

# Authenticate and retrieve DockerHub token
HUB_TOKEN=$(
curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{\"username\": \"$GPUCIBOT_DOCKERHUB_USER\", \"password\": \"$GPUCIBOT_DOCKERHUB_TOKEN\"}" \
    https://hub.docker.com/v2/users/login/ | jq -r .token \
)
echo "::add-mask::${HUB_TOKEN}"

org="rapidsai"

# Define tag arrays for different images
base_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
notebooks_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_tag="${RAFT_ANN_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_datasets_tag="${RAFT_ANN_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_cpu_tag="${RAFT_ANN_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-py${PYTHON_VER}"

for arch in $(echo "${ARCHES}" | jq .[] -r); do
    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$BASE_IMAGE_REPO/tags/$base_tag-$arch/"

    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$NOTEBOOKS_IMAGE_REPO/tags/$notebooks_tag-$arch/"

    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$RAFT_ANN_BENCH_IMAGE_REPO/tags/$raft_ann_bench_tag-$arch/"

    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$RAFT_ANN_BENCH_DATASETS_IMAGE_REPO/tags/$raft_ann_bench_datasets_tag-$arch/"

    if [ "$RAFT_ANN_BENCH_CPU_IMAGE_BUILT" = "true" ]; then
        curl -i -X DELETE \
            -H "Accept: application/json" \
            -H "Authorization: JWT $HUB_TOKEN" \
            "https://hub.docker.com/v2/repositories/$org/$RAFT_ANN_BENCH_CPU_IMAGE_REPO/tags/$raft_ann_bench_cpu_tag-$arch/"
    fi
done
