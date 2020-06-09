# RAPIDS Dockerfile for Ubuntu "quick devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VERSION=10.0
ARG LINUX_VERSION=ubuntu18.04
ARG PYTHON_VERSION=3.6

FROM rapidsaistaging/rapidsai-dev-nightly-staging:0.15-cuda${CUDA_VERSION}-devel-${LINUX_VERSION}-py${PYTHON_VERSION}

ARG PARALLEL_LEVEL

RUN cd ${RAPIDS_DIR}/rmm && \
    git pull
RUN cd ${RAPIDS_DIR}/cudf && \
    git pull
RUN cd ${RAPIDS_DIR}/cusignal && \
    git pull
RUN cd ${RAPIDS_DIR}/cuxfilter && \
    git pull
RUN cd ${RAPIDS_DIR}/cuspatial && \
    git pull
RUN cd ${RAPIDS_DIR}/cuml && \
    git pull
RUN cd ${RAPIDS_DIR}/cugraph && \
    git pull
RUN cd ${RAPIDS_DIR}/xgboost && \
    git pull
RUN cd ${RAPIDS_DIR}/dask-xgboost && \
    git pull
RUN cd ${RAPIDS_DIR}/dask-cuda && \
    git pull

ENV NCCL_ROOT=/opt/conda/envs/rapids
ENV PARALLEL_LEVEL=${PARALLEL_LEVEL}

RUN cd ${RAPIDS_DIR}/rmm && \
  source activate rapids && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cudf && \
  source activate rapids && \
  ./build.sh && \
  ./build.sh tests

RUN cd ${RAPIDS_DIR}/cusignal && \
  source activate rapids && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cuxfilter && \
  source activate rapids && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cuspatial && \
  source activate rapids && \
  export CUSPATIAL_HOME="$PWD" && \
  export CUDF_HOME="$PWD/../cudf" && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cuml && \
  source activate rapids && \
  ./build.sh --allgpuarch libcuml cuml prims

RUN cd ${RAPIDS_DIR}/cugraph && \
  source activate rapids && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/xgboost && \
  source activate rapids && \
  mkdir -p build && cd build && \
  cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
        -DUSE_NCCL=ON -DUSE_CUDA=ON -DUSE_CUDF=ON \
        -DBUILD_WITH_SHARED_NCCL=ON \
        -DGDF_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DCMAKE_CXX11_ABI=ON \
        -DCMAKE_BUILD_TYPE=release .. && \
  make -j && make -j install && \
  cd ../python-package && python setup.py install

RUN cd ${RAPIDS_DIR}/dask-xgboost && \
  source activate rapids && \
  python setup.py install

RUN cd ${RAPIDS_DIR}/dask-cuda && \
  source activate rapids && \
  python setup.py install


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR}