#!/bin/bash

if [ "$EXTRA_APT_PACKAGES" ]; then
    if ! grep -i "ubuntu" /etc/os-release > /dev/null; then
      echo "EXTRA_APT_PACKAGES var provided in a non-Ubuntu environment."
      echo "Exiting..."
      exit 1
    fi
    echo "EXTRA_APT_PACKAGES environment variable found. Installing packages."
    apt update -y
    apt install -y --no-install-recommends $EXTRA_APT_PACKAGES
fi

if [ "$EXTRA_YUM_PACKAGES" ]; then
    if ! grep -i "centos" /etc/os-release > /dev/null; then
      echo "EXTRA_YUM_PACKAGES var provided in a non-Centos environment."
      echo "Exiting..."
      exit 1
    fi
    echo "EXTRA_YUM_PACKAGES environment variable found. Installing packages."
    yum check-update -y
    yum install -y $EXTRA_YUM_PACKAGES
fi

if [ -e "/opt/rapids/environment.yml" ]; then
    echo "environment.yml found. Installing packages"
    conda env update -f /opt/rapids/environment.yml
fi

if [ "$EXTRA_CONDA_PACKAGES" ]; then
    echo "EXTRA_CONDA_PACKAGES environment variable found. Installing packages."
    conda install -y $EXTRA_CONDA_PACKAGES
fi

if [ "$EXTRA_PIP_PACKAGES" ]; then
    echo "EXTRA_PIP_PACKAGES environment variable found. Installing packages.".
    pip install $EXTRA_PIP_PACKAGES
fi
