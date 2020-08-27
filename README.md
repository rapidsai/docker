# <div align="left"><img src="https://rapids.ai/assets/images/rapids_logo.png" width="90px"/>&nbsp;docker

This repository contains the source files for [rapidsai Docker images](https://hub.docker.com/u/rapidsai)

## Table of Contents

- [Image Types](#Image-Types)
- [Extending Images](#Extending-Images)
- [Building Images](#Building-Images)
- [Contributing](#Contributing)

## Image Types

There are currently three different types of Docker images, which follow the same conventions provided by the [NVIDIA CUDA Docker images](https://github.com/NVIDIA/nvidia-docker/wiki/CUDA), and allow users to use the RAPIDS images a drop-in replacements for their CUDA images.  Each type is supported on a combination of OS, Python version, and CUDA version which produces a variety of available image types. The different types are described below:

Type | Description | Target Audience
---|---|---
`base` | Extends the corresponding CUDA image to add conda and the RAPIDS conda packages in a `rapids` conda environment | Users that do not need examples or the need to modify and/or build RAPIDS sources
`runtime` | Extends the `base` image to add the RAPIDS Jupyter notebooks, all dependencies of the notebooks installed to the `rapids` conda environment, and runs a Jupyter server as the default Docker `ENTRYPOINT` | Users interested in exploring the example notebooks
`devel` | Extends the corresponding CUDA image to add the full RAPIDS build and test toolchain (gcc, build tools, etc.) to the system and/or `rapids` environment as well as the notebooks, their dependencies, and runs a Jupyter server as the default Docker `ENTRYPOINT` | Users that are doing active development on RAPIDS and need to build and test their changes

At a high-level, the differences between `base`, `runtime`, and `devel` is the way RAPIDS is installed.  `base` and `runtime` are identical in how RAPIDS is installed, with the only difference between them is that `runtime` has (many) more 3rd-party packages installed to support the notebooks.  `devel` is completely different in that RAPIDS is built from source in the container and installed into the `rapids` environment using an install command.  Because of these differences, we often refer to the images as `base & runtime` and `devel`.

### Image Locations

RAPIDS releases both stable and nightly images in the following repositories. `stable` releases match our `conda` stable version releases. While our `nightly` releases are generated every night from the latest WIP development branch. Below is a table of their repositories and tag lists:

Type | `stable` Repository | `nightly` Repository
--- | --- | ---
`base` | [`rapidsai/rapidsai`](https://hub.docker.com/r/rapidsai/rapidsai/tags?page=1&name=base) | [`rapidsai/rapidsai-nightly`](https://hub.docker.com/r/rapidsai/rapidsai-nightly/tags?page=1&name=base)
`runtime` | [`rapidsai/rapidsai`](https://hub.docker.com/r/rapidsai/rapidsai/tags?page=1&name=runtime) | [`rapidsai/rapidsai-nightly`](https://hub.docker.com/r/rapidsai/rapidsai-nightly/tags?page=1&name=runtime)
`devel` | [`rapidsai/rapidsai-dev`](https://hub.docker.com/r/rapidsai/rapidsai-dev/tags) | [`rapidsai/rapidsai-dev-nightly`](https://hub.docker.com/r/rapidsai/rapidsai-dev-nightly/tags)

## Extending Images

Like any Docker image, the RAPIDS images can be extended to suit the needs of individual teams. Whether it is to add custom libraries, change security settings, or other customizations; using `FROM` and our RAPIDS images allows users to customize the container, but easily update to the latest versions with a new `docker build`.

### Custom Token Example

For example, the `runtime` and `devel` images use an empty token for securing the Jupyter notebook server. While this is a fast easy solution for dev and exploratory environments, those in production environments may need more security. 

Using the following short `Dockerfile` users can leverage the existing RAPIDS images and build a custom secure image:

```docker
FROM rapidsai/rapidsai-nightly:cuda10.2-runtime-ubuntu18.04-py3.7
RUN sed -i "s/NotebookApp.token=''/NotebookApp.token='secure-token-here'/g" /rapids/utils/start_jupyter.sh
```

Once built, the resulting image will be secured with the new token. 

This example can be repurposed by replacing the `sed` command with other commands for custom libraries or settings.

## Building Images

The Dockerfiles can be built from the root project directory with the following command:

```sh
docker build -f generated-dockerfiles/ubuntu18.04-base.Dockerfile context/
```

If no build arguments are specified, the image will be built with the OS specified in the file name (i.e. `ubuntu18.04` or `centos7`) and the default _Python_ and _CUDA_ versions specified in [settings.yaml](settings.yaml).

You can override these defaults by specifying Docker build arguments:

```sh
docker build --build-arg CUDA_VER=10.2 --build-arg PYTHON_VER=3.7 -f generated-dockerfiles/centos7-base.Dockerfile context/
```

The _Ubuntu_ images can take an additional `LINUX_VER` build argument to use other supported Ubuntu versions:

```sh
docker build --build-arg CUDA_VER=10.2 --build-arg PYTHON_VER=3.7 --build-arg LINUX_VER=ubuntu16.04 -f generated-dockerfiles/ubuntu18.04-base.Dockerfile context/
```

## Contributing

Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for details on how to contribute to this repo.
