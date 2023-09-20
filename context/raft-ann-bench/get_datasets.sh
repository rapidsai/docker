#!/bin/bash
# Copyright (c) 2023, NVIDIA CORPORATION.

set -eo pipefail

cat << EOF
This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.download.nvidia.com/licenses/NVIDIA_Deep_Learning_Container_License.pdf

EOF

export CONDA_PREFIX=/opt/conda

python -m raft-ann-bench.get_dataset --dataset deep-image-96-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m raft-ann-bench.get_dataset --dataset fashion-mnist-784-euclidean --dataset-path /home/rapids/preloaded_datasets
python -m raft-ann-bench.get_dataset --dataset glove-50-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m raft-ann-bench.get_dataset --dataset glove-100-angular --normalize --dataset-path /home/rapids/preloaded_datasets
# python -m raft-ann-bench.get_dataset --dataset lastfm-65-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m raft-ann-bench.get_dataset --dataset mnist-784-euclidean --dataset-path /home/rapids/preloaded_datasets
python -m raft-ann-bench.get_dataset --dataset nytimes-256-angular --normalize --dataset-path /home/rapids/preloaded_datasets
python -m raft-ann-bench.get_dataset --dataset sift-128-euclidean --dataset-path /home/rapids/preloaded_datasets
