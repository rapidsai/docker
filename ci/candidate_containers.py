# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Prepare the existing container targets from immutable train inputs."""

from __future__ import annotations

import argparse
import itertools
import json
import os
from pathlib import Path
import re
import shutil
import subprocess  # nosec B404 - invokes a validated tool allowlist without a shell.

import yaml

ROOT = Path(__file__).resolve().parents[1]
TOOLS = {"git", "docker", "bash", "yq", "jq", "aws", "python3"}
SOURCE_NAMES = ("integration", "cudf", "cuml", "cugraph")
REVISION = re.compile(r"[0-9a-f]{40}")
REPOSITORY = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")


def run(arguments, *, cwd=ROOT, env=None, input_text=None, stream=False):
    """Invoke only installed build tools, without interpreting shell input."""
    if arguments[0] not in TOOLS:
        raise ValueError("unsupported candidate build tool")
    executable = shutil.which(arguments[0])
    if executable is None:
        raise ValueError(f"required candidate tool is unavailable: {arguments[0]}")
    # The executable is resolved from the reviewed job PATH; arguments are never shell code.
    result = subprocess.run(  # noqa: S603 # nosec B603
        [executable, *arguments[1:]],
        cwd=cwd,
        env=env,
        input=input_text,
        check=True,
        capture_output=not stream,
        text=True,
    )
    return (result.stdout or "").strip()


def container_matrix(native, version):
    if not re.fullmatch(r"[0-9]{2}\.[0-9]{2}", version):
        raise ValueError("invalid frozen container version")
    result = []
    for row in native["include"]:
        kinds = ["base", "notebooks", "cuvs-bench"]
        if row["BUILD_CUVS_BENCH_CPU_IMAGE"]:
            kinds.append("cuvs-bench-cpu")
        for arch, kind in itertools.product(row["ARCHES"], kinds):
            if arch not in {"amd64", "arm64"}:
                raise ValueError("unsupported container platform")
            tag = f"{version}-py{row['PYTHON_VER']}"
            if kind != "cuvs-bench-cpu":
                tag = f"{version}-cuda{row['CUDA_TAG']}-py{row['PYTHON_VER']}"
            result.append({**{key: value for key, value in row.items() if key != "ARCHES"}, "ARCH": arch, "KIND": kind, "IMAGE_NAME": f"docker.io/rapidsai/{kind}", "IMAGE_TAG": f"{tag}-{arch}"})
    return {"include": result}


def frozen_sources(train):
    sources = {}
    for name in SOURCE_NAMES:
        revision = train["source_revisions"].get(name, "")
        repository = train["github_repositories"].get(name, "")
        if not REVISION.fullmatch(revision) or not REPOSITORY.fullmatch(repository):
            raise ValueError(f"missing frozen container source: {name}")
        sources[name] = {"repository": repository, "revision": revision}
    dfg = train["build_tool_revisions"].get("dependency-file-generator", "")
    if not REVISION.fullmatch(dfg):
        raise ValueError("missing frozen dependency-file-generator source")
    sources["dependency-file-generator"] = {"repository": "rapidsai/dependency-file-generator", "revision": dfg}
    metadata = train.get("rapids_metadata_revision", "")
    if not REVISION.fullmatch(metadata):
        raise ValueError("missing frozen rapids-metadata source")
    sources["rapids-metadata"] = {"repository": "rapidsai/rapids-metadata", "revision": metadata}
    return sources


def checkout_source(source, destination):
    run(["git", "init", "--quiet", str(destination)])
    run(["git", "-C", str(destination), "remote", "add", "origin", f"https://github.com/{source['repository']}.git"])
    run(["git", "-C", str(destination), "fetch", "--quiet", "--depth", "1", "origin", source["revision"]])
    run(["git", "-C", str(destination), "checkout", "--quiet", "--detach", "FETCH_HEAD"])
    if run(["git", "-C", str(destination), "rev-parse", "HEAD"]) != source["revision"]:
        raise ValueError("container source checkout is not the frozen commit")


def replace_once(source, before, after):
    if source.count(before) != 1:
        raise ValueError(f"candidate Dockerfile requires one reviewed statement: {before}")
    return source.replace(before, after, 1)


def candidate_dockerfile(source, dfg_source, metadata_source):
    """Inject a private channel and verification without changing public Dockerfiles."""
    injection = "COPY candidate-package-receipts.json /candidate-package-receipts.json\nCOPY scripts/verify-candidate-environment.py /verify-candidate-environment.py\n"
    source = source.replace("COPY condarc /", injection + "COPY condarc /")
    if "COPY notebooks.sh /notebooks.sh" in source:
        source = replace_once(source, 'ARG RAPIDS_BRANCH="main"', 'ARG RAPIDS_BRANCH="main"\nENV RAPIDS_RELEASE_CANDIDATE=1')
        source = replace_once(source, "COPY notebooks.sh /notebooks.sh", "COPY notebooks.sh /notebooks.sh\nCOPY candidate-source-manifest.json /candidate-source-manifest.json")
        source = replace_once(source, "'rapids-dependency-file-generator==1.*,>=1.22'", f"'rapids-metadata @ git+https://github.com/{metadata_source['repository']}.git@{metadata_source['revision']}'\n  'rapids-dependency-file-generator @ git+https://github.com/{dfg_source['repository']}.git@{dfg_source['revision']}'")
    # Every runtime target retains the real installs, then verifies their candidate origins.
    source = source.replace("# Notebooks image\n", "RUN python /verify-candidate-environment.py\n\n# Notebooks image\n")
    source += "\nRUN python /verify-candidate-environment.py\n"
    # Mount the channel only while building so the OCI image does not retain all train archives.
    return re.sub(r"^RUN\s", "RUN --mount=type=bind,source=candidate-channel,target=/candidate-channel,readonly ", source, flags=re.MULTILINE)


def package_receipts(channel, owned_names, required):
    packages = {}
    for platform in ("linux-64", "linux-aarch64", "noarch"):
        index = channel / platform / "repodata.json"
        if not index.exists():
            continue
        document = json.loads(index.read_text())
        for filename, record in {**document.get("packages", {}), **document.get("packages.conda", {})}.items():
            if Path(filename).name != filename or not re.fullmatch(r"[0-9a-f]{64}", record.get("sha256", "")):
                raise ValueError("private channel has an invalid package receipt")
            packages[f"{platform}/{filename}"] = {"name": record["name"], "sha256": record["sha256"]}
    return {"schema_version": 1, "owned_names": sorted(owned_names | {"rapids"}), "required": required, "packages": packages}


def prepare_context(train, arch, cuda, python, kind):
    sources = frozen_sources(train)
    source_inputs = json.loads(Path(os.environ["RELEASE_CANDIDATE_SOURCE_INPUTS"]).read_text())
    for name, source in sources.items():
        family = "sources" if name in SOURCE_NAMES else "build_tools"
        if source_inputs.get(family, {}).get(name) != source:
            raise ValueError(f"container source is absent from the validated build input receipt: {name}")
    channel = Path(os.environ["RAPIDS_CANDIDATE_CONDA_CHANNEL"]).resolve()
    if not channel.is_dir():
        raise ValueError("private candidate Conda channel is missing")
    context = ROOT / "context"
    work = ROOT / ".candidate-state"
    work.mkdir(exist_ok=True)
    aggregate = work / "aggregate"
    aggregate.mkdir()
    checkout_source(sources["integration"], aggregate / "integration")
    shutil.copytree(channel, aggregate / "channel", symlinks=False)
    version = train["version_contract"]["package_versions"]["conda"]
    miniforge = str(yaml.safe_load((ROOT / "versions.yaml").read_text())["MINIFORGE_VER"])
    if not re.fullmatch(r"[0-9A-Za-z.-]+", miniforge) or not re.fullmatch(r"[0-9A-Za-z.]+", version):
        raise ValueError("invalid frozen aggregate build version")
    date = os.environ["RAPIDS_DATETIME_STRING"]
    if not re.fullmatch(r"[0-9]{12}", date):
        raise ValueError("aggregate build datetime must match the declared build input")
    host_platform = "linux-64" if arch == "amd64" else "linux-aarch64"
    (aggregate / "Dockerfile").write_text(
        f"FROM condaforge/miniforge3:{miniforge} AS aggregate\n"
        "COPY integration /source\nCOPY channel /channel\nWORKDIR /source\n"
        f"ENV RAPIDS_PACKAGE_VERSION={version} RAPIDS_CUDA_VERSION={cuda} RAPIDS_DATETIME_STRING={date}\n"
        "RUN conda install -y --override-channels -c conda-forge rattler-build=0.76.1 && "
        "rattler-build build --experimental --recipe conda/recipes/rapids --variant-config conda/recipes/versions.yaml "
        f"--channel /channel --channel conda-forge --host-platform {host_platform} --test skip --output-dir /out\n"
        "FROM scratch\nCOPY --from=aggregate /out/noarch /noarch\n"
    )
    run(["docker", "buildx", "build", "--platform", f"linux/{arch}", "--output", f"type=local,dest={aggregate / 'output'}", str(aggregate)], stream=True)
    outputs = list((aggregate / "output/noarch").glob("rapids-*.conda"))
    if len(outputs) != 1:
        raise ValueError("frozen integration recipe did not produce exactly one RAPIDS aggregate")
    shutil.copy2(outputs[0], channel / "noarch" / outputs[0].name)
    # This installed indexer is pinned in the caller; no public RAPIDS channels are used.
    run(["python3", "-m", "conda_index", str(channel)])
    shutil.copytree(channel, context / "candidate-channel", symlinks=False)
    for member in (context / "candidate-channel").rglob("*"):
        member.chmod(0o755 if member.is_dir() else 0o644)
    (context / "condarc").write_text("auto_update_conda: false\nchannel_priority: strict\nchannels:\n  - file:///candidate-channel\n  - conda-forge\n")
    manifest = {"schema_version": 1, "source_revisions": {name: source["revision"] for name, source in sources.items()}, "github_repositories": {name: source["repository"] for name, source in sources.items()}}
    (context / "candidate-source-manifest.json").write_text(json.dumps(manifest, sort_keys=True) + "\n")
    gha_tools = Path(os.environ["RUNNER_TEMP"]) / "release-candidate-dependencies/gha-tools"
    if run(["git", "-C", str(gha_tools), "rev-parse", "HEAD"]) != train["build_implementation_revisions"]["gha-tools"]:
        raise ValueError("image gha-tools are not the frozen tool revision")
    shutil.copytree(gha_tools / "tools", context / "candidate-gha-tools")
    installer = "#!/bin/bash\nset -euo pipefail\ncp -a /candidate-gha-tools/. /usr/local/bin/\n"
    (context / "scripts/install-gha-tools").write_text(installer)
    ignore = context / ".dockerignore"
    ignore.write_text(ignore.read_text() + "\n!candidate-channel/\n!candidate-channel/**\n!candidate-gha-tools/\n!candidate-gha-tools/**\n!candidate-source-manifest.json\n!candidate-package-receipts.json\n!scripts/verify-candidate-environment.py\n")
    owned = {package for unit in train["release_units"] if unit["artifact_family"] == "conda" for package in unit["packages"]}
    required = ["rapids", "rapids-cli"] if kind in {"base", "notebooks"} else [kind]
    receipts = package_receipts(channel, owned, required)
    (context / "candidate-package-receipts.json").write_text(json.dumps(receipts, sort_keys=True) + "\n")
    original = ROOT / ("Dockerfile" if kind in {"base", "notebooks"} else f"cuvs-bench/{'cpu' if kind.endswith('-cpu') else 'gpu'}/Dockerfile")
    text = candidate_dockerfile(original.read_text(), sources["dependency-file-generator"], sources["rapids-metadata"])
    text = re.sub(r"^(FROM .+)$", r"\1\nCOPY candidate-gha-tools /candidate-gha-tools", text, flags=re.MULTILINE)
    destination = work / "candidate.Dockerfile"
    destination.write_text(text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["matrix", "prepare"])
    args = parser.parse_args()
    train = json.loads(Path(os.environ["RAPIDS_RELEASE_CANDIDATE_TRAIN_FILE"]).read_text())
    if args.command == "matrix":
        native = json.loads(run(["bash", "ci/compute-matrix.sh"]))
        matrix = container_matrix(native, train["version_contract"]["package_versions"]["container"])
        with Path(os.environ["GITHUB_OUTPUT"]).open("a") as output:
            output.write("matrix=" + json.dumps(matrix, separators=(",", ":")) + "\n")
    else:
        prepare_context(train, os.environ["ARCH"], os.environ["CUDA_VER"], os.environ["PYTHON_VER"], os.environ["IMAGE_KIND"])


if __name__ == "__main__":
    main()
