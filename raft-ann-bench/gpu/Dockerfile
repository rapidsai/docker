# syntax=docker/dockerfile:1

ARG CUDA_VER=12.0.1
ARG PYTHON_VER=3.11
ARG LINUX_VER=ubuntu22.04

ARG RAPIDS_VER=24.10

FROM rapidsai/miniforge-cuda:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} AS raft-ann-bench
ARG CUDA_VER
ARG RAPIDS_VER

COPY condarc /opt/conda/.condarc

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Create a data folder accessible by any user so mounted volumes under it can be accessible
# when the user passes their uid to docker run with -u $(id -u)
# Also add the conda_prefix config to the global bashrc file so that all users have it correctly configured.
RUN <<EOF
mkdir /data
chmod 777 /data
echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> /etc/bash.bashrc
EOF

# we need perl temporarily for the remaining benchmark perl scripts
RUN apt-get install perl -y

# temporarily downgrade conda from 23.9.0 due to https://github.com/mamba-org/mamba/issues/2882
# after the mamba update step
RUN <<EOF
mamba update --all -y -n base
mamba install -y -n base \
    "raft-ann-bench=${RAPIDS_VER}.*" \
    "cuda-version=${CUDA_VER%.*}.*"
conda clean -afy
chmod -R 777 /opt/conda
EOF

# We add rapids is the default user in case the user runs without -u,
# but users are encouraged to  use the -u docker run flag to write/read to mounted volumes.
RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms raft_cagra", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM raft-ann-bench AS raft-ann-bench-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmarks_preloaded_datasets.sh /data/scripts/run_benchmarks_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmarks_preloaded_datasets.sh"]
