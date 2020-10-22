# RAPIDS Dockerfile for centos7 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=centos7
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=0.17
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC7_DIR}/lib64
COPY nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/

COPY libm.so.6 ${GCC7_DIR}/lib64


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_conda_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN source activate rapids \
    && npm i -g npm@">=7"
COPY packages.sh /opt/docker/bin/


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
WORKDIR ${RAPIDS_DIR}

COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]