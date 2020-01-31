# build

This repository provides tools for developers, maintainers, and general users who want to build the [RAPIDS](https://github.com/rapidsai) [Docker images](https://www.docker.com/resources/what-container).

Currently, the tools in this repo cover only bulding RAPIDS Docker images.

## Docker Image builds

The build repo currently contains all build-related scripts, utilities, and meta-data for the RAPIDS Docker image builds.  This repo may be expanded to include build utilities for other RAPIDS components (as the name implies), but for now only Docker image builds are covered.

### Image build types

There are currently three different "flavors" of Docker image builds, which follow the same conventions provided by the [NVIDIA CUDA Docker images](https://github.com/NVIDIA/nvidia-docker/wiki/CUDA), and allow users to use the RAPIDS images a drop-in replacements for their CUDA images.  Each flavor is supported on a combination of OS, Python version, and CUDA version which produces a matrix of available image types (and lots of tags!). The different flavors are described below:
  * `base`
    * Extends the corresponding CUDA image to add conda and the RAPIDS conda packages in a `rapids` conda environment
    * These images are used for running RAPIDS applications by users that do not need examples or the need to modify and/or build RAPIDS sources.
  * `runtime`
    * Extends `base` to add the RAPIDS Jupyter notebooks, all dependencies of the notebooks installed to the `rapids` environment, and runs a Jupyter server as the default Docker [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint)
    * These images are used by users primarily for running the example notebooks.
  * `devel`
    * Extends the corresponding CUDA image to add the full RAPIDS build and test toolchain (gcc, build tools, etc.) to the system and/or `rapids` environment as well as the notebooks, their dependencies, and runs a Jupyter server as the default Docker [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint)
    * These images are used by users that are primarily doing active development on RAPIDS and need to build and test their changes.

At a high-level, the differences between `base`, `runtime`, and `devel` is the way RAPIDS is installed.  `base` and `runtime` are identical in how RAPIDS is installed, with the only difference between them is that `runtime` has (many) more 3rd-party packages installed to support the notebooks.  `devel` is completely different in that RAPIDS is built from source in the container and installed into the `rapids` environment using an install command.  Because of these differences, we often refer to the images as `base/runtime` and `devel`.

### Common problems building the image types

`base/runtime` images typically have one problem that prevents them from building: the `conda install` step fails, usually due to two reasons:
* communication between the build machine and the conda server stops or is corrupted.
* the conda dependency solver - used by conda to compute a dependency tree for any given package to determine the list of packages that need to be installed - fails to solve, usually due to an incompatible specification in either the list of packages given to the conda install line, or in the dependency meta-data built-in to a conda package (defined in the package's `meta.yaml`).

`devel` images can fail for the same reasons that `base/runtime` images do, as well as:
* Failure to build RAPIDS from source.  Actual coding problems are rare since those are usually caught in the per-PR CI build checks, but build errors often occur in `devel` builds due to incompatible environments, resulting in the need to update the `rapids` environment.  Because the gpuCI Docker images used for CI checks are not the same as `devel` images, `devel` builds often have to update based on word-of-mouth or from analyzing failures.
  * Determining what neds to be updated:
  * Ideas for addressing this problem:

### Nightly jobs associated with RAPIDS Docker images

* Builds covering the "full matrix" of OS, Python version, and CUDA versions for both `base` and `runtime` images.
  * pushed to rapidsai/rapidsai-nightly
* Builds covering the "full matrix" of OS, Python version, and CUDA versions for `devel` images.
  * pushed to rapidsai/rapidsai-dev-nightly
* unit/integration test runs
* RAPIDS notebook test runs
* RAPIDS integration test runs

### RAPIDS releases and the RAPIDS Docker image builds

RAPIDS releases include the following related to RAPIDS Docker images:
* builds of `base`, `runtime`, and `devel` images _using the latest master branch of the build repo_, pushed to rapidsai/rapidsai (`base/runtime`), rapidsai/rapidsai-dev (`devel`), and NGC (specific `base/runtime` images)
* updated READMEs for DockerHub and NGC
* updated documentation for the RAPIDS website

### build tools in the `build` repo

#### `rapidsdevtool.sh`
The `rapidsdevtool.sh` bash script has the following options:
```
USAGE:
   rapidsdevtool.sh [-h|-H] <command> [<arg> ...]

 -h   print brief help
 -H   print detailed help

 command is one of:

buildDockerImage [-h|-H] [-d] -t <templateName> [-i <imageTagName>] [<dockerBuildArgs>]
   This command automates the following:
      (setting up a unique build dir)
      (copying the 'supportfiles' dir)
      (copying the developer 'utils' dir)
      genDockerfile
      genBuildScript
      genCloneScript
      (running the generated clone script)
      buildDockerImageFromFile

   The scripts are generated based on the repoSettings file, and the Dockerfile is
   generated based on <templateName> and the dockerArgs file.

   If <imageTagName> is "" or not specified, a default image name of the form
   shown below is used.

   rapids_<username>-cuda10.0-devel-ubuntu16.04-gcc5-py3.6
                        ^       ^       ^         ^    ^
                        |       type    |         |    python version
                        |               |         |
                        cuda version    |         gcc version
                                        |
                                        linux version

   <dockerBuildArgs> can be provided to pass docker args as-is to the build
   command.

buildDockerImageFromFile [-h|-H] -f <dockerFile> -i <imageTagName> [-l <logDir>] [<dockerBuildArgs>]
   Creates a Docker image using nvidia-docker and <dockerFile>, tagged with
   <imageTagName>. <dockerBuildArgs> can be provided to pass docker args as-is
   to the build command.

   If <logDir> is not specified, it defaults to logs

genBuildScript [-h|-H] [-o <outputFileName>]
   Generate a script to build the RAPIDS components specified in
   repoSettings

   Use -o <outputFileName> to specify the name of the generated build script,
   but if not specified, the default generated build script will be named
   "build.sh"

genCloneScript [-h|-H] [-o <outputFileName>]
   Generate a script to clone RAPIDS components as specified in
   repoSettings

   Use -o <outputFileName> to specify the name of the generated clone script,
   but if not specified, the default generated clone script will be named
   "clone.sh"

genDockerfile [-h|-H] -t <templateName> [-o <outputFileName>]
   Generate a Dockerfile from a template. The template must be specified using
   -t <templateName> to refer to templates in templates/docker. Template
   file names must be of the form
   "templates/docker/Dockerfile_<templateName>.template", and
   <templateName> cannot contain a . or _.

   Currently, <templateName> must be one of: centos7-base centos7-devel centos7-runtime ubuntu-base ubuntu-devel ubuntu-runtime

   Use -o <outputFileName> to specify the name of the generated Dockerfile, but
   if not specified, the default generated Dockerfile will be placed in
   . and named after <templateName>

listDockerTemplNames [-h|-H]
   Prints a list of valid Docker template names found in templates/docker

   Template file names must be of the form
   "templates/docker/Dockerfile_<templateName>.template", and
   <templateName> cannot contain a . or _.

   The current list of valid templates found is:
      centos7-base centos7-devel centos7-runtime ubuntu-base ubuntu-devel ubuntu-runtime
```

Edit the `repoSettings` and `dockerArgs` files to customize a build with specific RAPIDS components, branches, and dependencies.

Copy and modify existing Dockerfile templates in `templates/docker` to create custom Docker images. Follow the naming convention in order for the `rapidsdevtool.sh` commands to recognize the new Dockerfile template (see the section on templates below).

## Templates and the repoSettings and dockerArgs files

`rapidsdevtool.sh` utilizes several code generators for creating Dockerfiles and utility scripts for users that are specific to the environment they're using. The templates in the `templates` subdir, along with the `repoSettings` and `dockerArgs` files are intended to be edited to customize the generated files.

To create additional Docker image types, simply create a new template in the `templates/docker` subdir named using the convention `Dockerfile_<imageName>.template`

Similar in convention to Dockerfiles, script templates are located in `templates/scripts`.

All templates have the ability to identify the following keywords when being used with the file generator:

`insertfile <fileName>` inserts `<fileName>` inline into the generated output, just like #include is treated by the C preprocessor.

`runcommand <command>` runs `<command>` and inserts the output of command inline into the generated output. `<command>` is typically a shell script, but can also be any command you would run in a shell, such as `ls -l`.
   Many existing templates make use of the scripts in `commands/utils` for generating output, in particular, output based on the contents of the `repoSettings` file.

## Extending `rapidsdevtool.sh`

`rapidsdevtool.sh` is a shell script that simplifies how users interact with the collection of underlying scripts contained in the `commands` subdir. To add functionality to `rapidsdevtool.sh`, simply add your script to the `commands` subdir, and make sure it conforms to the following minimum requirements:
* It responds to the `-h` arg by outputting a "short" help that simply shows the command and all the available options. Run `rapidsdevtool.sh -h` for an example.
* It responds to the `-H` arg by outputting the short help plus more detailed help, similar to a man page. Run `rapidsdevtool.sh -H` for an example.

All other args your script needs are passed straight through from `rapidsdevtool.sh` to your script.

Your script may access the `commands/utils` subdir which contains utilities shared by all the command scripts. See any of the existing scripts in `commands` for examples.
