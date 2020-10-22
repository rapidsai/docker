#!/bin/bash

# Run Jupyter in foreground if $JUPYTER_FG is set
if [[ "${JUPYTER_FG}" == "true" ]]; then
   jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token=''
   exit 0
else
   nohup jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' > /dev/null 2>&1 &

   echo "A JupyterLab server has been started!"
   echo "To access it, visit http://localhost:8888 on your host machine."
   echo 'Ensure the following arguments were added to "docker run" to expose the JupyterLab server to your host machine:
      -p 8888:8888 -p 8787:8787 -p 8786:8786'
   echo "Make local folders visible by bind mounting to /rapids/notebooks/host"
fi
