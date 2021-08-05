#!/bin/bash

# Activate the `rapids` conda environment.
. /opt/conda/etc/profile.d/conda.sh
conda activate rapids

cat << EOF
This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.download.nvidia.com/licenses/NVIDIA_Deep_Learning_Container_License.pdf

EOF

source /opt/docker/bin/packages.sh

# Source "source" file if it exists
SRC_FILE="/opt/docker/bin/entrypoint_source"
[ -f "${SRC_FILE}" ] && source "${SRC_FILE}"

# Check if we should quote the exec params
UNQUOTE=false
if [ "$1" = "--unquote-exec" ]; then
  UNQUOTE=true
  shift
elif [ -n "${UNQUOTE_EXEC}" ] && [[ "${UNQUOTE_EXEC}" =~ ^(true|yes|y)$ ]]; then
  UNQUOTE=true
fi

# Run whatever the user wants.
if [ "${UNQUOTE}" = "true" ]; then
  exec $@
else
  exec "$@"
fi
