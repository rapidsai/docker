#!/bin/bash

set -euo pipefail

yq -o json axis.yaml | jq -c 'include "ci/compute-mx"; compute_mx(.)'
