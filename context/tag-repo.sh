#!/bin/bash
set -e

# conventional prefix used in versioneer config (in setup.cfg)
# by RAPIDS libraries
TAG_PREFIX="v"

# this is the command used to detect tags by versioneer
if ! git describe --tags --dirty --long --match "${TAG_PREFIX}*" > /dev/null 2>&1; then
  GIT_HASH=$(git rev-parse --short HEAD)
  git tag "${TAG_PREFIX}${RAPIDS_VER}.00a0+g${GIT_HASH}"
fi
