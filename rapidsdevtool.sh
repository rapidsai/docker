#!/bin/bash
set -e

RAPIDSDEVTOOL_DIR=$(dirname $0)
pushd ${RAPIDSDEVTOOL_DIR} > /dev/null
RAPIDSDEVTOOL_DIR=$(pwd)
popd > /dev/null

HELPTEXT="
USAGE:
   $0 [-h|-H] <command> [<arg> ...]

where command is one of:
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

# Generate the help text by running help on each command
for cmdScript in ${COMMANDS_DIR}/*.sh; do
    cmdHelp=$(${cmdScript} ${HELPFLAG})
    HELPTEXT="${HELPTEXT}
${cmdHelp}
"
done

# Build a list of commands and also convert command script names into commands
# using sed
for cmdScript in ${COMMANDS_DIR}/*.sh; do
    cmdName=${cmdScript##*/}       # remove path up to and including last /
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
