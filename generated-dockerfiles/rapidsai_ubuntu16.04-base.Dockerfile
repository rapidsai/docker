# RAPIDS Dockerfile for ubuntu16.04 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=ubuntu16.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.06
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG RAPIDS_VER
ARG CUDA_VER

RUN gpuci_conda_retry install -y -n rapids -c blazingsql-nightly -c blazingsql\
  "rapids-blazing=${RAPIDS_VER}*" \
  "cudatoolkit=${CUDA_VER}"


ENV CONDA_DEFAULT_PKG_NUM=`conda list | awk '{ print $4}' | grep defaults | wc -l`
RUN if [[ ${CONDA_DEFAULT_PKG_NUM} -eq 0 ]]; then echo "ERROR: Packages from the default conda channel detected"; exit 1; fi
WORKDIR ${RAPIDS_DIR}


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]