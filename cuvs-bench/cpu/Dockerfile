# syntax=docker/dockerfile:1
# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

ARG PYTHON_VER=notset
ARG RAPIDS_VER=notset

FROM rapidsai/cuvs-bench-cpu:${RAPIDS_VER}-py${PYTHON_VER}

COPY pinned /opt/conda/conda-meta/pinned

RUN <<EOF
rapids-conda-retry update \
  --yes \
    ca-certificates \
    certifi \
    conda \
    pip
EOF
