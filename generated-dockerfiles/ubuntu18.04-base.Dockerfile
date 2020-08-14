# RAPIDS Dockerfile for ubuntu18.04 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=ubuntu18.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=0.15
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER=0.15*

ENV RAPIDS_DIR=/rapids
ENV LD_LIBRARY_PATH=/opt/conda/envs/rapids/lib:${LD_LIBRARY_PATH}
RUN apt-get update \
  && apt-get install -y \
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
  rapids=${RAPIDS_VER}

COPY run_commands.sh /opt/docker/bin/run_commands
RUN /opt/docker/bin/run_commands


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
WORKDIR ${RAPIDS_DIR}

COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]