#  RAPIDS - Open GPU Data Science



## What is RAPIDS?

Visit [rapids.ai](https://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.


### Current Version - RAPIDS v0.18

Versions of libraries included in the `0.18` images:
- `cuDF` [v0.18](https://github.com/rapidsai/cudf/tree/v0.18.0), `cuML` [v0.18](https://github.com/rapidsai/cuml/tree/v0.18.0), `cuGraph` [v0.18](https://github.com/rapidsai/cugraph/tree/v0.18.0), `RMM` [v0.18](https://github.com/rapidsai/RMM/tree/v0.18.0), `cuSpatial` [v0.18](https://github.com/rapidsai/cuspatial/tree/v0.18.0), `cuSignal` [v0.18](https://github.com/rapidsai/cusignal/tree/v0.18.0), `cuxfilter` [v0.18](https://github.com/rapidsai/cuxfilter/tree/v0.18.0), `blazingsql` [v0.18](https://github.com/BlazingDB/blazingsql/tree/v0.18.0)


### Image Types

The RAPIDS images are based on [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda), and are intended to be drop-in replacements for the corresponding CUDA
images in order to make it easy to add RAPIDS libraries while maintaining support for existing CUDA applications.

The RAPIDS images provided by NGC come in two types:
- `base` - contains a RAPIDS environment ready for use.
  - **TIP: Use this image if you want to use RAPIDS as a part of your pipeline.**
- `runtime` - extends the `base` image by adding a notebook server and example notebooks.
  - **TIP: Use this image if you want to explore RAPIDS through notebooks and examples.**

For `base` and `runtime` images with Python 3.8 support or additional OS support (Ubuntu 16.04/20.04 & CentOS 8), refer to our [rapidsai/rapidsai-core](https://hub.docker.com/r/rapidsai/rapidsai-core) repo on DockerHub.

For `devel` images that contain: the full RAPIDS source tree, pre-built with all artifacts in place, the compiler toolchain, the debugging tools, the headers and the static libraries for RAPIDS development refer to the [rapidsai/rapidsai-dev](https://hub.docker.com/repository/docker/rapidsai/rapidsai-dev) repo on DockerHub.

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

To get the latest RAPIDS version of a specific platform combination, simply exclude the RAPIDS version. For example, to pull the latest version of RAPIDS for the `runtime` image with support for CUDA 10.1, Python 3.7, and Ubuntu 18.04, use the following tag:
```
cuda10.1-runtime-ubuntu18.04-py3.7
```

Many users do not need a specific platform combination but would like to ensure they're getting the latest version of RAPIDS, so as an additional convenience, a tag named simply `latest` is also provided which is equivalent to `cuda10.1-runtime-ubuntu16.04-py3.7`.

## Prerequisites

- NVIDIA Pascal™ GPU architecture or better
- CUDA [10.1/10.2/11.0/11.2](https://developer.nvidia.com/cuda-downloads) with a compatible NVIDIA driver
- Ubuntu 18.04/20.04 or CentOS 7/8
- Docker CE v18+
- [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker)

## Usage

### Start Container and Notebook Server

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker pull nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker pull nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
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
    nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
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
    nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
```

### Use JupyterLab to Explore the Notebooks

Notebooks can be found in the following directories within the 0.18 container (not applicable for `base` images):

* `/rapids/notebooks/clx` - CLX demo notebooks
* `/rapids/notebooks/cugraph` - cuGraph demo notebooks
* `/rapids/notebooks/cuml` - cuML demo notebooks
* `/rapids/notebooks/cusignal` - cuSignal demo notebooks
* `/rapids/notebooks/cuxfilter` - cuXfilter demo notebooks
* `/rapids/notebooks/xgboost` - XGBoost demo notebooks

For a full description of each notebook, see the [README](https://github.com/rapidsai/notebooks/blob/branch-0.18/README.md) in the notebooks repository.

### Custom Data and Advanced Usage

You are free to modify the above steps. For example, you can launch an interactive session with your own data:

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
                  nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
                  nvcr.io/nvidia/rapidsai/rapidsai:0.18-cuda10.1-runtime-ubuntu18.04-py3.7
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
Check out the RAPIDS [documentation](http://rapids.ai/start.html) for more detailed information and a RAPIDS [cheat sheet](https://rapids.ai/assets/files/cheatsheet.pdf).

## More Information

Check out the [RAPIDS](https://docs.rapids.ai/api) and [XGBoost](https://xgboost.readthedocs.io/en/latest/) API docs.

Learn how to setup a multi-node cuDF and XGBoost data preparation and distributed training environment by following the [mortgage data example notebook and scripts](https://github.com/rapidsai/notebooks).

## Where can I get help or file bugs/requests?

Please submit issues with the container to this GitHub repository: [https://github.com/rapidsai/docker](https://github.com/rapidsai/docker/issues/new)

For issues with RAPIDS libraries like cuDF, cuML, RMM, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids) or [Google Groups](https://groups.google.com/forum/#!forum/rapidsai).

# License

By pulling and using the container, you accept the terms and conditions of this [End User License Agreement](https://developer.download.nvidia.com/licenses/NVIDIA_Deep_Learning_Container_License.pdf).
