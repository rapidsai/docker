#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -eEuo pipefail

: "${PROVENANCE_TARGET:?Set PROVENANCE_TARGET to a Dockerfile provenance target}"
: "${PROVENANCE_OUTPUT_DIR:?Set PROVENANCE_OUTPUT_DIR for the local exporter}"
: "${DOCKER_BUILD_ARGS:?Set DOCKER_BUILD_ARGS from compute-build-args.sh}"

build_args=()
while IFS= read -r argument; do
    [[ -z "$argument" ]] && continue
    build_args+=(--build-arg "$argument")
done <<<"$DOCKER_BUILD_ARGS"

rm -rf "$PROVENANCE_OUTPUT_DIR"
mkdir -p "$PROVENANCE_OUTPUT_DIR"

docker buildx build \
    --file Dockerfile \
    --target "$PROVENANCE_TARGET" \
    --output "type=local,dest=$PROVENANCE_OUTPUT_DIR" \
    "${build_args[@]}" \
    context

test -d "$PROVENANCE_OUTPUT_DIR/conda-meta"
