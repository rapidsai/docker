#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -eEuo pipefail

: "${IMAGE_REFERENCE:?Set IMAGE_REFERENCE to the multiarch image tag}"
: "${IMAGE_KIND:?Set IMAGE_KIND to base or notebooks}"
: "${RAPIDS_VER:?Set RAPIDS_VER}"
: "${CUDA_VER:?Set CUDA_VER}"
: "${PYTHON_VER:?Set PYTHON_VER}"
: "${PLATFORM_REFERENCES:?Set PLATFORM_REFERENCES as platform=tag lines}"

normalize_registry_reference() {
    local reference="$1"
    local first_component="${reference%%/*}"
    if [[ $first_component != *.* && $first_component != *:* && $first_component != "localhost" ]]; then
        reference="docker.io/${reference}"
    fi
    printf '%s\n' "$reference"
}

output_dir="${RUNNER_TEMP:-/tmp}/image-provenance-index-${IMAGE_KIND}"
manifest_path="$output_dir/image-provenance-index.json"
workflow_run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
registry_reference="$(normalize_registry_reference "$IMAGE_REFERENCE")"
mkdir -p "$output_dir"

image_digest="$(oras manifest fetch --descriptor "$registry_reference" | jq -r '.digest')"
platform_args=()
while IFS='=' read -r platform reference; do
    [[ -z "$platform" ]] && continue
    platform_reference="$(normalize_registry_reference "$reference")"
    digest="$(oras manifest fetch --descriptor "$platform_reference" | jq -r '.digest')"
    platform_args+=(--platform-manifest "${platform}|${platform_reference}|${digest}")
done <<<"$PLATFORM_REFERENCES"

python3 ci/image_provenance_manifest.py \
    --output "$manifest_path" \
    --image-reference "$IMAGE_REFERENCE" \
    --image-digest "$image_digest" \
    --image-kind "$IMAGE_KIND" \
    --rapids-version "$RAPIDS_VER" \
    --cuda-version "$CUDA_VER" \
    --python-version "$PYTHON_VER" \
    --platform multiarch \
    --source-repository "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}" \
    --source-commit "$GITHUB_SHA" \
    --workflow-ref "${GITHUB_WORKFLOW_REF:-$GITHUB_WORKFLOW}" \
    --workflow-run-url "$workflow_run_url" \
    --build-arg "RAPIDS_VER=$RAPIDS_VER" \
    --build-arg "CUDA_VER=$CUDA_VER" \
    --build-arg "PYTHON_VER=$PYTHON_VER" \
    "${platform_args[@]}"

attached_manifest="$output_dir/attached-image-provenance-index.json"
(
    cd "$output_dir"
    oras attach \
        --artifact-type application/vnd.rapids.image.provenance.index.v1+json \
        --export-manifest "$attached_manifest" \
        "${registry_reference%@*}@${image_digest}" \
        "image-provenance-index.json:application/vnd.rapids.image.provenance.index.v1+json"
)

artifact_digest="sha256:$(sha256sum "$attached_manifest" | awk '{print $1}')"
cosign sign --yes "${registry_reference%@*}@${artifact_digest}"
