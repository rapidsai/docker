# Assumes that this file is source'd from other scripts.
# RAPIDSDEVTOOL_DIR must be set from the script, prior to sourcing this file!
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


# function exitIfCode {
#     val=$1
#     if (( ${val} != 0 )); then
#         exit ${val}
#     fi
# }
