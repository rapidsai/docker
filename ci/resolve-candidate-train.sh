#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

: "${TRAIN_SHA256:?Run-bound train digest is required}"
: "${SOURCE_SHA:?Frozen source SHA is required}"
if [[ ! "${TRAIN_SHA256}" =~ ^[a-f0-9]{64}$ ]] ||
   [[ "$(git rev-parse HEAD)" != "${SOURCE_SHA}" ]] ||
   [[ "${SOURCE_SHA}" != "${GITHUB_SHA}" ]] ||
   [[ "${SOURCE_BRANCH}" != "${GITHUB_REF_NAME}" ]] ||
   [[ "${GITHUB_REF_NAME}" != release-test-* ]] ||
   [[ ! "${BUILD_DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo 'Candidate source must match the dispatched test branch and commit' >&2
  exit 1
fi
mkdir -p .candidate-state
aws s3 cp "s3://rapids-release-candidates/train-state/${TRAIN_SHA256}/release-train.json" .candidate-state/train.json
actual_digest=$(jq -cSj 'del(.train_sha256)' .candidate-state/train.json | sha256sum | awk '{print $1}')
if [[ "${actual_digest}" != "${TRAIN_SHA256}" ]]; then
  echo 'Stored train digest does not match the controller binding' >&2
  exit 1
fi
jq -e --arg sha "${SOURCE_SHA}" '
  .source_revisions.docker == $sha and
  any(.release_units[]; .id == "container:rapids-docker" and .source_revision == $sha)
' .candidate-state/train.json > /dev/null
version=$(jq -r '.version_contract.package_versions.container' .candidate-state/train.json)
source_version=$(rg -m1 '^ARG RAPIDS_VER=' Dockerfile | cut -d= -f2)
if [[ "${source_version}" != "${version}" ]]; then
  echo 'Dockerfile RAPIDS version does not match the frozen train container version' >&2
  exit 1
fi
export RAPIDS_RELEASE_CANDIDATE_TRAIN_FILE="${PWD}/.candidate-state/train.json"
python3 ci/candidate_containers.py matrix
echo "version=${version}" >> "${GITHUB_OUTPUT}"
