#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

: "${IMAGE_NAME:?Frozen image repository is required}"
: "${IMAGE_TAG:?Frozen image tag is required}"
: "${ARCH:?Image platform is required}"
: "${CONTAINER_VERSION:?Frozen container version is required}"
if [[ ! "${ARCH}" =~ ^(amd64|arm64)$ ]] ||
   [[ ! "${IMAGE_NAME}" =~ ^docker\.io/rapidsai/(base|notebooks|cuvs-bench|cuvs-bench-cpu)$ ]] ||
   [[ ! "${IMAGE_TAG}" =~ ^[0-9]{2}\.[0-9]{2}-(cuda[0-9]+-)?py[0-9.]+-(amd64|arm64)$ ]] ||
   [[ "${IMAGE_TAG}" != "${CONTAINER_VERSION}-"* ]]; then
  echo 'Invalid frozen image identity' >&2
  exit 1
fi
gzip --no-name .release-candidate-artifacts/container/image.tar
mv .release-candidate-artifacts/container/image.tar.gz \
  ".release-candidate-artifacts/container/image-${IMAGE_NAME##*/}-${IMAGE_TAG}.tar.gz"
jq -n --arg name "${IMAGE_NAME}" --arg version "${CONTAINER_VERSION}" \
  --arg build "${IMAGE_TAG}" --arg platform "linux/${ARCH}" \
  '{ecosystem:"container",name:$name,version:$version,build:$build,platform:$platform}' \
  > .release-candidate-artifacts/container/package-identity.json
