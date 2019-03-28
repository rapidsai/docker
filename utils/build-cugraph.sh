#!/bin/bash

cd cugraph/cpp && mkdir -p build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
      -DCMAKE_CXX11_ABI=ON \
      -DNVG_PLUGIN=True \
      -DCMAKE_BUILD_TYPE=release .. && \
make -j && make -j install && \
cd ../../python && python setup.py build_ext --inplace && \
python setup.py install
