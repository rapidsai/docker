# * This file is not intended to be a standalone script, and should
#   not run commands.
#
# * RAPIDSDEVTOOL_DIR must be set from the script, prior to sourcing
#   this file!

if [[ ${RAPIDSDEVTOOL_DIR} == "" ]]; then
    echo "INTERNAL ERROR: var RAPIDSDEVTOOL_DIR was not set before sourcing common.sh"
    exit 1
fi
UTILS_DIR=${RAPIDSDEVTOOL_DIR}/utils
COMMANDS_DIR=${RAPIDSDEVTOOL_DIR}/commands
COMMANDSUTILS_DIR=${COMMANDS_DIR}/utils
TEMPL_DIR=${RAPIDSDEVTOOL_DIR}/templates
DOCKER_TEMPL_DIR=${TEMPL_DIR}/docker
SCRIPTS_TEMPL_DIR=${TEMPL_DIR}/scripts
DOCKERFILE_BASENAME=Dockerfile
DOCKERIMAGE_BUILDLOG_SUFFIX=.imageBuildLog
CONFIG_FILE_NAME=${RAPIDSDEVTOOL_DIR}/config

# TODO: check that each of the dirs referenced in vars exist

DOCKER=nvidia-docker
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

# Find valid template names based on the templates present in
# DOCKER_TEMPL_DIR.
# Template names must be of the form Dockerfile_<templateName>.template, and
# <templateName> cannot contain a . or _.
DOCKER_TEMPL_DIR_EXISTS=1
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
