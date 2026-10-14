# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
import os
from pathlib import Path
import subprocess

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "ci/install-candidate-conda-indexer.sh"


def _run_installer(
    tmp_path: Path,
    *,
    architecture: str,
    version: str = "26.1.0-0",
    checksum_status: str = "0",
):
    bin_dir = tmp_path / "mock-bin"
    bin_dir.mkdir()
    log = tmp_path / "calls.log"
    (bin_dir / "uname").write_text(f"#!/bin/sh\nprintf '%s\\n' '{architecture}'\n")
    (bin_dir / "curl").write_text(
        "#!/bin/sh\nprintf '%s\\n' \"$*\" >> \"${CALL_LOG}\"\n"
        "while [ \"$1\" != \"--output\" ]; do shift; done\n"
        "shift\nprintf installer > \"$1\"\n"
        "cat > \"$1\" <<'INSTALLER'\n"
        "#!/bin/sh\n"
        "printf 'installer %s\\n' \"$*\" >> \"${CALL_LOG}\"\n"
        "while [ \"$1\" != \"-p\" ]; do shift; done\n"
        "shift\nmkdir -p \"$1/bin\"\n"
        "cat > \"$1/bin/conda\" <<'MOCK_CONDA'\n"
        "#!/bin/sh\nprintf 'conda %s\\n' \"$*\" >> \"${CALL_LOG}\"\n"
        "MOCK_CONDA\n"
        "chmod +x \"$1/bin/conda\"\n"
        "INSTALLER\n"
    )
    (bin_dir / "sha256sum").write_text(
        "#!/bin/sh\n"
        "read checksum path\n"
        "printf 'sha256 %s %s\\n' \"${checksum}\" \"${path}\" >> \"${CALL_LOG}\"\n"
        "exit \"${SHA256SUM_STATUS:-0}\"\n"
    )
    for executable in bin_dir.iterdir():
        executable.chmod(0o755)

    version_file = tmp_path / "versions.yaml"
    version_file.write_text(f"MINIFORGE_VER: {version}\n")
    github_path = tmp_path / "github-path"
    env = {
        **os.environ,
        "PATH": f"{bin_dir}:/usr/bin:/bin",
        "CALL_LOG": str(log),
        "SHA256SUM_STATUS": checksum_status,
        "GITHUB_PATH": str(github_path),
        "RUNNER_TEMP": str(tmp_path),
        "MINIFORGE_VERSION_FILE": str(version_file),
    }
    result = subprocess.run([str(INSTALLER)], env=env, check=False, capture_output=True, text=True)
    return result, log.read_text() if log.exists() else "", github_path


@pytest.mark.parametrize(
    ("architecture", "installer_arch", "sha256"),
    [
        (
            "x86_64",
            "x86_64",
            "127b5e14cfe6c83b787f624487cdc2168645ed82fdca1b0c1937caa086aed6d5",
        ),
        (
            "aarch64",
            "aarch64",
            "8baf8844ecf13e1458f81659ea286251d04b2d5ed90040efb77f158adedb2d95",
        ),
    ],
)
def test_installer_verifies_matching_miniforge_and_sets_conda_path(
    tmp_path: Path, architecture: str, installer_arch: str, sha256: str
):
    result, calls, github_path = _run_installer(tmp_path, architecture=architecture)

    assert result.returncode == 0, result.stderr
    assert f"Miniforge3-26.1.0-0-Linux-{installer_arch}.sh" in calls
    assert sha256 in calls
    assert "installer -b -p" in calls
    assert "conda install --yes --name base --override-channels --channel conda-forge conda-index=0.13.0 pyyaml=6.0.3" in calls
    assert github_path.read_text().strip() == f"{tmp_path}/miniforge/bin"


@pytest.mark.parametrize(
    ("architecture", "version"),
    [("x86_64", "26.1.1-0"), ("ppc64le", "26.1.0-0")],
)
def test_unknown_installer_version_or_architecture_fails_closed(
    tmp_path: Path, architecture: str, version: str
):
    result, calls, _ = _run_installer(tmp_path, architecture=architecture, version=version)

    assert result.returncode != 0
    assert "No verified Miniforge installer" in result.stderr
    assert calls == ""


def test_checksum_failure_prevents_running_installer_or_installing_conda_index(tmp_path: Path):
    result, calls, github_path = _run_installer(
        tmp_path, architecture="x86_64", checksum_status="1"
    )

    assert result.returncode != 0
    assert "installer -b -p" not in calls
    assert "conda install" not in calls
    assert not github_path.exists()


def test_private_workflow_installs_conda_index_runtime_before_dependency_channel():
    workflow = yaml.safe_load((ROOT / ".github/workflows/build.yaml").read_text())
    steps = workflow["jobs"]["candidate-images"]["steps"]
    runtime_index = next(i for i, step in enumerate(steps) if step.get("name") == "Install isolated Conda indexer")
    channel_index = next(i for i, step in enumerate(steps) if step.get("name") == "Prepare frozen candidate dependency channel")

    assert runtime_index < channel_index
    assert "ci/install-candidate-conda-indexer.sh" in steps[runtime_index]["run"]
    assert steps[channel_index]["with"]["prepare-conda-channel"] == "true"
    assert "container-index-tools" not in steps[runtime_index]["run"]
