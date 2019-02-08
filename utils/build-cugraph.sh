#!/bin/bash

cd cugraph && mkdir -p build && cd build && \
cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DNVG_PLUGIN=FALSE && \
make -j && make install && \
python setup.py install && \
cd $RAPIDS_ROOT