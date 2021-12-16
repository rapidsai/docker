# RAPIDS Dockerfile for centos8 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=centos8
ARG PYTHON_VER=3.8
ARG RAPIDS_VER=22.02
ARG FROM_IMAGE=rapidsai/rapidsai-core

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

ARG RAPIDS_VER
ARG CUDA_VER
RUN source activate rapids && \
    gpuci_mamba_retry install -y -n rapids -c pytorch \
    "clx=${RAPIDS_VER}" \
    "cudf_kafka=${RAPIDS_VER}" \
    "custreamz=${RAPIDS_VER}" \
    seqeval \
    python-whois \
    "cudatoolkit=${CUDA_VER}" && \
    pip install -U torch==1.10.0+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html && \
    pip install "git+https://github.com/rapidsai/cudatashader.git" && \
    pip install wget && \
    pip install "git+https://github.com/slashnext/SlashNext-URL-Analysis-and-Enrichment.git#egg=slashnext-phishing-ir&subdirectory=Python SDK/src"

RUN ln -sr /rapids/notebooks/repos/clx/notebooks/ /rapids/notebooks/clx

RUN chmod -R ugo+w /opt/conda ${CLX_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${CLX_DIR}
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]