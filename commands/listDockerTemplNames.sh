#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidstool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

SHORTHELP="$0 [-h|-H]"
LONGHELP="${SHORTHELP}
   Prints a list of valid Docker template names found in ${DOCKER_TEMPL_DIR}

   Template file names must be of the form
   \"${DOCKER_TEMPL_DIR}/Dockerfile_<templateName>.template\", and
   <templateName> cannot contain a . or _.

   The current list of valid templates found is:
      ${DOCKER_TEMPL_NAMES}
"

while getopts ":hH" option; do
    case "${option}" in
        h)
            echo "${SHORTHELP}"
            exit 0
            ;;
        H)
            echo "${LONGHELP}"
            exit 0
            ;;
    esac
done

if (( ${DOCKER_TEMPL_DIR_EXISTS} == 1 )); then
    for templName in ${DOCKER_TEMPL_NAMES}; do
	echo ${templName}
    done
    exit 0
else
    # DOCKER_TEMPL_NAMES should contain an error msg if templates DNE
    echo ${DOCKER_TEMPL_NAMES}
    exit 1
fi
