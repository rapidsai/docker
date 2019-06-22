#!/bin/bash

# Copyright (c) 2019, NVIDIA CORPORATION.

set -e
set -o pipefail

# Assume this script is in a subdir of the dir containing rapidsdevtool.sh
THISDIR=$(cd $(dirname $0); pwd)
RAPIDSDEVTOOL_DIR=${THISDIR}/..

source ${THISDIR}/utils/common.sh

LOG_DIR=${RAPIDSDEVTOOL_DIR}/logs
IMAGE_TAG_NAME=""
DOCKERFILE=""
TARGET_STAGE_NAME=""

SHORTHELP="$0 [-h|-H] -f <dockerFile> -r <targetStageName> -i <imageTagName> [-l <logDir>] [<dockerBuildArgs>]"
LONGHELP="${SHORTHELP}
   Creates a Docker image using ${DOCKER} and <dockerFile>, tagged with
   <imageTagName>, stopping at <targetStageName>. <dockerBuildArgs> can
   be provided to pass docker args as-is to the build command.

   If <logDir> is not specified, it defaults to ${LOG_DIR}
"

while getopts ":hHl:f:r:i:" option; do
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
	r)
            TARGET_STAGE_NAME=${OPTARG}
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
if [[ ${TARGET_STAGE_NAME} == "" ]]; then
    echo "ERROR: <targetStageName> must be specified."
    ERROR=1
fi
if (( ${ERROR} != 0 )); then
    exit ${ERROR}
fi

LOGFILE_NAME=${LOG_DIR}/${IMAGE_TAG_NAME}_image--${TIMESTAMP}.buildlog

mkdir -p ${LOG_DIR}
(time ${DOCKER} build --target ${TARGET_STAGE_NAME} --tag ${IMAGE_TAG_NAME} ${buildArgs} -f ${DOCKERFILE} $(dirname ${DOCKERFILE})) 2>&1|tee ${LOGFILE_NAME}
