# RAPIDS Dockerfile for ubuntu18.04 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=ubuntu18.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=0.17
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER

ENV RAPIDS_DIR=/rapids
ENV LD_LIBRARY_PATH=/opt/conda/envs/rapids/lib:${LD_LIBRARY_PATH}
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    sudo \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${RAPIDS_DIR}/utils 
COPY nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/



RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_conda_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN gpuci_conda_retry install -y -n rapids \
        "rapids-notebook-env=${RAPIDS_VER}*" \
    && conda remove -y -n rapids --force-remove \
        "rapids-notebook-env=${RAPIDS_VER}*"

RUN gpuci_conda_retry install -y -n rapids jupyterlab-nvdashboard

RUN source activate rapids \
  && jupyter labextension install dask-labextension jupyterlab-nvdashboard

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-${RAPIDS_VER} --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && cd notebooks \
  && git submodule update --init --remote --no-single-branch --depth 1

COPY test.sh test-nbcontrib.sh /

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786
COPY create_user.sh packages.sh /opt/docker/bin/
RUN /opt/docker/bin/create_user.sh


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
COPY source_entrypoints/runtime_devel.sh /opt/docker/bin/entrypoint_source
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]