# `docker`

This repository contains the end-user docker images for [RAPIDS](https://rapids.ai).


## Image types

There are two image types: `base` ([`rapidsai/rapidsai`](https://hub.docker.com/r/rapidsai/rapidsai)) and `notebooks` ([`rapidsai/rapidsai-notebooks`](https://hub.docker.com/r/rapidsai/rapidsai-notebooks)).

### Base image

This image can be found here: https://hub.docker.com/r/rapidsai/rapidsai

It contains the basic installation of RAPIDS and [`dask-sql`](https://github.com/dask-contrib/dask-sql). By default it starts an `ipython` REPL.

### Notebooks image

This image can be found here: https://hub.docker.com/r/rapidsai/rapidsai-notebooks

It extends the `base` images to include RAPIDS notebooks and a [`jupyterlab` server](https://jupyter.org/) which starts automatically.

## Image tags

Tags for both `base` and `notebooks` images take the form of `${RAPIDS_VER}-cuda${CUDA_VER}-${LINUX_VER}-py${PYTHON_VER}`.

There is no `latest` tag.

## Environment Variables

The following environment variables can be passed to the `docker run` commands for each image:

- `EXTRA_CONDA_PACKAGES` - used to install additional `conda` packages in the container. Use a space separated list of conda version specs
- `CONDA_TIMEOUT` - how long (in seconds) the `conda` install should wait before exiting
- `EXTRA_PIP_PACKAGES` - used to install additional `pip` packages in the container. Use a space separated list of pip version specs
- `PIP_TIMEOUT` - how long (in seconds) the `pip` install should wait before exiting
- `UNQUOTE` -

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
