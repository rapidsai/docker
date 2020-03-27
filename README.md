# build

This repository contains the source files for [rapidsai Docker images](https://hub.docker.com/u/rapidsai)

## Image types

There are currently three different types of Docker images, which follow the same conventions provided by the [NVIDIA CUDA Docker images](https://github.com/NVIDIA/nvidia-docker/wiki/CUDA), and allow users to use the RAPIDS images a drop-in replacements for their CUDA images.  Each type is supported on a combination of OS, Python version, and CUDA version which produces a matrix of available image types (and lots of tags!). The different types are described below:

Image Type | Description | Target Audience
---|---|---
`base` | Extends the corresponding CUDA image to add conda and the RAPIDS conda packages in a `rapids` conda environment | Users that do not need examples or the need to modify and/or build RAPIDS sources
`runtime` | Extends the `base` image to add the RAPIDS Jupyter notebooks, all dependencies of the notebooks installed to the `rapids` conda environment, and runs a Jupyter server as the default Docker `ENTRYPOINT` | Users interested in exploring the example notebooks
`devel` | Extends the corresponding CUDA image to add the full RAPIDS build and test toolchain (gcc, build tools, etc.) to the system and/or `rapids` environment as well as the notebooks, their dependencies, and runs a Jupyter server as the default Docker `ENTRYPOINT` | Users that are doing active development on RAPIDS and need to build and test their changes

At a high-level, the differences between `base`, `runtime`, and `devel` is the way RAPIDS is installed.  `base` and `runtime` are identical in how RAPIDS is installed, with the only difference between them is that `runtime` has (many) more 3rd-party packages installed to support the notebooks.  `devel` is completely different in that RAPIDS is built from source in the container and installed into the `rapids` environment using an install command.  Because of these differences, we often refer to the images as `base/runtime` and `devel`.


## Miscellaneous Docs

- [add-repo.md](add-repo.md) - instructions on how to add a new repository to `devel` images
- [tooling.md](tooling.md) - includes a description of the tooling used in this repository
- [common-build-problems.md](common-build-problems.md) - includes a description of potential build issues users may face
