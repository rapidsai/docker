# syntax=docker/dockerfile:1

ARG CUDA_VER=12.0.1
ARG PYTHON_VER=3.10
ARG LINUX_VER=ubuntu22.04

ARG RAPIDS_VER=23.12

FROM rapidsai/mambaforge-cuda:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} as raft-ann-bench
ARG CUDA_VER
ARG RAPIDS_VER

RUN mkdir /data && chmod 777 /data
RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids
# rapids is the default user, but users can use the -u docker run flag to write/read to mounted volumes.
USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

RUN mamba update --all -y -n base \
    && mamba install -y -n base \
        "raft-ann-bench=${RAPIDS_VER}.*" \
        "cuda-version=${CUDA_VER%.*}.*" \
        "rmm=${RAPIDS_VER}.*" \
    && conda clean -afy

# we need to change the permissions of the conda folder so that all users can execute
USER root
RUN chmod -R 777 /opt/conda
USER rapids

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms raft_cagra", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM raft-ann-bench as raft-ann-bench-datasets

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmarks_preloaded_datasets.sh /data/scripts/run_benchmarks_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmarks_preloaded_datasets.sh"]
