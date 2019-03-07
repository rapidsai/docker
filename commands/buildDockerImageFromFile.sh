#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidsdevtool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

LOG_DIR=${RAPIDSDEVTOOL_DIR}/logs
IMAGE_TAG_NAME=""
DOCKERFILE=""

SHORTHELP="$0 [-h|-H] -f <dockerFile> -i <imageTagName> [-l <logDir>] [<dockerBuildArgs>]"
LONGHELP="${SHORTHELP}
   Creates a Docker image using ${DOCKER} and <dockerFile>, tagged with
   <imageTagName>. <dockerBuildArgs> can be provided to pass docker args as-is
   to the build command.

   If <logDir> is not specified, it defaults to ${LOG_DIR}
"

while getopts ":hHl:f:i:" option; do
    case "${option}" in
        h)
            echo "${SHORTHELP}"
            exit 0
            ;;
        H)
            echo "${LONGHELP}"
            exit 0
            ;;
	f)
            DOCKERFILE=${OPTARG}
	    ;;
        i)
            IMAGE_TAG_NAME=${OPTARG}
            ;;
	l)
	    LOG_DIR=${OPTARG}
	    ;;
	*)
	    echo "${SHORTHELP}"
	    exit 1
    esac
done

if (( $# == 0 )); then
    echo "${SHORTHELP}"
    exit 0
fi

# Enforce all required conditions
ERROR=0
if [[ ${DOCKERFILE} == "" ]]; then
    echo "ERROR: <dockerFile> must be specified."
    ERROR=1
fi
if [[ ${IMAGE_TAG_NAME} == "" ]]; then
    echo "ERROR: <imageTagName> must be specified."
    ERROR=1
fi
if (( ${ERROR} != 0 )); then
    exit ${ERROR}
fi

LOGFILE_NAME=${LOG_DIR}/${IMAGE_TAG_NAME}_image--${TIMESTAMP}.buildlog

mkdir -p ${LOG_DIR}
(time ${DOCKER} build --tag ${IMAGE_TAG_NAME} ${buildArgs} -f ${DOCKERFILE} $(dirname ${DOCKERFILE})) 2>&1|tee ${LOGFILE_NAME}
