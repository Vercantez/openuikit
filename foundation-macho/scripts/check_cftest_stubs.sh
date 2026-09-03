#!/usr/bin/env bash
# Compare a derived libCFTest stub set to the committed arm64 expectation.
#
#   bash check_cftest_stubs.sh <stub-func-active> <stub-data> [expect-func] [expect-data]
#
# On match (stdout):
#   CFTEST_STUBS_OK func=<n> data=<m>
# On mismatch (stdout, exit 2):
#   CANNOT_CFTEST_STUBS extra=<comma-names> missing=<comma-names>
#
# extra= names in the derived set but not the pin (unexpected stubs — the
# 143-name x86 hole). missing= names the pin still expects. A libCFTest whose
# stub set differs is a CANNOT, not a build.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
EXPECT_FUNC=${3:-$FM/docs/cf-census/cftest-stub-func-active.txt}
EXPECT_DATA=${4:-$FM/docs/cf-census/cftest-stub-data.txt}

got_func=${1:-}
got_data=${2:-}
if [ -z "$got_func" ] || [ -z "$got_data" ]; then
    echo "usage: check_cftest_stubs.sh <stub-func-active> <stub-data> [expect-func] [expect-data]" >&2
    exit 2
fi
if [ ! -f "$EXPECT_FUNC" ] || [ ! -f "$EXPECT_DATA" ]; then
    echo "check_cftest_stubs: missing expectation $EXPECT_FUNC or $EXPECT_DATA" >&2
    exit 2
fi

tmp=$(mktemp -d /tmp/cftest-stubs.XXXXXX)
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

# Empty derived files are a real set (zero stubs), not a missing input.
: >>"$got_func"
: >>"$got_data"
sort -u "$got_func" | grep -v '^$' >"$tmp/got-func" || true
sort -u "$got_data" | grep -v '^$' >"$tmp/got-data" || true
sort -u "$EXPECT_FUNC" | grep -v '^$' >"$tmp/exp-func"
sort -u "$EXPECT_DATA" | grep -v '^$' >"$tmp/exp-data"

comm -13 "$tmp/exp-func" "$tmp/got-func" >"$tmp/extra-func" || true
comm -23 "$tmp/exp-func" "$tmp/got-func" >"$tmp/miss-func" || true
comm -13 "$tmp/exp-data" "$tmp/got-data" >"$tmp/extra-data" || true
comm -23 "$tmp/exp-data" "$tmp/got-data" >"$tmp/miss-data" || true

cat "$tmp/extra-func" "$tmp/extra-data" | grep -v '^$' | sort -u >"$tmp/extra" || true
cat "$tmp/miss-func" "$tmp/miss-data" | grep -v '^$' | sort -u >"$tmp/miss" || true

comma() {
    if [ ! -s "$1" ]; then
        printf ''
        return 0
    fi
    paste -sd, "$1"
}

extra=$(comma "$tmp/extra")
miss=$(comma "$tmp/miss")
if [ -s "$tmp/extra" ] || [ -s "$tmp/miss" ]; then
    printf 'CANNOT_CFTEST_STUBS extra=%s missing=%s\n' "$extra" "$miss"
    exit 2
fi

func_n=$(grep -c . "$tmp/got-func" || true)
data_n=$(grep -c . "$tmp/got-data" || true)
printf 'CFTEST_STUBS_OK func=%s data=%s\n' "$func_n" "$data_n"
exit 0
