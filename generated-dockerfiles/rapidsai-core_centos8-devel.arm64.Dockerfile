# RAPIDS Dockerfile for centos8 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2022, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=centos8
ARG PYTHON_VER=3.8
ARG RAPIDS_VER=22.04
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

ARG PARALLEL_LEVEL=16
ARG RAPIDS_VER
ARG CUDA_VER
ARG UCX_PY_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"
ARG LINUX_VER
ENV RAPIDS_VER=$RAPIDS_VER

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d;/dask\/label\/dev/d' /opt/conda/.condarc; fi

ARG PYTHON_VER

ENV RAPIDS_DIR=/rapids

RUN yum install -y \
      openssh-clients \
      openmpi-devel \
      libnsl \
      && yum clean all



RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC9_DIR}/lib64


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_mamba_retry install -y -n rapids \
      "rapids-build-env=${RAPIDS_VER}*" \
      "libcumlprims=${RAPIDS_VER}*" \
      "libcugraphops=${RAPIDS_VER}*" \
      "ucx-py=${UCX_PY_VER}.*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
      "rapids-build-env=${RAPIDS_VER}*"


RUN source activate rapids \
    && npm i -g npm@">=7.0"

RUN yum -y upgrade \
    && yum clean all


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls

RUN gpuci_mamba_retry install -y -n rapids \
        "rapids-notebook-env=${RAPIDS_VER}*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
        "rapids-notebook-env=${RAPIDS_VER}*"

ENV DASK_LABEXTENSION__FACTORY__MODULE="dask_cuda"
ENV DASK_LABEXTENSION__FACTORY__CLASS="LocalCUDACluster"

RUN gpuci_mamba_retry install -y -n rapids jupyterlab-nvdashboard

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && ln -s $(realpath notebooks/test/test.sh) /test.sh \
  && cd notebooks \
  && rm -rf ci clx \
  && git submodule update --init --remote --no-single-branch --depth 1

COPY start-jupyter.sh stop-jupyter.sh /rapids/utils/

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786
COPY tag-repo.sh /usr/local/bin/tag-repo

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cudf.git \
  && cd cudf \
  && tag-repo \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cuml.git \
  && cd cuml \
  && tag-repo \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-${RAPIDS_VER} --depth 1 --single-branch https://github.com/rapidsai/xgboost.git \
  && cd xgboost \
  && tag-repo \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/rmm.git \
  && cd rmm \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b main --depth 1 --single-branch https://github.com/rapidsai/benchmark.git \
  && cd benchmark \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/raft.git \
  && cd raft \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cusignal.git \
  && cd cusignal \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cuxfilter \
  && cd cuxfilter \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cuspatial.git \
  && cd cuspatial \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cugraph.git \
  && cd cugraph \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/dask-cuda.git \
  && cd dask-cuda \
  && tag-repo \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 
  

ENV LD_LIBRARY_PATH_PREBUILD=${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs

ENV NCCL_ROOT=/opt/conda/envs/rapids
ENV PARALLEL_LEVEL=${PARALLEL_LEVEL}

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/conda/envs/rapids/lib

ENV CUDAToolkit_ROOT="/usr/local/cuda"
ENV CUDACXX="/usr/local/cuda/bin/nvcc"

RUN cd ${RAPIDS_DIR}/rmm && \
  source activate rapids && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/benchmark && \
  source activate rapids && \
  cd rapids_pytest_benchmark && \
  python setup.py install

RUN cd ${RAPIDS_DIR}/raft && \
  source activate rapids && \
  ./build.sh --allgpuarch --compile-libs --install libraft pyraft pylibraft

RUN cd ${RAPIDS_DIR}/cudf && \
  source activate rapids && \
  ./build.sh --allgpuarch libcudf cudf dask_cudf libcudf_kafka cudf_kafka tests

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
  ./build.sh libcuspatial cuspatial tests

RUN cd ${RAPIDS_DIR}/cuml && \
  source activate rapids && \
  ./build.sh --allgpuarch libcuml cuml prims

RUN cd ${RAPIDS_DIR}/cugraph && \
  source activate rapids && \
  ./build.sh --allgpuarch cugraph libcugraph pylibcugraph

RUN cd ${RAPIDS_DIR}/xgboost && \
  source activate rapids && \
  mkdir -p build && cd build && \
  cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
        -DUSE_NCCL=ON -DUSE_CUDA=ON -DUSE_CUDF=ON \
        -DBUILD_WITH_SHARED_NCCL=ON \
        -DGDF_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DCMAKE_CXX_STANDARD:STRING="17" \
        -DPLUGIN_RMM=ON \
        -DBUILD_WITH_CUDA_CUB=ON \
        -DRMM_ROOT=${RAPIDS_DIR}/rmm \
        -DCMAKE_BUILD_TYPE=release .. && \
  make -j && make -j install && \
  cd ../python-package && python setup.py install;

RUN cd ${RAPIDS_DIR}/dask-cuda && \
  source activate rapids && \
  python setup.py install



ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH_PREBUILD}

COPY packages.sh /opt/docker/bin/


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
COPY NVIDIA_Deep_Learning_Container_License.pdf . 
COPY source_entrypoints/runtime_devel.sh /opt/docker/bin/entrypoint_source
COPY entrypoint.sh /opt/docker/bin/entrypoint


ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]