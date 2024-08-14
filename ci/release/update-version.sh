#!/bin/bash

## Usage
# bash update-version.sh <new_version>


# Format is YY.MM.PP - no leading 'v' or trailing 'a'
NEXT_FULL_TAG=$1

# Get current version
CURRENT_TAG=$(git tag --merged HEAD | grep -xE '^v.*' | sort --version-sort | tail -n 1 | tr -d 'v')
CURRENT_MAJOR=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[1]}')
CURRENT_MINOR=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[2]}')
CURRENT_PATCH=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[3]}')
CURRENT_SHORT_TAG=${CURRENT_MAJOR}.${CURRENT_MINOR}

# Get <major>.<minor> for next version
NEXT_MAJOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[1]}')
NEXT_MINOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[2]}')
NEXT_SHORT_TAG=${NEXT_MAJOR}.${NEXT_MINOR}

echo "Preparing release $CURRENT_TAG => $NEXT_FULL_TAG"

# Inplace sed replace; workaround for Linux and Mac
function sed_runner() {
    sed -i.bak ''"$1"'' $2 && rm -f ${2}.bak
}

for FILE in $(find . -name Dockerfile); do
  sed_runner "s/ARG RAPIDS_VER=.*/ARG RAPIDS_VER=${NEXT_SHORT_TAG}/g" "${FILE}"
done

sed_runner "s/com\.nvidia\.workbench\.image-version=.*/com.nvidia.workbench.image-version=\"${NEXT_FULL_TAG}\"/g" Dockerfile

# CI files
for FILE in .github/workflows/*.yml; do
  sed_runner "/shared-workflows/ s/@.*/@branch-${NEXT_SHORT_TAG}/g" "${FILE}"
done

sed_runner "s/v[[:digit:]]\+\.[[:digit:]]\+/v${NEXT_SHORT_TAG}/g" dockerhub-readme.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+-cuda/${NEXT_SHORT_TAG}-cuda/g" dockerhub-readme.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-cuda/${NEXT_SHORT_TAG}a-cuda/g" dockerhub-readme.md

sed_runner "s/v[[:digit:]]\+\.[[:digit:]]\+/v${NEXT_SHORT_TAG}/g" raft-ann-bench/README.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+-cuda/${NEXT_SHORT_TAG}-cuda/g" raft-ann-bench/README.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-py/${NEXT_SHORT_TAG}a-py/g" raft-ann-bench/README.md
sed_runner "s/[[:digit:]]\+\.[[:digit:]]\+a-cuda/${NEXT_SHORT_TAG}a-cuda/g" raft-ann-bench/README.md
