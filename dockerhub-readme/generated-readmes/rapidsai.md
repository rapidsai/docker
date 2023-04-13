#  RAPIDS - Open GPU Data Science



## What is RAPIDS?

Visit [rapids.ai](https://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our prerequisites section below to ensure your system meets the minimum requirements for RAPIDS.


### Current Version - RAPIDS v23.04

Versions of libraries included in the `23.04` images:
- `cuDF` [v23.04](https://github.com/rapidsai/cudf/tree/v23.04.00), `cuML` [v23.04](https://github.com/rapidsai/cuml/tree/v23.04.00), `cuGraph` [v23.04](https://github.com/rapidsai/cugraph/tree/v23.04.00), `RMM` [v23.04](https://github.com/rapidsai/RMM/tree/v23.04.00), `RAFT` [v23.04](https://github.com/rapidsai/raft/tree/v23.04.00), `cuSpatial` [v23.04](https://github.com/rapidsai/cuspatial/tree/v23.04.00), `cuSignal` [v23.04](https://github.com/rapidsai/cusignal/tree/v23.04.00), `cuxfilter` [v23.04](https://github.com/rapidsai/cuxfilter/tree/v23.04.00), `dask-sql` [2023.4.0](https://github.com/dask-contrib/dask-sql/tree/2023.4.0)


### Image Types

The RAPIDS images are based on [nvidia/cuda](https://hub.docker.com/r/nvidia/cuda), and are intended to be drop-in replacements for the corresponding CUDA
images in order to make it easy to add RAPIDS libraries while maintaining support for existing CUDA applications.

RAPIDS images come in three types, distributed in two different repos:

This repo (rapidsai), contains the following:

- `base` - contains a RAPIDS environment ready for use.
  - **TIP: Use this image if you want to use RAPIDS as a part of your pipeline.**
- `runtime` - extends the `base` image by adding a notebook server and example notebooks.
  - **TIP: Use this image if you want to explore RAPIDS through notebooks and examples.**

The [rapidsai/rapidsai-dev](https://hub.docker.com/r/rapidsai/rapidsai-dev/tags) repo contains the following:
- `devel` - contains the full RAPIDS source tree, pre-built with all artifacts in place, and the compiler toolchain, the debugging tools, the headers and the static libraries for RAPIDS development.
  - **TIP: Use this image to develop RAPIDS from source.**

### Image Tag Naming Scheme

The tag naming scheme for RAPIDS images incorporates key platform details into the tag as shown below:
```
23.04-cuda11.8-runtime-ubuntu22.04-py3.10
 ^       ^    ^        ^         ^
 |       |    type     |         python version
 |       |             |
 |       cuda version  |
 |                     |
 RAPIDS version        linux version
```

To get the latest RAPIDS version of a specific platform combination, simply exclude the RAPIDS version. For example, to pull the latest version of RAPIDS for the `runtime` image with support for CUDA 11.8, Python 3.10, and Ubuntu 18.04, use the following tag:
```
cuda11.8-runtime-ubuntu22.04-py3.10
```

Many users do not need a specific platform combination but would like to ensure they're getting the latest version of RAPIDS, so as an additional convenience, a tag named simply `latest` is also provided which is equivalent to `cuda11.8-runtime-ubuntu22.04-py3.10`.

## Prerequisites

- NVIDIA Pascal™ GPU architecture or better
- CUDA [11.2/11.4/11.5/11.8](https://developer.nvidia.com/cuda-downloads) with a compatible NVIDIA driver
- Ubuntu 20.04/22.04 or CentOS 7 or Rocky Linux 8
- Docker CE v18+
- [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker)

## Usage

### Start Container and Notebook Server

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker pull rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker pull rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
```

### Container Ports

The following ports are used by the **`runtime` containers only** (not `base` containers):

- `8888` - exposes a [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) notebook server
- `8786` - exposes a [Dask](https://docs.dask.org/en/latest/) scheduler
- `8787` - exposes a Dask [diagnostic web server](https://docs.dask.org/en/latest/setup/cli.html#diagnostic-web-servers)

### Environment Variables

The following environment variables can be passed to the `docker run` commands:

- `DISABLE_JUPYTER` - set to `true` to disable the default Jupyter server from starting (not applicable for `base` images)
- `JUPYTER_FG` - set to `true` to start Jupyter server in foreground instead of background (not applicable for `base` images)
- `EXTRA_APT_PACKAGES` - (**Ubuntu images only**) used to install additional `apt` packages in the container. Use a space separated list of values
- `APT_TIMEOUT` - (**Ubuntu images only**) how long (in seconds) the `apt` command should wait before exiting
- `EXTRA_YUM_PACKAGES` - (**CentOS images only**) used to install additional `yum` packages in the container. Use a space separated list of values
- `YUM_TIMEOUT` - (**CentOS images only**) how long (in seconds) the `yum` command should wait before exiting
- `EXTRA_CONDA_PACKAGES` - used to install additional `conda` packages in the container. Use a space separated list of values
- `CONDA_TIMEOUT` - how long (in seconds) the `conda` command should wait before exiting
- `EXTRA_PIP_PACKAGES` - used to install additional `pip` packages in the container. Use a space separated list of values
- `PIP_TIMEOUT` - how long (in seconds) the `pip` command should wait before exiting

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
    rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
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
    rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
```

### Use JupyterLab to Explore the Notebooks

Notebooks can be found in the following directories within the 23.04 container (not applicable for `base` images):

* `/rapids/notebooks/cugraph` - cuGraph demo notebooks
* `/rapids/notebooks/cuml` - cuML demo notebooks
* `/rapids/notebooks/cusignal` - cuSignal demo notebooks
* `/rapids/notebooks/cuxfilter` - cuXfilter demo notebooks
* `/rapids/notebooks/cuspatial` - cuSpatial demo notebooks
* `/rapids/notebooks/xgboost` - XGBoost demo notebooks

For a full description of each notebook, see the [README](https://github.com/rapidsai/notebooks/blob/branch-23.04/README.md) in the notebooks repository.

### Extending RAPIDS Images

All RAPIDS images use `conda` as their package manager, and all RAPIDS packages (including source-built) are available in the `rapids` conda environment. If you want to extend RAPIDS images (such as using `FROM`), then it is important to include `source activate rapids` at the start of all `RUN` commands in your `Dockerfile`. Without this, the docker build context will not have access to the RAPIDS libraries, as it uses the `base` environment by default. Examples of this can be found in our own Dockerfiles, which can be found in the [RAPIDS Docker Repository](https://github.com/rapidsai/docker) on GitHub.

### Custom Data and Advanced Usage

You are free to modify the above steps. For example, you can launch an interactive session with your own data:

#### Preferred - Docker CE v19+ and `nvidia-container-toolkit`
```bash
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
         rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         -v /path/to/host/data:/rapids/my_data \
         rapidsai/rapidsai:23.04-cuda11.8-runtime-ubuntu22.04-py3.10
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
