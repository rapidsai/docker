# Authenticate and retrieve DockerHub token
HUB_TOKEN=$(
curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{\"username\": \"$GPUCIBOT_DOCKERHUB_USER\", \"password\": \"$GPUCIBOT_DOCKERHUB_TOKEN\"}" \
    https://hub.docker.com/v2/users/login/ | jq -r .token \
)
echo "::add-mask::${HUB_TOKEN}"

org="rapidsai"

# Define tag arrays for different images
base_tag="${BASE_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
notebooks_tag="${NOTEBOOKS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_tag="${RAFT_ANN_BENCH_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_datasets_tag="${RAFT_ANN_BENCH_DATASETS_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-cuda${CUDA_TAG}-py${PYTHON_VER}"
raft_ann_bench_cpu_tag="${RAFT_ANN_BENCH_CPU_TAG_PREFIX}${RAPIDS_VER}${ALPHA_TAG}-py${PYTHON_VER}"

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

for arch in $(echo "${ARCHES}" | jq .[] -r); do
    full_base_tag="${base_tag}-${arch}"
    full_notebooks_tag="${notebooks_tag}-${arch}"
    full_raft_ann_bench_tag="${raft_ann_bench_tag}-${arch}"
    full_raft_ann_bench_datasets_tag="${raft_ann_bench_datasets_tag}-${arch}"
    full_raft_ann_bench_cpu_tag="${raft_ann_bench_cpu_tag}-${arch}"

    check_tag_exists "$BASE_IMAGE_REPO" "$full_base_tag"
    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$BASE_IMAGE_REPO/tags/$base_tag-$arch/"

    check_tag_exists "$NOTEBOOKS_IMAGE_REPO" "$full_notebooks_tag"
    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$NOTEBOOKS_IMAGE_REPO/tags/$notebooks_tag-$arch/"

    check_tag_exists "$RAFT_ANN_BENCH_IMAGE_REPO" "$full_raft_ann_bench_tag"
    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$RAFT_ANN_BENCH_IMAGE_REPO/tags/$raft_ann_bench_tag-$arch/"

    check_tag_exists "$RAFT_ANN_BENCH_DATASETS_IMAGE_REPO" "$full_raft_ann_bench_datasets_tag"
    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$RAFT_ANN_BENCH_DATASETS_IMAGE_REPO/tags/$raft_ann_bench_datasets_tag-$arch/"

    if [ "$RAFT_ANN_BENCH_CPU_IMAGE_BUILT" = "true" ]; then
        check_tag_exists "$RAFT_ANN_BENCH_CPU_IMAGE_REPO" "$full_raft_ann_bench_cpu_tag"
        curl -i -X DELETE \
            -H "Accept: application/json" \
            -H "Authorization: JWT $HUB_TOKEN" \
            "https://hub.docker.com/v2/repositories/$org/$RAFT_ANN_BENCH_CPU_IMAGE_REPO/tags/$raft_ann_bench_cpu_tag-$arch/"
    fi
done
