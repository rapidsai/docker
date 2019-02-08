# build

This repository provides tools to build [RAPIDS](https://github.com/rapidsai). The goal is to support a variety of different use cases (building RAPIDS locally, building for [Docker containers](https://www.docker.com/resources/what-container), building a specific RAPIDS component or branch for development, etc.) in order to minimize problems caused by environment and configuration inconsistencies, allowing users and developers to focus on working with RAPIDS and not build-related problems.

RAPIDS [Docker containers](https://hub.docker.com/u/rapidsai), [conda packages](https://anaconda.org/rapidsai), PIP Python packages, nightly, and CI builds will all eventually be built the using these tools.

Currently, only Docker container build utilities are present, but more use cases will be supported in the near future.

## Getting Started

The 'buildrapids.sh' bash script is used for building RAPIDS and has the following options:
```
USAGE: ./rapidstool.sh <command> [<arg>]

Where command is one of:

buildDockerImage <imageType>
   Runs 'genDockerfile' then 'clone' prior to creating a Docker image
   for <imageType> using the generated Dockerfile in
   "/home/rapidsuser/build"

   <imageType> must be one of: centos7-base centos7-devel centos7-runtime ubuntu-base ubuntu-devel ubuntu-runtime

buildDockerImageFromFile <imageType> <dockerfile>
   Unlike 'buildDockerImage', does not run 'genDockerfile' or 'clone'
   and instead only builds a Docker image from
   <dockerfile>. <imageType> must also be specified for generating the
   tag and log file names, but does not have to be a valid imageType
   as returned by 'listImageTypes'.

clone
   Clones all RAPIDS repos using /home/rapidsuser/build/utils/clone.sh
   to /home/rapidsuser/build/rapids.

genDockerfile <imageType>
   Generate a Dockerfile for <imageType> using the corresponding
   template in /home/rapidsuser/build/docker.  The generated
   Dockerfile will be named
   "/home/rapidsuser/build/Dockerfile.<imageType>" Template names must
   be of the form
   "/home/rapidsuser/build/docker/Dockerfile_<imageType>.template",
   and <imageType> cannot contain a . or _.

   <imageType> must be one of: centos7-base centos7-devel centos7-runtime ubuntu-base ubuntu-devel ubuntu-runtime

clean <stuffToClean>
   Removes all files associaetd with <stuffToClean>.
   <stuffToClean> can be:

   dockerstuff
      Removes only the generated Dockerfile(s) and Docker build logs

   all
      Removes everything from dockerstuff plus
      /home/rapidsuser/build/rapids and /home/rapidsuser/build/logs

listImageTypes
   Prints list of valid Docker image types that can be built, which is
   currently:

   centos7-base centos7-devel centos7-runtime ubuntu-base ubuntu-devel ubuntu-runtime

   The list is based on the presence of template files in /home/rapidsuser/build/docker.
```
