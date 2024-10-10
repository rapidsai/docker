#  RAPIDS - Open GPU Data Science

## What is RAPIDS?

Visit [rapids.ai](https://rapids.ai) for more information.

The RAPIDS suite of software libraries gives you the freedom to execute end-to-end data science and analytics pipelines entirely on GPUs. It relies on NVIDIA® CUDA® primitives for low-level compute optimization, but exposes GPU parallelism and high-bandwidth memory speed through user-friendly Python interfaces.

**NOTE:** Review our [system requirements](https://docs.rapids.ai/install#system-req) to ensure you have a compatible system!


### Current Version - RAPIDS v24.10

RAPIDS Libraries included in the images:
- `cuDF`
- `cuML`
- `cuGraph`
- `cuVS`
- `RMM`
- `RAFT`
- `cuSpatial`
- `cuxfilter`
- `cuCIM`
- `xgboost`


### Image Types

The RAPIDS images are based on [`nvidia/cuda`](https://hub.docker.com/r/nvidia/cuda) and [`rapidsai/miniforge-cuda`](https://hub.docker.com/r/rapidsai/miniforge-cuda). The RAPIDS images provide `amd64` & `arm64` architectures [where supported](https://docs.rapids.ai/install#system-req).


There are two types:
- `rapidsai/base` - contains a RAPIDS environment ready for use.
  - **TIP: Use this image if you want to use RAPIDS as a part of your pipeline.**
- `rapidsai/notebooks` - extends the `rapidsai/base` image by adding a [`jupyterlab` server](https://jupyter.org/), example notebooks, and dependencies.
  - **TIP: Use this image if you want to explore RAPIDS through notebooks and examples.**

### Image Tag Naming Scheme

The tag naming scheme for RAPIDS images incorporates key platform details into the tag as shown below:
```
24.10-cuda12.5-py3.12
 ^        ^      ^
 |        |      Python version
 |        |
 |        CUDA version
 |
 RAPIDS version
```

**Note: Nightly builds of the images have the RAPIDS version appended with an `a` (ie `24.10a-cuda12.5-py3.12`)**

## Usage

The `rapidsai/base` image starts with an [`ipython` shell](https://ipython.org/) by default.

The `rapidsai/notebooks` image starts with the [JupyterLab notebook server](https://jupyter.org/) by default.

### Container Ports

`rapidsai/notebooks` exposes port `8888` for the [JupyterLab notebook server](https://jupyter.org/).

### Environment Variables

The following environment variables can be passed to the `docker run` commands:

- `EXTRA_CONDA_PACKAGES` - used to install additional `conda` packages in the container. Use a space separated list of values
- `CONDA_TIMEOUT` - how long (in seconds) the `conda` command should wait before exiting
- `EXTRA_PIP_PACKAGES` - used to install additional `pip` packages in the container. Use a space separated list of values
- `PIP_TIMEOUT` - how long (in seconds) the `pip` command should wait before exiting

Example:

```sh
$ docker run \
    --rm \
    -it \
    --pull always \
    --gpus all \
    -shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
    -e EXTRA_CONDA_PACKAGES="jq" \
    -e EXTRA_PIP_PACKAGES="beautifulsoup4" \
    -p 8888:8888 \
    rapidsai/notebooks:24.10-cuda12.5-py3.12
```

### Bind Mounts

Mounting files/folders to the locations specified below provide additional functionality for the images.

- `/home/rapids/environment.yml` - a YAML file that contains a list of dependencies that will be installed by `conda`. The file should look like:

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
    --pull always \
    --gpus all \
    -shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
    -v $(pwd)/environment.yml:/home/rapids/environment.yml \
    rapidsai/base:24.10-cuda12.5-py3.12
```

### Use JupyterLab to Explore the Notebooks

The `rapidsai/notebooks` container has notebooks for the RAPIDS libraries in `/home/rapids/notebooks`.

### Extending RAPIDS Images

All RAPIDS images use `conda` as their package manager, and all RAPIDS packages are available in the `base` conda environment. These image run as the `rapids` user.

### Access Documentation within Notebooks

You can check the documentation for RAPIDS APIs inside the JupyterLab notebook using a `?` command, like this:
```
[1] ?cudf.read_csv
```
This prints the function signature and its usage documentation. If this is not enough, you can see the full code for the function using `??`:
```
[1] ??cudf.read_csv
```
Check out the RAPIDS [documentation](https://docs.rapids.ai/) for more detailed information.

## More Information

Check out the [RAPIDS User Guides](https://docs.rapids.ai/user-guide) and [XGBoost](https://xgboost.readthedocs.io/en/latest/) API docs.

## Where can I get help or file bugs/requests?

Please submit issues with the container to this GitHub repository: [https://github.com/rapidsai/docker](https://github.com/rapidsai/docker/issues/new)

For issues with RAPIDS libraries like cuDF, cuML, RMM, or others file an issue in the related GitHub project.

Additional help can be found on [Stack Overflow](https://stackoverflow.com/tags/rapids).
