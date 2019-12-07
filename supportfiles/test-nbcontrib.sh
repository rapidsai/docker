NCFOLDER=/notebooks-contrib
EXITCODE=0
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh

cd /
git clone https://github.com/rapidsai/notebooks-contrib.git
cd ${NCFOLDER}

FOLDERS=$(find . -name *.ipynb |cut -d'/' -f2|sort -u)

# louvain_benchmark.ipynb pagerank_benchmark.ipynb - timedout
# https://gpuci.gpuopenanalytics.com/job/docker/job/tests/job/docker-test-notebooks-contrib/17/CUDA_VERSION=10.0,LINUX_VERSION=ubuntu18.04/consoleFull
# cuml_benchmarks.ipynb - crash/hang on CentOS7 CUDA 10.*
# https://gpuci.gpuopenanalytics.com/job/docker/job/tests/job/docker-test-notebooks-contrib/24

SKIPNBS="louvain_benchmark.ipynb pagerank_benchmark.ipynb cuml_benchmarks.ipynb"

for folder in ${FOLDERS}; do
    echo "========================================"
    echo "FOLDER: ${folder}"
    echo "========================================"
    cd ${folder}
    for nb in $(find . -name *.ipynb); do
        nbBasename=$(basename ${nb})
        # Skip all NBs that use dask (in the code or even in their name)
        if ((echo ${nb}|grep -qi dask) || \
            (grep -q dask ${nb})); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nbBasename} (suspected Dask usage, not currently automatable)"
            echo "--------------------------------------------------------------------------------"
        elif (echo " ${SKIPNBS} " | grep -q " ${nbBasename} "); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nbBasename} (listed in skip list)"
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
