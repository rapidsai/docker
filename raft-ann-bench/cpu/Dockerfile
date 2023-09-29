# syntax=docker/dockerfile:1

ARG PYTHON_VER=3.10
ARG RAPIDS_VER=23.12

FROM condaforge/mambaforge:23.3.1-0 as raft-ann-bench-cpu
ARG RAPIDS_VER
ARG PYTHON_VER

# Create a conda group and assign it as root's primary group
RUN groupadd conda; \
  usermod -g conda root

# Ensure new files are created with group write access & setgid. See https://unix.stackexchange.com/a/12845
# /opt/conda will need to be accessible by every user to support the flag -u $(id -u)
RUN chown root:conda /opt/conda \
    && chmod -R 777 /opt/conda

# Reassign root's primary group to root
RUN usermod -g root root

# Create a data folder accessible by any user so mounted volumes under it can be accessible
# when the user passes their uid to docker run with -u $(id -u)
RUN mkdir /data && chmod 777 /data
RUN useradd -rm -d /home/rapids -s /bin/bash -g conda -u 1001 rapids
USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

RUN mamba update --all -y -n base \
    &&mamba install -y -n base \
        "raft-ann-bench-cpu=${RAPIDS_VER}.*" \
        "python=${PYTHON_VER}" \
    && conda clean -afy

# we need to change the permissions of the conda folder so that all users can execute
# particularly the user passed by -u $(id -u)
USER root
RUN chmod -R 777 /opt/conda
USER rapids

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark.sh"]


FROM bench-base as raft-ann-bench-cpu-datasets

COPY raft-ann-bench/get_datasets.sh /home/rapids/raftannbench/get_datasets.sh

COPY raft-ann-bench/run_benchmark.sh /data/scripts/run_benchmark_preloaded_datasets.sh

RUN /home/rapids/raftannbench/get_datasets.sh

CMD ["--dataset fashion-mnist-784-euclidean", "", "--algorithms hnswlib"]

ENTRYPOINT ["/bin/bash", "/data/scripts/run_benchmark_preloaded_datasets.sh"]

