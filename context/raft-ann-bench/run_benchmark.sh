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

. /opt/conda/etc/profile.d/conda.sh; conda activate rapids

export CONDA_PREFIX=/opt/conda/envs/rapids
export DATASET_ARG=$1
export GET_DATASET_ARGS=$2
export RUN_ARGS=$3
export PLOT_ARGS=$4

# (1) prepare dataset.
python -m raft_ann_bench.get_dataset ${DATASET_ARG} ${GET_DATASET_ARGS} --dataset-path /data/benchmarks/datasets

if [[ "$DATASET_ARG" == *"angular"* ]]; then
  export DATASET_ARG=${DATASET_ARG/angular/inner}
  echo "DATASET ARG"
  echo $DATASET_ARG
fi

# (2) build and search index
python -m raft_ann_bench.run  ${DATASET_ARG} --dataset-path /data/benchmarks/datasets --force ${RUN_ARGS}

# (3) export data
python -m raft_ann_bench.data_export  ${DATASET_ARG} --dataset-path /data/benchmarks/datasets

# Extract the algorithms from the run command to use in the plot command
ALGOS=$(grep -oP "algorithms\s+\K(\w+,?\w+)" <<< "$RUN_ARGS")
if [[ "$ALGOS" != "" ]]; then
    ALGOS="--algorithms $ALGOS"
fi

# (4) plot results
mkdir -p /data/benchmarks/datasets/result
cd /data/benchmarks/datasets/result
python -m raft_ann_bench.plot  ${DATASET_ARG} ${ALGOS} ${PLOT_ARGS} --dataset-path /data/benchmarks/datasets --build --search
