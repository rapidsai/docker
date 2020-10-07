# RAPIDS Dockerfile for centos7 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=centos7
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

# Clone, build, install. Note: This uses the current default branch instead of main.
RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/blazingsql.git

# Add additional CUDA lib dir to LD_LIBRARY_PATH for "docker build".  This is
# not needed when using the nvidia runtime with "docker run" since the nvidia
# runtime also installs libcuda to a system location that client builds often
# find.
ARG CUDA_VER
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/compat

RUN source activate rapids \
    && ccache -s \
    && cd ${BLAZING_DIR}/blazingsql \
    && ./build.sh
# Clone, build, install
RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/Welcome_to_BlazingSQL_Notebooks.git

# Update the test script to include BlazingSQL notebooks
COPY test.sh /
WORKDIR ${BLAZING_DIR}/Welcome_to_BlazingSQL_Notebooks


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR}