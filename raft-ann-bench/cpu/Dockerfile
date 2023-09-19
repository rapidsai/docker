# syntax=docker/dockerfile:1

# ARG CUDA_VER=12.0.1
ARG PYTHON_VER=3.10
ARG LINUX_VER=ubuntu22.04

ARG RAPIDS_VER=23.10

FROM condaforge/mambaforge:23.3.1-0 as bench-base
# ARG CUDA_VER
ARG RAPIDS_VER

# # Create a conda group and assign it as root's primary group
RUN groupadd conda; \
  usermod -g conda root

# # Ensure new files are created with group write access & setgid. See https://unix.stackexchange.com/a/12845
# RUN chmod g+ws /opt/conda

RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids

# USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

RUN mamba install -y -n base \
        "raft-ann-bench-cpu=${RAPIDS_VER}.*" \
    && conda clean -afy

COPY run_benchmark.sh /home/rapids/raftannbench/run_benchmark.sh

RUN echo "conda activate base" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/home/rapids/raftannbench/run_benchmark.sh"]


FROM bench-base as bench-datasets

COPY get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/home/rapids/raftannbench/run_benchmark_preloaded_datasets.sh"]

