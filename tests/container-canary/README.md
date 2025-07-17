# container-canary

Configurations for testing images built from this repo with `container-canary` ([NVIDIA/container-canary](https://github.com/NVIDIA/container-canary)).

## Running the tests

Install `container-canary` following the instructions in that project's repo.

Run the tests against a built image, the same way they're run in CI.

```shell
IMAGE_URI="rapidsai/notebooks:25.10a-cuda12.9-py3.13"

ci/run-validation-checks.sh \
    --dask-scheduler \
    --notebooks \
    "${IMAGE_URI}"
```

Or try invoking individual sets of `container-canary` checks.

```shell
# using a config checked in here
container-canary validate \
    --file ./tests/container-canary/base.yml \
    "${IMAGE_URI}"

# usage a config from the container-canary repo
container-canary validate \
    --file https://raw.githubusercontent.com/NVIDIA/container-canary/main/examples/databricks.yaml \
    "${IMAGE_URI}"
```
