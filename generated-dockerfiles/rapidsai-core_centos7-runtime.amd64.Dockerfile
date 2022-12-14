# RAPIDS Dockerfile for centos7 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2022, NVIDIA CORPORATION.

ARG CUDA_VER=11.5
ARG LINUX_VER=centos7
ARG PYTHON_VER=3.9
ARG RAPIDS_VER=23.02
ARG FROM_IMAGE=gpuci/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

ARG CUDA_VER
ARG DASK_XGBOOST_VER=0.2*
ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"
ARG LINUX_VER
ENV RAPIDS_VER=$RAPIDS_VER

RUN if [ "${BUILD_BRANCH}" = "main" ]; then sed -i '/nightly/d;/dask\/label\/dev/d' /opt/conda/.condarc; fi

ENV RAPIDS_DIR=/rapids

RUN mkdir -p ${RAPIDS_DIR}/utils

RUN yum install -y \
      openssh-clients \
      openmpi-devel \
      libnsl \
      findutils \
      && yum clean all



RUN source activate rapids \
  && env \
  && conda info \
  && conda config --show-sources \
  && conda list --show-channel-urls
RUN gpuci_mamba_retry install -y -n rapids \
  "rapids=${RAPIDS_VER}*"


RUN source activate rapids \
    && npm i -g npm@">=7.0" \
    && npm i -g codecov@">=3.7.1"

RUN rm -f /opt/conda/lib/python3.*/mailcap.py \
    && rm -f /opt/conda/envs/rapids/lib/python3.*/mailcap.py

RUN yum -y upgrade \
    && yum clean all


RUN gpuci_mamba_retry install -y -n rapids --freeze-installed \
        "rapids-notebook-env=${RAPIDS_VER}*" \
    && gpuci_conda_retry remove -y -n rapids --force-remove \
        "rapids-notebook-env=${RAPIDS_VER}*"

ENV DASK_LABEXTENSION__FACTORY__MODULE="dask_cuda"
ENV DASK_LABEXTENSION__FACTORY__CLASS="LocalCUDACluster"

RUN gpuci_mamba_retry install -y -n rapids --freeze-installed jupyterlab-nvdashboard

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
COPY packages.sh /opt/docker/bin/


RUN chmod -R ugo+w /opt/conda ${RAPIDS_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}
COPY NVIDIA_Deep_Learning_Container_License.pdf . 
COPY source_entrypoints/runtime_devel.sh /opt/docker/bin/entrypoint_source
COPY entrypoint.sh /opt/docker/bin/entrypoint

ENV PATH="/opt/conda/condabin:/opt/conda/envs/rapids/bin:/opt/conda/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]