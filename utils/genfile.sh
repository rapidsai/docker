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

if (( $# > 2 )); then
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

echo "#"
echo "# This file was generated! Edits made directly to this file may be lost."
echo "#   Generator:    $0"
echo "#   Timestamp:    ${TIMESTAMP}"
echo "#   Template Dir: ${TEMPLATEDIR}"
echo "#"

#
# awk script processes template file line-by-line.
# If line is "insertfile <file>", then cat the file to the generated output,
# If line is "runcommand <cmd> [<arg> ...]", then run the command with
# args and add the command output to the output,
# otherwise print the line as-is to the output.
#
awk --assign debug=${DEBUG} '
    /^insertfile .*$/ {
       if (debug) {
          printf("#---------8<------------------8<---------\n")
          printf("# BEGIN CONTENTS OF %s\n\n", $2)
       }	  
       while ((getline line < $2) > 0) {
          printf("%s\n", line)
       }
       if (debug) {
          printf("\n# END CONTENTS OF %s\n", $2)
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
          printf("# BEGIN OUTPUT OF %s\n\n", cmd)
       }
       while ((cmd | getline output) > 0) {
          printf("%s\n", output)
       }
       if (debug) {
          printf("\n# END OUTPUT OF %s\n", cmd)
          printf("#---------8<------------------8<---------\n")
       }
       next
    }

    // {
       print $0
    }
    ' ${TEMPLATEFILE}
