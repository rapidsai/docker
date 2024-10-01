# syntax=docker/dockerfile:1

ARG PYTHON_VER=unset
ARG RAPIDS_VER=unset

FROM condaforge/mambaforge:23.3.1-0 AS raft-ann-bench-cpu
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
echo ". /opt/conda/etc/profile.d/conda.sh; conda activate rapids" >> /etc/bash.bashrc
EOF

# we need perl temporarily for the remaining benchmark perl scripts
RUN apt-get install perl -y

# update everything before other environment changes, to ensure mixing
# an older conda with newer packages still works well
# ref: https://github.com/rapidsai/ci-imgs/issues/185
RUN <<EOF
mamba create -y -n rapids \
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


FROM bench-base AS raft-ann-bench-cpu-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark_preloaded_datasets.sh"]
