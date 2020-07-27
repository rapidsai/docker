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
ARG RAPIDS_VER=0.15
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

RUN source activate rapids \
 && git clone https://github.com/rapidsai/ccache-feedstock.git /tmp/ccache-feedstock && cd /tmp/ccache-feedstock \
 && git checkout enh-rapids-ccache  \
 && cd recipe \
 && conda build . \
 && conda install --use-local ccache


ENV CCACHE_NOHASHDIR=
ENV CCACHE_DIR="/ccache"
ENV CCACHE_COMPILERCHECK="%compiler% --version"

RUN which gcc
RUN which ccache
ENV CC="/usr/bin/gcc"
ENV CXX="/usr/bin/g++"
ENV NVCC="/usr/bin/nvcc"
ENV CUDAHOSTCXX="/usr/bin/g++"
RUN ln -s "$(which ccache)" "/usr/bin/gcc" \
    && ln -s "$(which ccache)" "/usr/bin/g++" \
    && ln -s "$(which ccache)" "/usr/bin/nvcc"

COPY ccache /ccache
RUN ccache -s

ARG PARALLEL_LEVEL=16
ARG RAPIDS_VER=0.15*

ARG PYTHON_VER

ENV RAPIDS_DIR=/rapids

RUN apt-get update && apt-get install -y \
    gsfonts \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${RAPIDS_DIR}/utils 
COPY start_jupyter.sh nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_retry conda install -y -n rapids \
      rapids-build-env=${RAPIDS_VER} \
      rapids-doc-env=${RAPIDS_VER} \
    && conda remove -y -n rapids --force-remove \
      rapids-build-env=${RAPIDS_VER} \
      rapids-doc-env=${RAPIDS_VER}


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls

RUN gpuci_conda_retry install -y -n rapids \
        rapids-notebook-env=${RAPIDS_VER} \
    && conda remove -y -n rapids --force-remove \
        rapids-notebook-env=${RAPIDS_VER}

RUN source activate rapids \
  && pip install "git+https://github.com/rapidsai/jupyterlab-nvdashboard.git@master#egg=jupyterlab-nvdashboard" --upgrade \
  && jupyter labextension install dask-labextension jupyterlab-nvdashboard

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && cd notebooks \
  && git submodule update --init --remote --no-single-branch --depth 1

COPY test.sh test-nbcontrib.sh /

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786

COPY .start_jupyter_run_in_rapids.sh /.run_in_rapids

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/cudf.git \
  && cd cudf \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/cuml.git \
  && cd cuml \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b v1.1.0 --depth 1 --single-branch https://github.com/dmlc/xgboost.git \
  && cd xgboost \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/rmm.git \
  && cd rmm \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/cusignal.git \
  && cd cusignal \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/cuxfilter \
  && cd cuxfilter \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/cuspatial.git \
  && cd cuspatial \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/cugraph.git \
  && cd cugraph \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/dask-cuda.git \
  && cd dask-cuda \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b dask-cudf --depth 1 --single-branch https://github.com/rapidsai/dask-xgboost.git \
  && cd dask-xgboost \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 
  


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
  ccache -s && \
  python setup.py install

RUN cd ${RAPIDS_DIR}/dask-cuda && \
  source activate rapids && \
  ccache -s && \
  python setup.py install



RUN ccache -s \
  && ccache -c \
  && chmod -R ugo+w /ccache \
  && ccache -s


RUN conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
ENTRYPOINT [ "/usr/bin/tini", "--", "/.run_in_rapids" ]

CMD [ "/bin/bash" ]