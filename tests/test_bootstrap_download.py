# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Real HTTP failures must finish downloading before archive extraction."""

import contextlib
import http.server
import io
import os
import shlex
import shutil
import subprocess
import tarfile
import threading
from pathlib import Path

import pytest

ROOT = Path(__file__).parents[1]
RETRY_ATTEMPTS = 4


@contextlib.contextmanager
def download_server(directory, failures, payload):
    state = {"requests": 0}

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            index = state["requests"]
            state["requests"] += 1
            failure = failures[index] if index < len(failures) else None
            if failure == "500":
                self.send_error(500)
            else:
                self.send_response(200)
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload[:10] if failure == "partial" else payload)
                self.close_connection = True

        def log_message(self, *_args):
            pass

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    binaries = directory / "bin"
    binaries.mkdir()
    for name in ("wget", "curl"):
        executable = shutil.which(name)
        assert executable is not None
        script = binaries / name
        script.write_text(
            "#!/bin/bash\narguments=()\n"
            'for argument in "$@"; do\n'
            '  case "$argument" in\n'
            f'    https://*) argument="http://127.0.0.1:{server.server_port}/asset" ;;\n'
            '    --waitretry=10) argument=--waitretry=0 ;;\n'
            '  esac\n'
            '  arguments+=("$argument")\n'
            'done\n'
            # Use real transfer/retry logic; shorten only the test's delays.
            'for ((i=0; i<${#arguments[@]}; i++)); do\n'
            '  if [[ "${arguments[i]}" == --retry-delay ]]; then arguments[i+1]=0; fi\n'
            'done\n'
            f'exec {shlex.quote(executable)} "${{arguments[@]}}"\n'
        )
        script.chmod(0o755)
    environment = {
        **os.environ,
        "PATH": f"{binaries}:{os.environ['PATH']}",
        "TMPDIR": str(directory),
        "NO_PROXY": "127.0.0.1",
        "no_proxy": "127.0.0.1",
    }
    try:
        yield environment, state
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


def tool_archive():
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w:gz") as archive:
        payload = b"#!/bin/sh\necho complete-tool\n"
        entry = tarfile.TarInfo("rapids-tool")
        entry.size = len(payload)
        entry.mode = 0o755
        archive.addfile(entry, io.BytesIO(payload))
    return output.getvalue()


@pytest.mark.parametrize("failures", [["500"], ["partial"], ["500", "partial"], ["500"] * 4])
def test_gha_tools_bootstrap_recovers_before_extracting(tmp_path, failures):
    destination = tmp_path / "installed"
    destination.mkdir()
    bash = shutil.which("bash")
    assert bash is not None
    with download_server(tmp_path, failures, tool_archive()) as (environment, state):
        before = set(tmp_path.iterdir())
        result = subprocess.run(  # noqa: S603 - fixed repository script with fixture-controlled destination.
            [bash, str(ROOT / "context/scripts/install-gha-tools")],
            env={**environment, "GHA_TOOLS_INSTALL_DIR": str(destination)},
            text=True,
            capture_output=True,
            timeout=20,
            check=False,
        )
        assert (result.returncode == 0) == (len(failures) < RETRY_ATTEMPTS), result.stdout + result.stderr
        assert state["requests"] == min(len(failures) + 1, RETRY_ATTEMPTS)
        assert set(tmp_path.iterdir()) == before
        if result.returncode == 0:
            installed = subprocess.check_output(  # noqa: S603 - executable is created by this fixture's archive.
                [str(destination / "rapids-tool")], text=True
            )
            assert installed.strip() == "complete-tool"
        else:
            assert not list(destination.iterdir())
