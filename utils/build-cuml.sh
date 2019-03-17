#!/bin/bash

# Set the multigpu option based on CUDA_VERSION env var
# Version 9.2 will disable multigpu, all others assume it should be
# enabled.
MULTIGPU_OPTION=""
if [[ ${CUDA_VERSION} != "9.2" ]]; then
    MULTIGPU_OPTION=--multigpu
fi

cd cuml/cuML && mkdir -p build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
      -DCMAKE_CXX11_ABI=ON \
      -DCMAKE_BUILD_TYPE=release .. && \
make -j && make -j install && \
cd ../../python && python setup.py build_ext --inplace ${MULTIGPU_OPTION} && \
python setup.py install ${MULTIGPU_OPTION}

