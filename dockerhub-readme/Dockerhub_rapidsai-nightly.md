# [NIGHTLY] RAPIDS - Open GPU Data Science

**IMPORTANT:** For our latest stable release please use the [rapidsai/rapidsai](https://hub.docker.com/r/rapidsai/rapidsai) containers.

## What is RAPIDS?

Visit [rapids.ai](http://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.

## What are RAPIDS NIGHTLY images?

The `rapidsai/rapidsai-nightly` repo contains nightly docker builds of the latest WIP changes merged into Github repos throughout the day for the next RAPIDS release. These containers are generally considered unstable, and should only be used for development and testing. For our latest stable release, please use the [rapidsai/rapidsai](https://hub.docker.com/r/rapidsai/rapidsai) containers.

#### RAPIDS NIGHTLY v0.14.0a

Versions of libraries included in the `0.14` images:
- `cuDF` [v0.14.0a](https://github.com/rapidsai/cudf), `cuML` [v0.14.0a](https://github.com/rapidsai/cuml), `cuGraph` [v0.14.0a](https://github.com/rapidsai/cugraph), `RMM` [v0.14.0a](https://github.com/rapidsai/RMM), `cuSpatial` [v0.14.0a](https://github.com/rapidsai/cuspatial), `cuxfilter` [v0.14.0a](https://github.com/rapidsai/cuxfilter)
  - **NOTE:** `cuxfilter` is only available in `runtime` containers
- `xgboost` [branch](https://github.com/rapidsai/xgboost/tree/rapids-0.12-release), `dask-xgboost` [branch](https://github.com/rapidsai/dask-xgboost/tree/dask-cudf) `dask-cuda` [branch](https://github.com/rapidsai/dask-cuda/tree/branch-0.12)

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
0.13-cuda10.1-runtime-ubuntu18.04-py3.7
 ^       ^    ^        ^         ^
 |       |    type     |         python version
 |       |             |
 |       cuda version  |
 |                     |
 RAPIDS version        linux version
```

To get the latest RAPIDS version of a specific platform combination, simply exclude the RAPIDS version.  For example, to pull the latest version of RAPIDS for the `runtime` image with support for CUDA 10.1, Python 3.7, and Ubuntu 18.04, use the following tag:
```
cuda10.1-runtime-ubuntu18.04-py3.7
```

Many users do not need a specific platform combination but would like to ensure they're getting the latest version of RAPIDS, so as an additional convenience, a tag named simply `latest` is also provided which is equivalent to `cuda10.1-runtime-ubuntu16.04-py3.7`.

## Prerequisites

* NVIDIA Pascal™ GPU architecture or better
* CUDA [10.1](https://developer.nvidia.com/cuda-downloads) compatible NVIDIA driver
* Ubuntu 16.04/18.04 or CentOS 7
* Docker CE v18+
* [nvidia-docker](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)) v2+

## Usage

See [usage instructions](https://hub.docker.com/r/rapidsai/rapidsai#usage) for information and replace references to `rapidsai/rapidsai` with `rapidsai/rapidsai-nightly`.

## Where can I get help or file bugs/requests?

For more information about the containers or to submit a container issue, visit: [https://github.com/rapidsai/build](https://github.com/rapidsai/build).

For issues with RAPIDS libraries like cuDF, cuML, RMM, cuGraph, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids) or [Google Groups](https://groups.google.com/forum/#!forum/rapidsai).
