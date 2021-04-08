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

# Run whatever the user wants.
exec "$@"
