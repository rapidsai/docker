# RAPIDS Dockerfile for ubuntu18.04 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=ubuntu18.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.08
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} AS rapids-core

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d' /opt/conda/.condarc; fi

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils 
COPY nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/



RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      openssh-client \
      libopenmpi-dev \
      openmpi-bin \
    && rm -rf /var/lib/apt/lists/*


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_conda_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN source activate rapids \
    && npm i -g npm@">=7.0"

RUN apt-get update \
    && apt-get -y upgrade \
    && rm -rf /var/lib/apt/lists/*

COPY packages.sh /opt/docker/bin/

RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}

WORKDIR ${RAPIDS_DIR}

COPY NVIDIA_Deep_Learning_Container_License.pdf . 
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]
FROM rapids-core AS rapids-std

ARG RAPIDS_VER
ARG CUDA_VER
ENV BLAZING_DIR=/blazing

RUN gpuci_conda_retry install -y -n rapids -c blazingsql-nightly -c blazingsql\
  "rapids-blazing=${RAPIDS_VER}*" \
  "cudatoolkit=${CUDA_VER}"

WORKDIR ${RAPIDS_DIR}

RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}

COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]

FROM rapids-std

ARG RAPIDS_VER
ARG CUDA_VER

RUN gpuci_conda_retry install -y -n rapids -c pytorch \
    "clx=${RAPIDS_VER}" \
    "cudatoolkit=${CUDA_VER}"

WORKDIR ${RAPIDS_DIR}

RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}

COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]