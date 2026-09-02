# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
# ruff: noqa: S101

from __future__ import annotations

import os
import subprocess
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).parents[1]


def run_tag_check(
    tmp_path: Path, http_codes: list[str]
) -> tuple[subprocess.CompletedProcess[str], str]:
    """Run check_tag_exists with deterministic curl and sleep replacements."""
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    codes_file = tmp_path / "http-codes"
    codes_file.write_text("\n".join(http_codes) + "\n", encoding="utf-8")
    sleep_log = tmp_path / "sleep-log"

    curl = bin_dir / "curl"
    curl.write_text(
        """#!/bin/bash
set -euo pipefail
if [[ $* == *'/users/login/'* ]]; then
    printf '{"token":"test-token"}'
    exit 0
fi
http_code="$(head -n 1 "$HTTP_CODES_FILE")"
tail -n +2 "$HTTP_CODES_FILE" > "${HTTP_CODES_FILE}.tmp"
mv "${HTTP_CODES_FILE}.tmp" "$HTTP_CODES_FILE"
printf '%s' "$http_code"
[[ $http_code != 000 ]]
""",
        encoding="utf-8",
    )
    curl.chmod(0o700)

    sleep = bin_dir / "sleep"
    sleep.write_text(
        """#!/bin/bash
set -euo pipefail
printf '%s\n' "$1" >> "$SLEEP_LOG"
""",
        encoding="utf-8",
    )
    sleep.chmod(0o700)

    environment = os.environ.copy()
    environment.update(
        {
            "GPUCIBOT_DOCKERHUB_TOKEN": "test-password",
            "GPUCIBOT_DOCKERHUB_USER": "test-user",
            "HTTP_CODES_FILE": str(codes_file),
            "PATH": f"{bin_dir}:{environment['PATH']}",
            "SLEEP_LOG": str(sleep_log),
        }
    )
    result = subprocess.run(
        ["/bin/bash", "-c", "source ci/common.sh; check_tag_exists staging test-tag"],
        cwd=REPOSITORY_ROOT,
        env=environment,
        check=False,
        capture_output=True,
        text=True,
    )
    sleeps = sleep_log.read_text(encoding="utf-8") if sleep_log.exists() else ""
    return result, sleeps


def test_tag_check_retries_transient_responses(tmp_path: Path) -> None:
    result, sleeps = run_tag_check(tmp_path, ["404", "429", "500", "200"])

    assert result.returncode == 0
    assert sleeps == "5\n10\n20\n"
    assert "HTTP 404" in result.stdout
    assert "HTTP 429" in result.stdout
    assert "HTTP 500" in result.stdout


def test_tag_check_fails_immediately_for_authentication_errors(tmp_path: Path) -> None:
    result, sleeps = run_tag_check(tmp_path, ["401"])

    assert result.returncode == 1
    assert sleeps == ""
    assert "HTTP 401" in result.stdout
