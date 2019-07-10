* "As a developer, I want to build my library using specific toolchains, a different OS, etc. than what my workstation has, and I want the resulting binaries in a specific location so I can access them again later."

# This example builds cuML for CentOS7.
# All commands will be issued from the location of the cuML repo that was cloned locally.
rratzel@sm01:~/Projects$ git clone https://github.com/rapidsai/cuml -b branch-0.8
rratzel@sm01:~/Projects$ cd cuml
rratzel@sm01:~/Projects/cuml$ git submodule update --init -- recursive

# Remove .git *files* from submodules since some have abs paths, because the container mounts will not have the same paths
rratzel@sm01:~/Projects/cuml$ find thirdparty -type f -name .git -exec rm {} \;

# Use a "devel" container for the OS/CUDA/Python/gcc versions you want
rratzel@sm01:~/Projects/cuml$ nvidia-docker pull rapidsai/rapidsai-nightly:0.8-cuda10.0-devel-centos7-gcc7-py3.7

# Create a place for the resulting binaries. Use a unique name to support binaries generated from different build containers on the same host.
rratzel@sm01:~/Projects/cuml$ mkdir build_cuda10.0-centos7-gcc7-py3.7

# Build the local sources using the tools and environment of the devel container and have the resulting binaries placed in build_cuda10.0-centos7-gcc7-py3
nvidia-docker run -ti --rm --cap-add=SYS_PTRACE -e NVIDIA_VISIBLE_DEVICES=1 -v `pwd`:/rapids/my_cuml -v `pwd`/build_cuda10.0-centos7-gcc7-py3.7:/rapids/my_cuml/cpp/build rapidsai/rapidsai-nightly:0.8-cuda10.0-devel-centos7-gcc7-py3.7 /rapids/my_cuml/build.sh -n libcuml cuml prims

# Build results for a CentOS7, CUDA 10.0, gcc7, Python 3.7 build will be in build_cuda10.0-centos7-gcc7-py3.7
# Build for other platforms using different images and save results side-by-side using the build dir naming convention

# Run the tests from the build above
nvidia-docker run -ti --rm --cap-add=SYS_PTRACE -e NVIDIA_VISIBLE_DEVICES=1 -v `pwd`:/rapids/my_cuml -v `pwd`/build_cuda10.0-centos7-gcc7-py3.7:/rapids/my_cuml/cpp/build rapidsai/rapidsai-nightly:0.8-cuda10.0-devel-centos7-gcc7-py3.7 /rapids/my_cuml/cpp/build/test/ml

# Modify sources locally, rebuild using the same containers. This will rebuild only what's necessary since cmake/make see the existing build artifacts, just like a local "bare metal" build.
<show example>

# Build a conda package using the local sources using the same container above
<show example, mount /conda/envs/rapids/conda-bld, conda install -y conda-build && cd /rapids/my_cuml && conda build ./conda/recipes/libcuml && conda build ./conda/recipes/cuml >

# Install the conda package built from the container
<show example, conda install -c conda-bld cuml>


* "As a SA, I need to make my builds against specific PRs, and using external conda, apt/yum, etc. with packages that work as expected with my notebooks/scripts."

* "As a SA, I want to generate docs for my local repo."
