#!/usr/bin/env bash
set -euo pipefail

cat << EOF
This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.download.nvidia.com/licenses/NVIDIA_Deep_Learning_Container_License.pdf

EOF

if [ -e "/home/rapids/environment.yml" ]; then
    echo "environment.yml found. Installing packages"
    timeout ${CONDA_TIMEOUT:-600} mamba env update -n base -f /home/rapids/environment.yml || exit $?
fi

if [ "$EXTRA_CONDA_PACKAGES" ]; then
    echo "EXTRA_CONDA_PACKAGES environment variable found. Installing packages."
    timeout ${CONDA_TIMEOUT:-600} mamba install -n base -y $EXTRA_CONDA_PACKAGES || exit $?
fi

if [ "$EXTRA_PIP_PACKAGES" ]; then
    echo "EXTRA_PIP_PACKAGES environment variable found. Installing packages.".
    timeout ${PIP_TIMEOUT:-600} pip install $EXTRA_PIP_PACKAGES || exit $?
fi

# Run whatever the user wants.
if [ "${UNQUOTE}" = "true" ]; then
    exec $@
else
    exec "$@"
fi
