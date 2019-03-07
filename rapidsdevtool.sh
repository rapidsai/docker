#!/bin/bash
set -e

RAPIDSDEVTOOL_DIR=$(dirname $0)
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

HELPTEXT="
USAGE:
   $0 [-h|-H] <command> [<arg> ...]

 -h   print brief help
 -H   print detailed help

 command is one of:
"
HELPFLAG_GIVEN=0
HELPFLAG=-h
COMMANDS_DIR=${RAPIDSDEVTOOL_DIR}/commands
VALID_COMMAND_GIVEN=""
COMMAND_TO_EXEC=""
COMMAND_NAMES=""

while getopts ":hH" option; do
    case "${option}" in
        h)
            HELPFLAG_GIVEN=1
            HELPFLAG=-h
            ;;
        H)
            HELPFLAG_GIVEN=1
            HELPFLAG=-H
            ;;
    esac
done

# Create a list of command scripts, with the "buildDockerImage" script first
# since this is currently the expected most-frequently used command
COMMAND_SCRIPTS="${COMMANDS_DIR}/buildDockerImage.sh $(echo ${COMMANDS_DIR}/*.sh|sed 's![^ ]*/buildDockerImage\.sh!!')"

# Generate the help text by running help on each command
for cmdScript in ${COMMAND_SCRIPTS}; do
    cmdHelp=$(${cmdScript} ${HELPFLAG})
    HELPTEXT="${HELPTEXT}
${cmdHelp}
"
done

# Build a list of commands and also convert the full command script paths in the
# help text into commands using sed
for cmdScript in ${COMMAND_SCRIPTS}; do
    cmdName=${cmdScript##*/} # remove path up to and including last /
    cmdName=${cmdName%%\.*}  # remove .sh
    COMMAND_NAMES="${COMMAND_NAMES} ${cmdName}"
    HELPTEXT=$(echo "${HELPTEXT}" | sed "s!${cmdScript}!${cmdName}!g")
done
# Add the last newline that sed took away
HELPTEXT="${HELPTEXT}
"

if (( ${HELPFLAG_GIVEN} )); then
    echo "${HELPTEXT}"
    exit 0
fi

for cmd in ${COMMAND_NAMES}; do
    if [[ $1 == ${cmd} ]]; then
        VALID_COMMAND_GIVEN=$1
        COMMAND_TO_EXEC=${COMMANDS_DIR}/${cmd}.sh
        break
    fi
done
if [[ ${VALID_COMMAND_GIVEN} == "" ]]; then
    echo "${HELPTEXT}"
    exit 1
fi

# Run the subcommand with the remaining args
shift
exec ${COMMAND_TO_EXEC} $*
