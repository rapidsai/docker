# RAPIDS Dockerfile for centos7 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2023, NVIDIA CORPORATION.

ARG CUDA_VER=11.8
ARG LINUX_VER=centos7
ARG PYTHON_VER=3.10
ARG RAPIDS_VER=23.06
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_SQL_VER

RUN gpuci_mamba_retry install -y -n rapids "dask-sql=${DASK_SQL_VER}"


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]