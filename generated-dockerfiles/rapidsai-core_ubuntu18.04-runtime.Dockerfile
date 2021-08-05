# RAPIDS Dockerfile for ubuntu18.04 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=ubuntu18.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=21.10
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d' /opt/conda/.condarc; fi

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils 
COPY nbtest.sh nbtestlog2junitxml.py ${RAPIDS_DIR}/utils/



RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      openssh-client \
      libopenmpi-dev \
      openmpi-bin \
    && rm -rf /var/lib/apt/lists/*


RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_conda_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN \
    pip install --upgrade "cryptography>=3.3.2" \
    && pip install --upgrade "urllib3>=1.26.5" \
    && source activate rapids \
    && npm i -g npm@">=7.0"

RUN apt-get update \
    && apt-get -y upgrade \
    && rm -rf /var/lib/apt/lists/*


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
COPY packages.sh /opt/docker/bin/


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
COPY NVIDIA_Deep_Learning_Container_License.pdf . 
COPY source_entrypoints/runtime_devel.sh /opt/docker/bin/entrypoint_source
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]