# RAPIDS Dockerfile for centos7 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=centos7
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.12
ARG FROM_IMAGE=rapidsai/rapidsai-core-dev

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_SQL_VER

ENV DASK_SQL_DIR=/dask-sql


RUN gpuci_mamba_retry install -y -n rapids -c conda-forge \
      "maven>=3.6.0" \
      "pip" \
      "setuptools_scm"

RUN mkdir -p ${DASK_SQL_DIR} \
    && cd ${DASK_SQL_DIR} \
    && git clone -b ${DASK_SQL_VER} https://github.com/dask-contrib/dask-sql dask-sql

RUN source activate rapids \
    && cd ${DASK_SQL_DIR}/dask-sql \
    && python -m pip install . --no-deps -vv
WORKDIR ${RAPIDS_DIR}


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${DASK_SQL_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]