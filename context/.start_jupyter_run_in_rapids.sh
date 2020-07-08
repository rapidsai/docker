#!/bin/bash
source activate rapids
/rapids/utils/start_jupyter.sh > /dev/null 
echo -e "\n"
echo "Notebook server successfully started!"
echo "Head to http://localhost:8888"
echo -e "\n"
exec "$@" 