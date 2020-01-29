# RAPIDS - Open GPU Data Science

## What is RAPIDS?

Visit [rapids.ai](http://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes that GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.

### Current Version

#### RAPIDS 0.11 - 11 December 2019

Versions of libraries included in the `0.11` [images](#rapids-11-images):
- `cuDF` [v0.11.0](https://github.com/rapidsai/cudf/tree/v0.11.0), `cuML` [v0.11.0](https://github.com/rapidsai/cuml/tree/v0.11.0), `cuGraph` [v0.11.0](https://github.com/rapidsai/cugraph/tree/v0.11.0), `RMM` [v0.11.0](https://github.com/rapidsai/RMM/tree/v0.11.0), `cuSpatial` [v0.11.0](https://github.com/rapidsai/cuspatial/tree/v0.11.0)
- `xgboost` [branch](https://github.com/rapidsai/xgboost/tree/rapids-0.11-release), `dask-xgboost` [branch](https://github.com/rapidsai/dask-xgboost/tree/dask-cudf) `dask-cuda` [branch](https://github.com/rapidsai/dask-cuda/tree/branch-0.11)

### Former Version

#### RAPIDS 0.10 - 17 October 2019

Versions of libraries included in the `0.10` [images](#rapids-10-images):
- `cuDF` [v0.10.0](https://github.com/rapidsai/cudf/tree/v0.10.0), `cuML` [v0.10.0](https://github.com/rapidsai/cuml/tree/v0.10.0), `cuGraph` [v0.10.0](https://github.com/rapidsai/cugraph/tree/v0.10.0), `RMM` [v0.10.0](https://github.com/rapidsai/RMM/tree/v0.10.0), `cuSpatial` [v0.10.0](https://github.com/rapidsai/cuspatial/tree/v0.10.0)
- `xgboost` [branch](https://github.com/rapidsai/xgboost/tree/rapids-0.10-release), `dask-xgboost` [branch](https://github.com/rapidsai/dask-xgboost/tree/dask-cudf) `dask-cuda` [branch](https://github.com/rapidsai/dask-cuda/tree/branch-0.10)

### Image Types

The RAPIDS images are based on [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda), and are intended to be drop-in replacements for the corresponding CUDA
images in order to make it easy to add RAPIDS libraries while maintaining support for existing CUDA applications.

The RAPIDS images provided by NGC come in two types:

- `base` - contains a RAPIDS environment ready for use.<br>Use this image if you want to use RAPIDS as a part of your pipeline.
- `runtime` - extends the `base` image by adding a notebook server and example notebooks.<br>Use this image if you want to explore RAPIDS through notebooks and examples.

For images that contain the full RAPIDS source tree, pre-built with all artifacts in place, and the compiler toolchain, the debugging tools, the headers and the static libraries for RAPIDS development - as well as support for Python 3.7 - refer to the [rapidsai/rapidsai-dev](https://cloud.docker.com/u/rapidsai/repository/docker/rapidsai/rapidsai-dev) repo on DockerHub.

### Image Tag Naming Scheme

The tag naming scheme for RAPIDS images incorporates key platform details into the tag as shown below:
```
0.9-cuda9.2-runtime-ubuntu16.04
 ^       ^    ^        ^
 |       |    type     |
 |       |             |
 |       cuda version  |
 |                     |
 RAPIDS version        linux version
```

To get the latest RAPIDS version of a specific platform combination, simply exclude the RAPIDS version.  For example, to pull the latest version of RAPIDS for the `runtime` image with support for CUDA 10.1, Python 3.6, and Ubuntu 18.04, use the following tag:
```
cuda10.1-runtime-ubuntu18.04
```
For most users the latest `runtime` image will be sufficient to get started with RAPIDS.

## Prerequisites

* NVIDIA Pascal™ GPU architecture or better
* CUDA [9.2](https://developer.nvidia.com/cuda-92-download-archive) or [10.0](https://developer.nvidia.com/cuda-downloads) compatible NVIDIA driver
* Ubuntu 16.04/18.04 or CentOS 7
* Docker CE v18+
* [nvidia-docker](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)) v2+

## Usage

### Start Container and Notebook Server

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker pull rapidsai/rapidsai:cuda9.2-runtime-ubuntu16.04
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai:cuda9.2-runtime-ubuntu16.04
```
**NOTE:** This will open a shell with [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) running in the background on port 8888 on your host machine.

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker pull rapidsai/rapidsai:cuda9.2-runtime-ubuntu16.04
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai:cuda9.2-runtime-ubuntu16.04
```
**NOTE:** This will open a shell with [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) running in the background on port 8888 on your host machine.

### Use JupyterLab to Explore the Notebooks

Notebooks can be found in the following directories within the container:

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
                  rapidsai/rapidsai:cuda9.2-runtime-ubuntu16.04
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
                  rapidsai/rapidsai:cuda9.2-runtime-ubuntu16.04
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

Check out the [cuDF](https://rapidsai.github.io/projects/cudf/en/latest), [cuML](https://rapidsai.github.io/projects/cuml/en/latest), and [XGBoost](https://xgboost.readthedocs.io/en/latest/) API docs.

Learn how to setup a mult-node cuDF and XGBoost data preparation and distributed training environment by following the [mortgage data example notebook and scripts](https://github.com/rapidsai/notebooks).

## Where can I get help or file bugs/requests?

Please submit issues with the container to this GitHub repository: [https://github.com/rapidsai/docs](https://github.com/rapidsai/docs/issues/new)

For issues with RAPIDS libraries like cuDF, cuML, RMM, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids) or [Google Groups](https://groups.google.com/forum/#!forum/rapidsai).
