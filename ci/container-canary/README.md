# container-canary

Configurations for testing images built from this repo with `container-canary` ([NVIDIA/container-canary](https://github.com/NVIDIA/container-canary)).

## Running the tests

Install `container-canary` following the instructions in that project's repo.

Run the tests against a built image.
For example:

```shell
IMAGE_URI="rapidsai/notebooks:25.06a-cuda12.8-py3.12"

# using a config checked in here
container-canary validate \
    --file ./ci/container-canary/base.yml \
    "${IMAGE_URI}"

# usage a config from the container-canary repo
container-canary validate \
    --file https://raw.githubusercontent.com/NVIDIA/container-canary/main/examples/databricks.yaml \
    "${IMAGE_URI}"
```
