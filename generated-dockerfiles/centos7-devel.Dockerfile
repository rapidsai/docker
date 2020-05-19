# RAPIDS Dockerfile for centos7 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VERSION=10.0
ARG CUDA_MAJORMINOR_VERSION=${CUDA_VERSION}
ARG LINUX_VERSION=centos7
ARG PYTHON_VERSION=3.6

FROM gpuci/miniconda-cuda-rapidsenv:${CUDA_VERSION}-devel-${LINUX_VERSION}-py${PYTHON_VERSION}

ARG CC_VERSION=7
ARG CXX_VERSION=7
ARG PARALLEL_LEVEL=16

ARG CUDA_MAJORMINOR_VERSION
ARG PYTHON_VERSION

ENV RAPIDS_DIR=/rapids


RUN yum -y update \
  && yum -y install which patch \
  && yum clean all

COPY --from=gpuci/builds-gcc7:10.0-devel-centos7 /usr/local/gcc7 /usr/local/gcc7

ENV GCC7_DIR=/usr/local/gcc7
ENV CC=${GCC7_DIR}/bin/gcc
ENV CXX=${GCC7_DIR}/bin/g++
ENV PATH=${GCC7_DIR}/bin:$PATH
ENV CUDAHOSTCXX=${GCC7_DIR}/bin/g++
ENV LD_LIBRARY_PATH=${GCC7_DIR}/lib64

RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC7_DIR}/lib64
COPY start_jupyter.sh condaretry nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/

COPY .condarc /opt/conda/.condarc

RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN ${RAPIDS_DIR}/utils/condaretry install -y -n rapids --freeze-installed \
  rapids-build-env=${RAPIDS_CONDA_VERSION_SPEC}

RUN ${RAPIDS_DIR}/utils/condaretry install -y -n rapids --freeze-installed \
  rapids-doc-env=${RAPIDS_CONDA_VERSION_SPEC}

RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN ${RAPIDS_DIR}/utils/condaretry install -y -n rapids --freeze-installed \
    rapids-notebook-env=${RAPIDS_CONDA_VERSION_SPEC} \
  && conda clean -afy \
  && chmod -R ugo+w /opt/conda

RUN source activate rapids \
  && pip install "git+https://github.com/rapidsai/jupyterlab-nvdashboard.git@master#egg=jupyterlab-nvdashboard" --upgrade \
  && jupyter labextension install dask-labextension jupyterlab-nvdashboard

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && cd notebooks \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}

COPY test.sh test-nbcontrib.sh /

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786

COPY .start_jupyter_run_in_rapids.sh /.run_in_rapids
COPY libm.so.6 ${GCC7_DIR}/lib64

RUN cd ${RAPIDS_DIR} \
  && source activate rapids \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/cudf.git \
  && cd cudf \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/cuml.git \
  && cd cuml \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b rapids-0.14-release --depth 1 --single-branch https://github.com/rapidsai/xgboost.git \
  && cd xgboost \
  && git submodule update --init --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/rmm.git \
  && cd rmm \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/cusignal.git \
  && cd cusignal \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/cuxfilter \
  && cd cuxfilter \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/cuspatial.git \
  && cd cuspatial \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/cugraph.git \
  && cd cugraph \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b branch-0.14 --depth 1 --single-branch https://github.com/rapidsai/dask-cuda.git \
  && cd dask-cuda \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && cd ${RAPIDS_DIR} \
  && git clone -b dask-cudf --depth 1 --single-branch https://github.com/rapidsai/dask-xgboost.git \
  && cd dask-xgboost \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 
  

ENV LD_LIBRARY_PATH_PREBUILD=${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs

ENV NCCL_ROOT=/opt/conda/envs/rapids
ENV PARALLEL_LEVEL=${PARALLEL_LEVEL}

RUN cd ${RAPIDS_DIR}/rmm && \
  source activate rapids && \
  ./build.sh

RUN cd ${RAPIDS_DIR}/cudf && \
  source activate rapids && \
  ./build.sh -l && \
  cd cpp/build && \
  make -j${PARALLEL_LEVEL} build_tests_nvstrings && \
  make -j${PARALLEL_LEVEL} build_tests_cudf

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


ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH_PREBUILD}

COPY .run_in_rapids.sh /.run_in_rapids
ENTRYPOINT [ "/usr/bin/tini", "--", "/.run_in_rapids" ]

CMD [ "/bin/bash" ]