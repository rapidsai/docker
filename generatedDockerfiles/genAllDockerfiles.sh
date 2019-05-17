#!/bin/bash

# Copyright (c) 2019, NVIDIA CORPORATION.

# Generate the Dockerfile from every available Dockerfile template in this repo.

cd $(dirname $0)
THISDIR=$(pwd)
RAPIDSDEVTOOL=${THISDIR}/../rapidsdevtool.sh

for tn in $(${RAPIDSDEVTOOL} listDockerTemplNames); do
    ${RAPIDSDEVTOOL} genDockerfile -t ${tn};
done
