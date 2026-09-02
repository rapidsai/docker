#!/bin/bash
# Copyright (c) 2023-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

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
    local attempts=6
    local attempt=1
    local delay=5
    local http_code

    while ((attempt <= attempts)); do
        http_code=$(curl -sS -o /dev/null -w "%{http_code}" -H "Authorization: JWT $HUB_TOKEN" \
            "https://hub.docker.com/v2/repositories/${org}/${repo}/tags/${tag}/") || http_code="000"

        if [[ $http_code == "200" ]]; then
            return 0
        fi

        if ((attempt == attempts)); then
            break
        fi

        case "$http_code" in
            000 | 404 | 429 | 5??)
                echo "Required image tag ${repo}:${tag} is not visible yet (HTTP ${http_code}); retrying in ${delay}s (${attempt}/${attempts})."
                sleep "$delay"
                delay=$((delay * 2))
                if ((delay > 60)); then
                    delay=60
                fi
                ;;
            *)
                echo "Error: Failed to check required image tag ${repo}:${tag} (HTTP ${http_code})."
                return 1
                ;;
        esac

        attempt=$((attempt + 1))
    done

    echo "Error: Required image tag ${repo}:${tag} was not visible after ${attempts} attempts (last HTTP ${http_code}). The image build may have failed, or Docker Hub may not have propagated the tag yet."
    return 1
}

export org="rapidsai"
