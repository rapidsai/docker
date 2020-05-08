#!/bin/bash
source activate rapids
/rapids/utils/start_jupyter.sh > /dev/null
exec "$@"
