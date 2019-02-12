#!/bin/bash

USAGE="
USAGE: $0 <Dockerfile template>
"
if (( $# != 1 )) || [ $1 == "-h" ]; then
    echo "${USAGE}"
    exit 1
fi

# Change to the same dir the template file resides in, making all
# relative #insertfile paths relative to the same dir as the template.
cd $(dirname $1)
TEMPLATEDIR=$(pwd)
TEMPLATEFILE=$(basename $1)
TIMESTAMP=$(date)

echo "#"
echo "# This file was generated! Edits made directly to this file may be lost."
echo "#   Generator:    $0"
echo "#   Timestamp:    ${TIMESTAMP}"
echo "#   Template Dir: ${TEMPLATEDIR}"
echo "#"

#
# awk script processes template file ($1) line-by-line.
# If line is "insertfile <file>", then cat the file to output,
# otherwise print the line as-is to output
#
awk '
    /^insertfile .*$/ {
       printf("#---------8<------------------8<---------\n")
       printf("# BEGIN CONTENTS OF %s\n\n", $2)

       while ((getline line < $2) > 0) {
          printf("%s\n", line)
       }

       printf("\n# END CONTENTS OF %s\n", $2)
       printf("#---------8<------------------8<---------\n")
       next
    }

    // {
       print $0
    }
    ' $TEMPLATEFILE
