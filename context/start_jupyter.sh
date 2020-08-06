#!/bin/bash
nohup jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' > .jupyter_lab_output.txt 2>&1 &
echo -e "\n"
echo "nohup jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' > .jupyter_lab_output.txt 2>&1 &"
echo -e "\n"
