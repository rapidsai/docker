# RAPIDS Dockerfile for ubuntu20.04 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=ubuntu20.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.12
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

ARG RAPIDS_VER
ARG CUDA_VER
RUN gpuci_conda_retry install -y -n rapids -c blazingsql-nightly -c blazingsql \
  "rapids-blazing=${RAPIDS_VER}*" \
  "cudatoolkit=${CUDA_VER}"

ENV BLAZING_DIR=/blazing


RUN mkdir -p ${BLAZING_DIR} \
    && cd ${BLAZING_DIR} \
    && git clone https://github.com/BlazingDB/Welcome_to_BlazingSQL_Notebooks.git
WORKDIR ${RAPIDS_DIR}


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR} ${BLAZING_DIR}
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]