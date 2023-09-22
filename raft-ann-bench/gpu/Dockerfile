# syntax=docker/dockerfile:1

ARG CUDA_VER=12.0.1
ARG PYTHON_VER=3.10
ARG LINUX_VER=ubuntu22.04

ARG RAPIDS_VER=23.10

FROM rapidsai/mambaforge-cuda:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} as raft-ann-bench
ARG CUDA_VER
ARG RAPIDS_VER

RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

RUN mamba install -y -n base \
        "raft-ann-bench=${RAPIDS_VER}.*" \
        "cuda-version=${CUDA_VER%.*}.*" \
        "rmm=${RAPIDS_VER}.*" \
    && conda clean -afy

COPY raft-ann-bench/run_benchmark.sh /home/rapids/raftannbench/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms raft_cagra", ""]

ENTRYPOINT ["/bin/bash", "/home/rapids/raftannbench/run_benchmark.sh"]


FROM raft-ann-bench as raft-ann-bench-datasets

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmark.sh /home/rapids/raftannbench/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib", ""]

ENTRYPOINT ["/bin/bash", "/home/rapids/raftannbench/run_benchmark_preloaded_datasets.sh"]

