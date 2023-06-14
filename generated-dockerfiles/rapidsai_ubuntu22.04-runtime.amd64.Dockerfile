# RAPIDS Dockerfile for ubuntu22.04 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2023, NVIDIA CORPORATION.

ARG CUDA_VER=11.8
ARG LINUX_VER=ubuntu22.04
ARG PYTHON_VER=3.10
ARG RAPIDS_VER=23.06
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_SQL_VER

RUN gpuci_mamba_retry install -y -n rapids "dask-sql=${DASK_SQL_VER}"


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR}
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]