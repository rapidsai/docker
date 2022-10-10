# RAPIDS Dockerfile for ubuntu20.04 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2022, NVIDIA CORPORATION.

ARG CUDA_VER=11.5
ARG LINUX_VER=ubuntu20.04
ARG PYTHON_VER=3.9
ARG RAPIDS_VER=22.10
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG CUDA_VER
ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"
ARG LINUX_VER
ENV RAPIDS_VER=$RAPIDS_VER

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d;/dask\/label\/dev/d' /opt/conda/.condarc; fi

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils


RUN apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/${LINUX_VER/./}/$(uname -p)/3bf863cc.pub" \
    && apt-get update \
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
RUN gpuci_mamba_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN rm /opt/conda/lib/python3.9/mailcap.py \
    && rm /opt/conda/rapids/lib/python3.9/mailcap.py

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

ENV PATH="/opt/conda/condabin:/opt/conda/envs/rapids/bin:/opt/conda/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]