#!/bin/bash
# Copyright (c) 2025, NVIDIA CORPORATION.

set -eEuo pipefail

common_path="$(dirname "$(realpath "$0")")/common.sh"
# shellcheck source=common.sh
source "$common_path"

# Function to retag images with major version tags
retag_major_version() {
    local source_tag="$1"
    local target_tag="$2"
    local image_repo="$3"
    local org="${org}"

    echo "Retagging ${org}/${image_repo}:${source_tag} to ${org}/${image_repo}:${target_tag}"

    # Check if source tag exists
    if ! docker manifest inspect "${org}/${image_repo}:${source_tag}" >/dev/null 2>&1; then
        echo "Warning: Source tag ${org}/${image_repo}:${source_tag} does not exist, skipping retag"
        return 0
    fi

    # Create and push the retagged manifest
    docker manifest create "${org}/${image_repo}:${target_tag}" "${org}/${image_repo}:${source_tag}"
    docker manifest push "${org}/${image_repo}:${target_tag}"

    echo "Successfully retagged ${org}/${image_repo}:${target_tag}"
}

# Determine which images to retag based on CUDA version
if [[ "$CUDA_VER" == "12.9.1" ]]; then
    # Retag CUDA 12.9.1 builds as cuda12
    echo "Retagging CUDA 12.9.1 builds as cuda12..."

    # RAPIDS images
    base_source_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12.9-py${PYTHON_VER}"
    base_target_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12-py${PYTHON_VER}"
    notebooks_source_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12.9-py${PYTHON_VER}"
    notebooks_target_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12-py${PYTHON_VER}"

    retag_major_version "$base_source_tag" "$base_target_tag" "$BASE_IMAGE_REPO"
    retag_major_version "$notebooks_source_tag" "$notebooks_target_tag" "$NOTEBOOKS_IMAGE_REPO"

    # cuVS images
    cuvs_bench_source_tag="${CUVS_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12.9-py${PYTHON_VER}"
    cuvs_bench_target_tag="${CUVS_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12-py${PYTHON_VER}"
    cuvs_bench_datasets_source_tag="${CUVS_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12.9-py${PYTHON_VER}"
    cuvs_bench_datasets_target_tag="${CUVS_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12-py${PYTHON_VER}"

    retag_major_version "$cuvs_bench_source_tag" "$cuvs_bench_target_tag" "$CUVS_BENCH_IMAGE_REPO"
    retag_major_version "$cuvs_bench_datasets_source_tag" "$cuvs_bench_datasets_target_tag" "$CUVS_BENCH_DATASETS_IMAGE_REPO"

    # Only retag CPU image if it was built
    if [[ "$BUILD_CUVS_BENCH_CPU_IMAGE" == "true" ]]; then
        cuvs_bench_cpu_source_tag="${CUVS_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12.9-py${PYTHON_VER}"
        cuvs_bench_cpu_target_tag="${CUVS_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda12-py${PYTHON_VER}"
        retag_major_version "$cuvs_bench_cpu_source_tag" "$cuvs_bench_cpu_target_tag" "$CUVS_BENCH_CPU_IMAGE_REPO"
    fi

elif [[ "$CUDA_VER" == "13.0.0" ]]; then
    # Retag CUDA 13.0.0 builds as cuda13
    echo "Retagging CUDA 13.0.0 builds as cuda13..."

    # RAPIDS images
    base_source_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13.0-py${PYTHON_VER}"
    base_target_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13-py${PYTHON_VER}"
    notebooks_source_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13.0-py${PYTHON_VER}"
    notebooks_target_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13-py${PYTHON_VER}"

    retag_major_version "$base_source_tag" "$base_target_tag" "$BASE_IMAGE_REPO"
    retag_major_version "$notebooks_source_tag" "$notebooks_target_tag" "$NOTEBOOKS_IMAGE_REPO"

    # cuVS images
    cuvs_bench_source_tag="${CUVS_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13.0-py${PYTHON_VER}"
    cuvs_bench_target_tag="${CUVS_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13-py${PYTHON_VER}"
    cuvs_bench_datasets_source_tag="${CUVS_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13.0-py${PYTHON_VER}"
    cuvs_bench_datasets_target_tag="${CUVS_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13-py${PYTHON_VER}"

    retag_major_version "$cuvs_bench_source_tag" "$cuvs_bench_target_tag" "$CUVS_BENCH_IMAGE_REPO"
    retag_major_version "$cuvs_bench_datasets_source_tag" "$cuvs_bench_datasets_target_tag" "$CUVS_BENCH_DATASETS_IMAGE_REPO"

    # Only retag CPU image if it was built
    if [[ "$BUILD_CUVS_BENCH_CPU_IMAGE" == "true" ]]; then
        cuvs_bench_cpu_source_tag="${CUVS_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13.0-py${PYTHON_VER}"
        cuvs_bench_cpu_target_tag="${CUVS_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda13-py${PYTHON_VER}"
        retag_major_version "$cuvs_bench_cpu_source_tag" "$cuvs_bench_cpu_target_tag" "$CUVS_BENCH_CPU_IMAGE_REPO"
    fi

else
    echo "No retagging needed for CUDA version: $CUDA_VER"
fi
