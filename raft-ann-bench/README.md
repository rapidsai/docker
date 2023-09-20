# RAFT ANN Benchmarks docker

This folder contains the dockerfiles for generating GPU and CPU RAFT ANN benchmark images.

This images are meant to

# Image types:

There are two image types:

- gpu: Contains dockerfile to build images using conda packages for GPU systems.
- cpu: Contains dockerfile to build images using conda packages for CPU systems. Based on `mambaforge`.

# Running the Containers

For complete details, refer to RAFT's documentation https://docs.rapids.ai/api/raft/nightly/raft_ann_benchmarks/#installing-the-benchmarks.

Basic usage:

```bash
docker run --gpus all --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks  \
    rapidsai/raft-ann-bench:23.10a-cuda11.8-py3.10 \
     "--dataset deep-image-96-angular" \
     "--normalize" \
     "--algorithms raft_cagra" \
```

```bash
docker run --rm -it \
    -v $DATA_FOLDER:/home/rapids/benchmarks  \
    rapidsai/raft-ann-bench-cpu:23.10a-py3.10 \
     "--dataset deep-image-96-angular" \
     "--normalize" \
     "--algorithms hnswlib" \
```
