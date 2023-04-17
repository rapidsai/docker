#!/usr/bin/env bash
set -e

mkdir -p /notebooks /dependencies
NB_REPOS=(cudf cuml cugraph cuxfilter cuspatial cusignal xgboost-conda)
for REPO in "${NB_REPOS[@]}"; do
    echo "Cloning $REPO..."
    git clone -b "${RAPIDS_BRANCH}" --depth 1 --single-branch "https://github.com/rapidsai/$REPO" "$REPO"
    cp -rL "$REPO"/notebooks /notebooks/"$REPO"
    if [ -f "$REPO/dependencies.yaml" ] && yq -e '.files.test_notebooks' "$REPO/dependencies.yaml" > /dev/null; then
        echo "Running dfg on $REPO"
        rapids-dependency-file-generator \
            --config "$REPO/dependencies.yaml" \
            --file_key test_notebooks \
            --matrix "cuda=${CUDA_VER%.*};py=${PYTHON_VER};arch=$(arch)" \
            --output conda > "/dependencies/${REPO}_notebooks_tests_dependencies.yaml"; \
    fi
done

pushd "/dependencies"
conda-merge ./*.yaml > /test_notebooks_dependencies.yaml