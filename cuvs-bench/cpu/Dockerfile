# syntax=docker/dockerfile:1
# Copyright (c) 2024-2026, NVIDIA CORPORATION.

ARG MINIFORGE_VER=notset
ARG PYTHON_VER=notset
ARG RAPIDS_VER=26.04

FROM condaforge/miniforge3:${MINIFORGE_VER} AS cuvs-bench-cpu
ARG PYTHON_VER=notset
ARG RAPIDS_VER=26.04

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
RUN <<EOF
apt-get update
PACKAGES_TO_INSTALL=(
  perl
  wget
)
apt-get install -y --no-install-recommends \
  "${PACKAGES_TO_INSTALL[@]}"
wget --quiet https://github.com/rapidsai/gha-tools/releases/latest/download/tools.tar.gz -O - | tar -xz -C /usr/local/bin
rm -rf /var/lib/apt/lists/*
EOF

# update everything before other environment changes, to ensure mixing
# an older conda with newer packages still works well
# ref: https://github.com/rapidsai/ci-imgs/issues/185
RUN <<EOF
rapids-mamba-retry update --all -y -n base
rapids-mamba-retry install -y -n base "python=${PYTHON_VER}"
rapids-mamba-retry update --all -y -n base
PACKAGES_TO_INSTALL=(
  "cuvs-bench-cpu=${RAPIDS_VER}.*"
  "python=${PYTHON_VER}"
)
rapids-mamba-retry install -y -n base \
  "${PACKAGES_TO_INSTALL[@]}"
conda clean -afy
chmod -R 777 /opt/conda
EOF

RUN useradd -rm -d /home/rapids -s /bin/bash -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY cuvs-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]

FROM cuvs-bench-cpu AS cuvs-bench-cpu-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY cuvs-bench/get_datasets.sh /home/rapids/cuvs-bench/get_datasets.sh

COPY cuvs-bench/run_benchmark.sh /data/scripts/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/cuvs-bench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark_preloaded_datasets.sh"]
