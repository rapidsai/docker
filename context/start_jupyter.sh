#!/bin/bash

# Run Jupyter in foreground if $JUPYTER_FG is set
if [[ -v JUPYTER_FG ]]; then
   jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token=''
   exit 0
fi

nohup jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' > /dev/null 2>&1 &
echo -e "\n"
echo "nohup jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' > /dev/null 2>&1 &"
echo -e "\n"
