#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

set -eo pipefail

# find cuVS in the environment
PACKAGE_FILE_PATH=$(python -c "import cuvs_bench; print(cuvs_bench.__file__)")
PACKAGE_DIR=$(dirname "$PACKAGE_FILE_PATH")

# Apply the patch
patch "$PACKAGE_DIR/get_dataset/__main__.py" < cuvs_bench_get_dataset.patch

python -m cuvs_bench.get_dataset --dataset deep-image-96-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset fashion-mnist-784-euclidean --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset glove-50-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset glove-100-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset mnist-784-euclidean --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset nytimes-256-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset sift-128-euclidean --dataset-path /home/rapids/preloaded_datasets
