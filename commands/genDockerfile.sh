#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidstool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

DEBUGFLAG=""
TEMPL_NAME=""
TEMPL_FILE_NAME=""
DOCKER_TEMPL_DIR_EXISTS=1

# Figure out the valid template names based on the templates present in
# DOCKER_TEMPL_DIR.
# Template names must be of the form Dockerfile_<templateName>.template, and
# <templateName> cannot contain a . or _.
DOCKER_TEMPL_NAMES=""
if [ -d ${DOCKER_TEMPL_DIR} ]; then
    for templateFile in ${DOCKER_TEMPL_DIR}/*.template; do
	if [ -e $templateFile ]; then
	    templateName=${templateFile##*_} # remove everything up to and including last _
	    templateName=${templateName%%\.*} # remove everything after and including last .
            DOCKER_TEMPL_NAMES+="${templateName} "
	fi
    done
else
    DOCKER_TEMPL_DIR_EXISTS=0
    DOCKER_TEMPL_NAMES="<ERROR: ${DOCKER_TEMPL_DIR} directory doesn't exist, valid template names can't be determined!>"
fi

SHORTHELP="$0 [-h|-H] -t <templateName> [-o <outputFileName>]"
LONGHELP="${SHORTHELP}
   Generate a Dockerfile from a template. The template must be specified using
   -t <templateName> to refer to templates in ${DOCKER_TEMPL_DIR}. Template
   file names must be of the form
   \"${DOCKER_TEMPL_DIR}/Dockerfile_<templateName>.template\", and
   <templateName> cannot contain a . or _.

   Currently, <templateName> must be one of: ${DOCKER_TEMPL_NAMES}

   Use -o <outputFileName> to specify the name of the generated Dockerfile, but
   if not specified, the default generated Dockerfile will be placed in
   ${RAPIDSDEVTOOL_DIR} and named after <templateName>
"

while getopts ":hHdt:o:" option; do
    case "${option}" in
        h)
            echo "${SHORTHELP}"
            exit 0
            ;;
        H)
            echo "${LONGHELP}"
            exit 0
            ;;
        d)
            DEBUGFLAG=-d
            ;;
	t)
            TEMPL_NAME=${OPTARG}
	    ;;
        o)
            OUTPUT_FILE_NAME=${OPTARG}
            ;;
	*)
	    echo "${SHORTHELP}"
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

# Safe to assume this exists if a valid templ name was given.
TEMPL_FILE_NAME=${DOCKER_TEMPL_DIR}/${DOCKERFILE_BASENAME}_${TEMPL_NAME}.template

# TODO: check that OUTPUT_FILE_NAME can be written
OUTPUT_FILE_NAME=${RAPIDSDEVTOOL_DIR}/${DOCKERFILE_BASENAME}.${TEMPL_NAME}
${COMMANDSUTILS_DIR}/genfile.sh ${DEBUGFLAG} ${TEMPL_FILE_NAME} > ${OUTPUT_FILE_NAME}
