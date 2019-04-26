#!/bin/bash

cd custrings/cpp && mkdir -p build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
      -DCMAKE_CXX11_ABI=ON \
      -DCMAKE_BUILD_TYPE=release .. && \
make -j && make -j install && \
cd ../../python && \
python setup.py install --single-version-externally-managed --record=record.txt
