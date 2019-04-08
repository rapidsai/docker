# build

This repository provides tools for developers, maintainers, and general users who want to work with [RAPIDS](https://github.com/rapidsai). The goal is to support a variety of different use cases (building RAPIDS locally from source, building [Docker containers](https://www.docker.com/resources/what-container), testing, package building, building a specific RAPIDS component or branch for development, etc.) in order to minimize problems caused by environment and configuration inconsistencies, allowing users and developers to focus more on working with RAPIDS.

The goal is to support the use cases mentioned above - and possibly more - but the current versions of these tools is focused on local and container builds.


## Getting Started

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

   The scripts are generated based on the config file, and the Dockerfile is
   generated based on <templateName> and the config file.

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

listDockerTemplNames [-h|-H]
   Prints a list of valid Docker template names found in templates/docker

   Template file names must be of the form
   "templates/docker/Dockerfile_<templateName>.template", and
   <templateName> cannot contain a . or _.

   The current list of valid templates found is:
      centos7-base centos7-devel centos7-runtime ubuntu-base ubuntu-devel ubuntu-runtime
```

Edit the `config` file to customize a build with specific RAPIDS components, branches, and dependencies.

Copy and modify existing Dockerfile templates in `templates/docker` to create custom Docker images. Follow the naming convention in order for the `rapidsdevtool.sh` commands to recognize the new Dockerfile template (see the section on templates below).

## Templates and the config file

`rapidsdevtool.sh` utilizes several code generators for creating Dockerfiles and utility scripts for users that are specific to the environment they're using. The templates in the `templates` subdir, along with the `config` file are intended to be edited to customize the generated files.

To create additional Docker image types, simply create a new template in the `templates/docker` subdir named using the convention `Dockerfile_<imageName>.template`

Similar in convention to Dockerfiles, script templates are located in `templates/scripts`.

All templates have the ability to identify the following keywords when being used with the file generator:

`insertfile <fileName>` inserts `<fileName>` inline into the generated output, just like #include is treated by the C preprocessor.
   
`runcommand <command>` runs `<command>` and inserts the output of command inline into the generated output. `<command>` is typically a shell script, but can also be any command you would run in a shell, such as `ls -l`.
   Many existing templates make use of the scripts in `commands/utils` for generating output, in particular, output based on the contents of the config file.

## Extending `rapidsdevtool.sh`

`rapidsdevtool.sh` is a shell script that simplifies how users interact with the collection of underlying scripts contained in the `commands` subdir. To add functionality to `rapidsdevtool.sh`, simply add your script to the `commands` subdir, and make sure it conforms to the following minimum requirements:
* It responds to the `-h` arg by outputting a "short" help that simply shows the command and all the available options. Run `rapidsdevtool.sh -h` for an example.
* It responds to the `-H` arg by outputting the short help plus more detailed help, similar to a man page. Run `rapidsdevtool.sh -H` for an example.

All other args your script needs are passed straight through from `rapidsdevtool.sh` to your script.

Your script may access the `commands/utils` subdir which contains utilities shared by all the command scripts. See any of the existing scripts in `commands` for examples.
