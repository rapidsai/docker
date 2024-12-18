# syntax=docker/dockerfile:1

ARG PYTHON_VER=unset
ARG RAPIDS_VER=24.12

FROM condaforge/miniforge3:24.7.1-2 AS cuvs-bench-cpu
ARG RAPIDS_VER
ARG PYTHON_VER

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
RUN apt-get install perl patch -y

# update everything before other environment changes, to ensure mixing
# an older conda with newer packages still works well
# ref: https://github.com/rapidsai/ci-imgs/issues/185
RUN <<EOF
mamba update --all -y -n base
mamba install -y -n base "python=${PYTHON_VER}"
mamba update --all -y -n base
mamba install -y -n base \
  "cuvs-bench-cpu=${RAPIDS_VER}.*" \
  "python=${PYTHON_VER}" \
  "requests"
conda clean -afy
chmod -R 777 /opt/conda
EOF

RUN useradd -rm -d /home/rapids -s /bin/bash -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY cuvs-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM bench-base AS cuvs-bench-cpu-datasets

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY cuvs-bench/cuvs_bench_get_dataset.patch /home/rapids/cuvs-bench/cuvs_bench_get_dataset.patch

COPY cuvs-bench/get_datasets.sh /home/rapids/cuvs-bench/get_datasets.sh

COPY cuvs-bench/run_benchmark.sh /data/scripts/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/cuvs-bench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark_preloaded_datasets.sh"]
