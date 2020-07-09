# RAPIDS - Open GPU Data Science

## What is RAPIDS?

Visit [rapids.ai](http://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes that GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.

### Current Version

#### RAPIDS 0.13 - 31 March 2020

Versions of libraries included in the `0.13` images:
- `cuDF` [v0.13.0](https://github.com/rapidsai/cudf/tree/v0.13.0), `cuML` [v0.13.0](https://github.com/rapidsai/cuml/tree/v0.13.0), `cuGraph` [v0.13.0](https://github.com/rapidsai/cugraph/tree/v0.13.0), `RMM` [v0.13.0](https://github.com/rapidsai/RMM/tree/v0.13.0), `cuSpatial` [v0.13.0](https://github.com/rapidsai/cuspatial/tree/v0.13.0), `cuxfilter` [v0.13.0](https://github.com/rapidsai/cuxfilter/tree/branch-0.13)
  - **NOTE:** `cuxfilter` is only available in `runtime` containers
- `xgboost` [branch](https://github.com/rapidsai/xgboost/tree/rapids-0.13-release), `dask-xgboost` [branch](https://github.com/rapidsai/dask-xgboost/tree/dask-cudf) `dask-cuda` [branch](https://github.com/rapidsai/dask-cuda/tree/branch-0.13)

### Former Version

#### RAPIDS 0.12 - 4 February 2020

Versions of libraries included in the `0.12` images:
- `cuDF` [v0.12.0](https://github.com/rapidsai/cudf/tree/v0.12.0), `cuML` [v0.12.0](https://github.com/rapidsai/cuml/tree/v0.12.0), `cuGraph` [v0.12.0](https://github.com/rapidsai/cugraph/tree/v0.12.0), `RMM` [v0.12.0](https://github.com/rapidsai/RMM/tree/v0.12.0), `cuSpatial` [v0.12.0](https://github.com/rapidsai/cuspatial/tree/v0.12.0), `cuxfilter` [v0.12.0](https://github.com/rapidsai/cuxfilter/tree/branch-0.12)
  - **NOTE:** `cuxfilter` is only available in `runtime` containers
- `xgboost` [branch](https://github.com/rapidsai/xgboost/tree/rapids-0.12-release), `dask-xgboost` [branch](https://github.com/rapidsai/dask-xgboost/tree/dask-cudf) `dask-cuda` [branch](https://github.com/rapidsai/dask-cuda/tree/branch-0.12)

### Image Types

The RAPIDS images are based on [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda), and are intended to be drop-in replacements for the corresponding CUDA
images in order to make it easy to add RAPIDS libraries while maintaining support for existing CUDA applications.

RAPIDS images come in three types, distributed in two different repos:

This repo (rapidsai), contains the following:
- `base` - contains a RAPIDS environment ready for use.
  - **TIP: Use this image if you want to use RAPIDS as a part of your pipeline.**
- `runtime` - extends the `base` image by adding a notebook server and example notebooks.
  - **TIP: Use this image if you want to explore RAPIDS through notebooks and examples.**

The [rapidsai/rapidsai-dev](https://hub.docker.com/r/rapidsai/rapidsai-dev/tags) repo adds the following:
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

### Start Container and Notebook Server

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker pull rapidsai/rapidsai:cuda10.1-runtime-ubuntu18.04-py3.7
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai:cuda10.1-runtime-ubuntu18.04-py3.7
```
**NOTE:** This will open a shell with [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) running in the background on port 8888 on your host machine.

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker pull rapidsai/rapidsai:cuda10.1-runtime-ubuntu18.04-py3.7
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai:cuda10.1-runtime-ubuntu18.04-py3.7
```
**NOTE:** This will open a shell with [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) running in the background on port 8888 on your host machine.

### Use JupyterLab to Explore the Notebooks

Notebooks can be found in the following directories within the 0.10 container:

* `/rapids/notebooks/xgboost` - XGBoost demo notebooks
* `/rapids/notebooks/cudf` - cuDF demo notebooks
* `/rapids/notebooks/cuml` - cuML demo notebooks
* `/rapids/notebooks/cugraph` - cuGraph demo notebooks
* `/rapids/notebooks/tutorials` - Tutorials with end-to-end workflows

For a full description of each notebook, see the [README](https://github.com/rapidsai/notebooks/blob/branch-0.9/README.md) in the notebooks repository.

### Custom Data and Advanced Usage

You are free to modify the above steps. For example, you can launch an interactive session with your own data:

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
                  rapidsai/rapidsai:cuda10.1-runtime-ubuntu18.04-py3.7
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
                  rapidsai/rapidsai:cuda10.1-runtime-ubuntu18.04-py3.7
```
This will map data from your host operating system to the container OS in the `/rapids/my_data` directory. You may need to modify the provided notebooks for the new data paths.

### Access Documentation within Notebooks

You can check the documentation for RAPIDS APIs inside the JupyterLab notebook using a `?` command, like this:
```
[1] ?cudf.read_csv
```
This prints the function signature and its usage documentation. If this is not enough, you can see the full code for the function using `??`:
```
[1] ??pygdf.read_csv
```
Check out the RAPIDS [documentation](http://rapids.ai/start.html) for more detailed information and a RAPIDS [cheat sheet](https://rapids.ai/files/cheatsheet.pdf).

## More Information

Check out the [RAPIDS](https://docs.rapids.ai/api) and [XGBoost](https://xgboost.readthedocs.io/en/latest/) API docs.

Learn how to setup a mult-node cuDF and XGBoost data preparation and distributed training environment by following the [mortgage data example notebook and scripts](https://github.com/rapidsai/notebooks).

## Where can I get help or file bugs/requests?

For more information about the containers or to submit a container issue, visit: [https://github.com/rapidsai/build](https://github.com/rapidsai/build).

For issues with RAPIDS libraries like cuDF, cuML, RMM, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids) or [Google Groups](https://groups.google.com/forum/#!forum/rapidsai).
