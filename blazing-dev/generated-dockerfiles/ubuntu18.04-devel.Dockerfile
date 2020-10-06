# RAPIDS Dockerfile for ubuntu18.04 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=ubuntu18.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=0.16
ARG FROM_IMAGE=rapidsai/rapidsai-dev-nightly

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

ENV BLAZING_DIR=/blazing

RUN gpuci_conda_retry install -y -n rapids \
        google-cloud-cpp=1.16.0 \
        ninja \
        gtest \
        gmock \
        cppzmq \
        openjdk=8.0 \
        maven \
        thrift=0.13.0 \
        jpype1 \
        netifaces \
        pyhive \
        nlohmann_json \
        arrow-cpp

ENV CUDF_HOME=/rapids/cudf

RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/blazingsql.git

RUN source activate rapids \
    && ccache -s \
    && cd ${BLAZING_DIR}/blazingsql \
    && ./build.sh
RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/Welcome_to_BlazingSQL_Notebooks.git

COPY test.sh /

RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}