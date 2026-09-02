# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# ruff: noqa: S101

from __future__ import annotations

import os
import subprocess
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).parents[1]
VERSION_SCRIPT = REPOSITORY_ROOT / "ci/compute-rapids-version.sh"


def git(repository: Path, *arguments: str) -> None:
    subprocess.run(  # noqa: S603
        ["/usr/bin/git", *arguments],
        cwd=repository,
        check=True,
        capture_output=True,
        text=True,
    )


def tagged_repository(tmp_path: Path) -> Path:
    repository = tmp_path / "repository"
    repository.mkdir()
    git(repository, "init")
    git(repository, "config", "user.email", "test@example.com")
    git(repository, "config", "user.name", "Test User")
    git(repository, "config", "commit.gpgsign", "false")

    tracked_file = repository / "tracked"
    tracked_file.write_text("26.08\n", encoding="utf-8")
    git(repository, "add", "tracked")
    git(repository, "commit", "-m", "26.08 alpha")
    git(repository, "tag", "v26.08.00a")

    tracked_file.write_text("26.10\n", encoding="utf-8")
    git(repository, "add", "tracked")
    git(repository, "commit", "-m", "26.10 alpha")
    git(repository, "tag", "v26.10.00a")
    return repository


def compute_version(
    repository: Path,
    tmp_path: Path,
    *,
    base_ref: str = "",
    ref_name: str,
) -> dict[str, str]:
    output = tmp_path / "output"
    environment = os.environ.copy()
    environment.update(
        {
            "GITHUB_BASE_REF": base_ref,
            "GITHUB_OUTPUT": str(output),
            "GITHUB_REF_NAME": ref_name,
        }
    )
    subprocess.run(  # noqa: S603
        [str(VERSION_SCRIPT)],
        cwd=repository,
        env=environment,
        check=True,
        capture_output=True,
        text=True,
    )
    return dict(line.split("=", 1) for line in output.read_text().splitlines())


def test_alpha_pull_request_to_main_uses_current_main_line(tmp_path: Path) -> None:
    repository = tagged_repository(tmp_path)

    version = compute_version(
        repository,
        tmp_path,
        base_ref="main",
        ref_name="904/merge",
    )

    assert version == {
        "ALPHA_TAG": "a",
        "RAPIDS_NOTEBOOKS_REF": "main",
        "RAPIDS_VER": "26.10",
    }


def test_alpha_release_branch_uses_its_matching_notebook_ref(tmp_path: Path) -> None:
    repository = tagged_repository(tmp_path)

    version = compute_version(
        repository, tmp_path, ref_name="release/26.10"
    )

    assert version == {
        "ALPHA_TAG": "a",
        "RAPIDS_NOTEBOOKS_REF": "release/26.10",
        "RAPIDS_VER": "26.10",
    }


def test_alpha_pull_request_uses_its_release_target(tmp_path: Path) -> None:
    repository = tagged_repository(tmp_path)

    version = compute_version(
        repository,
        tmp_path,
        base_ref="release/26.10",
        ref_name="904/merge",
    )

    assert version == {
        "ALPHA_TAG": "a",
        "RAPIDS_NOTEBOOKS_REF": "release/26.10",
        "RAPIDS_VER": "26.10",
    }
