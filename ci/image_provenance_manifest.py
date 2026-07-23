#!/usr/bin/env python3
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Generate a portable RAPIDS image provenance manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1


def _sha256(payload: bytes) -> str:
    return f"sha256:{hashlib.sha256(payload).hexdigest()}"


def parse_build_args(values: list[str]) -> dict[str, str]:
    """Convert repeated ``NAME=VALUE`` CLI options to a stable mapping."""
    build_args: dict[str, str] = {}
    for value in values:
        name, separator, argument = value.partition("=")
        if not separator or not name:
            raise ValueError(f"build argument must use NAME=VALUE syntax: {value!r}")
        build_args[name] = argument
    return dict(sorted(build_args.items()))


def conda_packages(metadata_dir: Path | None) -> list[dict[str, Any]]:
    """Read exact installed-package facts from conda-meta records."""
    if metadata_dir is None:
        return []
    packages: list[dict[str, Any]] = []
    for path in sorted(metadata_dir.glob("*.json")):
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise ValueError(f"invalid conda metadata JSON: {path}") from exc
        if not isinstance(record, dict):
            raise ValueError(f"conda metadata must be an object: {path}")
        name = str(record.get("name") or "").strip()
        version = str(record.get("version") or "").strip()
        build = str(record.get("build") or "").strip()
        if not name or not version:
            raise ValueError(f"conda metadata lacks name or version: {path}")
        packages.append(
            {
                "name": name,
                "version": version,
                "build": build,
                "build_number": record.get("build_number"),
                "channel": str(record.get("channel") or record.get("url") or ""),
                "url": str(record.get("url") or ""),
                # Conda is a distribution format, not an upstream pURL type.
                # A pURL is populated only once a vetted package mapping exists.
                "purls": [],
                "purl_source": "unmapped",
            }
        )
    return sorted(
        packages,
        key=lambda package: (
            package["name"],
            package["version"],
            package["build"],
            package["channel"],
        ),
    )


def parse_platform_manifest(value: str) -> dict[str, str]:
    """Parse ``os/architecture|reference|digest`` into a manifest entry."""
    platform, separator, remainder = value.partition("|")
    reference, separator2, digest = remainder.partition("|")
    os_name, separator3, architecture = platform.partition("/")
    if not separator or not separator2 or not separator3:
        raise ValueError(
            "platform manifests must use os/architecture|reference|sha256:digest"
        )
    if not digest.startswith("sha256:"):
        raise ValueError(f"platform manifest digest must be sha256: {digest!r}")
    return {
        "platform": platform,
        "reference": reference,
        "digest": digest,
    }


def build_manifest(
    *,
    image_reference: str,
    image_digest: str,
    image_kind: str,
    rapids_version: str,
    cuda_version: str,
    python_version: str,
    platform: str,
    source_repository: str,
    source_commit: str,
    workflow_ref: str,
    workflow_run_url: str,
    build_args: list[str],
    metadata_dir: Path | None = None,
    platform_manifests: list[str] | None = None,
) -> dict[str, Any]:
    """Construct the schema payload for a platform image or multiarch index."""
    if not image_digest.startswith("sha256:"):
        raise ValueError(f"image digest must be sha256: {image_digest!r}")
    packages = conda_packages(metadata_dir)
    package_payload = json.dumps(packages, sort_keys=True, separators=(",", ":")).encode()
    subject: dict[str, Any] = {
        "reference": image_reference,
        "digest": image_digest,
    }
    if platform != "multiarch":
        os_name, separator, architecture = platform.partition("/")
        if not separator:
            raise ValueError("platform must be os/architecture or multiarch")
        subject["platform"] = {"os": os_name, "architecture": architecture}
    manifest: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "subject": subject,
        "image": {
            "kind": image_kind,
            "rapids_version": rapids_version,
            "cuda_version": cuda_version,
            "python_version": python_version,
        },
        "build": {
            "source_repository": source_repository,
            "source_commit": source_commit,
            "workflow_ref": workflow_ref,
            "workflow_run_url": workflow_run_url,
            "build_args": parse_build_args(build_args),
        },
        "conda_packages": packages,
        "conda_packages_sha256": _sha256(package_payload),
        "platform_manifests": sorted(
            (parse_platform_manifest(value) for value in platform_manifests or []),
            key=lambda item: item["platform"],
        ),
    }
    return manifest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--image-reference", required=True)
    parser.add_argument("--image-digest", required=True)
    parser.add_argument("--image-kind", required=True)
    parser.add_argument("--rapids-version", required=True)
    parser.add_argument("--cuda-version", required=True)
    parser.add_argument("--python-version", required=True)
    parser.add_argument("--platform", required=True)
    parser.add_argument("--source-repository", required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--workflow-ref", required=True)
    parser.add_argument("--workflow-run-url", required=True)
    parser.add_argument("--conda-meta-dir", type=Path)
    parser.add_argument("--build-arg", action="append", default=[])
    parser.add_argument("--platform-manifest", action="append", default=[])
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    manifest = build_manifest(
        image_reference=args.image_reference,
        image_digest=args.image_digest,
        image_kind=args.image_kind,
        rapids_version=args.rapids_version,
        cuda_version=args.cuda_version,
        python_version=args.python_version,
        platform=args.platform,
        source_repository=args.source_repository,
        source_commit=args.source_commit,
        workflow_ref=args.workflow_ref,
        workflow_run_url=args.workflow_run_url,
        build_args=args.build_arg,
        metadata_dir=args.conda_meta_dir,
        platform_manifests=args.platform_manifest,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    main()
