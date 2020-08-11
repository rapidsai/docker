#!/bin/bash
. /opt/conda/etc/profile.d/conda.sh
conda activate rapids

source /rapids/utils/start_jupyter.sh

exec "$@"
