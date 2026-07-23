# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

import pytest


MODULE_PATH = Path(__file__).parents[1] / "ci" / "image_provenance_manifest.py"
SPEC = importlib.util.spec_from_file_location("image_provenance_manifest", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_build_manifest_records_exact_conda_package_facts(tmp_path: Path) -> None:
    metadata_dir = tmp_path / "conda-meta"
    metadata_dir.mkdir()
    (metadata_dir / "c-ares-1.34.8-h1.json").write_text(
        json.dumps(
            {
                "name": "c-ares",
                "version": "1.34.8",
                "build": "h1",
                "build_number": 2,
                "channel": "https://conda.anaconda.org/conda-forge",
                "url": "https://conda.anaconda.org/conda-forge/linux-64/c-ares.conda",
            }
        )
    )

    manifest = MODULE.build_manifest(
        image_reference="rapidsai/base:26.08-cuda12-py312-amd64",
        image_digest="sha256:image",
        image_kind="base",
        rapids_version="26.08",
        cuda_version="12",
        python_version="3.12",
        platform="linux/amd64",
        source_repository="https://github.com/rapidsai/docker",
        source_commit="abc123",
        workflow_ref=".github/workflows/build-rapids-image.yml@abc123",
        workflow_run_url="https://github.com/rapidsai/docker/actions/runs/1",
        build_args=["PYTHON_VER=3.12", "CUDA_VER=12"],
        metadata_dir=metadata_dir,
    )

    assert manifest["subject"]["platform"] == {
        "os": "linux",
        "architecture": "amd64",
    }
    assert manifest["conda_packages"] == [
        {
            "build": "h1",
            "build_number": 2,
            "channel": "https://conda.anaconda.org/conda-forge",
            "name": "c-ares",
            "purl_source": "unmapped",
            "purls": [],
            "url": "https://conda.anaconda.org/conda-forge/linux-64/c-ares.conda",
            "version": "1.34.8",
        }
    ]
    assert manifest["build"]["build_args"] == {"CUDA_VER": "12", "PYTHON_VER": "3.12"}
    assert manifest["conda_packages_sha256"].startswith("sha256:")


def test_build_manifest_links_platform_manifests_for_multiarch_images() -> None:
    manifest = MODULE.build_manifest(
        image_reference="rapidsai/base:26.08-cuda12-py312",
        image_digest="sha256:index",
        image_kind="base",
        rapids_version="26.08",
        cuda_version="12",
        python_version="3.12",
        platform="multiarch",
        source_repository="https://github.com/rapidsai/docker",
        source_commit="abc123",
        workflow_ref="workflow",
        workflow_run_url="run",
        build_args=[],
        platform_manifests=[
            "linux/arm64|rapidsai/base:tag-arm64|sha256:arm",
            "linux/amd64|rapidsai/base:tag-amd64|sha256:amd",
        ],
    )

    assert "platform" not in manifest["subject"]
    assert [item["platform"] for item in manifest["platform_manifests"]] == [
        "linux/amd64",
        "linux/arm64",
    ]


def test_invalid_build_argument_is_rejected() -> None:
    with pytest.raises(ValueError, match="NAME=VALUE"):
        MODULE.parse_build_args(["CUDA_VER"])
