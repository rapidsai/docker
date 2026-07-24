# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# ruff: noqa: S101

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest


MODULE_PATH = Path(__file__).parents[1] / "ci" / "image_provenance_manifest.py"
REPOSITORY_ROOT = MODULE_PATH.parents[1]
SPEC = importlib.util.spec_from_file_location("image_provenance_manifest", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def manifest_context(**overrides: object) -> object:
    """Create valid provenance inputs, with targeted test overrides."""
    defaults = {
        "image_reference": "rapidsai/base:26.08-cuda12-py312-amd64",
        "image_digest": "sha256:image",
        "image_kind": "base",
        "rapids_version": "26.08",
        "cuda_version": "12",
        "python_version": "3.12",
        "platform": "linux/amd64",
        "source_repository": "https://github.com/rapidsai/docker",
        "source_commit": "abc123",
        "workflow_ref": ".github/workflows/build-rapids-image.yml@abc123",
        "workflow_run_url": "https://github.com/rapidsai/docker/actions/runs/1",
        "build_args": ["PYTHON_VER=3.12", "CUDA_VER=12"],
    }
    defaults.update(overrides)
    return MODULE.ManifestContext(**defaults)


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
        manifest_context(),
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
        manifest_context(
            image_reference="rapidsai/base:26.08-cuda12-py312",
            image_digest="sha256:index",
            platform="multiarch",
            workflow_ref="workflow",
            workflow_run_url="run",
            build_args=[],
        ),
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


@pytest.mark.parametrize(
    ("script_name", "safe_title"),
    [
        ("publish-image-provenance.sh", "image-provenance.json"),
        ("publish-image-provenance-index.sh", "image-provenance-index.json"),
    ],
)
def test_published_provenance_uses_safe_oci_layer_titles(
    script_name: str,
    safe_title: str,
) -> None:
    script = (REPOSITORY_ROOT / "ci" / script_name).read_text()

    assert "--disable-path-validation" not in script
    assert f'"{safe_title}:application/vnd.rapids.image.provenance' in script
