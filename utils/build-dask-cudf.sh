#!/bin/bash

cd dask-cudf && \
python setup.py install && \
git clean -xdff
