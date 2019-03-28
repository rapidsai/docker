#!/bin/bash

cd xgboost && mkdir -p build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
      -DUSE_NCCL=ON -DUSE_CUDA=ON -DUSE_CUDF=ON \
      -DGDF_INCLUDE_DIR=$CONDA_PREFIX/include \
      -DCMAKE_CXX11_ABI=ON \
      -DCMAKE_BUILD_TYPE=release .. && \
make -j && make -j install && \
cd ../python-package && python setup.py install
