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
- `DASK_SQL_VER` - Version of `dask-sql` to use. Should be `YYYY.M.P`
