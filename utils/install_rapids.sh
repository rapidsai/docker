#!/bin/bash

export RAPIDS_PREFIX=/rapids
export XGBOOST_PREFIX=/rapids

source activate gdf && \

    cd $RAPIDS_PREFIX/cudf/libgdf && mkdir -p build && cd build &&\
    cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX .. && \
    make -j && \
    make copy_python && \
    make install && \
    python setup.py install && \
    cd $RAPIDS_PREFIX/cudf && python setup.py install &&

    cd $XGBOOST_PREFIX/nv-xgboost && mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
          -DUSE_CUDA=ON -DUSE_NCCL=ON .. && \
    make -j && make install && \
    cd ../python-package && python setup.py install && \

    cd $RAPIDS_PREFIX/dask_gdf && python setup.py install && \
    cd $XGBOOST_PREFIX/dask-xgboost && python setup.py install