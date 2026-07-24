#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -eEuo pipefail

: "${IMAGE_REFERENCE:?Set IMAGE_REFERENCE to the pushed image tag}"
: "${IMAGE_DIGEST:?Set IMAGE_DIGEST from docker/build-push-action output}"
: "${IMAGE_KIND:?Set IMAGE_KIND to base or notebooks}"
: "${IMAGE_PLATFORM:?Set IMAGE_PLATFORM to linux/architecture}"
: "${PROVENANCE_OUTPUT_DIR:?Set PROVENANCE_OUTPUT_DIR from export-image-provenance.sh}"
: "${RAPIDS_VER:?Set RAPIDS_VER}"
: "${CUDA_VER:?Set CUDA_VER}"
: "${PYTHON_VER:?Set PYTHON_VER}"

normalize_registry_reference() {
    local reference="$1"
    local first_component="${reference%%/*}"
    if [[ $first_component != *.* && $first_component != *:* && $first_component != "localhost" ]]; then
        reference="docker.io/${reference}"
    fi
    printf '%s\n' "$reference"
}

manifest_path="$PROVENANCE_OUTPUT_DIR/image-provenance.json"
workflow_run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
registry_reference="$(normalize_registry_reference "$IMAGE_REFERENCE")"

generator_args=()
while IFS= read -r argument; do
    [[ -z "$argument" ]] && continue
    generator_args+=(--build-arg "$argument")
done <<<"${DOCKER_BUILD_ARGS:-}"

python3 ci/image_provenance_manifest.py \
    --output "$manifest_path" \
    --image-reference "$IMAGE_REFERENCE" \
    --image-digest "$IMAGE_DIGEST" \
    --image-kind "$IMAGE_KIND" \
    --rapids-version "$RAPIDS_VER" \
    --cuda-version "$CUDA_VER" \
    --python-version "$PYTHON_VER" \
    --platform "$IMAGE_PLATFORM" \
    --source-repository "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}" \
    --source-commit "$GITHUB_SHA" \
    --workflow-ref "${GITHUB_WORKFLOW_REF:-$GITHUB_WORKFLOW}" \
    --workflow-run-url "$workflow_run_url" \
    --conda-meta-dir "$PROVENANCE_OUTPUT_DIR/conda-meta" \
    "${generator_args[@]}"

attached_manifest="$PROVENANCE_OUTPUT_DIR/attached-image-provenance.json"
oras attach \
    --artifact-type application/vnd.rapids.image.provenance.v1+json \
    --disable-path-validation \
    --export-manifest "$attached_manifest" \
    "${registry_reference%@*}@${IMAGE_DIGEST}" \
    "$manifest_path:application/vnd.rapids.image.provenance.v1+json"

artifact_digest="sha256:$(sha256sum "$attached_manifest" | awk '{print $1}')"
cosign sign --yes "${registry_reference%@*}@${artifact_digest}"
