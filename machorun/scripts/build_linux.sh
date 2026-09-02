#!/bin/sh
# The entry point harness/run_linux.sh invokes inside the container.
# Everything real lives in scripts/build.sh.
set -eu
exec sh "$(cd "$(dirname "$0")" && pwd)/build.sh" all
