#!/bin/bash
# Copyright (c) 2025, NVIDIA CORPORATION.

set -eEuo pipefail

common_path="$(dirname "$(realpath "$0")")/common.sh"
# shellcheck source=common.sh
source "$common_path"

# Initialize arrays to store source tags for each image
base_source_tags=()
notebooks_source_tags=()

# Define tag arrays for different images
base_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
notebooks_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"

# Check if all source tags exist and add to source tags array
for arch in $(echo "${ARCHES}" | jq .[] -r); do
    full_base_tag="${base_tag}-${arch}"
    full_notebooks_tag="${notebooks_tag}-${arch}"

    check_tag_exists "$BASE_IMAGE_REPO" "$full_base_tag"
    base_source_tags+=("${org}/${BASE_IMAGE_REPO}:$full_base_tag")

    check_tag_exists "$NOTEBOOKS_IMAGE_REPO" "$full_notebooks_tag"
    notebooks_source_tags+=("${org}/${NOTEBOOKS_IMAGE_REPO}:$full_notebooks_tag")
done

# Create and push Docker multi-arch manifests
docker manifest create "${org}/${BASE_IMAGE_REPO}:${base_tag}" "${base_source_tags[@]}"
docker manifest push "${org}/${BASE_IMAGE_REPO}:${base_tag}"

docker manifest create "${org}/${NOTEBOOKS_IMAGE_REPO}:${notebooks_tag}" "${notebooks_source_tags[@]}"
docker manifest push "${org}/${NOTEBOOKS_IMAGE_REPO}:${notebooks_tag}"
