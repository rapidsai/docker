#!/usr/bin/env bash
# Copyright (c) 2023-2025, NVIDIA CORPORATION.

# Clones repos with notebooks & compiles notebook test dependencies
# Requires environment variables:
#    RAPIDS_BRANCH
#    CUDA_VER
#    PYTHON_VER

set -euo pipefail

NOTEBOOK_REPOS=(cudf cuml cugraph)

mkdir -p /notebooks /dependencies
for REPO in "${NOTEBOOK_REPOS[@]}"; do
    echo "Cloning $REPO..."
    if [[ "${REPO}" == "cugraph" ]]; then
        git clone -b split-test-libraries --depth 1 --single-branch "https://github.com/jayavenkatesh19/cugraph" "$REPO"
    else
        git clone -b "${RAPIDS_BRANCH}" --depth 1 --single-branch "https://github.com/rapidsai/$REPO" "$REPO"
    fi

    SOURCE="$REPO/notebooks"
    DESTINATION="/notebooks/$REPO"
    if [ "$REPO" = "cugraph" ]; then
        echo "Special handling for $REPO..."
        EXCLUDE_LIST=$(mktemp)
        mkdir -p $DESTINATION
        find "$SOURCE" -type f -name "SKIP_CI_TESTING" -printf "%h\n" | sed "s|^$SOURCE/||" > "$EXCLUDE_LIST"
        rsync -avL --exclude-from="$EXCLUDE_LIST" "$SOURCE"/ "$DESTINATION"
        rm "$EXCLUDE_LIST"
    else
        cp -rL "$SOURCE" "$DESTINATION"
    fi

    if [[ "${REPO}" == "cugraph" ]]; then
        FILE_KEY="run_notebooks"
    else
        FILE_KEY="test_notebooks"
    fi
    echo "Running dfg on $REPO (file-key: $FILE_KEY)"
    rapids-dependency-file-generator \
        --config "$REPO/dependencies.yaml" \
        --file-key "$FILE_KEY" \
        --matrix "cuda=${CUDA_VER%.*};arch=$(arch);py=${PYTHON_VER}" \
        --output conda >"/dependencies/${REPO}_notebooks_tests_dependencies.yaml"
done

pushd "/dependencies"
conda-merge ./*.yaml |
    yq '.channels = load("/condarc").channels' |                 # Use channels provided by CI, not repos
    tee /test_notebooks_dependencies.yaml
