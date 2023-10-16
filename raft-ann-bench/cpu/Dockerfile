# syntax=docker/dockerfile:1

ARG PYTHON_VER=3.10
ARG RAPIDS_VER=23.12

FROM condaforge/mambaforge:23.3.1-0 as raft-ann-bench-cpu
ARG RAPIDS_VER
ARG PYTHON_VER

COPY condarc /opt/conda/.condarc

# Create a data folder accessible by any user so mounted volumes under it can be accessible
# when the user passes their uid to docker run with -u $(id -u)
# Also add the conda_prefix config to the global bashrc file so that all users have it correctly configured.
RUN mkdir /data && chmod 777 /data \
    &&  echo "export CONDA_PREFIX=/opt/conda" >> /etc/bash.bashrc

# temporarily downgrade conda from 23.9.0 due to https://github.com/mamba-org/mamba/issues/2882
# after the mamba update step
RUN mamba update --all -y -n base \
    && conda install -y -n base conda==23.7.4 \
    && mamba install -y -n base \
    "raft-ann-bench-cpu=${RAPIDS_VER}.*" \
    "python=${PYTHON_VER}" \
    && conda clean -afy \
    && chmod -R 777 /opt/conda

RUN useradd -rm -d /home/rapids -s /bin/bash -u 1001 rapids
USER rapids
WORKDIR /data/benchmarks

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM bench-base as raft-ann-bench-cpu-datasets

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark_preloaded_datasets.sh"]

