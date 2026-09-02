#!/bin/bash
# Copyright (c) 2023-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

set -euo pipefail

matrix="$(yq -o json matrix.yaml)"
for dimension in CUDA PYTHON; do
    variable="MATRIX_${dimension}_VERSIONS"
    if [[ -n ${!variable:-} ]]; then
        key="${dimension}_VER"
        matrix="$(jq --arg key "$key" --argjson values "${!variable}" \
            '.[$key] = $values' <<<"$matrix")"
    fi
done

jq -c 'include "ci/compute-matrix"; compute_matrix(.)' <<<"$matrix"
