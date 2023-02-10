# RAPIDS Dockerfile for ubuntu22.04 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2023, NVIDIA CORPORATION.

ARG CUDA_VER=11.8
ARG LINUX_VER=ubuntu22.04
ARG PYTHON_VER=3.10
ARG RAPIDS_VER=23.04
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG RAPIDS_VER
ARG CUDA_VER

RUN gpuci_mamba_retry install -y -n rapids -c pytorch \
    "clx=${RAPIDS_VER}" \
    "cudatoolkit=${CUDA_VER}"


RUN chmod -R ugo+w /opt/conda ${CLX_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${CLX_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]