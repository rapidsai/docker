# `rapidsai/docker`

This repository contains the end-user docker images for [RAPIDS](https://rapids.ai).

## Image types

There are two image types: `base` ([`rapidsai/base`](https://hub.docker.com/r/rapidsai/base)) and `notebooks` ([`rapidsai/notebooks`](https://hub.docker.com/r/rapidsai/notebooks)).

### Base image

This image can be found here: https://hub.docker.com/r/rapidsai/base

It contains the basic installation of RAPIDS. By default it starts an `ipython` REPL.

### Notebooks image

This image can be found here: https://hub.docker.com/r/rapidsai/notebooks

It extends the `base` images to include RAPIDS notebooks and a [`jupyterlab` server](https://jupyter.org/) which starts automatically.

## Image tags

Tags for both `base` and `notebooks` images take the form of `${RAPIDS_VER}-cuda${CUDA_VER}-py${PYTHON_VER}`.

**Note on CUDA versioning**:
- **RAPIDS 25.12 and later**: CUDA version tags are major-only (e.g., `cuda12`, `cuda13`).
- **RAPIDS 25.10**: Both major.minor version tags (e.g., `cuda12.9`, `cuda13.1`) and major version tags (e.g., `cuda12`, `cuda13`). The major version tags are created by retagging the latest minor version builds.
- **RAPIDS 25.08 and older**: CUDA version tags are major.minor (e.g., `cuda12.9`).

There is no `latest` tag.

## Environment Variables

The following environment variables can be passed to the `docker run` commands for each image:

- `EXTRA_CONDA_PACKAGES` - used to install additional `conda` packages in the container. Use a space separated list of conda version specs
- `CONDA_TIMEOUT` - how long (in seconds) the `conda` install should wait before exiting
- `EXTRA_PIP_PACKAGES` - used to install additional `pip` packages in the container. Use a space separated list of pip version specs
- `PIP_TIMEOUT` - how long (in seconds) the `pip` install should wait before exiting
- `UNQUOTE` - Whether the command line args to `docker run` should be [executed with or without being quoted](./context/entrypoint.sh). Default to false and it is unlikely that you need to change this.

## Bind Mounts

Mounting files/folders to the locations specified below provide additional functionality for the images.

- `/home/rapids/environment.yml` - a `conda` YAML environment file that contains a list of dependencies that will be installed. The file should look like:

```yml
dependencies:
  - beautifulsoup4
  - jq
```

## Contributing

Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for details on how to contribute to this repo.
