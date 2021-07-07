# RAPIDS Dockerfile for centos8 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=centos8
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.08
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER} AS rapids-core

ARG PARALLEL_LEVEL=16
ARG RAPIDS_VER
ARG CUDA_VER
ARG UCX_PY_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d' /opt/conda/.condarc; fi

ARG PYTHON_VER

ENV RAPIDS_DIR=/rapids


RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC9_DIR}/lib64
COPY nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/

COPY libm.so.6 ${GCC9_DIR}/lib64

RUN yum install -y \
      openssh-clients \
      openmpi-devel \
      libnsl \
      && yum clean all



RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_conda_retry install -y -n rapids \
      "rapids-build-env=${RAPIDS_VER}*" \
      "rapids-doc-env=${RAPIDS_VER}*" \
      "libcumlprims=${RAPIDS_VER}*" \
      "ucx-py=${UCX_PY_VER}.*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
      "rapids-build-env=${RAPIDS_VER}*" \
      "rapids-doc-env=${RAPIDS_VER}*"


RUN source activate rapids \
    && npm i -g npm@">=7.0"

RUN yum -y upgrade \
    && yum clean all


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls

RUN gpuci_conda_retry install -y -n rapids \
        "rapids-notebook-env=${RAPIDS_VER}*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
        "rapids-notebook-env=${RAPIDS_VER}*"

ENV DASK_LABEXTENSION__FACTORY__MODULE="dask_cuda"
ENV DASK_LABEXTENSION__FACTORY__CLASS="LocalCUDACluster"

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && cd notebooks \
  && git submodule update --init --remote --no-single-branch --depth 1

COPY test.sh /

COPY start-jupyter.sh stop-jupyter.sh /rapids/utils/

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786
RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cudf.git \
  && cd cudf \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cuml.git \
  && cd cuml \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-${RAPIDS_VER} --depth 1 --single-branch https://github.com/rapidsai/xgboost.git \
  && cd xgboost \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/rmm.git \
  && cd rmm \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b main --depth 1 --single-branch https://github.com/rapidsai/benchmark.git \
  && cd benchmark \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cusignal.git \
  && cd cusignal \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cuxfilter \
  && cd cuxfilter \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cuspatial.git \
  && cd cuspatial \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/cugraph.git \
  && cd cugraph \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b ${BUILD_BRANCH} --depth 1 --single-branch https://github.com/rapidsai/dask-cuda.git \
  && cd dask-cuda \
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
  ./build.sh --allgpuarch cugraph libcugraph

RUN cd ${RAPIDS_DIR}/xgboost && \
  source activate rapids && \
  TREELITE_VER=$(conda list -e treelite | grep -v "#" | grep "treelite=") && \
  gpuci_conda_retry remove -y --force-remove treelite && \
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
  fi && \
  gpuci_conda_retry install -y --no-deps "${TREELITE_VER}"

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
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]
FROM rapids-core AS rapids-std

ARG RAPIDS_VER
ARG CUDA_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"

ENV BLAZING_DIR=/blazing

RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/Welcome_to_BlazingSQL_Notebooks.git


RUN gpuci_conda_retry install -y -n rapids -c blazingsql-nightly -c blazingsql \
      "blazingsql-build-env=${RAPIDS_VER}*" \
      "rapids-build-env=${RAPIDS_VER}*" \
      "cudatoolkit=${CUDA_VER}*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
      "blazingsql-build-env=${RAPIDS_VER}*" \
      "rapids-build-env=${RAPIDS_VER}*"


ENV CUDF_HOME=/rapids/cudf

RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone -b ${BUILD_BRANCH} https://github.com/BlazingDB/blazingsql.git


ENV LD_LIBRARY_PATH_ORIG=${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/compat

RUN rm -f ${GCC9_DIR}/lib64/libm.so.6

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
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]

FROM rapids-std

ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"


RUN source activate rapids && \
    gpuci_conda_retry install -y -n rapids -c pytorch \
        "pytorch=1.7.1" \
        torchvision \
        "cudf_kafka=${RAPIDS_VER}" \
        "custreamz=${RAPIDS_VER}" \
        "transformers=4.*" \
        seqeval \
        python-whois \
        faker && \
    pip install "git+https://github.com/rapidsai/cudatashader.git" && \
    pip install mockito && \
    pip install wget && \
    pip install "git+https://github.com/slashnext/SlashNext-URL-Analysis-and-Enrichment.git#egg=slashnext-phishing-ir&subdirectory=Python SDK/src"

RUN cd ${RAPIDS_DIR} \
    && git clone -b ${BUILD_BRANCH} https://github.com/rapidsai/clx.git

# clx build/install
RUN source activate rapids && \
    cd /rapids/clx/python && \
    python setup.py install
WORKDIR ${RAPIDS_DIR}

RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR}

COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]