# syntax=docker/dockerfile:1

ARG CUDA_VER=11.8.0
ARG PYTHON_VER=3.10
ARG LINUX_VER=ubuntu22.04

ARG RAPIDS_VER=23.04
ARG DASK_SQL_VER=2023.2.0

ARG BASE_FROM_IMAGE=rapidsai/mambaforge-cuda

# Gather dependency information
FROM rapidsai/ci:latest AS dependencies
ARG CUDA_VER
ARG PYTHON_VER

ARG RAPIDS_VER

ARG RAPIDS_BRANCH="branch-${RAPIDS_VER}"

RUN pip install --upgrade conda-merge rapids-dependency-file-generator

COPY notebooks.sh /notebooks.sh

RUN /notebooks.sh


# Base image
FROM ${BASE_FROM_IMAGE}:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} as base
ARG CUDA_VER
ARG PYTHON_VER

ARG RAPIDS_VER
ARG DASK_SQL_VER

RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids

USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

COPY entrypoint.sh /home/rapids/entrypoint.sh

# CI should handle modifying this file instead of the dockerfile
# RUN if [ "${RAPIDS_BRANCH}" = "main" ]; then sed -i '/nightly/d;/dask\/label\/dev/d' /opt/conda/.condarc; fi

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba install -y -n base \
        "rapids=${RAPIDS_VER}.*" \
        "dask-sql=${DASK_SQL_VER%.*}.*" \
        "python=${PYTHON_VER}.*" \
        "cudatoolkit=${CUDA_VER%.*}.*" \
        ipython \
    && conda clean -afy

ENTRYPOINT ["/home/rapids/entrypoint.sh"]

CMD ["ipython"]


# Notebooks image
FROM base as notebooks

USER rapids

WORKDIR /home/rapids

COPY --from=dependencies --chown=rapids /test_notebooks_dependencies.yaml test_notebooks_dependencies.yaml

COPY --from=dependencies --chown=rapids /notebooks /home/rapids/notebooks

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env update -n base -f test_notebooks_dependencies.yaml \
    && conda clean -afy

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba install -y -n base \
        jupyterlab \
        dask-labextension \
        jupyterlab-nvdashboard \
    && conda clean -afy

ENV DASK_LABEXTENSION__FACTORY__MODULE="dask_cuda"
ENV DASK_LABEXTENSION__FACTORY__CLASS="LocalCUDACluster"

EXPOSE 8888

ENTRYPOINT ["/home/rapids/entrypoint.sh"]

CMD ["jupyter-lab", "--allow-root", "--notebook-dir=/home/rapids/notebooks", "--ip=0.0.0.0", "--no-browser", "--NotebookApp.token=''", "--NotebookApp.allow_origin='*'"]