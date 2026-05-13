# Security Policy

`rapidsai/docker` builds and publishes the official RAPIDS end-user container
images — `rapidsai/base` (a minimal CUDA + RAPIDS conda environment) and
`rapidsai/notebooks` (the base image plus JupyterLab and the RAPIDS example
notebooks). The repository's "product" is the images themselves; the source
in this repo is build tooling, image-build context, CI workflows, and the
container entrypoint.

This SECURITY.md is therefore oriented around the security properties of the
shipped images and the supply chain that produces them, in addition to the
usual reporting policy.

## Reporting a Vulnerability

Please report security vulnerabilities privately through one of the channels
below. **Do not open a public GitHub issue, PR, or discussion** for a
suspected vulnerability.

1. **NVIDIA Vulnerability Disclosure Program (preferred)**
   <https://www.nvidia.com/en-us/security/>
   Submit through the NVIDIA PSIRT web form. This is the fastest path to
   triage and tracking.

2. **Email NVIDIA PSIRT**
   psirt@nvidia.com — encrypt sensitive reports with the
   [NVIDIA PSIRT PGP key](https://www.nvidia.com/en-us/security/pgp-key).

3. **GitHub Private Vulnerability Reporting**
   Use the **Security** tab on this repository → *Report a vulnerability*.

Please include, where possible:

- Affected image (`rapidsai/base` or `rapidsai/notebooks`) and tag
- Affected component (entrypoint script, Dockerfile stage, a specific bundled
  package, a CI workflow)
- Reproduction steps and the exact `docker run` invocation if relevant
- Impact assessment (image-content vulnerability, runtime privilege issue,
  supply-chain compromise, CI/CD weakness)
- Any relevant CWE / CVE identifiers

NVIDIA PSIRT will acknowledge receipt and coordinate triage, fix development,
and coordinated disclosure. More on NVIDIA's response process:
<https://www.nvidia.com/en-us/security/psirt-policies/>.

## Security Architecture & Context

**Classification:** Container image build + distribution. The repository
contains a multi-stage `Dockerfile`, the build context (`context/`,
including `entrypoint.sh` and `notebooks.sh`), version / matrix metadata
(`matrix.yaml`, `versions.yaml`, `pinned/`), CI workflows, and tests.

**Shipped artifacts:**

- **`rapidsai/base`** — Ubuntu + NVIDIA CUDA base + miniforge (`conda-forge`)
  with the RAPIDS conda environment installed under `/opt/conda`. Default
  command is `ipython`. Runs as the unprivileged `rapids` user.
- **`rapidsai/notebooks`** — extends `base` with `jupyterlab=4`,
  `dask-labextension`, `jupyterlab-nvdashboard`, and the RAPIDS example
  notebooks under `/home/rapids/notebooks`. The default `CMD` starts
  `jupyter-lab` listening on `0.0.0.0:8888`. **The default JupyterLab
  configuration sets `--NotebookApp.token=''` and
  `--NotebookApp.allow_origin='*'`** — that is, an empty token and any-
  origin CORS. This is intentional for local interactive use; see the
  assumptions below.

**Build inputs (supply chain):**

- Base image: `nvidia/cuda:${CUDA_VER}-base-${LINUX_VER}` and
  `condaforge/miniforge3:${MINIFORGE_VER}`.
- Conda packages from `conda-forge` and `rapidsai` channels.
- pip packages from PyPI.
- `yq` binary downloaded from GitHub releases at a pinned version.
- A pinned Python-tarfile patch for CVE-2025-8194 fetched from a GitHub
  gist at a fixed commit SHA.
- RAPIDS notebooks cloned from `github.com/rapidsai/<repo>` at
  `${RAPIDS_BRANCH}` (defaults to `main`).
- GitHub Actions workflows under `.github/workflows/` produce and push
  the images.

**Container runtime configuration honored by `entrypoint.sh`:**

| Env var | Effect |
| --- | --- |
| `EXTRA_CONDA_PACKAGES` | Passed verbatim to `conda install -n base -y` |
| `EXTRA_PIP_PACKAGES`   | Passed verbatim to `pip install` |
| `CONDA_TIMEOUT`        | Timeout (seconds) wrapping the conda call |
| `PIP_TIMEOUT`          | Timeout (seconds) wrapping the pip call |
| `UNQUOTE=true`         | Switches the final `exec` from quoted (`exec "$@"`) to word-split (`exec $@`) |
| `/home/rapids/environment.yml` | Volume-mounted file is `conda env update`'d at startup |

**Out of scope for this policy:** vulnerabilities in upstream base images
(`nvidia/cuda`, `condaforge/miniforge3`), in CUDA itself, in the upstream
conda / pip packages that compose the RAPIDS environment, or in JupyterLab.
Report those to their respective projects (NVIDIA driver and CUDA bugs
still go to PSIRT). Vulnerabilities in *how* this repo composes those
upstreams — pinning, fetch integrity, build-time patching, runtime config —
are in scope.

## Threat Model

The threats below are concrete to this repository's role as a container
image producer. Several have already been observed and remediated through
the [RAPIDS Security Audit](https://github.com/orgs/rapidsai/projects/207).

1. **Default-credential JupyterLab on `rapidsai/notebooks`.**
   The notebooks image's default `CMD` starts JupyterLab with an empty
   token and `allow_origin='*'` on `0.0.0.0:8888`. Any process or
   network peer that can reach port 8888 has full code execution as the
   `rapids` user inside the container, with whatever GPU and volume
   access the host has granted. Publishing the container's port to a
   shared network — even briefly — is an unauthenticated remote-code-
   execution exposure.

2. **Runtime-controlled package installation via env vars.**
   `entrypoint.sh` passes `EXTRA_CONDA_PACKAGES` and `EXTRA_PIP_PACKAGES`
   unquoted into `conda install` and `pip install`. A caller that
   controls the container's environment (a misconfigured orchestrator,
   a multi-tenant runner) can install arbitrary packages from
   conda-forge / PyPI / arbitrary indexes, with whatever post-install
   hooks they ship. This is documented behavior, not a bug, but it is
   load-bearing for the trust model: the container's environment must
   be controlled by the deployer, not by container users.

3. **`UNQUOTE=true` argument splitting.**
   Setting `UNQUOTE=true` switches the final `exec` from `exec "$@"`
   to `exec $@`, performing word-splitting and glob expansion on
   `docker run` arguments. Documented and intentional; the same
   environment-control assumption applies.

4. **GitHub Actions template / shell injection.**
   The build workflows use `${{ ... }}` GitHub Actions expression
   interpolation in shell `run:` blocks. Historically, untrusted PR
   metadata (titles, branch names) reached these interpolation points,
   yielding arbitrary command execution in the runner with the
   workflow's secrets and write tokens. This is the
   [highest-severity finding](https://github.com/orgs/rapidsai/projects/207)
   the audit produced against this repository.

5. **Mutable-ref action / workflow pinning.**
   Reusable workflows and third-party actions referenced by tag rather
   than commit SHA permit upstream maintainers (or anyone who compromises
   them) to retroactively change the code that runs in this repo's CI,
   with access to its secrets. The audit produced fixes pinning to SHAs;
   re-introduction is the recurring risk.

6. **`secrets: inherit` over-broad scope.**
   Calls to reusable workflows with `secrets: inherit` pass every
   repository secret to the called workflow. Even if the called workflow
   is trusted today, it expands the blast radius of any future bug in
   it. Audit remediation moved to explicit secret passing; new callers
   should follow that pattern.

7. **Build-time network fetches.**
   The image build pulls a `yq` binary from a GitHub release and a
   tarfile-CVE patch from a personal GitHub gist (both at pinned
   references). If either source were tampered with at the pinned ref —
   GitHub release replacement, gist account compromise — the resulting
   image would carry tampered code. The pin reduces but does not
   eliminate this risk.

8. **Notebook content executes on container start.**
   The `rapidsai/notebooks` image ships example notebooks under
   `/home/rapids/notebooks`. JupyterLab clients open and can execute
   them. Users who treat the notebooks as inert documentation should
   not — they are code that runs in-container with GPU and volume
   access.

## Critical Security Assumptions

The following are assumed of the image deployer / operator. These are
load-bearing — violating them turns documented behavior into a vulnerability.

- **JupyterLab is exposed only on trusted networks.**
  The `rapidsai/notebooks` default configuration is suitable for
  `docker run` on a single-user workstation behind a host firewall, or
  for deployments that put their own authenticating reverse proxy in
  front of the container. Publishing port 8888 to a multi-user network
  or to the public internet without an authenticating layer in front is
  an unauthenticated-RCE configuration. Operators who need
  authentication should set `JUPYTER_TOKEN` (or override the `CMD`) to
  enable a real token, and restrict CORS appropriately.

- **The container's environment is controlled by the deployer.**
  `EXTRA_CONDA_PACKAGES`, `EXTRA_PIP_PACKAGES`, `UNQUOTE`, and the
  contents of `/home/rapids/environment.yml` are intentional
  configuration knobs. They are not safe inputs from container users —
  do not pass through user-controlled env vars or mount user-supplied
  `environment.yml` files in multi-tenant deployments.

- **Volume mounts are scoped to what the container needs.**
  The container runs as the `rapids` user, but `docker run -v` mounts
  carry whatever the host grants. Mount sensitive paths read-only or
  not at all.

- **GPU sharing is not a confidentiality boundary.**
  Multiple containers sharing a GPU may observe each other's GPU memory
  through driver-level side channels. Use MIG, exclusive process
  scheduling, or one GPU per container when confidentiality matters.

- **The image tag is pinned in production.**
  Image tags like `26.06-cuda13-py3.13` are reused as new patch
  versions are published. Production users should pin to a specific
  digest (`rapidsai/base@sha256:…`) and rebuild on a deliberate cadence
  to take in security fixes.

- **CI workflow changes go through review.**
  The history of this repo includes critical CI workflow findings;
  template injection and over-broad secret scopes recur if reviewers
  don't actively look for them. Maintainers are expected to enforce
  this in code review; treat workflow YAML changes with the same care
  as production code.

- **The build host's outbound network is trusted.**
  Image builds fetch `yq`, conda packages, pip packages, RAPIDS git
  repos, and a CVE patch from a GitHub gist. A compromised build-host
  network (DNS poisoning, transparent proxy injection) can substitute
  any of these — pinning protects against upstream tampering at the
  source, not against in-path tampering on the build host.

## Supported Versions

Image tags follow the RAPIDS release cadence. Older image tags are not
re-published with new security fixes; pull a recent tag (or rebuild from a
recent `RAPIDS_VER`) to receive upstream and in-house security updates.

## Dependency Security

The image inherits the security posture of its bases (`nvidia/cuda`,
`condaforge/miniforge3`), of every conda package in the RAPIDS environment,
and of JupyterLab and its extensions. Upstream CVE advisories in any of
those translate to image-level rebuilds; high-severity advisories may
trigger out-of-band image republishes.
