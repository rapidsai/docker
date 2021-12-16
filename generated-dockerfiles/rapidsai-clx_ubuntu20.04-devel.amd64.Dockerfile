# RAPIDS Dockerfile for ubuntu20.04 "devel" image
#
# RAPIDS is built from-source and installed in the base conda environment. The
# sources and toolchains to build RAPIDS are included in this image. RAPIDS
# jupyter notebooks are also provided, as well as jupyterlab and all the
# dependencies required to run them.
#
# Copyright (c) 2021, NVIDIA CORPORATION.

ARG CUDA_VER=11.0
ARG LINUX_VER=ubuntu20.04
ARG PYTHON_VER=3.8
ARG RAPIDS_VER=22.02
ARG FROM_IMAGE=rapidsai/rapidsai-core-dev

FROM ${FROM_IMAGE}:${RAPIDS_VER}-cuda${CUDA_VER}-devel-${LINUX_VER}-py${PYTHON_VER}

ARG RAPIDS_VER
ARG BUILD_BRANCH="branch-${RAPIDS_VER}"

ENV CLX_DIR=${RAPIDS_DIR}/clx

RUN source activate rapids && \
    gpuci_mamba_retry install -y -n rapids -c pytorch \
        "pytorch=1.7.1" \
        torchvision \
        "cudf_kafka=${RAPIDS_VER}" \
        "custreamz=${RAPIDS_VER}" \
        "transformers=4.*" \
        seqeval \
        python-whois \
        faker && \
    pip install -U torch==1.10.0+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html && \
    pip install "git+https://github.com/rapidsai/cudatashader.git" && \
    pip install mockito && \
    pip install wget && \
    pip install "git+https://github.com/slashnext/SlashNext-URL-Analysis-and-Enrichment.git#egg=slashnext-phishing-ir&subdirectory=Python SDK/src"

RUN cd ${RAPIDS_DIR} && \
    git clone -b ${BUILD_BRANCH} https://github.com/rapidsai/clx.git && \
    source activate rapids && \
    cd /rapids/clx/python && \
    python setup.py install


RUN ln -sr /rapids/notebooks/repos/clx/notebooks/ /rapids/notebooks/clx

RUN chmod -R ugo+w /opt/conda ${CLX_DIR} \
  && conda clean -tipy \
  && chmod -R ugo+w /opt/conda ${CLX_DIR}
COPY entrypoint.sh /opt/docker/bin/entrypoint
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]

CMD [ "/bin/bash" ]