def compute_arch($x):
  ["amd64"] |
  if
    $x.LINUX_VER != "ubuntu20.04" # Dask-sql arm64 requires glibc >=2.32
  then
    . + ["arm64"]
  else
    .
  end |
  $x + {ARCHES: .};

def compute_ubuntu_version($x):
  if
    $x.CUDA_VER >= "11.7" # Ubuntu 22.04 nvidia/cuda images were added starting with CUDA 11.7
  then
    "ubuntu22.04"
  else
    "ubuntu20.04"
  end |
  $x + {LINUX_VER: .};

def compute_cuda_tag($x):
  $x + {CUDA_TAG: $x.CUDA_VER | split(".") | [.[0], .[1]] | join(".") };

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
  [
    combinations |
    lists2dict($matrix_keys; .) |
    compute_ubuntu_version(.) |
    compute_cuda_tag(.) |
    filter_excludes(.; $excludes) |
    compute_arch(.)
  ] |
  {include: .};
