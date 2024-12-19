#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

set -eo pipefail

# find cuVS-bench in the environment
# __file__ is empty, so we use __path__
PACKAGE_FILE_PATH=$(python -c "import cuvs_bench; print(list(cuvs_bench.__path__)[0])")

# Apply the patch
patch "$PACKAGE_FILE_PATH/get_dataset/__main__.py" < /home/rapids/cuvs-bench/cuvs_bench_get_dataset.patch

python -m cuvs_bench.get_dataset --dataset deep-image-96-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset fashion-mnist-784-euclidean --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset glove-50-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset glove-100-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset mnist-784-euclidean --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset nytimes-256-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m cuvs_bench.get_dataset --dataset sift-128-euclidean --dataset-path /home/rapids/preloaded_datasets
