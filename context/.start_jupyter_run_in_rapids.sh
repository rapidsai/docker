#!/bin/bash
. /opt/conda/etc/profile.d/conda.sh
conda activate rapids

# Run Jupyter in foreground if $JUPYTER_FG is set
if [[ -v JUPYTER_FG ]]; then
   OUTPUT="/dev/tty"
else
   OUTPUT="/dev/null"
fi

source /rapids/utils/start_jupyter.sh > "${OUTPUT}"
echo "Notebook server successfully started, a JupyterLab instance has been executed!"
echo "Make local folders visible by volume mounting to /rapids/notebook"
echo "To access visit http://localhost:8888 on your host machine."
echo 'Ensure the following arguments to "docker run" are added to expose the server ports to your host machine:
   -p 8888:8888 -p 8787:8787 -p 8786:8786'
exec "$@"
