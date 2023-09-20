#!/bin/bash
# Copyright (c) 2023, NVIDIA CORPORATION.

set -eo pipefail

cat << EOF
This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.download.nvidia.com/licenses/NVIDIA_Deep_Learning_Container_License.pdf

EOF

function hasArg {
    (( ${NUMARGS} != 0 )) && (echo " ${ARGS} " | grep -q " $1 ")
}

export CONDA_PREFIX=/opt/conda
export DATASET_ARG=$1
export GET_DATASET_ARGS=$2
export RUN_ARGS=$3
export $PLOT_ARGS=$4

# (1) prepare dataset only if not using prebuilt dataset
case $DATASET_ARG in
   deep-image-96-angular|fashion-mnist-784|glove-50-angular|glove-100-angular|lastfm-65-angular|mnist-784-euclidean|nytimes-256-angular|sift-128-euclidean)
     export DATASET_PATH=/home/rapids/preloaded_datasets ;;
   *)
      python -m raft-ann-bench.get_dataset ${DATASET_ARG} ${GET_DATASET_ARGS} --dataset-path /home/rapids/benchmarks/datasets
     export DATASET_PATH=/home/rapids/benchmarks/datasets ;;
esac

if [[ "$DATASET_ARG" == *"angular"* ]]; then
  export DATASET_ARG=${DATASET_ARG/angular/inner}
  echo "DATASET ARG"
  echo $DATASET_ARG
fi

# (2) build and search index
python -m raft-ann-bench.run  ${DATASET_ARG} --dataset-path /home/rapids/benchmarks/datasets $3

# (3) export data
python -m raft-ann-bench.data_export  ${DATASET_ARG} --dataset-path /home/rapids/benchmarks/datasets

# (4) plot results
python -m raft-ann-bench.plot  ${DATASET_ARG} ${PLOT_ARGS} --dataset-path /home/rapids/benchmarks/datasets --output-filepath /home/rapids/benchmarks/results
