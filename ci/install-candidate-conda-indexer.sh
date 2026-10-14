#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

version_file=${MINIFORGE_VERSION_FILE:-versions.yaml}
miniforge_version=$(awk '$1 == "MINIFORGE_VER:" { print $2 }' "${version_file}")
if [[ -z "${miniforge_version}" ]]; then
  echo "MINIFORGE_VER is missing from ${version_file}" >&2
  exit 1
fi

architecture=$(uname -m)
# Official installer checksums published at https://conda-forge.org/miniforge/.
case "${miniforge_version}:${architecture}" in
  26.1.0-0:x86_64)
    installer_arch=x86_64
    installer_sha256=127b5e14cfe6c83b787f624487cdc2168645ed82fdca1b0c1937caa086aed6d5
    ;;
  26.1.0-0:aarch64)
    installer_arch=aarch64
    installer_sha256=8baf8844ecf13e1458f81659ea286251d04b2d5ed90040efb77f158adedb2d95
    ;;
  *)
    echo "No verified Miniforge installer for version ${miniforge_version} on ${architecture}" >&2
    exit 1
    ;;
esac

installer="${RUNNER_TEMP}/Miniforge3-${miniforge_version}-Linux-${installer_arch}.sh"
install_prefix="${RUNNER_TEMP}/miniforge"
installer_url="https://github.com/conda-forge/miniforge/releases/download/${miniforge_version}/Miniforge3-${miniforge_version}-Linux-${installer_arch}.sh"
curl --fail --silent --show-error --location --output "${installer}" "${installer_url}"
printf '%s  %s\n' "${installer_sha256}" "${installer}" | sha256sum --check --status
bash "${installer}" -b -p "${install_prefix}"

"${install_prefix}/bin/conda" install --yes --name base --override-channels --channel conda-forge \
  conda-index=0.13.0 pyyaml=6.0.3
printf '%s\n' "${install_prefix}/bin" >> "${GITHUB_PATH}"
