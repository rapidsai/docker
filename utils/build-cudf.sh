#!/bin/bash

cd cudf/cpp && mkdir -p build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
      -DCMAKE_CXX11_ABI=ON \
      -DCMAKE_BUILD_TYPE=release .. && \
make -j && make -j install && \
make python_cffi && make install_python && \
cd ../../python && python setup.py build_ext --inplace && \
python setup.py install
