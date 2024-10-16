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
export PLOT_ARGS=$4

echo $DATASET_ARG

case $DATASET_ARG in
"--dataset deep-image-96-angular"|"--dataset fashion-mnist-784"|"--dataset glove-50-angular"|"--dataset glove-100-angular"|"--dataset lastfm-65-angular"|"--dataset mnist-784-euclidean"|"--dataset nytimes-256-angular"|"--dataset sift-128-euclidean")
    export DATASET_PATH=/home/rapids/preloaded_datasets ;;
   *)
    export DATASET_PATH=/data/benchmarks/datasets
    python -m cuvs_bench.get_dataset ${DATASET_ARG} ${GET_DATASET_ARGS} --dataset-path $DATASET_PATH ;;
esac

if [[ "$DATASET_ARG" == *"angular"* ]]; then
  export DATASET_ARG=${DATASET_ARG/angular/inner}
  echo "DATASET ARG"
  echo $DATASET_ARG
fi

# (2) build and search index
python -m cuvs_bench.run  ${DATASET_ARG} --dataset-path $DATASET_PATH ${RUN_ARGS}

# (3) export data
python -m cuvs_bench.data_export  ${DATASET_ARG} --dataset-path $DATASET_PATH

# Extract the algorithms from the run command to use in the plot command
ALGOS=$(grep -oP "algorithms\s+\K(\w+,?\w+)" <<< "$RUN_ARGS")
if [[ "$ALGOS" != "" ]]; then
    ALGOS="--algorithms $ALGOS"
fi

# (4) plot results
mkdir -p $DATASET_PATH/result
cd $DATASET_PATH/result
python -m cuvs_bench.plot  ${DATASET_ARG} ${ALGOS} ${PLOT_ARGS} --dataset-path $DATASET_PATH
