#!/bin/bash

cd dask-xgboost && \
python setup.py install && \
git clean -xdff
