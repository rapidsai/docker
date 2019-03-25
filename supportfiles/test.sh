#!/bin/bash
set -ex

# Test script used by Jenkins to check that builds are ready to publish

## Check env
env

## Activate conda env
source activate rapids

# Test cuML notebooks
cd /rapids/notebooks/cuml

# Test dbscan notebook
## filter out magics first
cat dbscan_demo.ipynb | grep -v "%%" > /tmp/dbscan_demo-test.ipynb
jupyter nbconvert --to script /tmp/dbscan_demo-test.ipynb --output /tmp/dbscan_demo-test
python /tmp/dbscan_demo-test.py

# Test knn notebook
## filter out magics first
cat knn_demo.ipynb | grep -v "%%" > /tmp/knn_demo-test.ipynb
jupyter nbconvert --to script /tmp/knn_demo-test.ipynb --output /tmp/knn_demo-test
python /tmp/knn_demo-test.py

# Test pca notebook
## filter out magics first
cat pca_demo.ipynb | grep -v "%%" > /tmp/pca_demo-test.ipynb
jupyter nbconvert --to script /tmp/pca_demo-test.ipynb --output /tmp/pca_demo-test
python /tmp/pca_demo-test.py

# Test tsvd notebook
## filter out magics first
cat tsvd_demo.ipynb | grep -v "%%" > /tmp/tsvd_demo-test.ipynb
jupyter nbconvert --to script /tmp/tsvd_demo-test.ipynb --output /tmp/tsvd_demo-test
python /tmp/tsvd_demo-test.py
