# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
import json
from pathlib import Path
import runpy

import pytest
import yaml

from ci.candidate_containers import candidate_dockerfile, container_matrix, frozen_sources, run

ROOT = Path(__file__).resolve().parents[1]
VERIFY = runpy.run_path(str(ROOT / "context/scripts/verify-candidate-environment.py"))["verify_environment"]


def test_full_native_matrix_includes_all_targets_and_both_architectures():
    native = json.loads(run(["bash", "ci/compute-matrix.sh"]))
    matrix = container_matrix(native, "26.12")["include"]
    assert len(matrix) == 56
    assert {row["ARCH"] for row in matrix} == {"amd64", "arm64"}
    assert {row["KIND"] for row in matrix} == {"base", "notebooks", "cuvs-bench", "cuvs-bench-cpu"}
    identities = {(row["IMAGE_NAME"], row["IMAGE_TAG"], row["ARCH"]) for row in matrix}
    assert len(identities) == len(matrix)
    cpu = [row for row in matrix if row["KIND"] == "cuvs-bench-cpu"]
    assert len(cpu) == 8
    assert {row["CUDA_VER"] for row in cpu} == {"13.3.0"}


@pytest.mark.parametrize("version", ["latest", "26.12\nRUN evil", "26"])
def test_mutable_or_invalid_container_versions_are_rejected(version):
    with pytest.raises(ValueError, match="frozen container version"):
        container_matrix({"include": []}, version)


def source_train():
    names = ["integration", "cudf", "cuml", "cugraph"]
    return {"source_revisions": dict.fromkeys(names, "a" * 40), "github_repositories": {name: f"rapidsai/{name}" for name in names}, "build_tool_revisions": {"dependency-file-generator": "b" * 40}, "rapids_metadata_revision": "c" * 40}


@pytest.mark.parametrize("missing", ["integration", "cudf", "cuml", "cugraph"])
def test_missing_frozen_notebook_or_aggregate_source_has_no_branch_fallback(missing):
    train = source_train()
    del train["source_revisions"][missing]
    with pytest.raises(ValueError, match="missing frozen container source"):
        frozen_sources(train)


@pytest.mark.parametrize("dockerfile", ["Dockerfile", "cuvs-bench/gpu/Dockerfile", "cuvs-bench/cpu/Dockerfile"])
def test_candidate_context_keeps_real_builds_and_adds_origin_verification(dockerfile):
    original = (ROOT / dockerfile).read_text()
    dfg = {"repository": "rapidsai/dependency-file-generator", "revision": "b" * 40}
    metadata = {"repository": "rapidsai/rapids-metadata", "revision": "c" * 40}
    transformed = candidate_dockerfile(original, dfg, metadata)
    assert "rapids-conda-retry install" in transformed
    assert "--mount=type=bind,source=candidate-channel,target=/candidate-channel,readonly" in transformed
    assert "COPY candidate-channel" not in transformed
    assert transformed.endswith("python /verify-candidate-environment.py\n")
    if dockerfile == "Dockerfile":
        assert "rapids-dependency-file-generator @ git+https://github.com/rapidsai/dependency-file-generator.git@" + "b" * 40 in transformed
        assert "COPY candidate-source-manifest.json /candidate-source-manifest.json" in transformed
        assert "rapids-metadata @ git+https://github.com/rapidsai/rapids-metadata.git@" + "c" * 40 in transformed
        assert "python /verify-candidate-environment.py\n\n# Notebooks image" in transformed


def receipt():
    return {"required": ["cudf"], "owned_names": ["cudf", "cuml"], "packages": {"linux-64/cudf.conda": {"name": "cudf", "sha256": "a" * 64}}}


def test_installed_train_package_matches_private_candidate_origin_and_hash():
    VERIFY(receipt(), [{"name": "cudf", "url": "file:///candidate-channel/linux-64/cudf.conda", "sha256": "a" * 64}, {"name": "numpy", "url": "https://conda.anaconda.org/conda-forge/numpy.conda"}])


@pytest.mark.parametrize("url", ["https://conda.anaconda.org/rapidsai-nightly/cudf.conda", "https://conda.anaconda.org/conda-forge/cudf.conda", "file:///other/cudf.conda", "file:///candidate-channel/../other/cudf.conda"])
def test_public_or_unrelated_owned_packages_are_rejected(url):
    with pytest.raises(ValueError):
        VERIFY(receipt(), [{"name": "cudf", "url": url, "sha256": "a" * 64}])


def test_different_candidate_bytes_and_missing_runtime_are_rejected():
    with pytest.raises(ValueError, match="candidate bytes"):
        VERIFY(receipt(), [{"name": "cudf", "url": "file:///candidate-channel/linux-64/cudf.conda", "sha256": "b" * 64}])
    with pytest.raises(ValueError, match="lacks required"):
        VERIFY(receipt(), [])


def test_private_workflow_never_logs_in_pushes_or_writes_registry_cache():
    workflow = yaml.safe_load((ROOT / ".github/workflows/build.yaml").read_text())
    for job in workflow["jobs"].values():
        assert "secrets" not in job
        assert job["permissions"].get("packages", "read") == "read"
        for step in job["steps"]:
            assert "docker/login-action" not in step.get("uses", "")
            if "docker/build-push-action" in step.get("uses", ""):
                assert step["with"]["push"] is False
                assert "cache-to" not in step["with"]
                assert step["with"]["outputs"].startswith("type=oci,")
    assert "release-catalog-dispatch@" in (ROOT / ".github/workflows/build.yaml").read_text()
