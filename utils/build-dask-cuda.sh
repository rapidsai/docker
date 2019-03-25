#!/bin/bash

cd dask-cuda && \
python setup.py install && \
git clean -xdff
