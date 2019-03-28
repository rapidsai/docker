#!/bin/bash

EXITCODE=0

for nb in $*; do
    NBFILENAME=$1
    NBNAME=$(echo ${NBFILENAME}|cut -d'.' -f1)
    NBTESTFILENAME=/tmp/${NBNAME}-test.ipynb
    NBTESTSCRIPT=/tmp/${NBNAME}-test.py
    shift

    echo --------------------
    echo ${NBNAME}
    echo --------------------
    cat ${NBFILENAME} | grep -v "%%" > ${NBTESTFILENAME}
    jupyter nbconvert --to script ${NBTESTFILENAME} --output /tmp/${NBNAME}-test
    echo "Running \"python ${NBTESTSCRIPT}\" on $(date)"
    echo 
    time python ${NBTESTSCRIPT}
    NBEXITCODE=$?
    echo EXIT CODE: ${NBEXITCODE}
    echo
    EXITCODE=$((EXITCODE | ${NBEXITCODE}))
done

exit ${EXITCODE}
