# syntax=docker/dockerfile:1

ARG CUDA_VER=unset
ARG PYTHON_VER=unset
ARG LINUX_VER=unset

ARG RAPIDS_VER=25.06

FROM rapidsai/miniforge-cuda:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} AS cuvs-bench
ARG CUDA_VER
ARG RAPIDS_VER

COPY condarc /opt/conda/.condarc

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Create a data folder accessible by any user so mounted volumes under it can be accessible
# when the user passes their uid to docker run with -u $(id -u)
# Also add the conda_prefix config to the global bashrc file so that all users have it correctly configured.
RUN <<EOF
mkdir /data
chmod 777 /data
echo ". /opt/conda/etc/profile.d/conda.sh; conda activate base" >> /etc/bash.bashrc
EOF

# we need perl temporarily for the remaining benchmark perl scripts
RUN <<EOF
apt-get update
apt-get install -y \
  perl \
  wget
wget https://github.com/rapidsai/gha-tools/releases/latest/download/tools.tar.gz -O - | tar -xz -C /usr/local/bin
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
rapids-mamba-retry update --all -y -n base
rapids-mamba-retry install -y -n base \
    "cuvs-bench=${RAPIDS_VER}.*" \
    "cuda-version=${CUDA_VER%.*}.*"
conda clean -afy
chmod -R 777 /opt/conda
EOF

# We add rapids is the default user in case the user runs without -u,
# but users are encouraged to  use the -u docker run flag to write/read to mounted volumes.
RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY cuvs-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms cuvs_cagra", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM cuvs-bench AS cuvs-bench-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY cuvs-bench/get_datasets.sh /home/rapids/cuvs-bench/get_datasets.sh

COPY cuvs-bench/run_benchmarks_preloaded_datasets.sh /data/scripts/run_benchmarks_preloaded_datasets.sh

RUN /home/rapids/cuvs-bench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib", ""]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmarks_preloaded_datasets.sh"]
