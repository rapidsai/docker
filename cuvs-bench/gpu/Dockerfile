# syntax=docker/dockerfile:1
# Copyright (c) 2024-2026, NVIDIA CORPORATION.

ARG CUDA_VER=notset
ARG LINUX_VER=notset
ARG MINIFORGE_VER=notset
ARG PYTHON_VER=notset
ARG RAPIDS_VER=26.04

# --- begin 'rapidsai/miniforge-cuda' --- #
FROM condaforge/miniforge3:${MINIFORGE_VER} AS miniforge-upstream

RUN \
  --mount=type=bind,source=scripts,target=/tmp/build-scripts \
<<EOF
  # update everything in 'base' before we copy files into later targets
  /tmp/build-scripts/update-base-conda-environment
EOF

################################ build miniforge-cuda using updated miniforge-upstream from above ###############################

FROM nvidia/cuda:${CUDA_VER}-base-${LINUX_VER} AS miniforge-cuda

ARG CUDA_VER=notset
ARG LINUX_VER=notset
ARG PYTHON_VER=notset
ARG DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/conda/bin:$PATH
ENV PYTHON_VERSION=${PYTHON_VER}

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Create a conda group and assign it as root's primary group
RUN <<EOF
groupadd conda
usermod -g conda root
EOF

# Ownership & permissions based on https://docs.anaconda.com/anaconda/install/multi-user/#multi-user-anaconda-installation-on-linux
COPY --from=miniforge-upstream --chown=root:conda --chmod=770 /opt/conda /opt/conda

RUN \
  --mount=type=bind,source=scripts,target=/tmp/build-scripts \
<<EOF
# configure apt (do this first because it affects installs in later scripts)
/tmp/build-scripts/configure-apt

# install gha-tools
/tmp/build-scripts/install-gha-tools

# set up conda
/tmp/build-scripts/configure-conda-base-environment

# install tzdata system packages
/tmp/build-scripts/install-tzdata-packages
EOF

# --- end 'rapidsai/miniforge-cuda' --- #

FROM miniforge-cuda AS cuvs-bench
ARG CUDA_VER=notset
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

RUN \
  --mount=type=bind,source=scripts,target=/tmp/build-scripts \
<<EOF
# we need perl temporarily for the remaining benchmark perl scripts
apt-get update
PACKAGES_TO_INSTALL=(
  perl
  wget
)
apt-get install -y --no-install-recommends \
  "${PACKAGES_TO_INSTALL[@]}"
rm -rf /var/lib/apt/lists/*

# install gha-tools
/tmp/build-scripts/install-gha-tools

# install cuvs-bench
rapids-mamba-retry update --all -y -n base
PACKAGES_TO_INSTALL=(
    "cuvs-bench=${RAPIDS_VER}.*"
    "cuda-version=${CUDA_VER%.*}.*"
)
rapids-mamba-retry install -y -n base \
  "${PACKAGES_TO_INSTALL[@]}"
conda clean -afy
chmod -R 777 /opt/conda
EOF

# We add rapids is the default user in case the user runs without -u,
# but users are encouraged to  use the -u docker run flag to write/read to mounted volumes.
RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY cuvs-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms cuvs_cagra", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]

FROM cuvs-bench AS cuvs-bench-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY cuvs-bench/get_datasets.sh /home/rapids/cuvs-bench/get_datasets.sh

COPY cuvs-bench/run_benchmarks_preloaded_datasets.sh /data/scripts/run_benchmarks_preloaded_datasets.sh

RUN /home/rapids/cuvs-bench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmarks_preloaded_datasets.sh"]
