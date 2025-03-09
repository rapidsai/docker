#!/usr/bin/env python

import argparse
import os
import sys
import timeit
from typing import Iterable
import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
import yaml


ignored_subdirectory_names = [
    "data",
    "the_archive",
    "utils",
    "conference",
    ".ipynb_checkpoints",
    "cugraph_benchmarks",
    "tools",
    "demo",
]
ignored_filenames = ["-csv", "benchmark", "target", "performance"]
ignored_notebooks = []


def get_notebooks(directory: str) -> Iterable[str]:
    for root, _, files in os.walk(directory):
        for file in files:
            if (
                file.endswith(".ipynb")
                and not (
                    any(
                        match_ignored_subs in root
                        for match_ignored_subs in ignored_subdirectory_names
                    )
                )
                and not (
                    any(match_ignored_file in file for match_ignored_file in ignored_filenames)
                )
                and "MNMG" not in file.upper()
                and not any(file in ignored_notebook for ignored_notebook in ignored_notebooks)
            ):
                path = os.path.join(root.replace(directory, ''), file)
                if path.startswith('/'):
                    path = path[1::]
                yield path


def test_notebook(notebook_file, executed_nb_file):
    current_directory = os.path.realpath(os.path.curdir)
    try:
        with open(notebook_file) as f:
            nb = nbformat.read(f, as_version=4)

        notebook_dir = os.path.dirname(notebook_file)
        os.chdir(notebook_dir)

        errors = []
        warnings = []
        outputs = []


        # use nbconvert to run the notebook natively
        ep = ExecutePreprocessor(timeout=600, kernel_name="python3", allow_errors=True)
        task_init = timeit.default_timer()
        try:
            nb, _ = ep.preprocess(nb, {"metadata": {"path": ""}})
        except Exception as e:
            errors.append(e)
        execution_time = timeit.default_timer() - task_init

        with open(executed_nb_file, "w", encoding="utf-8") as f:
            nbformat.write(nb, f)

        # extract the output of the completed notebook
        ec = 0
        for cell in filter(lambda c: c["cell_type"] == "code", nb.cells):
            for output in cell["outputs"]:
                if "execution_count" in output.keys():
                    ec = output["execution_count"]
                if output["output_type"] == "stream":
                    outputs.append(str(ec) + "\n" + str(output["text"]))
                    if ("warn" in output["text"]) | ("[W]" in output["text"]):
                        warnings.append(str(ec) + "\n" + str(output["text"]))
                elif (
                    output["output_type"] == "execute_result"
                    or output["output_type"] == "display_data"
                ):
                    if "text/plain" in str(output["data"]):
                        outputs.append(str(ec) + "\n" + str(output["data"]["text/plain"]))
                        if (
                            "warn" in output["data"]["text/plain"]
                            or "[W]" in output["data"]["text/plain"]
                        ):
                            warnings.append(
                                str(ec) + "\n" + str(output["data"]["text/plain"])
                            )
                    elif "text/html" in str(output["data"]):
                        outputs.append(str(ec) + "\n" + str(output["data"]["text/html"]))
                        if (
                            "warn" in output["data"]["text/html"]
                            or "[W]" in output["data"]["text/html"]
                        ):
                            warnings.append(
                                str(ec) + "\n" + str(output["data"]["text/html"])
                            )
                    else:
                        outputs.append(str(ec) + "\n" + str(output["data"]))
                elif output["output_type"] == "error":
                    errors.append(
                        [
                            str(output["ename"]),
                            str(ec + 1) + "\n" + str(output["traceback"]),
                        ]
                    )
                    print(str(output["ename"]), str(output["traceback"]))
                else:
                    print(f'Unknown output type: {output["output_type"]}')

        return execution_time, outputs, warnings, errors
    except Exception as e:
        print(e)
        return -1, [], [], [e]
    finally:
        os.chdir(current_directory)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input", "-i", dest="input", default=os.path.expanduser("~/notebooks")
    )
    parser.add_argument(
        "--output",
        "-o",
        dest="output",
        default=os.path.expanduser("~/notebooks_output"),
    )

    ns = parser.parse_args()

    if not os.path.isdir(ns.input):
        print(f"Input must be a directory. Got: {ns.input}")
        sys.exit(1)

    notebooks = sorted(get_notebooks(ns.input))
    print(f"{len(notebooks)} Notebooks to be tested:")
    for notebook in notebooks:
        print(notebook)

    print()

    nb_errors = {}
    found_errors = False

    for notebook in notebooks:
        print(f"Testing {notebook}")
        notebook_file = os.path.join(ns.input, notebook)
        executed_nb_file = os.path.realpath(os.path.join(ns.output, notebook))

        executed_nb_dir = os.path.dirname(executed_nb_file)
        os.makedirs(executed_nb_dir, exist_ok=True)

        execution_time, outputs, warnings, errors = test_notebook(
            notebook_file, executed_nb_file
        )
        result = {
            "notebook": notebook,
            "filename": notebook_file,
            "executed_filename": executed_nb_file,
            "execution_time": execution_time,
            "outputs": outputs,
            "warnings": warnings,
            "errors": errors,
        }
        nb_errors[notebook]=errors
        found_errors = found_errors or len(errors)!=0
        with open(executed_nb_file + ".yaml", "w", encoding="utf-8") as f:
            yaml.dump(result, f)
        print(f'Completed {notebook} with {len(warnings)} warnings and {len(errors)} errors')
        print()

    if found_errors:
        print("Error during notebook tests!")
        for notebook in nb_errors.keys():
            if nb_errors[notebook]:
                print(f'Errors during {notebook}')
        sys.exit(2)
