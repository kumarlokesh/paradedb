#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
versions=(15 16 17 18)

render() {
  local flavor="$1"
  local pg_version="$2"
  local output="${script_dir}/${flavor}/${pg_version}/Dockerfile"

  mkdir -p "$(dirname "$output")"
  awk \
    -v pg_version="$pg_version" \
  -v flavor="$flavor" '
      BEGIN { include = 1 }
      /^# %%ANTITHESIS_BEGIN%%$/ { include = flavor == "antithesis"; next }
      /^# %%BARMAN_BEGIN%%$/ { include = flavor != "official"; next }
      /^# %%STANDARD_BEGIN%%$/ { include = flavor != "antithesis"; next }
      /^# %%(ANTITHESIS|BARMAN|STANDARD)_END%%$/ { include = 1; next }
      !include { next }
      {
        gsub(/@@PG_VERSION_MAJOR@@/, pg_version)
        print
      }
    ' "${script_dir}/Dockerfile.template" > "$output"
}

for pg_version in "${versions[@]}"; do
  render paradedb "$pg_version"
  render antithesis "$pg_version"
  render official "$pg_version"
done
