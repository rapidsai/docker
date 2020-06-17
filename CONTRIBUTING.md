# RAPIDS Images

This repo uses [Jinja2](https://www.palletsprojects.com/p/jinja/) to generate Dockerfiles for [RAPIDS](https://github.com/rapidsai).

## Table of Contents

- [Dependencies](#Dependencies)
- [Project Structure](#Project-Structure)
- [Development](#Development)
- [Building the Docker Images](#Building-the-Docker-Images)
- [CI](#CI)
- [Pre-Commit Hook](#Pre-commit-hook)
- [Adding a new Repo to Devel Images](#Adding-a-new-Repo-to-Devel-Images)
- [Recommended VS Code Plugin](#Recommended-VS-Code-Plugin)

## Dependencies

Make sure to have the following dependencies installed to compile the Dockerfiles.

- Python 3.6+
- [Jinja2](https://pypi.org/project/Jinja2/)
- [PyYAML](https://pypi.org/project/PyYAML/)

## Project Structure

```
├── settings.yaml
├── context/
├── generated-dockerfiles/
├── generate_dockerfiles.py
└── templates/
    └── partials/
```

- [`settings.yaml`](/settings.yaml) - Contains some default values used by all of the Jinja2 templates. All values from this file are available in the Jinja2 templates.
- [`context/`](/context/) - Contains any files that will be copied into the Docker images during the Docker build process.
- [`generated-dockerfiles/`](/generated-dockerfiles/) - Contains the latest compiled Dockerfiles. This folder is populated automatically and it's contents should never be edited directly by developers.
- [`generate_dockerfiles.py`](/generate_dockerfiles.py) - Python script to compile Jinja templates.
- [`templates/`](/templates/) - Contains the Jinja2 templates for the different RAPIDS image types.
- [`partials/`](/templates/partials/) - Contains Jinja2 templates that may be included from files in the parent `templates` folder. Only create a partial if a piece of code needs to be repeated across multiple parent templates.

## Development

Dockerfile changes should be made to the `templates/` folder.

Once changes have been made, run the following command to generate the Dockerfiles:

```sh
python generate_dockerfiles.py
# or
./generate_dockerfiles.py
```

This will write the Dockerfiles to the `generated-dockerfiles` directory.

## Building the Docker Images

See the [_Building Images_](README.md#Building-Images) section in the `README.md` for details on how to build the compiled Dockerfiles.

## CI

The following CI checks must pass before a PR can be merged:

- **Dockerfiles updated** - the Dockerfiles in `generated-dockerfiles` must be up to date. Make sure to have run and committed the files that are output from `generate_dockerfiles.py` to ensure this check passes. See the [Pre-commit Hook](#Pre-commit-Hook) section below to get earlier feedback.

## Pre-commit Hook

This repo utilizes [pre-commit](https://pre-commit.com/) to provide developers with quick feedback about their changes. Install [pre-commit](https://pre-commit.com/#installation) and run `pre-commit install` from the project's root folder to activate the hooks.

## Adding a new Repo to Devel Images

To add a new repo to the `devel` image, simply add another entry to the `RAPIDS_LIBS` list in `settings.yaml`. The attributes of `RAPIDS_LIBS` are explained below:

```yaml
RAPIDS_LIBS:
  - name: xgboost # name of the library
    repo_url: https://github.com/rapidsai/xgboost.git # URL of the repo
    update_submodules: no # (optional, default: yes) determines whether the "--remote-submodules" flag should be used when cloning the repo
    branch: rapids-0.14-release # (optional, default: "branch-<rapids_version>") branch to be cloned inside of the image
```

If the new repo does not have a `build.sh` file in it's root directory and thus requires special instructions to build, make sure to add an additional `elif` block in [devel_build.dockerfile.j2](/templates/partials/devel_build.dockerfile.j2).

## Recommended VS Code Plugin

Users using VS Code as their editor can install the [Better Jinja](https://marketplace.visualstudio.com/items?itemName=samuelcolvin.jinjahtml) plugin to enable Jinja syntax highlighting for `*.dockerfile.j2` files.
