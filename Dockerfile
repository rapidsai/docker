# syntax=docker/dockerfile:1
# Copyright (c) 2024-2025, NVIDIA CORPORATION.

ARG CUDA_VER=unset
ARG PYTHON_VER=unset
ARG LINUX_DISTRO=ubuntu
ARG LINUX_DISTRO_VER=22.04
ARG LINUX_VER=${LINUX_DISTRO}${LINUX_DISTRO_VER}

ARG RAPIDS_VER=25.06

# Gather dependency information
FROM rapidsai/ci-conda:latest AS dependencies
ARG CUDA_VER
ARG PYTHON_VER

ARG RAPIDS_VER

ARG RAPIDS_BRANCH="branch-${RAPIDS_VER}"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN pip install --upgrade conda-merge rapids-dependency-file-generator

COPY condarc /condarc
COPY notebooks.sh /notebooks.sh

RUN <<EOF
apt-get update
apt-get install -y rsync
/notebooks.sh
apt-get purge -y --auto-remove rsync
rm -rf /var/lib/apt/lists/*
EOF


# Base image
FROM rapidsai/miniforge-cuda:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} AS base
ARG CUDA_VER
ARG PYTHON_VER

ARG RAPIDS_VER

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <<EOF
apt-get update
apt-get install -y wget
wget https://github.com/rapidsai/gha-tools/releases/latest/download/tools.tar.gz -O - | tar -xz -C /usr/local/bin
apt-get purge -y --auto-remove wget
rm -rf /var/lib/apt/lists/*
EOF
RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids

USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

RUN <<EOF
# Include common diagnostic info
conda info
conda config --show-sources
conda list --show-channel-urls

# Install RAPIDS
rapids-mamba-retry install -y -n base \
    "dask-cudf=${RAPIDS_VER}.*" \
    "python=${PYTHON_VER}.*" \
    "cuda-version=${CUDA_VER%.*}.*" \
    ipython
conda clean -afy
EOF

COPY entrypoint.sh /home/rapids/entrypoint.sh

ENTRYPOINT ["/home/rapids/entrypoint.sh"]

CMD ["ipython"]


# Notebooks image
FROM base AS notebooks

ARG CUDA_VER
ARG LINUX_DISTRO
ARG LINUX_DISTRO_VER

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
rapids-mamba-retry install -y -n base \
    "jupyterlab=4" \
    dask-labextension \
    jupyterlab-nvdashboard
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
LABEL com.nvidia.workbench.image-version="25.06.00"
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
LABEL com.nvidia.workbench.package-manager.conda3.installed-packages="rapids cudf cuml cugraph rmm pylibraft cuspatial cuxfilter cucim xgboost jupyterlab"
LABEL com.nvidia.workbench.package-manager.pip.binary="/opt/conda/bin/pip"
LABEL com.nvidia.workbench.package-manager.pip.installed-packages="jupyterlab-nvdashboard"
LABEL com.nvidia.workbench.programming-languages="python3"
LABEL com.nvidia.workbench.schema-version="v2"
LABEL com.nvidia.workbench.user.gid="1000"
LABEL com.nvidia.workbench.user.uid="1001"
LABEL com.nvidia.workbench.user.username="rapids"
