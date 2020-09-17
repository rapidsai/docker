#!/bin/bash
set -e

# give sudo permission for rapids user to run apt/yum (user creation is postponed
# to the entrypoint, so we can create a user with the same id as the host)
if cat /etc/os-release | grep centos > /dev/null; then
  PKG_MGR="yum";
else
  PKG_MGR="apt";
fi
echo "rapids ALL=NOPASSWD: /usr/bin/${PKG_MGR}" >> /etc/sudoers

# Install su-exec
SU_PKG="su-exec"
conda install --yes ${SU_PKG}
CONDA_SUEXEC_INFO=( `conda list ${SU_PKG} | grep ${SU_PKG}` )
echo "${SU_PKG} ${CONDA_SUEXEC_INFO[1]}" >> /opt/conda/conda-meta/pinned
conda clean -tipy
