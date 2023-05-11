def compute_arch($x):
  ["amd64"] |
  if
    $x.CUDA_VER > "11.2.2" and
    $x.LINUX_VER != "centos7"
  then
    . + ["arm64"]
  else
    .
  end |
  $x + {ARCHES: .};

# Checks the current entry to see if it matches the given exclude
def matches($entry; $exclude):
  all($exclude | to_entries | .[]; $entry[.key] == .value);

# Checks the current entry to see if it matches any of the excludes.
# If so, produce no output. Otherwise, output the entry.
def filter_excludes($entry; $excludes):
  select(any($excludes[]; matches($entry; .)) | not);

def compute_mx($input):
  ($input.exclude // []) as $excludes |
  $input | del(.exclude) |
  to_entries |
  map(.value) |
  [
    combinations |
    {CUDA_VER: .[0], PYTHON_VER: .[1], LINUX_VER: .[2], RAPIDS_VER: .[3], DASK_SQL_VER: .[4]} |
    filter_excludes(.; $excludes) |
    compute_arch(.)
  ] |
  {include: .};