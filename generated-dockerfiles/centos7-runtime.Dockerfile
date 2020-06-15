# RAPIDS Dockerfile for centos7 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2020, NVIDIA CORPORATION.

ARG CUDA_VERSION=10.0
ARG CUDA_MAJORMINOR_VERSION=${CUDA_VERSION}
ARG LINUX_VERSION=centos7
ARG PYTHON_VERSION=3.6

FROM rapidsaistaging/rapidsai-nightly-staging:0.15-cuda${CUDA_VERSION}-base-${LINUX_VERSION}-py${PYTHON_VERSION}

ARG CUDA_MAJORMINOR_VERSION

ARG DASK_XGBOOST_CONDA_VERSION_SPEC=0.2*
ARG RAPIDS_CONDA_VERSION_SPEC=0.15*

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
  && git clone -b branch-0.15 --depth 1 --single-branch https://github.com/rapidsai/notebooks.git \
  && cd notebooks \
  && git submodule update --init --remote --recursive --no-single-branch --depth 1 \
  && chmod -R ugo+w /opt/conda ${RAPIDS_DIR}

COPY test.sh test-nbcontrib.sh /

WORKDIR ${RAPIDS_DIR}/notebooks
EXPOSE 8888
EXPOSE 8787
EXPOSE 8786

COPY .start_jupyter_run_in_rapids.sh /.run_in_rapids