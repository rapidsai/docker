#!/bin/bash
# Copyright (c) 2023-2025, NVIDIA CORPORATION.

## Usage
# Primary interface:   bash update-version.sh <new_version> [--run-context=main|release]
# Fallback interface:  [RAPIDS_RUN_CONTEXT=main|release] bash update-version.sh <new_version>
# CLI arguments take precedence over environment variables
# Defaults to main when no run-context is specified

set -euo pipefail

# Verify we're running from the repository root
if [[ ! -d ".git" ]]; then
    echo "Error: This script must be run from the repository root directory."
    echo "Expected to find: .git/"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Parse command line arguments
CLI_RUN_CONTEXT=""
VERSION_ARG=""

for arg in "$@"; do
    case $arg in
        --run-context=*)
            CLI_RUN_CONTEXT="${arg#*=}"
            shift
            ;;
        *)
            if [[ -z "$VERSION_ARG" ]]; then
                VERSION_ARG="$arg"
            fi
            ;;
    esac
done

# Format is YY.MM.PP - no leading 'v' or trailing 'a'
NEXT_FULL_TAG="$VERSION_ARG"

# Determine RUN_CONTEXT with CLI precedence over environment variable, defaulting to main
if [[ -n "$CLI_RUN_CONTEXT" ]]; then
    RUN_CONTEXT="$CLI_RUN_CONTEXT"
    echo "Using run-context from CLI: $RUN_CONTEXT"
elif [[ -n "${RAPIDS_RUN_CONTEXT}" ]]; then
    RUN_CONTEXT="$RAPIDS_RUN_CONTEXT"
    echo "Using run-context from environment: $RUN_CONTEXT"
else
    RUN_CONTEXT="main"
    echo "No run-context provided, defaulting to: $RUN_CONTEXT"
fi

# Validate RUN_CONTEXT value
if [[ "${RUN_CONTEXT}" != "main" && "${RUN_CONTEXT}" != "release" ]]; then
    echo "Error: Invalid run-context value '${RUN_CONTEXT}'"
    echo "Valid values: main, release"
    exit 1
fi

# Validate version argument
if [[ -z "$NEXT_FULL_TAG" ]]; then
    echo "Error: Version argument is required"
    echo "Usage: $0 <new_version> [--run-context=<context>]"
    echo "   or: [RAPIDS_RUN_CONTEXT=<context>] $0 <new_version>"
    echo "Note: Defaults to main when run-context is not specified"
    exit 1
fi

# Get current version
CURRENT_TAG=$(git tag --merged HEAD | grep -xE '^v.*' | sort --version-sort | tail -n 1 | tr -d 'v')

# Get <major>.<minor> for next version
NEXT_MAJOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[1]}')
NEXT_MINOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[2]}')
NEXT_SHORT_TAG=${NEXT_MAJOR}.${NEXT_MINOR}

# Set branch references based on RUN_CONTEXT
if [[ "${RUN_CONTEXT}" == "main" ]]; then
    RAPIDS_BRANCH_NAME="main"
    WORKFLOW_BRANCH_REF="main"
    echo "Preparing development branch update $CURRENT_TAG => $NEXT_FULL_TAG (targeting main branch)"
elif [[ "${RUN_CONTEXT}" == "release" ]]; then
    RAPIDS_BRANCH_NAME="release/${NEXT_SHORT_TAG}"
    WORKFLOW_BRANCH_REF="release/${NEXT_SHORT_TAG}"
    echo "Preparing release branch update $CURRENT_TAG => $NEXT_FULL_TAG (targeting release/${NEXT_SHORT_TAG} branch)"
fi

# Inplace sed replace; workaround for Linux and Mac
function sed_runner() {
    sed -i.bak ''"$1"'' $2 && rm -f ${2}.bak
}

find . -name Dockerfile -print0 | while IFS= read -r -d '' FILE; do
  sed_runner "s/ARG RAPIDS_VER=.*/ARG RAPIDS_VER=${NEXT_SHORT_TAG}/g" "${FILE}"
done

sed_runner "s/com\.nvidia\.workbench\.image-version=.*/com.nvidia.workbench.image-version=\"${NEXT_FULL_TAG}\"/g" Dockerfile

# Dockerfile RAPIDS_BRANCH
sed_runner "s|ARG RAPIDS_BRANCH=\"release/[0-9]\+\.[0-9]\+\"|ARG RAPIDS_BRANCH=\"${RAPIDS_BRANCH_NAME}\"|g" Dockerfile
sed_runner "s|ARG RAPIDS_BRANCH=\"main\"|ARG RAPIDS_BRANCH=\"${RAPIDS_BRANCH_NAME}\"|g" Dockerfile

# CI files
for FILE in .github/workflows/*.yaml .github/workflows/*.yml; do
  sed_runner "/shared-workflows/ s|@.*|@${WORKFLOW_BRANCH_REF}|g" "${FILE}"
done

sed_runner "s/v[[:digit:]]\+\.[[:digit:]]\+/v${NEXT_SHORT_TAG}/g" dockerhub-readme.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+-cuda/${NEXT_SHORT_TAG}-cuda/g" dockerhub-readme.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-cuda/${NEXT_SHORT_TAG}a-cuda/g" dockerhub-readme.md

sed_runner "s/v[[:digit:]]\+\.[[:digit:]]\+/v${NEXT_SHORT_TAG}/g" cuvs-bench/README.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+-cuda/${NEXT_SHORT_TAG}-cuda/g" cuvs-bench/README.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-py/${NEXT_SHORT_TAG}a-py/g" cuvs-bench/README.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-cuda/${NEXT_SHORT_TAG}a-cuda/g" cuvs-bench/README.md

sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-cuda/${NEXT_SHORT_TAG}a-cuda/g" tests/container-canary/README.md
