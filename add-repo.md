# Adding a new repo to `devel` images

- Update `repoSettings` by adding `<repo name>_REPO` and `<repo name>_BRANCH` settings. These will automatically get picked up by the code generator scripts responsible for doing the `clone` steps during the build.
- Update `templates/docker/build_rapids` Dockerfile template snippet to add the `RUN` command to build the new component. If the new component is following conventions (mainly that it has a `build.sh` at the repo root), then the addition should be easy.
