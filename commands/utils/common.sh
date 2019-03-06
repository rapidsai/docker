# Assumes that this file is source'd from other scripts.
# RAPIDSDEVTOOL_DIR must be set from the script, prior to sourcing this file!
COMMANDS_DIR=${RAPIDSDEVTOOL_DIR}/commands
COMMANDSUTILS_DIR=${COMMANDS_DIR}/utils
DOCKER_TEMPL_DIR=${RAPIDSDEVTOOL_DIR}/templates/docker
DOCKER_TEMPL_DIR_EXISTS=1
DOCKERFILE_BASENAME=Dockerfile
DOCKERIMAGE_BUILDLOG_SUFFIX=.imageBuildLog
CONFIG_FILE_NAME=${RAPIDSDEVTOOL_DIR}/config
LOG_DIR=${RAPIDSDEVTOOL_DIR}/logs

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

DOCKER=nvidia-docker
TIMESTAMP=$(date "+%Y%m%d%H%M%S")


# function exitIfCode {
#     val=$1
#     if (( ${val} != 0 )); then
#         exit ${val}
#     fi
# }
