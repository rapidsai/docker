def compute_arch($x):
  $x + {ARCHES: ["amd64", "arm64"]};

def compute_ubuntu_version($x):
  if
    $x.CUDA_VER >= "11.7" # Ubuntu 22.04 nvidia/cuda images were added starting with CUDA 11.7
  then
    ["ubuntu", "22.04"]
  else
    ["ubuntu", "20.04"]
  end |
  $x + {LINUX_VER: (.[0]+.[1]), LINUX_DISTRO: .[0], LINUX_DISTRO_VER: .[1]};

def compute_cuda_tag($x):
  $x + {CUDA_TAG: $x.CUDA_VER | split(".") | [.[0], .[1]] | join(".") };

def latest_cuda_version($cuda_versions):
  $cuda_versions | max_by(. | split(".") | map(tonumber));

def compute_build_raft_ann_bench_cpu_image($x; $latest_cuda_version):
  $x + {BUILD_RAFT_ANN_BENCH_CPU_IMAGE: ($x.CUDA_VER == $latest_cuda_version)}; # we don't need to build CPU packages for different CUDA versions

# Checks the current entry to see if it matches the given exclude
def matches($entry; $exclude):
  all($exclude | to_entries | .[]; $entry[.key] == .value);

# Checks the current entry to see if it matches any of the excludes.
# If so, produce no output. Otherwise, output the entry.
def filter_excludes($entry; $excludes):
  select(any($excludes[]; matches($entry; .)) | not);

def lists2dict($keys; $values):
  reduce range($keys | length) as $ind ({}; . + {($keys[$ind]): $values[$ind]});

def compute_matrix($input):
  ($input.exclude // []) as $excludes |
  $input | del(.exclude) |
  keys_unsorted as $matrix_keys |
  to_entries |
  map(.value) |
  latest_cuda_version($input.CUDA_VER) as $latest_cuda_version |
  [
    combinations |
    lists2dict($matrix_keys; .) |
    compute_ubuntu_version(.) |
    compute_cuda_tag(.) |
    compute_build_raft_ann_bench_cpu_image(.; $latest_cuda_version) |
    filter_excludes(.; $excludes) |
    compute_arch(.)
  ] |
  {include: .};
