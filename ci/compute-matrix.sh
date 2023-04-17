#!/bin/bash
# Computes matrix based on "axis.yaml" values.
# Example Usage:
#   ./ci/compute-matrix.sh
set -eu

MATRIX=$(yq -o json '.' axis.yaml | jq -c)
echo "MATRIX=${MATRIX}" | tee --append ${GITHUB_OUTPUT:-/dev/null}