# cuVS Benchmarks Docker Images

This folder contains the Dockerfiles for generating GPU and CPU cuVS benchmark images.

These images are meant to enable end users of cuVS ANN algorithms to easily run and reproduce benchmarks and comparisons between cuVS and third party libraries.

# Image types:

There are two image types:

- gpu: Contains dockerfile to build images using conda packages for GPU systems.
- cpu: Contains dockerfile to build images using conda packages for CPU systems. Based on `mambaforge`.

# Running the Containers

For complete details, refer to the cuVS documentation: https://docs.rapids.ai/api/cuvs/nightly/cuvs_bench/#installing-the-benchmarks

We provide images for GPU enabled systems, as well as systems without a GPU. The following images are available:

- `cuvs-bench`: Contains GPU and CPU benchmarks, can run all algorithms supported. Will download million-scale datasets as required. Best suited for users that prefer a smaller container size for GPU based systems. Requires the NVIDIA Container Toolkit to run GPU algorithms, can run CPU algorithms without it.
- `cuvs-bench-datasets`: Contains the GPU and CPU benchmarks with million-scale datasets already included in the container. Best suited for users that want to run multiple million scale datasets already included in the image.
- `cuvs-bench-cpu`: Contains only CPU benchmarks with minimal size. Best suited for users that want the smallest containers to reproduce benchmarks on systems without a GPU.

Nightly images are located in [DockerHub](https://hub.docker.com/r/rapidsai/cuvs-bench), release versions will be located in NCG in the next release.

## Container Usage

The containers can be used in two manners:

1. **Quick benchmark with single `docker run`**: The docker containers already include helper scripts to be able to invoke most of the functionality of the benchmarks from docker run for a simple and easy way to run benchmarks.

For GPU systems, where $DATA_FOLDER is a local folder where you want datasets stored in $DATA_FOLDER/datasets and results in $DATA_FOLDER/results:

```bash
export DATA_FOLDER=path/to/store/results/and/data
docker run --gpus all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks \
    -u $(id -u) \
    rapidsai/cuvs-bench:25.10a-cuda13.0-py3.13 \
    "--dataset deep-image-96-angular" \
    "--normalize" \
    "--algorithms cuvs_cagra" \
    ""
```

Where:

- `DATA_FOLDER=path/to/store/results/and/data`: Results and datasets will be written to this host folder.
- `-u $(id -u)`: This flag allows the container to use the host user for permissions
- `rapidsai/cuvs-bench:25.10a-cuda13.0-py3.13`: Image to use, either `cuvs-bench` or `cuvs-bench-datasets`, cuVS version, CUDA version, and Python version.
- "--dataset deep-image-96-angular": Dataset name(s). See https://docs.rapids.ai/api/cuvs/nightly/cuvs_bench for more details.
- "--normalize": Whether to normalize the dataset, leave string empty ("") to not normalize.
- "--algorithms cuvs_cagra": What algorithm(s) to use as a ; separated list, as well as any other argument to pass to `cuvs_bench.run`.
- Last line, (""): optional arguments to pass to `cuvs_bench.plot`, pass an empty string if no parameters to plot are needed.

For CPU systems the same interface applies, except for not needing the gpus argument and using the cpu images:

```bash
export DATA_FOLDER=path/to/store/results/and/data
docker run  all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks \
    -u $(id -u) \
    rapidsai/cuvs-bench-cpu:25.10a-py3.13 \
     "--dataset deep-image-96-angular" \
     "--normalize" \
     "--algorithms cuvs_cagra" \
     ""
```

2. **Using the preinstalled `cuvs_bench` python package**: The docker containers are built using the conda packages described in the following section, so they can be used directly as if they were installed manually following the instructions in the next section. This allows using the full flexibility of the scripts. To use the python scripts directly, an easy way is to use the following command:

```bash
export DATA_FOLDER=path/to/store/results/and/data
docker run --gpus all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks \
    -u $(id -u) \
    rapidsai/cuvs-bench:25.10a-cuda13.0-py3.13 \
    --entrypoint /bin/bash
```

This will drop you into a command line in the container, with cuVS and the `cuvs_bench` python package ready to use:

```
(base) root@00b068fbb862:/home/rapids#
```

Additionally, the containers could be run in detached form without any issue.
