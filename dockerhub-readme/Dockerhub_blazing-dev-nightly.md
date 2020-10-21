# [NIGHTLY] BlazingSQL - GPU accelerated, SQL engine built on the RAPIDS ecosystem

**IMPORTANT:** For the latest stable release please use the [rapidsai/blazingsql-dev](https://hub.docker.com/r/rapidsai/blazingsql-dev) containers.

## What is BlazingSQL?

Visit [https://blazingsql.com/](https://blazingsql.com/) for more information.

BlazingSQL is a SQL interface for cuDF, with various features to support large scale data science workflows and enterprise datasets.
- **Query Data Stored Externally** - a single line of code can register remote storage solutions, such as Amazon S3.
- **Simple SQL** - incredibly easy to use, run a SQL query and the results are GPU DataFrames (GDFs).
- **Interoperable** - GDFs are immediately accessible to any [RAPIDS](htts://github.com/rapidsai) library for data science workloads.

**NOTE:** Review the [prerequisites](#prerequisites) section to ensure your system meets the minimum requirements for RAPIDS.

## What are BlazingSQL NIGHTLY "dev" images?

The `rapidsai/blazingsql-dev-nightly` images are an extension of the `rapidsai/rapidsai-dev-nightly` images that also include the latest developments from the [BlazingSQL](https://blazingsql.com/) project. Because `rapidsai/blazingsql-dev-nightly` images extend the official RAPIDS images, all of the RAPIDS libraries are also available in the `rapidsai/blazingsql-dev-nightly` images.

### Image Tag Naming Scheme

The tag naming scheme for BlazingSQL images incorporates key platform details into the tag as shown below:
```
0.17-cuda10.1-devel-ubuntu18.04-py3.7
 ^       ^    ^        ^         ^
 |       |    type     |         python version
 |       |             |
 |       cuda version  |
 |                     |
 BlazingSQL branch     linux version
```

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
$ docker pull rapidsai/blazingsql-dev-nightly:0.17-cuda10.1-devel-ubuntu18.04-py3.7
$ docker run --gpus all --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/blazingsql-dev-nightly:0.17-cuda10.1-devel-ubuntu18.04-py3.7
```

#### Legacy - Docker CE v18 and `nvidia-docker2`
```bash
$ docker pull rapidsai/blazingsql-dev-nightly:0.17-cuda10.1-devel-ubuntu18.04-py3.7
$ docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
         rapidsai/blazingsql-dev-nightly:0.17-cuda10.1-devel-ubuntu18.04-py3.7
```

### Container Ports

The following ports are used by the `devel` containers:

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
    rapidsai/blazingsql-dev-nightly:0.17-cuda10.1-devel-ubuntu18.04-py3.7
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
    -p 8888:8888 \
    -p 8787:8787 \
    -p 8786:8786 \
    rapidsai/blazingsql-dev-nightly:0.17-cuda10.1-devel-ubuntu18.04-py3.7
```

## Where can I get help or file bugs/requests?

Please submit issues with the container to this GitHub repository: [https://github.com/rapidsai/docker](https://github.com/rapidsai/docker/issues/new)

For issues with BlazingSQL or RAPIDS libraries like cuDF, cuML, RMM, or others file an issue in the related GitHub project.