# RAPIDS Dockerfile for Ubuntu "quick devel" image
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
ARG RAPIDS_VER=0.15
ARG FROM_IMAGE=rapidsaistaging/rapidsai-dev-nightly-staging

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

ARG PARALLEL_LEVEL=16

RUN source activate rapids && \
    cd ${RAPIDS_DIR}/rmm && \
    git pull && \
    cd ${RAPIDS_DIR}/cudf && \
    git pull && \
    cd ${RAPIDS_DIR}/cusignal && \
    git pull && \
    cd ${RAPIDS_DIR}/cuxfilter && \
    git pull && \
    cd ${RAPIDS_DIR}/cuspatial && \
    git pull && \
    cd ${RAPIDS_DIR}/cuml && \
    git pull && \
    cd ${RAPIDS_DIR}/cugraph && \
    git pull && \
    cd ${RAPIDS_DIR}/xgboost && \
    git pull && \
    cd ${RAPIDS_DIR}/dask-xgboost && \
    git pull && \
    cd ${RAPIDS_DIR}/dask-cuda && \
    git pull 

ENV NCCL_ROOT=/opt/conda/envs/rapids
ENV PARALLEL_LEVEL=${PARALLEL_LEVEL}

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/conda/envs/rapids/lib

RUN cd ${RAPIDS_DIR}/rmm && \
  source activate rapids && \
  ccache -s && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cudf && \
  source activate rapids && \
  ccache -s && \
  ./build.sh && \
  ./build.sh libcudf_kafka cudf_kafka && \
  ./build.sh tests

RUN cd ${RAPIDS_DIR}/cusignal && \
  source activate rapids && \
  ccache -s && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cuxfilter && \
  source activate rapids && \
  ccache -s && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cuspatial && \
  source activate rapids && \
  ccache -s && \
  export CUSPATIAL_HOME="$PWD" && \
  export CUDF_HOME="$PWD/../cudf" && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cuml && \
  source activate rapids && \
  ccache -s && \
  ./build.sh --allgpuarch libcuml cuml prims

RUN cd ${RAPIDS_DIR}/cugraph && \
  source activate rapids && \
  ccache -s && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/xgboost && \
  source activate rapids && \
  ccache -s && \
  if [[ "$CUDA_VER" == "11.0" ]]; then \
    mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
          -DUSE_NCCL=ON -DUSE_CUDA=ON -DUSE_CUDF=ON \
          -DBUILD_WITH_SHARED_NCCL=ON \
          -DGDF_INCLUDE_DIR=$CONDA_PREFIX/include \
          -DCMAKE_CXX_STANDARD:STRING="14" \
          -DPLUGIN_RMM=ON \
          -DRMM_ROOT=${RAPIDS_DIR}/rmm \
          -DCMAKE_BUILD_TYPE=release .. && \
    make -j && make -j install && \
    cd ../python-package && python setup.py install; \
  else \
    mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
          -DUSE_NCCL=ON -DUSE_CUDA=ON -DUSE_CUDF=ON \
          -DBUILD_WITH_SHARED_NCCL=ON \
          -DGDF_INCLUDE_DIR=$CONDA_PREFIX/include \
          -DCMAKE_CXX11_ABI=ON \
          -DPLUGIN_RMM=ON \
          -DRMM_ROOT=${RAPIDS_DIR}/rmm \
          -DCMAKE_BUILD_TYPE=release .. && \
    make -j && make -j install && \
    cd ../python-package && python setup.py install; \
  fi

RUN cd ${RAPIDS_DIR}/dask-xgboost && \
  source activate rapids && \
  ccache -s && \
  python setup.py install

RUN cd ${RAPIDS_DIR}/dask-cuda && \
  source activate rapids && \
  ccache -s && \
  python setup.py install



RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}