#!/usr/bin/env python3
"""
Python script to generate Dockerfiles
"""

import os
from datetime import datetime
import jinja2
from jinja2 import Environment, FileSystemLoader
import yaml

TEMPLATES_DIRNAME = "templates"
OUTPUT_DIRNAME = "generated-dockerfiles"
DEFAULT_PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUTPUT_DIR = os.path.join(DEFAULT_PROJECT_DIR, OUTPUT_DIRNAME)
DEFAULT_TEMPLATES_DIR = os.path.join(DEFAULT_PROJECT_DIR, TEMPLATES_DIRNAME)


def load_settings():
    """Loads settings.yaml and sets default variables on necessary RAPIDS_LIBS entries"""
    with open("settings.yaml") as settings_file:
        settings = yaml.load(settings_file, Loader=yaml.FullLoader)
    # Set default RAPIDS_LIBS values
    for lib in settings["RAPIDS_LIBS"]:
        if "update_submodules" not in lib.keys():
            lib["update_submodules"] = True
    return settings


def initialize_output_dir(output_dir):
    """Creates the OUTPUT_DIR directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        return
    return


def main():
    """Generates Dockerfiles using Jinja2"""

    initialize_output_dir(OUTPUT_DIRNAME)

    settings = load_settings()
    file_loader = FileSystemLoader(TEMPLATES_DIRNAME)
    env = Environment(loader=file_loader, lstrip_blocks=True, trim_blocks=True)
    for docker_os in ["centos7", "centos8", "ubuntu18.04", "ubuntu20.04"]:
        for image_type in ["Base", "Devel", "Runtime"]:
            dockerfile_name = f"{docker_os}-{image_type.lower()}.Dockerfile"
            try:
                template = env.get_template(f"{image_type}.dockerfile.j2")
            except jinja2.exceptions.TemplateNotFound:
                print(f"Warning: template for image type {image_type} not "
                        "found, skipping for {docker_os}.")
                continue
            output = template.render(
                os=docker_os, image_type=image_type.lower(), now=datetime.utcnow(), **settings,
            )
            output_dockerfile_path = f"{OUTPUT_DIRNAME}/{dockerfile_name}"
            if not(os.path.exists(output_dockerfile_path)) \
                or (open(output_dockerfile_path).read() != output):

                with open(output_dockerfile_path, "w") as dockerfile:
                    dockerfile.write(output)
                    print(f"Updated: {output_dockerfile_path}")

    print(f"Dockerfiles successfully written to the '{OUTPUT_DIRNAME}' directory.")


if __name__ == "__main__":
    main()
