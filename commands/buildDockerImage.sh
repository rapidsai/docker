#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidsdevtool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

DEBUGFLAG=""
TEMPL_NAME=""
IMAGE_TAG_NAME=""
GEND_CLONESCRIPT=${RAPIDSDEVTOOL_DIR}/clone.sh
GENDOCKERFILE_CMD=${THISDIR}/genDockerfile.sh
GENCLONESCRIPT_CMD=${THISDIR}/genCloneScript.sh
BUILDDOCKERIMAGEFROMFILE_CMD=${THISDIR}/buildDockerImageFromFile.sh

SHORTHELP="$0 [-h|-H] [-d] -t <templateName> [-i <imageTagName>] [<dockerBuildArgs>]"
LONGHELP="${SHORTHELP}
   This command automates running the following commands:
      ${GENDOCKERFILE_CMD}
      ${GENCLONESCRIPT_CMD}
      (running the generated clone script)
      ${BUILDDOCKERIMAGEFROMFILE_CMD}
"

while getopts ":hHdt:i:" option; do
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
        i)
            IMAGE_TAG_NAME=${OPTARG}
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

# Generate the Dockerfile
GEND_DOCKERFILE=${RAPIDSDEVTOOL_DIR}/${DOCKERFILE_BASENAME}.${TEMPL_NAME}
${GENDOCKERFILE_CMD} ${DEBUGFLAG} -t ${TEMPL_NAME} -o ${GEND_DOCKERFILE}

# Clone RAPIDS
${GENCLONESCRIPT_CMD} ${DEBUGFLAG} -o ${GEND_CLONESCRIPT}
(cd ${RAPIDSDEVTOOL_DIR}; ${GEND_CLONESCRIPT})

# Create the Docker image
if [[ ${IMAGE_TAG_NAME} != "" ]]; then
    ${BUILDDOCKERIMAGEFROMFILE_CMD} -f ${GEND_DOCKERFILE} -i ${IMAGE_TAG_NAME}
else
    ${BUILDDOCKERIMAGEFROMFILE_CMD} -f ${GEND_DOCKERFILE}
fi
