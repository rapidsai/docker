#!/bin/bash

USAGE="
USAGE: $0 [-d] <template>
   -d    add debug info to generated output
"
DEBUG=0

while getopts ":d" option; do
    case "${option}" in
	d)
	    DEBUG=1
	    ;;
	*)
	    echo "${USAGE}"
	    exit 1
    esac
done

if (( $# > 2 )) || (( $# == 0 )); then
    echo "${USAGE}"
    exit 1
fi

LASTARG=${BASH_ARGV}
# Change to the same dir the template file resides in, making all
# relative #insertfile paths relative to the same dir as the template.
cd $(dirname ${LASTARG})
TEMPLATEDIR=$(pwd)
TEMPLATEFILE=$(basename ${LASTARG})
TIMESTAMP=$(date)
HEADER=\
"#\n\
# This file was generated! Edits made directly to this file may be lost.\n\
#   Generator:    $0\n\
#   Timestamp:    ${TIMESTAMP}\n\
#   Template Dir: ${TEMPLATEDIR}\n\
#"
PROCESSED_OUTPUT=""

# "process" the template, put processed output in PROCESSED_OUTPUT
function process {
    string="$1"
    header="$2"

    # awk script processes string line-by-line.
    # If line is "insertfile <file>", then cat the file to the generated output,
    # If line is "runcommand <cmd> [<arg> ...]", then run the command with args
    # and add the command output to the output, otherwise print the line as-is
    # to the output.
    PROCESSED_OUTPUT=$(echo "${string}" | awk -v "debug=${DEBUG}" \
                                              -v "header=${header}" \
        '
        # special case: ensure the header is printed after a shebang, if present.
        NR == 1 {
           if (header != "") {
              if (index($0, "#!") == 1) {
                 printf("%s\n", $0)
                 printf("%s\n", header)
                 next
              } else {
                 printf("%s\n", header)
              }
           }
        }

        /^insertfile .*$/ {
           if (debug) {
              printf("#---------8<------------------8<---------\n")
              printf("# BEGIN CONTENTS OF %s\n", $2)
           }
           while ((getline line < $2) > 0) {
              printf("%s\n", line)
           }
           if (debug) {
              printf("# END CONTENTS OF %s\n", $2)
              printf("#---------8<------------------8<---------\n")
           }
           next
        }

        /^runcommand .*$/ {
           cmd = $2
           for(i=3; i <= NF; i++) {
              cmd = cmd " " $i
           }
           if (debug) {
              printf("#---------8<------------------8<---------\n")
              printf("# BEGIN OUTPUT OF %s\n", cmd)
           }
           cmdToRun = cmd "||echo GENFILE_CMD_FAILED!"
           while ((cmdToRun | getline output) > 0) {
              if (output == "GENFILE_CMD_FAILED!") {
                 exit 1
              }
              printf("%s\n", output)
           }
           close(cmdToRun)
           if (debug) {
              printf("# END OUTPUT OF %s\n", cmd)
              printf("#---------8<------------------8<---------\n")
           }
           next
        }

        # Ignore template comments
        /^#:#.*$/ {
           next
        }

        // {
           print $0
        }
        ')
}

########################################

# Set up a loop that continues to process the contents of the file until there
# are no remaining lines to expand, commands to run, etc. This allows processed
# output to contain additional template commands which will themselves get
# processed too. Watch out for infinite loops!
# Use a tmp var to insert the header only once.
# The output of the "process" function is in PROCESSED_OUTPUT
PROCESSED_OUTPUT=$(cat ${TEMPLATEFILE})
INPUT=""
hdr="${HEADER}"

until [[ "${PROCESSED_OUTPUT}" == "${INPUT}" ]]; do
    INPUT="${PROCESSED_OUTPUT}"
    process "${INPUT}" "${hdr}"
    hdr=""
done

echo "${PROCESSED_OUTPUT}"
