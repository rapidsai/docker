# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Reject public substitutes for installed train-owned Conda packages."""

import json
from pathlib import Path
from urllib.parse import unquote, urlparse


def verify_environment(receipts, records):
    installed = {record["name"]: record for record in records}
    missing = set(receipts["required"]) - installed.keys()
    if missing:
        raise ValueError(f"candidate image lacks required packages: {sorted(missing)}")
    for name in set(receipts["owned_names"]) & installed.keys():
        record = installed[name]
        url = urlparse(record.get("url", ""))
        if url.scheme != "file" or url.netloc:
            raise ValueError(f"train-owned package came from a public source: {name}")
        try:
            relative = str(Path(unquote(url.path)).relative_to("/candidate-channel"))
        except ValueError as error:
            raise ValueError(f"train-owned package is outside the private channel: {name}") from error
        expected = receipts["packages"].get(relative)
        if not expected or expected["name"] != name or expected["sha256"] != record.get("sha256"):
            raise ValueError(f"installed package does not match the candidate bytes: {name}")


def main():
    receipts = json.loads(Path("/candidate-package-receipts.json").read_text())
    records = [json.loads(path.read_text()) for path in Path("/opt/conda/conda-meta").glob("*.json")]
    verify_environment(receipts, records)


if __name__ == "__main__":
    main()
