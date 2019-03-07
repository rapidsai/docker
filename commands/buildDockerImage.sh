#!/bin/bash
set -e

# Assume this script is in a subdir of the dir containing rapidsdevtool.sh
THISDIR=$(dirname $0)
RAPIDSDEVTOOL_DIR=${THISDIR}/..
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

source ${THISDIR}/utils/common.sh

TIMESTAMP=$(date "+%Y%m%d%H%M%S")
OUTPUT_DIR=${RAPIDSDEVTOOL_DIR}/rapids_${USER}-${TIMESTAMP}
LOG_DIR=${OUTPUT_DIR}/logs
DEBUGFLAG=""
TEMPL_NAME=""
IMAGE_TAG_NAME=""
GEND_CLONESCRIPT=${OUTPUT_DIR}/clone.sh
GEND_BUILDSCRIPT=${OUTPUT_DIR}/build.sh
GENDOCKERFILE_CMD=${THISDIR}/genDockerfile.sh
GENCLONESCRIPT_CMD=${THISDIR}/genCloneScript.sh
GENBUILDSCRIPT_CMD=${THISDIR}/genBuildScript.sh
BUILDDOCKERIMAGEFROMFILE_CMD=${THISDIR}/buildDockerImageFromFile.sh

SHORTHELP="$0 [-h|-H] [-d] -t <templateName> [-i <imageTagName>] [<dockerBuildArgs>]"
LONGHELP="${SHORTHELP}
   This command automates running the following commands:
      ${GENDOCKERFILE_CMD}
      ${GENCLONESCRIPT_CMD}
      (running the generated clone script)
      ${GENBUILDSCRIPT_CMD}
      ${BUILDDOCKERIMAGEFROMFILE_CMD}

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

# Create the working directory
# TODO: make this configurable
# TODO: should this complain if it already exists?
mkdir -p ${OUTPUT_DIR}

# Generate the Dockerfile
GEND_DOCKERFILE=${OUTPUT_DIR}/${DOCKERFILE_BASENAME}.${TEMPL_NAME}
${GENDOCKERFILE_CMD} ${DEBUGFLAG} -t ${TEMPL_NAME} -o ${GEND_DOCKERFILE}

# Compute the image tag name if not specified

TEMPL_FILE_NAME=${DOCKER_TEMPL_DIR}/${DOCKERFILE_BASENAME}_${TEMPL_NAME}.template
if [ ! -r ${TEMPL_FILE_NAME} ]; then
    echo "ERROR: ${TEMPL_FILE_NAME} is not a readable file."
    exit 1
fi
if [[ ${IMAGE_TAG_NAME} == "" ]]; then
    # TODO: include any overrides specified in Docker build args, if specified.
    # TODO: provide an error message if these greps fail
    cudaVersion=$(grep "^ARG CUDA_VERSION=" ${GEND_DOCKERFILE} | cut -d'=' -f2)
    templType=$(grep "^#:# tag:type " ${TEMPL_FILE_NAME} | cut -d' ' -f3)
    linuxVersion=$(grep "^ARG LINUX_VERSION=" ${GEND_DOCKERFILE} | cut -d'=' -f2)
    gccVersion=$(grep "^CXX_VERSION=" ${CONFIG_FILE_NAME} | cut -d'=' -f2)
    pyVersion=$(grep "^PYTHON_VERSION=" ${CONFIG_FILE_NAME} | cut -d'=' -f2)

    IMAGE_TAG_NAME="rapids_${USER}-cuda${cudaVersion}-${templType}-${linuxVersion}-gcc${gccVersion}-py${pyVersion}"
fi

# Clone RAPIDS
${GENCLONESCRIPT_CMD} ${DEBUGFLAG} -o ${GEND_CLONESCRIPT}
(cd ${OUTPUT_DIR}; ${GEND_CLONESCRIPT})

# Add a build script
${GENBUILDSCRIPT_CMD} ${DEBUGFLAG} -o ${GEND_BUILDSCRIPT}

# Copy the developer utils dir since many Dockerfiles expect to copy
# it from the CWD
cp -a ${RAPIDSDEVTOOL_DIR}/utils ${OUTPUT_DIR}

# Create the Docker image
if [[ ${IMAGE_TAG_NAME} != "" ]]; then
    (cd ${OUTPUT_DIR}; ${BUILDDOCKERIMAGEFROMFILE_CMD} -f ${GEND_DOCKERFILE} -l ${LOG_DIR} -i ${IMAGE_TAG_NAME})
else
    (cd ${OUTPUT_DIR}; ${BUILDDOCKERIMAGEFROMFILE_CMD} -f ${GEND_DOCKERFILE} -l ${LOG_DIR})
fi
