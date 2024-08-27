# container-canary

Configurations for testing images built from this repo with `container-canary` ([NVIDIA/container-canary](https://github.com/NVIDIA/container-canary)).

## Running the tests

Install `container-canary` following the instructions in that project's repo.

Run the tests against a built image.
For example:

```shell
IMAGE_URI="rapidsai/notebooks:24.06a-cuda11.8-py3.11"

# using a config checked in here
canary validate \
    --file ./ci/container-canary/rapids.yml \
    "${IMAGE_URI}"

# usage a config from the container-canary repo
canary validate \
    --file https://raw.githubusercontent.com/NVIDIA/container-canary/main/examples/databricks.yaml \
    "${IMAGE_URI}"
```
