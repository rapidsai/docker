# RAPIDS Dockerfile for ubuntu20.04 "runtime" image
#
# runtime: RAPIDS is installed from published conda packages to the 'rapids'
# conda environment. RAPIDS jupyter notebooks are also provided, as well as
# jupyterlab and all the dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=10.1
ARG LINUX_VER=ubuntu20.04
ARG PYTHON_VER=3.7
ARG RAPIDS_VER=0.18
ARG FROM_IMAGE=rapidsai/rapidsai

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-runtime-${LINUX_VER}-py${PYTHON_VER}

RUN source activate rapids && \
    gpuci_conda_retry install -y -n rapids -c pytorch \
    "clx=${RAPIDS_VER}" \
    "cudf_kafka=${RAPIDS_VER}" \
    "custreamz=${RAPIDS_VER}" \
    seqeval \
    python-whois \
    "cudatoolkit=${CUDA_VER}" && \
    pip install "git+https://github.com/rapidsai/cudatashader.git" && \
    pip install wget && \
    pip install "git+https://github.com/slashnext/SlashNext-URL-Analysis-and-Enrichment.git#egg=slashnext-phishing-ir&subdirectory=Python SDK/src"

WORKDIR ${RAPIDS_DIR}

RUN conda clean -afy

ENTRYPOINT [ "/usr/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]