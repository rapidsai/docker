#!/bin/bash

if [[ "$@" = *"ipykernel"* ]]; then
   return 0
fi

if [[ "$@" = *"jupyter kernelspec"* ]]; then
   return 0
fi


# Disable automatic Jupyter launch if $DISABLE_JUPYTER is set
if [[ "${DISABLE_JUPYTER}" =~ ^(true|yes|y)$ ]]; then
   return 0

# Run Jupyter in foreground if $JUPYTER_FG is set or container is running non-interactively
elif [[ "${JUPYTER_FG}" =~ ^(true|yes|y)$ ]] || ! [ -t 0 ]; then
   jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.allow_origin="*" --NotebookApp.base_url="${NB_PREFIX:-/}"
   exit 0
else
   source /rapids/utils/start-jupyter.sh > /dev/null

   echo "A JupyterLab server has been started!"
   echo "To access it, visit http://localhost:8888 on your host machine."
   echo 'Ensure the following arguments were added to "docker run" to expose the JupyterLab server to your host machine:
      -p 8888:8888 -p 8787:8787 -p 8786:8786'
   if [ ! -d "/rapids/notebooks/host/" ]; then
       echo "Make local folders visible by bind mounting to /rapids/notebooks/host"
   fi
fi

