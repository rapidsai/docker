#!/bin/bash
set -e

# Get abs path for the rapidsai dir (ie. the location of this script)
RAPIDSAI_DIR=$(dirname $0)
pushd ${RAPIDSAI_DIR} > /dev/null
RAPIDSAI_DIR=$(pwd)
popd > /dev/null

NUMARGS=$#
UTIL_DIR=${RAPIDSAI_DIR}/utils
RAPIDS_SRC_DIR=${RAPIDSAI_DIR}/rapids
DOCKER_DIR=${RAPIDSAI_DIR}/docker
LOG_DIR=${RAPIDSAI_DIR}/logs

DOCKERFILE_BASENAME=${RAPIDSAI_DIR}/Dockerfile
DOCKERIMAGE_BUILDLOG_SUFFIX=.imageBuildLog

# Figure out the valid image types based on the templates present in DOCKER_DIR
# Template names must be of the form Dockerfile_<imageType>.template, and
# <imageType> cannot contain a . or _.
DOCKERIMAGE_TYPES=""
if [ -d ${DOCKER_DIR} ]; then
    for templateFile in ${DOCKER_DIR}/*.template; do
	if [ -e $templateFile ]; then
	    imageType=${templateFile##*_}
	    imageType=${imageType%%\.*}
            DOCKERIMAGE_TYPES+="${imageType} "
	fi
    done
else 
    echo "

WARNING: ${DOCKER_DIR} directory doesn't exist, valid image types can't be determined.

"
fi

DOCKER=nvidia-docker

IMAGETAG=$(date "+%Y%m%d-%H%M%S")

BUILDDOCKERIMAGE_HELPTEXT="buildDockerImage <imageType>
   Runs 'genDockerfile' then 'clone' prior to creating a Docker image
   for <imageType> using the generated Dockerfile in
   \"${RAPIDSAI_DIR}\"

   <imageType> must be one of: ${DOCKERIMAGE_TYPES}
"

BUILDDOCKERIMAGEFROMFILE_HELPTEXT="buildDockerImageFromFile <imageType> <dockerfile>
   Unlike 'buildDockerImage', does not run 'genDockerfile' or 'clone'
   and instead only builds a Docker image from
   <dockerfile>. <imageType> must also be specified for generating the
   tag and log file names, but does not have to be a valid imageType
   as returned by 'listImageTypes'.
"

CLONE_HELPTEXT="clone
   Clones all RAPIDS repos using ${UTIL_DIR}/clone.sh
   to ${RAPIDS_SRC_DIR}.
"

GENDOCKERFILE_HELPTEXT="genDockerfile <imageType>
   Generate a Dockerfile for <imageType> using the corresponding
   template in ${DOCKER_DIR}.  The generated Dockerfile will be named
   \"${RAPIDSAI_DIR}/Dockerfile.<imageType>\" Template names must be
   of the form \"${DOCKER_DIR}/Dockerfile_<imageType>.template\", and
   <imageType> cannot contain a . or _.

   <imageType> must be one of: ${DOCKERIMAGE_TYPES}
"

CLEAN_HELPTEXT="clean <stuffToClean>
   Removes all files associaetd with <stuffToClean>.
   <stuffToClean> can be:

   dockerstuff
      Removes only the generated Dockerfile(s) and Docker build logs

   all
      Removes everything from dockerstuff plus
      ${RAPIDS_SRC_DIR} and ${LOG_DIR}
"

LISTIMAGETYPES_HELPTEXT="listImageTypes
   Prints list of valid Docker image types that can be built, which is
   currently:

   ${DOCKERIMAGE_TYPES}

   The list is based on the presence of template files in ${DOCKER_DIR}.
"

HELPTEXT="
USAGE: $0 <command> [<arg>]

Where command is one of:

${BUILDDOCKERIMAGE_HELPTEXT}
${BUILDDOCKERIMAGEFROMFILE_HELPTEXT}
${CLONE_HELPTEXT}
${GENDOCKERFILE_HELPTEXT}
${CLEAN_HELPTEXT}
${LISTIMAGETYPES_HELPTEXT}
"

########################################

function assertNumArgs {
    numArgsNeeded=$1
    helptext=$2

    if (( ${NUMARGS} != ${numArgsNeeded} )); then
        echo "${helptext}"
        exit 1
    fi
}

function ensureValidImageType {
    imageType=$1
    for validImageType in ${DOCKERIMAGE_TYPES}; do
	if [ "${imageType}" == "${validImageType}" ]; then
	    return 0
	fi
    done
    echo "Unknown image type: \"${imageType}\" , must be one of: ${DOCKERIMAGE_TYPES}"
    exit 1
}

function ensureFileExists {
    if [ -r $1 ]; then
	return 0
    fi
    echo "$1 is not a readable file."
    exit 1
}

function buildDockerImage {
    # This assumes everything needed by the image build is in place
    # (eg. clone was run)
    imageType=$1
    dockerfile=$2

    # Assume Dockerfile name if one not specified
    if [ "${dockerfile}" == "" ]; then
	dockerfile=${RAPIDSAI_DIR}/Dockerfile.${imageType}
    fi
    contextdir=$(dirname ${dockerfile})
    logfile=${LOG_DIR}/${imageType}_image-${IMAGETAG}.buildlog

    ensureFileExists ${dockerfile}

    mkdir -p ${LOG_DIR} && \
	((time ${DOCKER} build --tag ${imageType}:${IMAGETAG} -f ${dockerfile} ${contextdir}) 2>&1|tee ${logfile})
}

function clone {
    mkdir -p ${RAPIDS_SRC_DIR} && \
        cd ${RAPIDS_SRC_DIR} && \
        ${UTIL_DIR}/clone.sh
    return $?
}

function genDockerfileFromImageType {
    imageType=$1
    template=${DOCKER_DIR}/Dockerfile_${imageType}.template
    newDockerfile=${RAPIDSAI_DIR}/Dockerfile.${imageType}
    
    ensureValidImageType ${imageType}
    ensureFileExists ${template}
    
    ${UTIL_DIR}/gendockerfile.sh ${template} > ${newDockerfile}
}

function clean {
    case "$1" in
        'dockerstuff')
            for imageType in ${DOCKERIMAGE_TYPES}; do
                rm -f ${DOCKERFILE_BASENAME}.${imageType}
                rm -f ${LOG_DIR}/${imageType}_image-*.buildlog
            done
            ;;
        'all')
            rm -rf ${RAPIDS_SRC_DIR}
            rm -rf ${LOG_DIR}
	    for imageType in ${DOCKERIMAGE_TYPES}; do
                rm -f ${DOCKERFILE_BASENAME}.${imageType}
	    done
            ;;
        *)
            echo "${CLEAN_HELPTEXT}"
            return 1
            ;;
    esac
}

function listImageTypes {
    echo ${DOCKERIMAGE_TYPES}
}

########################################

case "$1" in
    'buildDockerImage')
        assertNumArgs 2 "${BUILDDOCKERIMAGE_HELPTEXT}"
        genDockerfileFromImageType $2 && clone && buildDockerImage $2
        ;;
    'buildDockerImageFromFile')
        assertNumArgs 3 "${BUILDDOCKERIMAGEFROMFILE_HELPTEXT}"
        buildDockerImage $2 $3
        ;;
    'clone')
        assertNumArgs 1 "${CLONE_HELPTEXT}"
        clone
        ;;
    'genDockerfile')
        assertNumArgs 2 "${GENDOCKERFILE_HELPTEXT}"
        genDockerfileFromImageType $2
        ;;
    'clean')
        assertNumArgs 2 "${CLEAN_HELPTEXT}"
        clean $2
        ;;
    'listImageTypes')
	assertNumArgs 1 "${LISTIMAGETYPES_HELPTEXT}"
	listImageTypes
	;;
    *)
        echo "${HELPTEXT}"
        ;;
esac
