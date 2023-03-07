#!/usr/bin/env python3
"""
Python script to generate DockerHub READMEs
"""

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import argparse

TEMPLATES_DIRNAME = "templates"
OUTPUT_DIRNAME = "generated-readmes"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PATH = os.path.join(BASE_DIR, OUTPUT_DIRNAME)
TEMPLATES_DIR = os.path.join(BASE_DIR, TEMPLATES_DIRNAME)
OUTPUT_READMES = [
    "rapidsai-core",
    "rapidsai-core-nightly",
    "rapidsai-core-dev",
    "rapidsai-core-dev-nightly",
    "rapidsai",
    "rapidsai-nightly",
    "rapidsai-dev",
    "rapidsai-dev-nightly",
    "ngc-rapidsai-core",
    "ngc-rapidsai-core-dev",
    "ngc-rapidsai",
    "ngc-rapidsai-dev",
]


def load_settings():
    """Loads settings.yaml and sets default variables on necessary RAPIDS_LIBS entries"""
    with open("settings.yaml") as settings_file:
        settings = yaml.load(settings_file, Loader=yaml.FullLoader)
    return settings


def initialize_output_dir(output_dir):
    """Creates the OUTPUT_DIR directory"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        return
    return


def main(nightly_version, stable_version, settings):
    """Generates DockerHub READMEs using Jinja2"""

    initialize_output_dir(OUTPUT_PATH)

    file_loader = FileSystemLoader(TEMPLATES_DIR)
    env = Environment(loader=file_loader, lstrip_blocks=True, trim_blocks=True)
    env.filters["nightly2stable"] = lambda x: x.replace("-nightly", "")
    env.filters["br2devel"] = (
        lambda x: x.replace("-nightly", "-dev-nightly")
        if "nightly" in x
        else f"{x}-dev"
    )
    env.filters["devel2br"] = lambda x: x.replace("-dev", "")
    template = env.get_template("base.md.j2")
    for output_file in OUTPUT_READMES:
        jinja_vars = {}
        jinja_vars["repo_name"] = output_file.replace('ngc-','')
        jinja_vars["is_nightly"] = "nightly" in output_file
        jinja_vars["is_stable"] = not jinja_vars["is_nightly"]
        jinja_vars["is_devel"] = "dev" in output_file
        jinja_vars["is_br"] = not jinja_vars["is_devel"]  # br = base_runtime
        jinja_vars["is_ngc"] = "ngc" in output_file
        jinja_vars["ngc_prefix"] = "nvcr.io/nvidia/"
        jinja_vars["is_rapids_core"] = "core" in output_file
        jinja_vars["is_rapids_proper"] = not (jinja_vars["is_rapids_core"])
        jinja_vars["stable_version"] = stable_version
        jinja_vars["nightly_version"] = nightly_version
        jinja_vars["dask_sql_version"] = dask_sql_version
        if jinja_vars["is_nightly"]:
            jinja_vars["repo_rapids_version"] = jinja_vars["nightly_version"]
        if jinja_vars["is_stable"]:
            jinja_vars["repo_rapids_version"] = jinja_vars["stable_version"]
        if jinja_vars["is_devel"]:
            jinja_vars["repo_default_img_type"] = "devel"
        if jinja_vars["is_br"]:
            jinja_vars["repo_default_img_type"] = "runtime"

        output = template.render(
            **jinja_vars,
            **settings,
        )

        output_path = f"{OUTPUT_PATH}/{output_file}.md"
        with open(output_path, "w") as readme:
            readme.write(output)

    print(f"READMEs successfully written to the '{OUTPUT_PATH}' directory.")


if __name__ == "__main__":
    settings = load_settings()
    nightly_version = settings["DEFAULT_NIGHTLY_RAPIDS_VERSION"]
    stable_version = settings["DEFAULT_STABLE_RAPIDS_VERSION"]
    dask_sql_version = settings["STABLE_DASK_SQL_VERSION"]
    parser = argparse.ArgumentParser(
        description="Arguments for generating DockerHub READMEs."
    )
    parser.add_argument(
        "-n",
        metavar="nightly_version",
        dest="nightly_version",
        help="RAPIDS nightly version (i.e. 21.06)",
        default=nightly_version,
    )
    parser.add_argument(
        "-s",
        metavar="stable_version",
        dest="stable_version",
        help="RAPIDS stable version (i.e. 0.19)",
        default=stable_version,
    )
    args = parser.parse_args()
    main(args.nightly_version, args.stable_version, settings)
