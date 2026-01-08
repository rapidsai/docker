# syntax=docker/dockerfile:1
# Copyright (c) 2024-2026, NVIDIA CORPORATION.

ARG CUDA_VER=notset
ARG LINUX_DISTRO=ubuntu
ARG LINUX_DISTRO_VER=22.04
ARG LINUX_VER=${LINUX_DISTRO}${LINUX_DISTRO_VER}
ARG PYTHON_VER=notset
ARG RAPIDS_VER=26.02

# Gather dependency information
FROM python:${PYTHON_VER} AS dependencies
ARG CPU_ARCH=notset
ARG CUDA_VER=notset
ARG PYTHON_VER=notset
ARG RAPIDS_BRANCH="main"
ARG RAPIDS_VER=notset
ARG YQ_VER=notset

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY condarc /condarc
COPY notebooks.sh /notebooks.sh

# clone RAPIDS repos and extract the following:
#
#   * IPython notebooks (/notebooks)
#   * a single conda env YAML with all dependencies needed to run the notebooks (at /test_notebooks_dependencies.yaml)
#
RUN <<EOF
apt-get update
APT_PACKAGES_TO_INSTALL=(
  jq
  rsync
)
apt-get install -y --no-install-recommends \
  "${APT_PACKAGES_TO_INSTALL[@]}"

PACKAGES_TO_INSTALL=(
  'conda-merge==0.3.*'
  'rapids-dependency-file-generator==1.20.*'
)
python -m pip install --no-cache-dir --prefer-binary --upgrade \
  "${PACKAGES_TO_INSTALL[@]}"

# yq>=4.0 is needed for the bit in /notebooks.sh that uses load() to read channels from /condarc
wget -q https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_${CPU_ARCH} -O /tmp/yq
mv /tmp/yq /usr/bin/yq
chmod +x /usr/bin/yq

/notebooks.sh

apt-get purge -y --auto-remove \
  "${APT_PACKAGES_TO_INSTALL[@]}"

rm -rf /var/lib/apt/lists/*
EOF

# Base image
FROM rapidsai/miniforge-cuda:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} AS base
ARG CUDA_VER=notset
ARG PYTHON_VER=notset
ARG RAPIDS_VER=notset

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <<EOF
apt-get update
PACKAGES_TO_INSTALL=(
  curl
  git
  wget
)
apt-get install -y --no-install-recommends \
  "${PACKAGES_TO_INSTALL[@]}"
curl --silent --show-error -L https://github.com/rapidsai/gha-tools/releases/latest/download/tools.tar.gz | tar -xz -C /usr/local/bin
rm -rf /var/lib/apt/lists/*
EOF

RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids

### -- CVE-2025-8194 tarfile patch -- ###
# Adjust Python version path if needed (e.g., 3.9 or 3.11)
ENV PYTHON_SITE_PKGS=/opt/conda/lib/python${PYTHON_VER}/site-packages

# Download and install the patch
RUN curl -sSL https://gist.githubusercontent.com/sethmlarson/1716ac5b82b73dbcbf23ad2eff8b33e1/raw/70aedc4e31f4785b537b026f903fafc758fb2c17/cve-2025-8194.py \
      -o ${PYTHON_SITE_PKGS}/tarfile_patch.py && \
    echo "import tarfile_patch" > ${PYTHON_SITE_PKGS}/zzz_tar_patch.pth

USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

RUN <<EOF
# Include common diagnostic info
conda info
conda config --show-sources
conda list --show-channel-urls

# Install RAPIDS
PACKAGES_TO_INSTALL=(
  "rapids=${RAPIDS_VER}.*"
  "python=${PYTHON_VER}.*"
  "cuda-version=${CUDA_VER%.*}.*"
  'ipython>=8.37.0'
  'rapids-cli==0.1.*'
  'openssl==3.6.0'
)
rapids-mamba-retry install -y -n base \
  "${PACKAGES_TO_INSTALL[@]}"

conda clean -afy
EOF

COPY entrypoint.sh /home/rapids/entrypoint.sh

ENTRYPOINT ["/home/rapids/entrypoint.sh"]

CMD ["ipython"]

# Notebooks image
FROM base AS notebooks

ARG CUDA_VER=notset
ARG LINUX_DISTRO=notset
ARG LINUX_DISTRO_VER=notset

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

USER rapids

WORKDIR /home/rapids

COPY --from=dependencies --chown=rapids /test_notebooks_dependencies.yaml test_notebooks_dependencies.yaml

COPY --from=dependencies --chown=rapids /notebooks /home/rapids/notebooks

RUN <<EOF
rapids-mamba-retry env update -n base -f test_notebooks_dependencies.yaml
conda clean -afy
EOF

RUN <<EOF
PACKAGES_TO_INSTALL=(
  'jupyterlab=4'
  'dask-labextension>=7.0.0'
  'jupyterlab-nvdashboard>=0.13.0'
)
rapids-mamba-retry install -y -n base \
  "${PACKAGES_TO_INSTALL[@]}"
conda clean -afy
EOF

# Disable the JupyterLab announcements
RUN /opt/conda/bin/jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

ENV DASK_LABEXTENSION__FACTORY__MODULE="dask_cuda"
ENV DASK_LABEXTENSION__FACTORY__CLASS="LocalCUDACluster"

COPY test_notebooks.py /home/rapids/

EXPOSE 8888

ENTRYPOINT ["/home/rapids/entrypoint.sh"]

CMD [ "sh", "-c", "jupyter-lab --notebook-dir=/home/rapids/notebooks --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.allow_origin='*' --NotebookApp.base_url=\"${NB_PREFIX:-/}\"" ]

# Labels for NVIDIA AI Workbench
LABEL com.nvidia.workbench.application.jupyterlab.class="webapp"
LABEL com.nvidia.workbench.application.jupyterlab.health-check-cmd="[ \\$(echo url=\\$(jupyter lab list | head -n 2 | tail -n 1 | cut -f1 -d' ' | grep -v 'Currently' | sed \"s@/?@/lab?@g\") | curl -o /dev/null -s -w '%{http_code}' --config -) == '200' ]"
LABEL com.nvidia.workbench.application.jupyterlab.start-cmd="jupyter lab --allow-root --port 8888 --ip 0.0.0.0 --no-browser --NotebookApp.base_url=\\\$PROXY_PREFIX --NotebookApp.default_url=/lab --NotebookApp.allow_origin='*'"
LABEL com.nvidia.workbench.application.jupyterlab.stop-cmd="jupyter lab stop 8888"
LABEL com.nvidia.workbench.application.jupyterlab.type="jupyterlab"
LABEL com.nvidia.workbench.application.jupyterlab.webapp.autolaunch="true"
LABEL com.nvidia.workbench.application.jupyterlab.webapp.port="8888"
LABEL com.nvidia.workbench.application.jupyterlab.webapp.url-cmd="jupyter lab list | head -n 2 | tail -n 1 | cut -f1 -d' ' | grep -v 'Currently'"
LABEL com.nvidia.workbench.cuda-version="$CUDA_VER"
LABEL com.nvidia.workbench.description="RAPIDS with CUDA ${CUDA_VER}"
LABEL com.nvidia.workbench.entrypoint-script="/home/rapids/entrypoint.sh"
LABEL com.nvidia.workbench.image-version="26.02.00"
LABEL com.nvidia.workbench.labels="cuda${CUDA_VER}"
LABEL com.nvidia.workbench.name="RAPIDS with CUDA ${CUDA_VER}"
LABEL com.nvidia.workbench.os-distro-release="$LINUX_DISTRO_VER"
LABEL com.nvidia.workbench.os-distro="$LINUX_DISTRO"
LABEL com.nvidia.workbench.os="linux"
LABEL com.nvidia.workbench.package-manager-environment.target="/opt/conda"
LABEL com.nvidia.workbench.package-manager-environment.type="conda"
LABEL com.nvidia.workbench.package-manager.apt.binary="/usr/bin/apt"
LABEL com.nvidia.workbench.package-manager.apt.installed-packages=""
LABEL com.nvidia.workbench.package-manager.conda3.binary="/opt/conda/bin/conda"
LABEL com.nvidia.workbench.package-manager.conda3.installed-packages="rapids cudf cuml cugraph rmm pylibraft cuxfilter cucim xgboost jupyterlab"
LABEL com.nvidia.workbench.package-manager.pip.binary="/opt/conda/bin/pip"
LABEL com.nvidia.workbench.package-manager.pip.installed-packages="jupyterlab-nvdashboard"
LABEL com.nvidia.workbench.programming-languages="python3"
LABEL com.nvidia.workbench.schema-version="v2"
LABEL com.nvidia.workbench.user.gid="1000"
LABEL com.nvidia.workbench.user.uid="1001"
LABEL com.nvidia.workbench.user.username="rapids"
