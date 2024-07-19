# RAFT ANN Benchmarks docker

This folder contains the dockerfiles for generating GPU and CPU RAFT ANN benchmark images.

These images are meant to enable end users of RAFT's ANN algorithms to easily run and reproduce benchmarks and comparisons between RAFT and third party libraries.

# Image types:

There are two image types:

- gpu: Contains dockerfile to build images using conda packages for GPU systems.
- cpu: Contains dockerfile to build images using conda packages for CPU systems. Based on `mambaforge`.

# Running the Containers

For complete details, refer to RAFT's documentation https://docs.rapids.ai/api/raft/nightly/raft_ann_benchmarks/#installing-the-benchmarks.

We provide images for GPU enabled systems, as well as systems without a GPU. The following images are available:

- `raft-ann-bench`: Contains GPU and CPU benchmarks, can run all algorithms supported. Will download million-scale datasets as required. Best suited for users that prefer a smaller container size for GPU based systems. Requires the NVIDIA Container Toolkit to run GPU algorithms, can run CPU algorithms without it.
- `raft-ann-bench-datasets`: Contains the GPU and CPU benchmarks with million-scale datasets already included in the container. Best suited for users that want to run multiple million scale datasets already included in the image.
- `raft-ann-bench-cpu`: Contains only CPU benchmarks with minimal size. Best suited for users that want the smallest containers to reproduce benchmarks on systems without a GPU.

Nightly images are located in [dockerhub](https://hub.docker.com/r/rapidsai/raft-ann-bench), meanwhile release (stable) versions are located in [NGC](https://hub.docker.com/r/rapidsai/raft-ann-bench), starting with release 23.12.

## Container Usage

The containers can be used in two manners:

1. **Quick benchmark with single `docker run`**: The docker containers already include helper scripts to be able to invoke most of the functionality of the benchmarks from docker run for a simple and easy way to run benchmarks.

For GPU systems, where $DATA_FOLDER is a local folder where you want datasets stored in $DATA_FOLDER/datasets and results in $DATA_FOLDER/results:

```bash
export DATA_FOLDER=path/to/store/results/and/data
docker run --gpus all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks  \
    -u $(id -u) \
    rapidsai/raft-ann-bench:24.10a-cuda11.8-py3.11 \
    "--dataset deep-image-96-angular" \
    "--normalize" \
    "--algorithms raft_cagra" \
    ""
```

Where:

```bash
export DATA_FOLDER=path/to/store/results/and/data # <- Results and datasets will be written to this host folder.
docker run --gpus all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks  \ # <- local folder to store datasets and results
    -u $(id -u) \ # <- this flag allows the container to use the host user for permissions
    rapidsai/raft-ann-bench:24.10a-cuda11.8-py3.11 \ # <- image to use, either `raft-ann-bench` or `raft-ann-bench-datasets`
    "--dataset deep-image-96-angular" \ # <- dataset name
    "--normalize" \ # <- whether to normalize the dataset, leave string empty ("") to not normalize.
    "--algorithms raft_cagra" \ # <- what algorithm(s) to use as a ; separated list, as well as any other argument to pass to `raft_ann_benchmarks.run`
    "" # optional argumetns to pass to `raft_ann_benchmarks.plot`
```

For CPU systems the same interface applies, except for not needing the gpus argument and using the cpu images:
```bash
export DATA_FOLDER=path/to/store/results/and/data
docker run  all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks  \
    -u $(id -u) \ # <- this flag allows the container to use the host user for permissions
    rapidsai/raft-ann-bench-cpu:24.10a-py3.11 \
     "--dataset deep-image-96-angular" \
     "--normalize" \
     "--algorithms raft_cagra" \
     ""
```

2. **Using the preinstalled `raft_ann_benchmarks` python package**: The docker containers are built using the conda packages described in the following section, so they can be used directly as if they were installed manually following the instructions in the next section. This allows using the full flexibility of the scripts. To use the python scripts directly, an easy way is to use the following command:

```bash
export DATA_FOLDER=path/to/store/results/and/data
docker run --gpus all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks  \
    -u $(id -u) \
    rapidsai/raft-ann-bench:24.10a-cuda11.8-py3.11 \
    --entrypoint /bin/bash
```

This will drop you into a command line in the container, with RAFT and the `raft_ann_benchmarks` python package ready to use:

```
(base) root@00b068fbb862:/home/rapids#
```

Additionally, the containers could be run in dettached form without any issue.
