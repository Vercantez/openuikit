#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

bash -n "$HERE/build_and_run.sh"
bash -n "$HERE/container_build.sh"
perl -c "$HERE/policy_tool.pl"
perl "$HERE/policy_tool.pl" assets "$HERE/policy.json" "$HERE"
python3 -B -m unittest -v "$HERE/test_policy.py"
