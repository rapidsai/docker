#!/bin/bash
source activate rapids
/rapids/utils/start_jupyter.sh > /dev/null 
echo "Notebook server successfully started!"
echo "To access visit http://localhost:8888 on your host machine."
exec "$@" 
