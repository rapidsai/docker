#!/bin/bash
# Copyright (c) 2023-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

set -euo pipefail

matrix="$(yq -o json matrix.yaml)"
if [[ -n ${MATRIX_CUDA_VERSIONS:-} ]]; then
  matrix="$(jq --argjson cuda_versions "$MATRIX_CUDA_VERSIONS" '.CUDA_VER = $cuda_versions' <<<"$matrix")"
fi

jq -c 'include "ci/compute-matrix"; compute_matrix(.)' <<<"$matrix"
