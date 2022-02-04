# Release Process

This article outlines the release process for the `rapidsai/docker` repo.

- Development occurs on versioned branches (i.e. `branch-21.08`)
- A few days prior to a release, `gpuci-scripts` will open a release PR that merges the versioned branch that is to be released into the `main` branch
  - Ensure the [rapidsai/notebooks](https://github.com/rapidsai/notebooks) repo release PR has been merged
  - Make sure the [ci/axis](/ci/axis) files get updated prior to merging to `main`
    - Update `FROM_IMAGE` to remove `-nightly` suffix
    - Add `-nightly` suffix to excludes
    - Remove any other `RAPIDS_VER` entries that aren't the release versions
  - Immediately prior to merging this release PR, the updated DockerHub READMEs need to be pushed to the verisoned branch using `./dockerhub-readme/generate_readmes.py -n 21.08 -s 21.06`, where `-s` is the stable version that will be released and `-n` is the next RAPIDS nightly version (i.e. the RAPIDS version _after_ the current release). This should be pushed directly to the release branch (i.e. `branch-21.08`)<sup>1</sup>.
- Create the next versioned branch after the release versioned branch has been merged to `main`
- The first commit on the next versioned branch should include the following changes:
  - Re-add `-nightly` suffix to `FROM_IMAGE` fields in the axis files in [ci/axis](/ci/axis)
  - Update `excludes` fields in the axis files in [ci/axis](/ci/axis)
  - Update `RAPIDS_VER` fields in the axis files in [ci/axis](/ci/axis)
  - Update `settings.yaml`
  - Regenerate Dockerfiles with `generate_dockerfiles.py`
  - Regenerate DockerHub READMEs with `dockerhub-readme/generate_readmes.py`

## Footnotes

1. As outlined in the [generated-files.yml](/.github/workflows/generated-files.yml) GitHub Action, PRs that are submitted to the `main` branch generate the DockerHub READMEs using a different version than non-`main` PRs. Therefore, DockerHub README updates for releases need to be pushed directly to the versioned branch as opposed to having a separate PR which merges the changes into the versioned branch.
