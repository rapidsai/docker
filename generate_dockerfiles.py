#!/usr/bin/env python3

from datetime import datetime
from jinja2 import Environment, FileSystemLoader
import os as os_lib
import yaml

file_loader = FileSystemLoader("templates")
env = Environment(loader=file_loader, lstrip_blocks=True, trim_blocks=True)


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


def initialize_build_dir():
    """Creates or empties the "build" directory"""
    build_dir = "build"
    if not os_lib.path.exists(build_dir):
        return os_lib.makedirs(build_dir)
    filelist = [f for f in os_lib.listdir(build_dir) if f.endswith(".Dockerfile")]
    for f in filelist:
        os_lib.remove(os_lib.path.join(build_dir, f))


def main():
    """Generates Dockerfiles using Jinja2"""
    initialize_build_dir()
    settings = load_settings()
    for os in ["centos7", "ubuntu18.04"]:
        for image_type in ["Base", "Devel", "Runtime", "Quick"]:
            template = env.get_template(f"{image_type}.dockerfile.j2")
            output = template.render(
                os=os, image_type=image_type, now=datetime.utcnow(), **settings,
            )
            with open(f"build/{os}-{image_type.lower()}.Dockerfile", "w") as f:
                f.write(output)
    print("Dockerfiles successfully written to 'build' directory.")


if __name__ == "__main__":
    main()
