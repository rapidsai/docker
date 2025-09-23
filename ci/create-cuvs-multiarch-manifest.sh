#!/bin/bash
# Copyright (c) 2025, NVIDIA CORPORATION.

set -eEuo pipefail

common_path="$(dirname "$(realpath "$0")")/common.sh"
# shellcheck source=common.sh
source "$common_path"

cuvs_bench_source_tags=()
# cuvs_bench_datasets_source_tags=()
cuvs_bench_cpu_source_tags=()

# Define tag arrays for different images
cuvs_bench_tag="${CUVS_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
# cuvs_bench_datasets_tag="${CUVS_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
cuvs_bench_cpu_tag="${CUVS_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-py${PYTHON_VER}"

# Check if all source tags exist and add to source tags array
for arch in $(echo "${ARCHES}" | jq .[] -r); do
    full_cuvs_bench_tag="${cuvs_bench_tag}-${arch}"
    # full_cuvs_bench_datasets_tag="${cuvs_bench_datasets_tag}-${arch}"
    full_cuvs_bench_cpu_tag="${cuvs_bench_cpu_tag}-${arch}"

    check_tag_exists "$CUVS_BENCH_IMAGE_REPO" "$full_cuvs_bench_tag"
    cuvs_bench_source_tags+=("${org}/${CUVS_BENCH_IMAGE_REPO}:$full_cuvs_bench_tag")

    # check_tag_exists "$CUVS_BENCH_DATASETS_IMAGE_REPO" "$full_cuvs_bench_datasets_tag"
    # cuvs_bench_datasets_source_tags+=("${org}/${CUVS_BENCH_DATASETS_IMAGE_REPO}:$full_cuvs_bench_datasets_tag")

    if [ "$CUVS_BENCH_CPU_IMAGE_BUILT" = "true" ]; then
        check_tag_exists "$CUVS_BENCH_CPU_IMAGE_REPO" "$full_cuvs_bench_cpu_tag"
        cuvs_bench_cpu_source_tags+=("${org}/${CUVS_BENCH_CPU_IMAGE_REPO}:$full_cuvs_bench_cpu_tag")
    fi
done

docker manifest create "${org}/${CUVS_BENCH_IMAGE_REPO}:${cuvs_bench_tag}" "${cuvs_bench_source_tags[@]}"
docker manifest push "${org}/${CUVS_BENCH_IMAGE_REPO}:${cuvs_bench_tag}"

# this and everything above that it uses can be uncommented once the issues with cuVS datasets are fixed
# ref: https://github.com/rapidsai/docker/issues/724
# docker manifest create "${org}/${CUVS_BENCH_DATASETS_IMAGE_REPO}:${cuvs_bench_datasets_tag}" "${cuvs_bench_datasets_source_tags[@]}"
# docker manifest push "${org}/${CUVS_BENCH_DATASETS_IMAGE_REPO}:${cuvs_bench_datasets_tag}"

if [ "$CUVS_BENCH_CPU_IMAGE_BUILT" = "true" ]; then
    docker manifest create "${org}/${CUVS_BENCH_CPU_IMAGE_REPO}:${cuvs_bench_cpu_tag}" "${cuvs_bench_cpu_source_tags[@]}"
    docker manifest push "${org}/${CUVS_BENCH_CPU_IMAGE_REPO}:${cuvs_bench_cpu_tag}"
fi

# If CUDA 12.9 or 13.0, retag images as cuda12 or cuda13
if [[ "$CUDA_TAG" == "12.9" || "$CUDA_TAG" == "13.0" ]]; then
    major_version=${CUDA_TAG%.*}
    echo "Retagging cuda${CUDA_TAG} images as cuda${major_version}..."

    cuvs_bench_tag_cuda_major="${CUVS_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${major_version}-py${PYTHON_VER}"
    docker manifest create "${org}/${CUVS_BENCH_IMAGE_REPO}:${cuvs_bench_tag_cuda_major}" "${cuvs_bench_source_tags[@]}"
    docker manifest push "${org}/${CUVS_BENCH_IMAGE_REPO}:${cuvs_bench_tag_cuda_major}"
fi
