# RAPIDS Dockerfile for centos7 "base" image
#
# base: RAPIDS is installed from published conda packages to the 'rapids' conda
# environment.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VERSION=10.0
ARG CUDA_MAJORMINOR_VERSION=${CUDA_VERSION}
ARG LINUX_VERSION=centos7
ARG PYTHON_VERSION=3.6

FROM gpuci/miniconda-cuda-rapidsenv:${CUDA_VERSION}-runtime-${LINUX_VERSION}-py${PYTHON_VERSION}

ARG CUDA_MAJORMINOR_VERSIONssssss

ARG DASK_XGBOOST_CONDA_VERSION_SPEC=0.2*
ARG RAPIDS_CONDA_VERSION_SPEC=0.15*

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils ${GCC7_DIR}/lib64
COPY start_jupyter.sh condaretry nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/

COPY libm.so.6 ${GCC7_DIR}/lib64

COPY .condarc /opt/conda/.condarc

RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN ${RAPIDS_DIR}/utils/condaretry install -y -n rapids --freeze-installed \
  cudatoolkit=${CUDA_MAJORMINOR_VERSION} \
  rapids=${RAPIDS_CONDA_VERSION_SPEC} \
  && conda clean -afy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}

WORKDIR ${RAPIDS_DIR}

COPY .run_in_rapids.sh /.run_in_rapids
ENTRYPOINT [ "/usr/bin/tini", "--", "/.run_in_rapids" ]

CMD [ "/bin/bash" ]