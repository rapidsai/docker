#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidstool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

IMAGE_TAG_NAME=""
DOCKERFILE=""

HELPTEXT="$0 -f <dockerFile> [-i <imageTagName>] [<dockerBuildArgs>]
   Creates a Docker image using ${DOCKER} and <dockerFile>, tagged with
   <imageTagName>. <dockerBuildArgs> can be provided to pass docker args as-is
   to the build command.

   If <imageTagName> is \"\" or not specified, a default image name of the form
   shown below is used.

   rapids_<username>-cuda9.2-devel-ubuntu16.04-gcc5-py3.6
                        ^      ^       ^         ^    ^
                        |      type    |         |    python version
                        |              |         |
                        cuda version   |         gcc version
                                       |
                                       linux version
"

while getopts ":hf:i:" option; do
    case "${option}" in
        h)
            echo "${HELPTEXT}"
            exit 0
            ;;
	f)
            DOCKERFILE=${OPTARG}
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

# Enforce all required conditions
ERROR=0
if [[ ${DOCKERFILE} == "" ]]; then
    echo "ERROR: <dockerFile> must be specified."
    ERROR=1
fi
if (( ${ERROR} != 0 )); then
    exit ${ERROR}
fi

if [[ ${IMAGE_TAG_NAME} == "" ]]; then
    # TODO: include any overrides specified in Docker build args, if specified.
    # TODO: provide an error message if these greps fail
    cudaVersion=$(grep "^ARG CUDA_VERSION=" ${DOCKERFILE} | cut -d'=' -f2)
    templType=$(grep "^#:# tag:type " ${DOCKERFILE} | cut -d' ' -f3)
    linuxVersion=$(grep "^ARG LINUX_VERSION=" ${DOCKERFILE} | cut -d'=' -f2)
    gccVersion=$(grep "^CXX_VERSION=" ${DOCKERFILE} | cut -d'=' -f2)
    pyVersion=$(grep "^PYTHON_VERSION=" ${DOCKERFILE} | cut -d'=' -f2)

    IMAGE_TAG_NAME="rapids_${USER}-cuda${cudaVersion}-${templType}-${linuxVersion}-gcc${gccVersion}-py${pyVersion}"
fi

LOGFILE_NAME=${LOG_DIR}/${IMAGE_TAG_NAME}_image--${TIMESTAMP}.buildlog

mkdir -p ${LOG_DIR}
(time ${DOCKER} build --tag ${IMAGE_TAG_NAME} ${buildArgs} -f ${DOCKERFILE} $(dirname ${DOCKERFILE})) 2>&1|tee ${LOGFILE_NAME}
