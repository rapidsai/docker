# RAPIDS Dockerfile for centos7 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=centos7
ARG PYTHON_VER=3.8
ARG RAPIDS_VER=22.02
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_SQL_VER

RUN gpuci_mamba_retry install -y -n rapids -c dask/label/dev \
  "dask-sql=${DASK_SQL_VER}"

WORKDIR ${RAPIDS_DIR}


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]