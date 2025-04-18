#!/bin/bash
# Copyright (c) 2023-2025, NVIDIA CORPORATION.

set -euo pipefail

yq -o json matrix.yaml | jq -c 'include "ci/compute-matrix"; compute_matrix(.)'
