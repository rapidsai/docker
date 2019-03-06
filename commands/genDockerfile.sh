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
TEMPL_FILE_NAME=""
OUTPUT_FILE_NAME=""

GENDOCKERFILE_HELPTEXT="$0 -t <templateName> [-o <outputFileName>]

   Generate a Dockerfile from a template. The template must be specified using
   -t <templateName> to refer to templates in ${DOCKER_TEMPL_DIR}. Template
   file names must be of the form
   \"${DOCKER_TEMPL_DIR}/Dockerfile_<templateName>.template\", and
   <templateName> cannot contain a . or _.

   Currently, <templateName> must be one of: ${DOCKER_TEMPL_NAMES}

   Use -o <outputFileName> to specify the name of the generated Dockerfile, but
   if not specified, the default generated Dockerfile will be named
   \"${RAPIDSAI_DIR}/Dockerfile.<templateName>\"
"

while getopts ":ht:o:" option; do
    case "${option}" in
        h)
            echo "${HELPTEXT}"
            exit 0
            ;;
	t)
            TEMPL_NAME=${OPTARG}
	    ;;
        o)
            OUTPUT_FILE_NAME=${OPTARG}
            ;;
	*)
	    echo "${HELPTEXT}"
	    exit 1
    esac
done

# FIXME: Add backwards-compat: support genDockerfile.sh <templateName> usage

# Enforce all required conditions
ERROR=0
if (( ${DOCKER_TEMPL_DIR_EXISTS} == 0 )); then
    echo "ERROR: ${DOCKER_TEMPL_DIR} directory doesn't exist, valid template names can't be determined."
    ERROR=1
fi
# if [ ! -r ${CONFIG_FILE_NAME} ]; then
#     echo "ERROR: ${CONFIG_FILE_NAME} is not a readable file."
#     ERROR=1
# fi
if [[ ${TEMPL_NAME} == "" ]]; then
    echo "ERROR: <templateName> must be specified."
    ERROR=1
else
    valid=0
    for templName in ${DOCKER_TEMPL_NAMES}; do
        if [[ ${TEMPL_NAME} == ${templName} ]]; then
            valid=1
            break
        fi
    done
    if (( ${valid} == 0 )); then
        echo "ERROR: invalid template name '${TEMPL_NAME}', must be one of: ${DOCKER_TEMPL_NAMES}."
        ERROR=1
    fi
fi
if (( ${ERROR} != 0 )); then
    exit ${ERROR}
fi

if [[ ${OUTPUT_FILE_NAME} == "" ]]; then
    OUTPUT_FILE_NAME=${RAPIDSDEVTOOL_DIR}/${DOCKERFILE_BASENAME}.${TEMPL_NAME}
fi

# Safe to assume this exists if a valid templ name was given.
TEMPL_FILE_NAME=${DOCKER_TEMPL_DIR}/${DOCKERFILE_BASENAME}_${TEMPL_NAME}.template

${COMMANDSUTILS_DIR}/genfile.sh -d ${TEMPL_FILE_NAME} > ${OUTPUT_FILE_NAME}
