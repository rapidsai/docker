#!/bin/bash

set -euo pipefail

yq -o json matrix.yaml | jq -c 'include "ci/compute-mx"; compute_mx(.)'
