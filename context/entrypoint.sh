#!/bin/bash

# Create conda user with the same uid as the host, so the container can write
# to mounted volumes
# Adapted from https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
USER_ID=${HOST_USER_ID:-9001}
useradd --shell /bin/bash -u $USER_ID -o -c "" -m rapids
export HOME=/home/rapids
export USER=rapids
export LOGNAME=rapids
export MAIL=/var/spool/mail/rapids
export PATH=$PATH:/home/rapids/bin
export supkg="su-exec"
chown rapids:rapids $HOME

# Activate the `rapids` conda environment.
. /opt/conda/etc/profile.d/conda.sh
conda activate rapids

source /opt/docker/bin/packages.sh

# Source "source" file if it exists
SRC_FILE="/opt/docker/bin/entrypoint_source"
[ -f "${SRC_FILE}" ] && source "${SRC_FILE}"

# Run whatever the user wants.
exec /opt/conda/bin/$supkg rapids "$@"
