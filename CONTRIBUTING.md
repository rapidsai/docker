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
export PYTHON_VER=3.14

# RAPIDS version in {major}.{minor}
export RAPIDS_VER=26.06

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

## Preparing a release branch

Run the version update with the release context when preparing `release/YY.MM`:

```sh
bash ci/release/update-version.sh YY.MM.00 --run-context=release
```

This updates the Dockerfile's `RAPIDS_NOTEBOOKS_REF` default to `release/YY.MM`.
Branch CI also derives the notebook ref directly from `GITHUB_REF_NAME`, so alpha-tagged
builds on `release/YY.MM` clone notebook inputs from the matching `cudf`, `cuml`, and
`cugraph` release branches instead of `main`. Those release branches must exist before
the first Docker build runs; no separate notebook-ref edit is otherwise required during
the branch cut.

Pull requests targeting `main` use the current version derived from the repository tag
and clone notebook inputs from `main`. Pull requests targeting `release/YY.MM` use that
target branch for both the package version and notebook inputs. This keeps package and
source lines matched without hardcoded version pins or manual updates when the next
release branch is created.
