#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidstool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

TEMPL_NAME=""
IMAGE_TAG_NAME=""

HELPTEXT="$0 -t <templateName> [-i <imageTagName>] [<dockerBuildArgs>]
   Creates a Docker image for <templateName>, tagged with <imageTagName>.
   <dockerBuildArgs> can be provided to pass docker args as-is to the build
   command.

   If <imageTagName> is \"\" or not specified, a default image name of the form
   shown below is used.

   rapids_<username>-cuda9.2-devel-ubuntu16.04-gcc5-py3.6
                        ^      ^       ^         ^    ^
                        |      type    |         |    python version
                        |              |         |
                        cuda version   |         gcc version
                                       |
                                       linux version

   <templateName> must be one of: ${DOCKER_TEMPL_NAMES}
"

while getopts ":ht:i:" option; do
    case "${option}" in
        h)
            echo "${HELPTEXT}"
            exit 0
            ;;
	t)
            TEMPL_NAME=${OPTARG}
	    ;;
        i)
            IMAGE_TAG_NAME=${OPTARG}
            ;;
	*)
	    echo "${HELPTEXT}"
	    exit 1
    esac
done

if (( $# == 0 )); then
    echo "${HELPTEXT}"
    exit 0
fi

# Generate the Dockerfile
GEND_DOCKERFILE=${RAPIDSDEVTOOL_DIR}/${DOCKERFILE_BASENAME}.${TEMPL_NAME}
genDockerfile.sh -t ${TEMPL_NAME} -o ${GEND_DOCKERFILE}

# Clone RAPIDS
clone.sh

# Create the Docker image
if [[ ${IMAGE_TAG_NAME} != "" ]]; then
    buildDockerImageFromFile.sh -f ${GEND_DOCKERFILE} -i ${IMAGE_TAG_NAME}
else
    buildDockerImageFromFile.sh -f ${GEND_DOCKERFILE}
fi
