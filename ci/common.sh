#!/bin/bash
# Copyright (c) 2023-2025, NVIDIA CORPORATION.

set -eEuo pipefail

# Authenticate and retrieve DockerHub token
HUB_TOKEN=$(
curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{\"username\": \"$GPUCIBOT_DOCKERHUB_USER\", \"password\": \"$GPUCIBOT_DOCKERHUB_TOKEN\"}" \
    https://hub.docker.com/v2/users/login/ | jq -r .token \
)
echo "::add-mask::${HUB_TOKEN}"
export HUB_TOKEN

# Function to check if a Docker tag exists
check_tag_exists() {
    local repo="$1"
    local tag="$2"
    local exists
    exists=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/${org}/${repo}/tags/${tag}/")

    if [ "$exists" -ne 200 ]; then
        echo "Error: Required image tag ${repo}:${tag} does not exist. This implies that the image was not built successfully in the build job."
        exit 1
    fi
}

export org="rapidsai"
