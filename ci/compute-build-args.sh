#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2023-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# start with arguments provided by environment variables. Anything with a fallback is only used by
# a subset of images built here.
ARGS="
CPU_ARCH: ${CPU_ARCH:-notset}
CUDA_VER: ${CUDA_VER}
LINUX_DISTRO: ${LINUX_DISTRO:-notset}
LINUX_DISTRO_VER: ${LINUX_DISTRO_VER:-notset}
LINUX_VER: ${LINUX_VER}
PYTHON_VER: ${PYTHON_VER}
RAPIDS_VER: ${RAPIDS_VER}
"
export ARGS

# add in arguments parsed out of 'versions.yaml'
if [ -n "${GITHUB_ACTIONS:-}" ]; then
# on GitHub Actions, create a step output called 'DOCKER_BUILD_ARGS' with this information appended to it.
#
# That can be referenced like:
#
#   - name: Build image
#     uses: docker/build-push-action@v6
#     with:
#       build-args: |
#         ${{ steps.generate-build-args.outputs.DOCKER_BUILD_ARGS }}
#
cat <<EOF > "${GITHUB_OUTPUT:-/dev/stdout}"
DOCKER_BUILD_ARGS<<EOT
$(yq -r '. + env(ARGS) | to_entries | map(.key + "=" + .value) | join(" \n")' versions.yaml)
EOT
EOF
else
  yq -r '. + env(ARGS) | to_entries | map("--build-arg " + .key + "=" + .value) | join(" ")' versions.yaml
fi
