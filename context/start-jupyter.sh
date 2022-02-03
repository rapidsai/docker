#!/bin/bash

nohup jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.allow_origin="*" --NotebookApp.base_url="${NB_PREFIX:-/}" > /dev/null 2>&1 &

echo "JupyterLab server started."
