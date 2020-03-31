# Common problems building the image types

`base/runtime` images typically have one problem that prevents them from building: the `conda install` step fails, usually due to two reasons:

- communication between the build machine and the conda server stops or is corrupted.
- the conda dependency solver - used by conda to compute a dependency tree for any given package to determine the list of packages that need to be installed - fails to solve, usually due to an incompatible specification in either the list of packages given to the conda install line, or in the dependency meta-data built-in to a conda package (defined in the package's `meta.yaml`).

`devel` images can fail for the same reasons that `base/runtime` images do, as well as:

- Failure to build RAPIDS from source. Actual coding problems are rare since those are usually caught in the per-PR CI build checks, but build errors often occur in `devel` builds due to incompatible environments, resulting in the need to update the `rapids` environment. Because the gpuCI Docker images used for CI checks are not the same as `devel` images, `devel` builds often have to update based on word-of-mouth or from analyzing failures.
  - Determining what neds to be updated:
  - Ideas for addressing this problem:
