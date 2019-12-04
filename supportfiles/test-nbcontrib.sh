NCFOLDER=/notebooks-contrib
EXITCODE=0
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh

cd /
git clone https://github.com/rapidsai/notebooks-contrib.git
cd ${NCFOLDER}

FOLDERS=$(find . -name *.ipynb |cut -d'/' -f2|sort -u)

for folder in ${FOLDERS}; do
    echo "========================================"
    echo "FOLDER: ${folder}"
    echo "========================================"
    cd ${folder}
    for nb in $(find . -name *.ipynb); do
        nbBasename=$(basename ${nb})
        if (echo ${nb}|grep -qi dask); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nbBasename}"
            echo "--------------------------------------------------------------------------------"
        else
            cd $(dirname ${nb})
            nvidia-smi
            ${NBTEST} ${nbBasename}
            EXITCODE=$((EXITCODE | $?))
            cd ${NCFOLDER}/${folder}
        fi
   done
   cd ${NCFOLDER}
done

exit ${EXITCODE}
