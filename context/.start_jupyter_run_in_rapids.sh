#!/bin/bash
. /opt/conda/etc/profile.d/conda.sh
conda activate rapids
/rapids/utils/start_jupyter.sh > /dev/null
exec "$@"
