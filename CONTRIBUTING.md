# Contributing to `rapidsai/docker`

## Requirements

Building the images requires `docker` `>=18.09` with [`buildkit`](https://docs.docker.com/build/buildkit/).

## Building the images locally

To build the images locally, you may use the following snippets.

```sh
# one of ('amd64', 'arm64')
export CPU_ARCH=amd64

# CUDA version in {major}.{minor}.{patch}
export CUDA_VER=13.0.2

# Linux distribution
export LINUX_DISTRO=ubuntu
export LINUX_DISTRO_VER=24.04
export LINUX_VER=ubuntu24.04

# Python version in {major}.{minor}
export PYTHON_VER=3.13

# RAPIDS version in {major}.{minor}
export RAPIDS_VER=26.02

# rapidsai/base
docker build $(ci/compute-build-args.sh) \
    --target=base \
    -t rapidsai/base:local \
    -f Dockerfile \
    context/

# rapidsai/cuvs-bench-cpu
docker build $(ci/compute-build-args.sh) \
    -t rapidsai/cuvs-bench:local \
    -f ./cuvs-bench/gpu/Dockerfile \
    context/

# rapidsai/cuvs-bench-cpu
docker build $(ci/compute-build-args.sh) \
    -t rapidsai/cuvs-bench-cpu:local \
    -f ./cuvs-bench/cpu/Dockerfile \
    context/

# rapidsai/notebooks
docker build $(ci/compute-build-args.sh) \
    --target=base \
    -t rapidsai/notebooks:notebooks \
    -f Dockerfile \
    context/
```

## Cleaning Up

Every build first writes images to the https://hub.docker.com/r/rapidsai/staging repo on DockerHub,
then pushes them on to the individual repos like `rapidsai/base`, `rapidsai/notebooks`, etc.

A scheduled job regularly deletes old images from that `rapidsai/staging` repo.
See https://github.com/rapidsai/workflows/blob/main/.github/workflows/cleanup_staging.yaml for details.

If you come back to a pull request here after more than a few days and find that jobs are failing with errors
that suggest that some necessary images don't exist, re-run all of CI on that pull request to produce new images.
