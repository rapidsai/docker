# RAPIDS Dockerfile for ubuntu18.04 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=ubuntu18.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.12
ARG FROM_IMAGE=rapidsai/rapidsai-core-dev

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

ARG RAPIDS_VER
ARG CUDA_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"

ENV BLAZING_DIR=/blazing

RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/Welcome_to_BlazingSQL_Notebooks.git

RUN gpuci_mamba_retry install -y -n rapids -c blazingsql-nightly -c blazingsql \
      "blazingsql-build-env=${RAPIDS_VER}*" \
      "rapids-build-env=${RAPIDS_VER}*" \
      "cudatoolkit=${CUDA_VER}*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
      "blazingsql-build-env=${RAPIDS_VER}*" \
      "rapids-build-env=${RAPIDS_VER}*"


ENV CUDF_HOME=/rapids/cudf

RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone -b ${BUILD_BRANCH} https://github.com/rapidsai/blazingsql-release-staging.git blazingsql


ENV LD_LIBRARY_PATH_ORIG=${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/compat


RUN source activate rapids \
    && cd ${BLAZING_DIR}/blazingsql \
    && ./build.sh

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH_ORIG}
ENV LD_LIBRARY_PATH_ORIG=
WORKDIR ${RAPIDS_DIR}


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]