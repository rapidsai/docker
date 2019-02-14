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

# Figure out the valid template names based on the templates present
# in DOCKER_DIR Template names must be of the form
# Dockerfile_<templateName>.template, and <templateName> cannot contain a
# . or _.
DOCKER_TEMPL_NAMES=""
if [ -d ${DOCKER_DIR} ]; then
    for templateFile in ${DOCKER_DIR}/*.template; do
	if [ -e $templateFile ]; then
	    templateName=${templateFile##*_}
	    templateName=${templateName%%\.*}
            DOCKER_TEMPL_NAMES+="${templateName} "
	fi
    done
else 
    echo "

WARNING: ${DOCKER_DIR} directory doesn't exist, valid template names can't be determined.

"
fi

DOCKER=nvidia-docker
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

BUILDDOCKERIMAGE_HELPTEXT="buildDockerImage <templateName> [<imageTagName>] [<dockerBuildArgs>]
   Runs 'genDockerfile' then 'clone' prior to creating a Docker image
   for <templateName> using the generated Dockerfile in
   \"${RAPIDSAI_DIR}\", tagged with <imageTagName>. If <imageTagName>
   is \"\" or not specified, <templateName>-<timestamp> is used.
   <dockerBuildArgs> can be provided to pass docker args as-is to the
   build command.

   <templateName> must be one of: ${DOCKER_TEMPL_NAMES}
"

BUILDDOCKERIMAGEFROMFILE_HELPTEXT="buildDockerImageFromFile <dockerfile> <imageTagName> [<dockerBuildArgs>]
   Unlike 'buildDockerImage', does not run 'genDockerfile' or 'clone'
   and instead only builds a Docker image from <dockerfile>, tagged
   with <imageTagName>. If <imageTagName> is \"\" or not specified,
   $USER-<timestamp> is used.  <dockerBuildArgs> can be provided to
   pass docker args as-is to the build command.
"

CLONE_HELPTEXT="clone
   Clones all RAPIDS repos using ${UTIL_DIR}/clone.sh
   to ${RAPIDS_SRC_DIR}.
"

GENDOCKERFILE_HELPTEXT="genDockerfile <templateName>
   Generate a Dockerfile for <templateName> using the corresponding
   template in ${DOCKER_DIR}.  The generated Dockerfile will be named
   \"${RAPIDSAI_DIR}/Dockerfile.<templateName>\" Template names must be
   of the form \"${DOCKER_DIR}/Dockerfile_<templateName>.template\", and
   <templateName> cannot contain a . or _.

   <templateName> must be one of: ${DOCKER_TEMPL_NAMES}
"

CLEAN_HELPTEXT="clean <stuffToClean>
   Removes all files associaetd with <stuffToClean>.
   <stuffToClean> can be:

   dockerstuff
      Removes only the generated Dockerfile(s)

   all
      Removes everything from dockerstuff plus
      ${RAPIDS_SRC_DIR} and ${LOG_DIR}
"

LISTTEMPLNAMES_HELPTEXT="listTemplNames
   Prints list of valid Docker template names that can be built, which is
   currently:

   ${DOCKER_TEMPL_NAMES}

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
${LISTTEMPLNAMES_HELPTEXT}
"

########################################

function assertNumArgs {
    numArgsNeeded=$1
    helptext=$2

    if (( ${NUMARGS} != ${numArgsNeeded} )); then
        echo
	echo "${helptext}"
        exit 1
    fi
}

function assertMinNumArgs {
    numArgsNeeded=$1
    helptext=$2

    if (( ${NUMARGS} < ${numArgsNeeded} )); then
        echo
	echo "${helptext}"
        exit 1
    fi
}

function ensureValidImageType {
    templateName=$1
    for validImageType in ${DOCKER_TEMPL_NAMES}; do
	if [ "${templateName}" == "${validImageType}" ]; then
	    return 0
	fi
    done
    echo "Unknown template name: \"${templateName}\" , must be one of: ${DOCKER_TEMPL_NAMES}"
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
    dockerfile=$1
    imageTagName=$2
    shift 2
    buildArgs=$@
    contextdir=$(dirname ${dockerfile})
    logfile=${LOG_DIR}/${imageTagName}_image--${TIMESTAMP}.buildlog

    ensureFileExists ${dockerfile}
    mkdir -p ${LOG_DIR} && \
	((time ${DOCKER} build --tag ${imageTagName} ${buildArgs} -f ${dockerfile} ${contextdir}) 2>&1|tee ${logfile})
}

function clone {
    mkdir -p ${RAPIDS_SRC_DIR} && \
        cd ${RAPIDS_SRC_DIR} && \
        ${UTIL_DIR}/clone.sh
    return $?
}

function genDockerfileFromImageType {
    templateName=$1
    templateFile=${DOCKER_DIR}/Dockerfile_${templateName}.template
    newDockerfile=${RAPIDSAI_DIR}/Dockerfile.${templateName}
    
    ensureValidImageType ${templateName}
    ensureFileExists ${templateFile}
    ${UTIL_DIR}/gendockerfile.sh ${templateFile} > ${newDockerfile}
}

function clean {
    case "$1" in
        'dockerstuff')
            for templateName in ${DOCKER_TEMPL_NAMES}; do
                rm -f ${DOCKERFILE_BASENAME}.${templateName}
            done
            ;;
        'all')
            rm -rf ${RAPIDS_SRC_DIR}
            rm -rf ${LOG_DIR}
	    for templateName in ${DOCKER_TEMPL_NAMES}; do
                rm -f ${DOCKERFILE_BASENAME}.${templateName}
	    done
            ;;
        *)
            echo "${CLEAN_HELPTEXT}"
            return 1
            ;;
    esac
}

function listTemplNames {
    echo ${DOCKER_TEMPL_NAMES}
}

########################################

case "$1" in
    'buildDockerImage')
        assertMinNumArgs 2 "${BUILDDOCKERIMAGE_HELPTEXT}"
	templateName=$2
	imageTagName=${3:-${templateName}-${TIMESTAMP}} # use default if needed
	if (( $# > 3 )); then
	    shift 3
	    buildArgs=$@
	else
	    buildArgs=""
	fi
	newDockerFile=${RAPIDSAI_DIR}/Dockerfile.${templateName}
        genDockerfileFromImageType ${templateName} && clone && \
	    buildDockerImage ${newDockerFile} ${imageTagName} ${buildArgs}
        ;;
    'buildDockerImageFromFile')
        assertMinNumArgs 2 "${BUILDDOCKERIMAGEFROMFILE_HELPTEXT}"
	dockerfile=$2
	imageTagName=${3:-${USER}-${TIMESTAMP}} # use default if needed
	if (( $# > 3 )); then
	    shift 3
	    buildArgs=$@
	else
	    buildArgs=""
	fi
        buildDockerImage ${dockerfile} ${imageTagName} ${buildArgs}
        ;;
    'clone')
        assertNumArgs 1 "${CLONE_HELPTEXT}"
        clone
        ;;
    'genDockerfile')
        assertNumArgs 2 "${GENDOCKERFILE_HELPTEXT}"
	templateName=$2
        genDockerfileFromImageType ${templateName}
        ;;
    'clean')
        assertNumArgs 2 "${CLEAN_HELPTEXT}"
	mode=$2
        clean ${mode}
        ;;
    'listTemplNames')
	assertNumArgs 1 "${LISTTEMPLNAMES_HELPTEXT}"
	listTemplNames
	;;
    *)
        echo "${HELPTEXT}"
        ;;
esac
