#!/bin/bash

MAGIC_OVERRIDE_CODE="
def my_run_line_magic(*args, **kwargs):
    g=globals()
    l={}
    for a in args:
        try:
            exec(str(a),g,l)
        except:
            pass
        else:
            g.update(l)

def my_run_cell_magic(*args, **kwargs):
    my_run_line_magic(*args, **kwargs)

get_ipython().run_line_magic=my_run_line_magic
get_ipython().run_cell_magic=my_run_cell_magic

"

EXITCODE=0

for nb in $*; do
    NBFILENAME=$1
    NBNAME=$(echo ${NBFILENAME}|cut -d'.' -f1)
    NBTESTSCRIPT=/tmp/${NBNAME}-test.py
    shift

    echo --------------------
    echo ${NBNAME}
    echo --------------------
    jupyter nbconvert --to script ${NBFILENAME} --output /tmp/${NBNAME}-test
    echo "${MAGIC_OVERRIDE_CODE}" > /tmp/tmpfile
    cat ${NBTESTSCRIPT} >> /tmp/tmpfile
    mv /tmp/tmpfile ${NBTESTSCRIPT}

    echo "Running \"ipython ${NBTESTSCRIPT}\" on $(date)"
    echo 
    time ipython ${NBTESTSCRIPT}
    NBEXITCODE=$?
    echo EXIT CODE: ${NBEXITCODE}
    echo
    EXITCODE=$((EXITCODE | ${NBEXITCODE}))
done

exit ${EXITCODE}
