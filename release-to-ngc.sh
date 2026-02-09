#!/bin/bash
# Copyright (c) 2024-2025, NVIDIA CORPORATION.
#
# Script to publish release images to NGC
# Usage: ./release-to-ngc.sh <RAPIDS_VERSION>
# Example: ./release-to-ngc.sh 25.10

set -eEuo pipefail

# Check if RAPIDS version is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <RAPIDS_VERSION>"
    echo "Example: $0 25.10"
    exit 1
fi

RAPIDS_VER="$1"

# Check if required commands are available
for cmd in yq jq docker; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

# Check if matrix.yaml exists
if [ ! -f "matrix.yaml" ]; then
    echo "Error: matrix.yaml not found in current directory"
    exit 1
fi

echo "Publishing RAPIDS $RAPIDS_VER images to NGC..."

# Generate matrix from matrix.yaml
echo "Computing matrix from matrix.yaml..."
matrix=$(yq '.' matrix.yaml | yq -o json | jq -c)

# Extract CUDA_VER and PYTHON_VER arrays
cuda_versions=$(echo "$matrix" | jq -r '.CUDA_VER[]')
python_versions=$(echo "$matrix" | jq -r '.PYTHON_VER[]')

echo "CUDA versions: $(echo "$cuda_versions" | tr '\n' ' ')"
echo "Python versions: $(echo "$python_versions" | tr '\n' ' ')"

# Check Docker login status
echo "Checking Docker login status..."
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or not accessible"
    exit 1
fi

# Function to copy image using skopeo
copy_image() {
    local source="$1"
    local target="$2"
    
    echo "$source => $target"
    # docker run --rm -v ~/.docker/config.json:/config.json \
    #     quay.io/skopeo/stable:latest copy \
    #     --multi-arch all \
    #     --dest-authfile=/config.json \
    #     "docker://$source" \
    #     "docker://$target"
}

# Process each combination of CUDA and Python versions
for cuda_ver in $cuda_versions; do
    for python_ver in $python_versions; do
        echo ""
        echo "Processing CUDA $cuda_ver, Python $python_ver..."
        
        CUDA_VER_SHORT=${cuda_ver%.*}
        CUDA_MAJOR=${cuda_ver%%.*}
        
        for type in base notebooks; do
            echo "  Processing $type image..."

            # For CUDA 12, copy both major.minor and major tags
            if [[ "$CUDA_MAJOR" == "12" ]]; then
                echo "    CUDA 12 detected - copying both major.minor and major tags"
                
                # Copy major.minor tag
                source="rapidsai/$type:${RAPIDS_VER}-cuda${CUDA_VER_SHORT}-py${python_ver}"
                target="nvcr.io/nvstaging/rapids/$type:${RAPIDS_VER}-cuda${CUDA_VER_SHORT}-py${python_ver}"
                copy_image "$source" "$target"
                
                # Copy major tag
                source="rapidsai/$type:${RAPIDS_VER}-cuda${CUDA_MAJOR}-py${python_ver}"
                target="nvcr.io/nvstaging/rapids/$type:${RAPIDS_VER}-cuda${CUDA_MAJOR}-py${python_ver}"
                copy_image "$source" "$target"

            # For CUDA 13, copy only major tag
            elif [[ "$CUDA_MAJOR" == "13" ]]; then
                echo "    CUDA 13 detected - copying only major tag"
                
                source="rapidsai/$type:${RAPIDS_VER}-cuda${CUDA_MAJOR}-py${python_ver}"
                target="nvcr.io/nvstaging/rapids/$type:${RAPIDS_VER}-cuda${CUDA_MAJOR}-py${python_ver}"
                copy_image "$source" "$target"

            else
                echo "    Warning: Unsupported CUDA major version $CUDA_MAJOR, skipping..."
            fi
        done
    done
done

echo ""
echo "Successfully published all RAPIDS $RAPIDS_VER images to NGC!"
echo ""
echo "Note: Make sure you are logged in to both DockerHub and NGC:"
echo "  docker login"
echo "  docker login nvcr.io"