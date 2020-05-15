#!/usr/bin/env python3

from datetime import datetime
from jinja2 import Environment, FileSystemLoader
import os
import yaml

file_loader = FileSystemLoader("templates")
env = Environment(loader=file_loader, lstrip_blocks=True, trim_blocks=True)
output_dir = "build"


def load_settings():
    """Loads settings.yaml and sets default variables on necessary RAPIDS_LIBS entries"""
    with open("settings.yaml") as f:
        settings = yaml.load(f, Loader=yaml.FullLoader)
    # Set default RAPIDS_LIBS values
    for lib in settings["RAPIDS_LIBS"]:
        if "branch" not in lib.keys():
            lib["branch"] = f'branch-{settings["RAPIDS_VERSION"]}'
        if "update_submodules" not in lib.keys():
            lib["update_submodules"] = True
    return settings


def isFileMissingOrDifferent(filename, new_file_contents):
    """
    Determines whether a given filename is missing from the output_dir directory
    or if its contents are different from the given new_file_contents
    """
    if not (os.path.exists(f"{output_dir}/{filename}")):
        return True
    with open(f"{output_dir}/{filename}", "r") as f:
        existing_file_contents = f.read()
    if existing_file_contents != new_file_contents:
        return True
    return False


def main():
    """Generates missing or changed Dockerfiles using Jinja2"""
    files_changed = []
    settings = load_settings()
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for docker_os in ["centos7", "ubuntu18.04"]:
        for image_type in ["Base", "Devel", "Runtime", "Quick"]:
            dockerfile_name = f"{docker_os}-{image_type.lower()}.Dockerfile"
            template = env.get_template(f"{image_type}.dockerfile.j2")
            output = template.render(
                os=docker_os, image_type=image_type, now=datetime.utcnow(), **settings,
            )
            if isFileMissingOrDifferent(dockerfile_name, output):
                files_changed.append(dockerfile_name)
                with open(f"{output_dir}/{dockerfile_name}", "w") as f:
                    f.write(output)
    if not files_changed:
        print(f"No files in the {output_dir} directory were changed.")
    else:
        print(
            f"The following files were generated or changed and written to the {output_dir} directory:"
        )
        for file in files_changed:
            print(f"  - {file}")


if __name__ == "__main__":
    main()
