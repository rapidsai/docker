#!/bin/bash
# Copyright (c) 2025, NVIDIA CORPORATION.

set -u -o pipefail

# only exit at the very end, instead of on the first failed check
EXIT_CODE=0
trap "EXIT_CODE=1" ERR
set +e

DOCKERFILES=$(find . -type f -name 'Dockerfile')

for dockerfile in ${DOCKERFILES}; do
	echo "linting '${dockerfile}'"
	docker run \
		--rm \
        -v "$(pwd)/.hadolint.yaml":/.config/hadolint.yaml \
		-i \
		hadolint/hadolint \
	< "${dockerfile}"
done

echo "done checking images with 'hadolint'. Exiting (exit code = ${EXIT_CODE})."
exit ${EXIT_CODE}
