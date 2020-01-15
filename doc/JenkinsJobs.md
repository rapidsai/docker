# Jenkins Jobs

All Jenkins jobs for building and running tests with the RAPIDS Docker images are here:

https://gpuci.gpuopenanalytics.com/job/docker/

## Nightly base/runtime pipeline

* primary set of images used by users
* pipeline serializes base before runtime, then runs tests in parallel
* these images also have shortcuts on DH

## Nightly devel job

* individual job for devel
* completion triggers test jobs
* pushes to "dev" DH repo

## tests



## RAPIDS releases

* update build repo master branch
* manually run jobs specifying different (non-nightly) DH repo and build branch
* manually run ngc-push-all
* update README.md files in `doc` and post accordingly


## "vplus1" pipeline

* builds the next RAPIDS version of devel images
* used only during code freeze (if at all)