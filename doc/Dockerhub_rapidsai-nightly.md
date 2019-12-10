# [NIGHTLY] RAPIDS - Open GPU Data Science

**IMPORTANT:** For our latest stable release please use the [rapidsai/rapidsai](https://hub.docker.com/r/rapidsai/rapidsai) containers.

## What is RAPIDS?

Visit [rapids.ai](http://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes that GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.

## What are RAPIDS NIGHTLY containers?

The `rapidsai/rapidsai-nightly` repo contains nightly docker builds of the latest WIP builds of the next release. These containers are considered generally to be unstable and should only be used for development and testing. For our latest stable release please use the [rapidsai/rapidsai](https://hub.docker.com/r/rapidsai/rapidsai) containers.

### Current Version

<!-- Replace with description of what is in a nightly, and how to read tags -->

#### RAPIDS 0.9.0a - WIP v0.9 release
Versions of libraries included in the `0.9` [images](#rapids-0-9-images):
- `cuDF` [branch-0.9](https://github.com/rapidsai/cudf/tree/branch-0.9), `cuML` [branch-0.9](https://github.com/rapidsai/cuml/tree/branch-0.9), `RMM` [branch-0.9](https://github.com/rapidsai/RMM/tree/branch-0.9), `cuGraph` [branch-0.9](https://github.com/rapidsai/cugraph/tree/branch-0.9)
- `xgboost` [cudf-interop](https://github.com/rapidsai/xgboost/tree/cudf-interop), `dask-xgboost` [dask-cudf](https://github.com/rapidsai/dask-xgboost/tree/dask-cudf), `dask-cudf` [branch-0.9](https://github.com/rapidsai/dask-cudf/tree/branch-0.9), `dask-cuda` [branch-0.9](https://github.com/rapidsai/dask-cuda/tree/branch-0.9)

### Tags

The RAPIDS image is based on [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda).
This means it is a drop-in replacement, making it easy to gain the RAPIDS
libraries while maintaining support for existing CUDA applications.

RAPIDS images come in three types, distributed in two different repos:

This repo (rapidsai-nightly), contains the following:
- `base` - contains a RAPIDS environment ready for use. <b>Use this image if you want to use RAPIDS as a part of your pipeline.</b>
- `runtime` - extends the `base` image by adding a notebook server and example notebooks. <b>Use this image if you want to explore RAPIDS through notebooks and examples.</b>

The [rapidsai/rapidsai-dev-nightly](https://hub.docker.com/r/rapidsai/rapidsai-dev-nightly/tags) repo adds the following:
- `devel` - contains the full RAPIDS source tree, pre-built with all artifacts in place, and the compiler toolchain, the debugging tools, the headers and the static libraries for RAPIDS development. <b>Use this image to develop RAPIDS from source.</b>

#### Common Tags

For most users, the `runtime` image will be sufficient to get started with RAPIDS,
you can use the following tags to pull the latest stable image:
- `latest` or `cuda9.2-runtime-ubuntu16.04` <br/>with `gcc 5.4` and `Python 3.6`
- `cuda10.0-runtime-ubuntu16.04`<br/>with `gcc 7.3` and `Python 3.6`

#### Tag Naming Scheme

Using the image types [above](#tags) `base`, `runtime`, or `devel` we use the following
tag naming scheme for RAPIDS images:

```
0.9-cuda9.2-devel-ubuntu16.04-py3.6
 ^       ^    ^        ^         ^
 |       |    type     |         python version
 |       |             |
 |       cuda version  |
 |                     |
 RAPIDS version        linux version
```

## Prerequisites

* NVIDIA Pascal™ GPU architecture or better
* CUDA [9.2](https://developer.nvidia.com/cuda-92-download-archive) or [10.0](https://developer.nvidia.com/cuda-downloads) compatible NVIDIA driver
* Ubuntu 16.04/18.04 or CentOS 7
* Docker CE v18+
* [nvidia-docker](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)) v2+

## Usage

See [usage instructions](https://hub.docker.com/r/rapidsai/rapidsai#usage) for information and replace references to `rapidsai/rapidsai` with `rapidsai/rapidsai-nightly`.

## Where can I get help or file bugs/requests?

For issues with RAPIDS libraries like cuDF, cuML, RMM, cuGraph, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids) or [Google Groups](https://groups.google.com/forum/#!forum/rapidsai).