#!/bin/bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

GIT_DESCRIBE_TAG="$(git describe --tags --first-parent --abbrev=0)"
GIT_DESCRIBE_TAG="${GIT_DESCRIBE_TAG#v}"
ALPHA_TAG=""
if [[ $GIT_DESCRIBE_TAG =~ [a-z] ]]; then
    echo "Most recent tag is an alpha tag"
    ALPHA_TAG="a"
fi

RAPIDS_VER="${GIT_DESCRIBE_TAG%.*}"
RAPIDS_NOTEBOOKS_REF="main"
RELEASE_REF=""
if [[ ${GITHUB_BASE_REF:-} =~ ^release/[0-9]{2}\.[0-9]{2}$ ]]; then
    RELEASE_REF="${GITHUB_BASE_REF}"
elif [[ ${GITHUB_REF_NAME:-} =~ ^release/[0-9]{2}\.[0-9]{2}$ ]]; then
    RELEASE_REF="${GITHUB_REF_NAME}"
fi

if [[ -n $RELEASE_REF ]]; then
    RAPIDS_VER="${RELEASE_REF#release/}"
    RAPIDS_NOTEBOOKS_REF="${RELEASE_REF}"
elif [[ -z $ALPHA_TAG ]]; then
    RAPIDS_NOTEBOOKS_REF="release/${RAPIDS_VER}"
fi

{
    echo "RAPIDS_NOTEBOOKS_REF=${RAPIDS_NOTEBOOKS_REF}"
    echo "RAPIDS_VER=${RAPIDS_VER}"
    echo "ALPHA_TAG=${ALPHA_TAG}"
} | tee -a "${GITHUB_OUTPUT:-/dev/stdout}"
