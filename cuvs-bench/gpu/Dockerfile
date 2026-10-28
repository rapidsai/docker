# syntax=docker/dockerfile:1
# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
ARG CUDA_MAJOR=notset
ARG PYTHON_VER=notset
ARG RAPIDS_VER=notset

FROM rapidsai/cuvs-bench:${RAPIDS_VER}-cuda${CUDA_MAJOR}-py${PYTHON_VER} AS cuvs-bench

COPY pinned /opt/conda/conda-meta/pinned

RUN <<EOF
rapids-conda-retry update \
  --no-deps \
  --force-reinstall \
  --yes \
    ca-certificates \
    certifi \
    conda \
    pip
EOF

USER root

# Update Ubuntu certs
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

USER rapids

# Test that revoked certs are rejected by the system store, Python's
# builtin store, and certifi (each of these should fail)
RUN ! curl https://dv-g3b-emudhra.we-have-a-problem.com/ && \
    ! python -c "import urllib.request; urllib.request.urlopen('https://dv-g3b-emudhra.we-have-a-problem.com/')" 2>&1 && \
    ! python -c "import ssl, certifi, urllib.request; ctx = ssl.create_default_context(cafile=certifi.where()); urllib.request.urlopen('https://dv-g3b-emudhra.we-have-a-problem.com/', context=ctx)" 2>&1
