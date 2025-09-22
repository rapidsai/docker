# Contributing to `rapidsai/docker`

## Requirements

Building the images requires `docker` `>=18.09` with [`buildkit`](https://docs.docker.com/build/buildkit/).

## Building

To build the `notebooks` image with default arguments: `docker buildx build --pull -f Dockerfile -t rapidsai/notebooks context/`

To build just the `base` image with default arguments: `docker buildx build --pull -f Dockerfile -t rapidsai/base --target=base context/`

### Build arguments

- `CUDA_VER` - Version of CUDA to use. Should be `major.minor.patch`
- `PYTHON_VER` - Version of Python to use. Should be `major.minor`
- `RAPIDS_VER` - Version of RAPIDS to use. Should be `YY.MM`

**Note on CUDA versioning**:
- **RAPIDS 25.08 and older**: CUDA version tags are major.minor (e.g., `cuda12.9`).
- **RAPIDS 25.10**: Both major.minor version tags (e.g., `cuda12.9`, `cuda13.0`) and consolidated major version tags (e.g., `cuda12`, `cuda13`). The major version tags are created by retagging the latest minor version builds.
- **RAPIDS 25.12 and later**: Only major version tags will be created (e.g., `cuda12`, `cuda13`).

## Cleaning Up

Every build first writes images to the https://hub.docker.com/r/rapidsai/staging repo on DockerHub,
then pushes them on to the individual repos like `rapidsai/base`, `rapidsai/notebooks`, etc.

A scheduled job regularly deletes old images from that `rapidsai/staging` repo.
See https://github.com/rapidsai/workflows/blob/main/.github/workflows/cleanup_staging.yaml for details.

If you come back to a pull requests here after more than a few days and find that jobs are failing with errors
that suggest that some necessary images don't exist, re-run all of CI on that pull request to produce new images.
