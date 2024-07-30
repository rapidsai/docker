# syntax=docker/dockerfile:1

ARG PYTHON_VER=3.11
ARG RAPIDS_VER=24.08

FROM condaforge/miniforge3:24.3.0-0 as raft-ann-bench-cpu
ARG RAPIDS_VER
ARG PYTHON_VER

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

# Install python before updating environment, otherwise Python 3.9 image
# runs into a solver conflict with truststore 0.8.0. This avoids the environment installing
# packages incompatible with python version needed before python itself is pinned to the correct version.
RUN <<EOF
mamba install -y -n base "python=${PYTHON_VER}"
mamba update --all -y -n base
mamba install -y -n base \
  "raft-ann-bench-cpu=${RAPIDS_VER}.*" \
  "python=${PYTHON_VER}"
conda clean -afy
chmod -R 777 /opt/conda
EOF

RUN useradd -rm -d /home/rapids -s /bin/bash -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM bench-base as raft-ann-bench-cpu-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark_preloaded_datasets.sh"]
