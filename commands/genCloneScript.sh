#!/bin/bash

# Copyright (c) 2019, NVIDIA CORPORATION.

set -e

# Assume this script is in a subdir of the dir containing rapidstool.sh
THISDIR=$(cd $(dirname $0); pwd)
RAPIDSDEVTOOL_DIR=${THISDIR}/..

source ${THISDIR}/utils/common.sh

DEBUGFLAG=""
TEMPL_FILE_NAME=${SCRIPTS_TEMPL_DIR}/clone.sh.template
OUTPUT_FILE_NAME=${PWD}/clone.sh

SHORTHELP="$0 [-h|-H] [-o <outputFileName>]"
LONGHELP="${SHORTHELP}
   Generate a script to clone RAPIDS components as specified in
   ${CONFIG_FILE_NAME}

   Use -o <outputFileName> to specify the name of the generated clone script,
   but if not specified, the default generated clone script will be named
   \"${OUTPUT_FILE_NAME}\" "

while getopts ":hHdo:" option; do
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
        o)
            OUTPUT_FILE_NAME=${OPTARG}
            ;;
	*)
	    echo "${SHORTHELP}"
	    exit 1
    esac
done

# TODO: check that OUTPUT_FILE_NAME can be written
${COMMANDSUTILS_DIR}/genfile.sh ${DEBUGFLAG} ${TEMPL_FILE_NAME} > ${OUTPUT_FILE_NAME}
chmod ugo+x ${OUTPUT_FILE_NAME}
