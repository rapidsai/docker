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

# Checks the current entry to see if it matches the given exclude
def matches($entry; $exclude):
  all($exclude | to_entries | .[]; $entry[.key] == .value);

# Checks the current entry to see if it matches any of the excludes.
# If so, produce no output. Otherwise, output the entry.
def filter_excludes($entry; $excludes):
  select(any($excludes[]; matches($entry; .)) | not);

def lists2dict($keys; $values):
  reduce range($keys | length) as $ind ({}; . + {($keys[$ind]): $values[$ind]});

def compute_mx($input):
  ($input.exclude // []) as $excludes |
  $input | del(.exclude) |
  keys_unsorted as $mx_keys |
  to_entries |
  map(.value) |
  [
    combinations |
    lists2dict($mx_keys; .) |
    filter_excludes(.; $excludes) |
    compute_arch(.)
  ] |
  {include: .};