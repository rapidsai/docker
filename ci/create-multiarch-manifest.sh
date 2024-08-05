# Authenticate and retrieve DockerHub token
HUB_TOKEN=$(
curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{\"username\": \"$GPUCIBOT_DOCKERHUB_USER\", \"password\": \"$GPUCIBOT_DOCKERHUB_TOKEN\"}" \
    https://hub.docker.com/v2/users/login/ | jq -r .token \
)
echo "::add-mask::${HUB_TOKEN}"

org="rapidsai"

# Initialize arrays to store source tags for each image
base_source_tags=()
notebooks_source_tags=()
raft_ann_bench_source_tags=()
raft_ann_bench_datasets_source_tags=()
raft_ann_bench_cpu_source_tags=()

# Define tag arrays for different images
base_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
notebooks_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_tag="${RAFT_ANN_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_datasets_tag="${RAFT_ANN_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_cpu_tag="${RAFT_ANN_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-py${PYTHON_VER}"

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

# Check if all source tags exist and add to source tags array
for arch in $(echo "${ARCHES}" | jq .[] -r); do
    full_base_tag="${base_tag}-${arch}"
    full_notebooks_tag="${notebooks_tag}-${arch}"
    full_raft_ann_bench_tag="${raft_ann_bench_tag}-${arch}"
    full_raft_ann_bench_datasets_tag="${raft_ann_bench_datasets_tag}-${arch}"
    full_raft_ann_bench_cpu_tag="${raft_ann_bench_cpu_tag}-${arch}"

    check_tag_exists "$BASE_IMAGE_REPO" "$full_base_tag"
    base_source_tags+=("${org}/${BASE_IMAGE_REPO}:$full_base_tag")

    check_tag_exists "$NOTEBOOKS_IMAGE_REPO" "$full_notebooks_tag"
    notebooks_source_tags+=("${org}/${NOTEBOOKS_IMAGE_REPO}:$full_notebooks_tag")

    check_tag_exists "$RAFT_ANN_BENCH_IMAGE_REPO" "$full_raft_ann_bench_tag"
    raft_ann_bench_source_tags+=("${org}/${RAFT_ANN_BENCH_IMAGE_REPO}:$full_raft_ann_bench_tag")

    check_tag_exists "$RAFT_ANN_BENCH_DATASETS_IMAGE_REPO" "$full_raft_ann_bench_datasets_tag"
    raft_ann_bench_datasets_source_tags+=("${org}/${RAFT_ANN_BENCH_DATASETS_IMAGE_REPO}:$full_raft_ann_bench_datasets_tag")

    check_tag_exists "$RAFT_ANN_BENCH_CPU_IMAGE_REPO" "$full_raft_ann_bench_cpu_tag"
    raft_ann_bench_cpu_source_tags+=("${org}/${RAFT_ANN_BENCH_CPU_IMAGE_REPO}:$full_raft_ann_bench_cpu_tag")
done

# Create and push Docker multi-arch manifests
docker manifest create "${org}/${BASE_IMAGE_REPO}:${base_tag}" "${base_source_tags[@]}"
docker manifest push "${org}/${BASE_IMAGE_REPO}:${base_tag}"

docker manifest create "${org}/${NOTEBOOKS_IMAGE_REPO}:${notebooks_tag}" "${notebooks_source_tags[@]}"
docker manifest push "${org}/${NOTEBOOKS_IMAGE_REPO}:${notebooks_tag}"

docker manifest create "${org}/${RAFT_ANN_BENCH_IMAGE_REPO}:${raft_ann_bench_tag}" "${raft_ann_bench_source_tags[@]}"
docker manifest push "${org}/${RAFT_ANN_BENCH_IMAGE_REPO}:${raft_ann_bench_tag}"

docker manifest create "${org}/${RAFT_ANN_BENCH_DATASETS_IMAGE_REPO}:${raft_ann_bench_datasets_tag}" "${raft_ann_bench_datasets_source_tags[@]}"
docker manifest push "${org}/${RAFT_ANN_BENCH_DATASETS_IMAGE_REPO}:${raft_ann_bench_datasets_tag}"

docker manifest create "${org}/${RAFT_ANN_BENCH_CPU_IMAGE_REPO}:${raft_ann_bench_cpu_tag}" "${raft_ann_bench_cpu_source_tags[@]}"
docker manifest push "${org}/${RAFT_ANN_BENCH_CPU_IMAGE_REPO}:${raft_ann_bench_cpu_tag}"
