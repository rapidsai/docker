#!/usr/bin/env bash

# Clones repos with notebooks & compiles notebook test dependencies
# Requires environment variables:
#    RAPIDS_BRANCH
#    CUDA_VER
#    PYTHON_VER

set -euo pipefail

NOTEBOOK_REPOS=(cudf cuml cugraph cuspatial)

mkdir -p /notebooks /dependencies
for REPO in "${NOTEBOOK_REPOS[@]}"; do
    echo "Cloning $REPO..."
    git clone -b "${RAPIDS_BRANCH}" --depth 1 --single-branch "https://github.com/rapidsai/$REPO" "$REPO"
    cp -rL "$REPO"/notebooks /notebooks/"$REPO"
    if [ -f "$REPO/dependencies.yaml" ] && yq -e '.files.test_notebooks' "$REPO/dependencies.yaml" > /dev/null; then
        echo "Running dfg on $REPO"
        rapids-dependency-file-generator \
            --config "$REPO/dependencies.yaml" \
            --file_key test_notebooks \
            --matrix "cuda=${CUDA_VER%.*};arch=$(arch);py=${PYTHON_VER}" \
            --output conda > "/dependencies/${REPO}_notebooks_tests_dependencies.yaml"; \
    fi
done

pushd "/dependencies"
conda-merge ./*.yaml > /test_notebooks_dependencies.yaml
