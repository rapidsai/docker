# syntax=docker/dockerfile:1
# Copyright (c) 2024-2026, NVIDIA CORPORATION.

ARG CUDA_VER=notset
ARG LINUX_VER=notset
ARG MINIFORGE_VER=notset
ARG PYTHON_VER=notset
ARG RAPIDS_VER=26.02

# --- begin 'rapidsai/miniforge-cuda' --- #
FROM condaforge/miniforge3:${MINIFORGE_VER} AS miniforge-upstream

ENV PATH=

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Install gha-tools
RUN <<EOF
  i=0; until apt-get update -y; do ((++i >= 5)) && break; sleep 10; done
  apt-get install -y --no-install-recommends wget
  wget -q https://github.com/rapidsai/gha-tools/releases/latest/download/tools.tar.gz -O - | tar -xz -C /usr/local/bin
  apt-get purge -y wget && apt-get autoremove -y
  rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
# Ensure new files/dirs have group write permissions
umask 002

# Example of pinned package in case you require an override
# echo '<PACKAGE_NAME>==<VERSION>' >> /opt/conda/conda-meta/pinned

# update everything before other environment changes, to ensure mixing
# an older conda with newer packages still works well
PATH="/opt/conda/bin:$PATH" \
  rapids-mamba-retry update --all -y -n base
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

# Set apt policy configurations
# We bump up the number of retries and the timeouts for `apt`
# Note that `dnf` defaults to 10 retries, so no additional configuration is required here
RUN <<EOF
echo 'APT::Update::Error-Mode "any";' > /etc/apt/apt.conf.d/warnings-as-errors
echo 'APT::Acquire::Retries "10";' > /etc/apt/apt.conf.d/retries
echo 'APT::Acquire::https::Timeout "240";' > /etc/apt/apt.conf.d/https-timeout
echo 'APT::Acquire::http::Timeout "240";' > /etc/apt/apt.conf.d/http-timeout
EOF

# Install gha-tools
RUN <<EOF
  i=0; until apt-get update -y; do ((++i >= 5)) && break; sleep 10; done
  apt-get install -y --no-install-recommends wget
  wget -q https://github.com/rapidsai/gha-tools/releases/latest/download/tools.tar.gz -O - | tar -xz -C /usr/local/bin
  apt-get purge -y wget && apt-get autoremove -y
  rm -rf /var/lib/apt/lists/*
EOF

# Create a conda group and assign it as root's primary group
RUN <<EOF
groupadd conda
usermod -g conda root
EOF

# Ownership & permissions based on https://docs.anaconda.com/anaconda/install/multi-user/#multi-user-anaconda-installation-on-linux
COPY --from=miniforge-upstream --chown=root:conda --chmod=770 /opt/conda /opt/conda

RUN <<EOF
# Ensure new files are created with group write access & setgid. See https://unix.stackexchange.com/a/12845
chmod g+ws /opt/conda

# Ensure new files/dirs have group write permissions
umask 002

# install expected Python version
PYTHON_MAJOR_VERSION=${PYTHON_VERSION%%.*}
PYTHON_MINOR_VERSION=${PYTHON_VERSION#*.}
PYTHON_UPPER_BOUND="${PYTHON_MAJOR_VERSION}.$((PYTHON_MINOR_VERSION+1)).0a0"
PYTHON_MINOR_PADDED=$(printf "%02d" "$PYTHON_MINOR_VERSION")
PYTHON_VERSION_PADDED="${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_PADDED}"
# 'shellcheck' is unhappy with the use of '>' to compare decimals here, but it works as expected for the 'bash' version in these
# images, and installing 'bc' or using a Python interpreter seem heavy for this purpose.
#
# shellcheck disable=SC2072
if [[ "$PYTHON_VERSION_PADDED" > "3.12" ]]; then
    PYTHON_ABI_TAG="cp${PYTHON_MAJOR_VERSION}${PYTHON_MINOR_VERSION}"
else
    PYTHON_ABI_TAG="cpython"
fi
rapids-mamba-retry install -y -n base "python>=${PYTHON_VERSION},<${PYTHON_UPPER_BOUND}=*_${PYTHON_ABI_TAG}"
rapids-mamba-retry update --all -y -n base
find /opt/conda -follow -type f -name '*.a' -delete
find /opt/conda -follow -type f -name '*.pyc' -delete
# recreate missing libstdc++ symlinks
conda clean -aiptfy
EOF

RUN <<EOF
# Reassign root's primary group to root
usermod -g root root

# ensure conda environment is always activated
ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> /etc/skel/.bashrc
echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> ~/.bashrc
EOF

# tzdata is needed by the ORC library used by pyarrow, because it provides /etc/localtime
# On Ubuntu 24.04 and newer, we also need tzdata-legacy
RUN <<EOF
PACKAGES_TO_INSTALL=(
  tzdata
)

os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2)
# 'shellcheck' is unhappy with the use of '>' to compare decimals here, but it works as expected for the 'bash' version in these
# images, and installing 'bc' or using a Python interpreter seem heavy for this purpose.
#
# shellcheck disable=SC2072
if [[ "${os_version}" > "24.04" ]] || [[ "${os_version}" == "24.04" ]]; then
    PACKAGES_TO_INSTALL+=(tzdata-legacy)
fi

rapids-retry apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  "${PACKAGES_TO_INSTALL[@]}"

rm -rf "/var/lib/apt/lists/*"
;;
EOF

# --- end 'rapidsai/miniforge-cuda' --- #

FROM miniforge-cuda AS cuvs-bench
ARG CUDA_VER=notset
ARG RAPIDS_VER=notset

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

RUN <<EOF
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
