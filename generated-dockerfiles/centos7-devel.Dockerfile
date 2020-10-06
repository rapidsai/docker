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
ARG RAPIDS_VER=0.17
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

RUN conda install -c gpuci gpuci-ccache
ENV CCACHE_NOHASHDIR=
ENV CCACHE_DIR="/ccache"
ENV CCACHE_COMPILERCHECK="%compiler% --version"

ENV CC="/usr/local/bin/gcc"
ENV CXX="/usr/local/bin/g++"
ENV NVCC="/usr/local/bin/nvcc"
ENV CUDAHOSTCXX="/usr/local/bin/g++"
ENV CUDAToolkit_ROOT="/usr/local/cuda"
RUN ln -s "$(which ccache)" "/usr/local/bin/gcc" \
    && ln -s "$(which ccache)" "/usr/local/bin/g++" \
    && ln -s "$(which ccache)" "/usr/local/bin/nvcc"

COPY ccache /ccache
RUN ccache -s

ARG PARALLEL_LEVEL=16
ARG RAPIDS_VER

ARG PYTHON_VER

ENV RAPIDS_DIR=/rapids


RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC7_DIR}/lib64
COPY nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/

COPY libm.so.6 ${GCC7_DIR}/lib64
RUN yum update -y \
    && yum install -y \
        sudo \
    && rm -rf /var/cache/yum/*


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_retry conda install -y -n rapids \
      "rapids-build-env=${RAPIDS_VER}*" \
      "rapids-doc-env=${RAPIDS_VER}*" \
      "libcumlprims=${RAPIDS_VER}*" \
      "ucx-py=${RAPIDS_VER}*" \
    && conda remove -y -n rapids --force-remove \
      "rapids-build-env=${RAPIDS_VER}*" \
      "rapids-doc-env=${RAPIDS_VER}*"


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls

RUN gpuci_conda_retry install -y -n rapids \
        "rapids-notebook-env=${RAPIDS_VER}*" \
    && conda remove -y -n rapids --force-remove \
        "rapids-notebook-env=${RAPIDS_VER}*"

RUN gpuci_conda_retry install -y -n rapids jupyterlab-nvdashboard

RUN source activate rapids \
  && jupyter labextension install dask-labextension jupyterlab-nvdashboard

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-${RAPIDS_VER} --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && cd notebooks \
  && git submodule update --init --remote --no-single-branch --depth 1

COPY test.sh test-nbcontrib.sh /

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/cudf.git \
  && cd cudf \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/cuml.git \
  && cd cuml \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b rapids-v0.16 --depth 1 --single-branch https://github.com/rapidsai/xgboost.git \
  && cd xgboost \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/rmm.git \
  && cd rmm \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/cusignal.git \
  && cd cusignal \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/cuxfilter \
  && cd cuxfilter \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/cuspatial.git \
  && cd cuspatial \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/cugraph.git \
  && cd cugraph \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.17 --depth 1 --single-branch https://github.com/rapidsai/dask-cuda.git \
  && cd dask-cuda \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b dask-cudf --depth 1 --single-branch https://github.com/rapidsai/dask-xgboost.git \
  && cd dask-xgboost \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 
  

ENV LD_LIBRARY_PATH_PREBUILD=${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs

RUN mv /opt/conda/envs/rapids/include/dmlc/ /opt/conda/envs/rapids/include/dmlc-OFF

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



ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH_PREBUILD}

RUN ccache -s \
  && ccache -c \
  && chmod -R ugo+w /ccache \
  && ccache -s

COPY create_user.sh packages.sh /opt/docker/bin/
RUN /opt/docker/bin/create_user.sh


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
COPY source_entrypoints/runtime_devel.sh /opt/docker/bin/entrypoint_source
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]