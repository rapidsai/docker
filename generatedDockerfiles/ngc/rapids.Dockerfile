ARG CUDA_VERSION=10.0
ARG BASE_IMAGE=devel-ubuntu18.04
FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-${BASE_IMAGE}

COPY rapids.Dockerfile /Dockerfile

CMD ["/bin/bash"]
