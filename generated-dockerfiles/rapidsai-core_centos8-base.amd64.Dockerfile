# RAPIDS Dockerfile for centos8 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2022, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=centos8
ARG PYTHON_VER=3.8
ARG RAPIDS_VER=22.04
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG CUDA_VER
ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"
ENV RAPIDS_VER=$RAPIDS_VER

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d;/dask\/label\/dev/d' /opt/conda/.condarc; fi

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC9_DIR}/lib64

RUN yum install -y \
      openssh-clients \
      openmpi-devel \
      libnsl \
      && yum clean all



RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_mamba_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN source activate rapids \
    && npm i -g npm@">=7.0"

RUN yum -y upgrade \
    && yum clean all

COPY packages.sh /opt/docker/bin/


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
WORKDIR ${RAPIDS_DIR}

COPY NVIDIA_Deep_Learning_Container_License.pdf . 
COPY entrypoint.sh /opt/docker/bin/entrypoint

ENV PATH="/opt/conda/envs/rapids/bin:/opt/conda/condabin:/opt/conda/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]