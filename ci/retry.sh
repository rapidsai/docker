#!/bin/bash
set +e
set -x

COMMAND=$1
shift
ARGS=$*
MAX_RETRIES=10
RETRIES=0
SLEEP_INTERVAL=60

${COMMAND} ${ARGS}
EXITCODE=$?
while (( ${EXITCODE} != 0 )) && \
      (( ${RETRIES} < ${MAX_RETRIES} )); do
    ((RETRIES++))
    echo "========================================"
    echo "RETRY ${RETRIES} OF ${MAX_RETRIES}"...
    echo -n "sleeping for ${SLEEP_INTERVAL} seconds..."
    sleep ${SLEEP_INTERVAL}
    echo "done"
    echo "========================================"

    ${COMMAND} ${ARGS}
    EXITCODE=$?
done
if (( ${EXITCODE} != 0 )); then
    exit ${EXITCODE}
fi
