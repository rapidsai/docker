# [NIGHTLY] RAPIDS - Open GPU Data Science

**IMPORTANT:** For our latest stable release please use the [rapidsai/rapidsai](https://hub.docker.com/r/rapidsai/rapidsai) containers.

## What is RAPIDS?

Visit [rapids.ai](https://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.

## What are RAPIDS NIGHTLY images?

The `rapidsai/rapidsai-nightly` repo contains nightly docker builds of the latest WIP changes merged into Github repos throughout the day for the next RAPIDS release. These containers are generally considered unstable, and should only be used for development and testing. For our latest stable release, please use the [rapidsai/rapidsai](https://hub.docker.com/r/rapidsai/rapidsai) containers.

#### RAPIDS NIGHTLY v0.18.0a

Versions of libraries included in the `0.18` images:
- `cuDF` [v0.18.0a](https://github.com/rapidsai/cudf), `cuML` [v0.18.0a](https://github.com/rapidsai/cuml), `cuGraph` [v0.18.0a](https://github.com/rapidsai/cugraph), `RMM` [v0.18.0a](https://github.com/rapidsai/RMM), `cuSpatial` [v0.18.0a](https://github.com/rapidsai/cuspatial), `cuSignal` [v0.18.0a](https://github.com/rapidsai/cusignal), `cuxfilter` [v0.18.0a](https://github.com/rapidsai/cuxfilter)
- `blazingsql` [v0.17](https://github.com/rapidsai/blazingsql/tree/v0.17.0), `xgboost` [branch](https://github.com/rapidsai/xgboost), `dask-cuda` [branch](https://github.com/rapidsai/dask-cuda)

### Image Types

The RAPIDS images are based on [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda), and are intended to be drop-in replacements for the corresponding CUDA
images in order to make it easy to add RAPIDS libraries while maintaining support for existing CUDA applications.

RAPIDS images come in three types, distributed in two different repos:

This repo (rapidsai-nightly), contains the following:
- `base` - contains a RAPIDS environment ready for use.
  - **TIP: Use this image if you want to use RAPIDS as a part of your pipeline.**
- `runtime` - extends the `base` image by adding a notebook server and example notebooks.
  - **TIP: Use this image if you want to explore RAPIDS through notebooks and examples.**

The [rapidsai/rapidsai-dev-nightly](https://hub.docker.com/r/rapidsai/rapidsai-dev-nightly/tags) repo adds the following:
- `devel` - contains the full RAPIDS source tree, pre-built with all artifacts in place, and the compiler toolchain, the debugging tools, the headers and the static libraries for RAPIDS development.
  - **TIP: Use this image to develop RAPIDS from source.**

### Image Tag Naming Scheme

The tag naming scheme for RAPIDS images incorporates key platform details into the tag as shown below:
```
0.18-cuda10.1-runtime-ubuntu18.04-py3.7
 ^       ^    ^        ^         ^
 |       |    type     |         python version
 |       |             |
 |       cuda version  |
 |                     |
 RAPIDS version        linux version
```

To get the latest RAPIDS version of a specific platform combination, simply exclude the RAPIDS version. For example, to pull the latest version of RAPIDS for the `runtime` image with support for CUDA 10.1, Python 3.6, and Ubuntu 18.04, use the following tag:
```
cuda10.1-runtime-ubuntu18.04-py3.6
```

Many users do not need a specific platform combination but would like to ensure they're getting the latest version of RAPIDS, so as an additional convenience, a tag named simply `latest` is also provided which is equivalent to `cuda10.1-runtime-ubuntu16.04-py3.6`.

## Prerequisites

* NVIDIA Pascal™ GPU architecture or better
* CUDA [10.1/10.2/11.0](https://developer.nvidia.com/cuda-downloads) with a compatible NVIDIA driver
* Ubuntu 16.04/18.04 or CentOS 7
* Docker CE v18+
* [nvidia-docker](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)) v2+

## Usage

### Start Container and Notebook Server

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker pull rapidsai/rapidsai-nightly:cuda10.1-runtime-ubuntu18.04-py3.7
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai-nightly:cuda10.1-runtime-ubuntu18.04-py3.7
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker pull rapidsai/rapidsai-nightly:cuda10.1-runtime-ubuntu18.04-py3.7
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai-nightly:cuda10.1-runtime-ubuntu18.04-py3.7
```

### Container Ports

The following ports are used by the **`runtime` containers only** (not `base` containers):

- `8888` - exposes a [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) notebook server
- `8786` - exposes a [Dask](https://docs.dask.org/en/latest/) scheduler
- `8787` - exposes a Dask [diagnostic web server](https://docs.dask.org/en/latest/setup/cli.html#diagnostic-web-servers)

### Environment Variables

The following environment variables can be passed to the `docker run` commands:

- `JUPYTER_FG` - set to `true` to start jupyter server in foreground instead of background (not applicable for `base` images)
- `EXTRA_APT_PACKAGES` - (**Ubuntu images only**) used to install additional `apt` packages in the container. Use a space separated list of values
- `EXTRA_YUM_PACKAGES` - (**CentOS images only**) used to install additional `yum` packages in the container. Use a space separated list of values
- `EXTRA_CONDA_PACKAGES` - used to install additional `conda` packages in the container. Use a space separated list of values
- `EXTRA_PIP_PACKAGES` - used to install additional `pip` packages in the container. Use a space separated list of values

Example:

```sh
$ docker run \
    --rm \
    -it \
    --gpus all \
    -e EXTRA_APT_PACKAGES="vim nano" \
    -e EXTRA_CONDA_PACKAGES="jq" \
    -e EXTRA_PIP_PACKAGES="beautifulsoup4" \
    -p 8888:8888 \
    -p 8787:8787 \
    -p 8786:8786 \
    rapidsai/rapidsai-nightly:0.18-cuda10.1-base-ubuntu18.04-py3.7
```

### Bind Mounts

Mounting files/folders to the locations specified below provide additional functionality for the images.

- `/opt/rapids/environment.yml` - a YAML file that contains a list of dependencies that will be installed by `conda`. The file should look like:

```yml
dependencies:
  - beautifulsoup4
  - jq
```

Example:

```sh
$ docker run \
    --rm \
    -it \
    --gpus all \
    -v $(pwd)/environment.yml:/opt/rapids/environment.yml \
    rapidsai/rapidsai-nightly:0.18-cuda10.1-base-ubuntu18.04-py3.7
```

## Where can I get help or file bugs/requests?

Please submit issues with the container to this GitHub repository: [https://github.com/rapidsai/docker](https://github.com/rapidsai/docker/issues/new)

For issues with RAPIDS libraries like cuDF, cuML, RMM, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids) or [Google Groups](https://groups.google.com/forum/#!forum/rapidsai).