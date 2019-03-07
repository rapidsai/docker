# build

This repository provides tools for developers, maintainers, and general users who want to work with [RAPIDS](https://github.com/rapidsai). The goal is to support a variety of different use cases (building RAPIDS locally from source, building [Docker containers](https://www.docker.com/resources/what-container, testing, package building, building a specific RAPIDS component or branch for development, etc.) in order to minimize problems caused by environment and configuration inconsistencies, allowing users and developers to focus more on working with RAPIDS.

The goal is to support the use cases mentioned above - and possibly more - but the current versions of these tools is focused on local and container builds.


## Getting Started

The 'rapidsdevtool.sh' bash script has the following options:
```
USAGE:
   rapidsdevtool.sh [-h|-H] <command> [<arg> ...]

 -h   print brief help
 -H   print detailed help

 command is one of:

buildDockerImage [-h|-H] [-d] -t <templateName> [-i <imageTagName>] [<dockerBuildArgs>]
   This command automates the following:
      (setting up a unique build dir)
      genDockerfile
      genCloneScript
      (running the generated clone script)
      genBuildScript
      (copying the developer 'utils' dir)
      buildDockerImageFromFile

   The scripts are generated based on the config file, and the Dockerfile is
   generated based on <templateName> and the config file.

   If <imageTagName> is "" or not specified, a default image name of the form
   shown below is used.

   rapids_<username>-cuda9.2-devel-ubuntu16.04-gcc5-py3.6
                        ^      ^       ^         ^    ^
                        |      type    |         |    python version
                        |              |         |
                        cuda version   |         gcc version
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
   config

   Use -o <outputFileName> to specify the name of the generated build script,
   but if not specified, the default generated build script will be named
   "build.sh"

genCloneScript [-h|-H] [-o <outputFileName>]
   Generate a script to clone RAPIDS components as specified in
   config

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
```
