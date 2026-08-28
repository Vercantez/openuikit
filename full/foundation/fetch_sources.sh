#!/bin/bash
# fetch_sources.sh -- the two upstream checkouts this port builds from, at the
# revisions the Swift 6.2.2 release ACTUALLY RESOLVES.  Both land in scratch/,
# which is gitignored.
#
# THE PIN IS NOT A GUESS AND IT IS NOT THE PACKAGE.SWIFT RANGE.
# `swift-foundation` release/6.2.2 declares only `.package(url: swift-collections,
# from: "1.1.0")` and ships no Package.resolved, so a range-satisfying clone is
# not the same thing as the version the release was built with.  The authority
# is the Swift toolchain's own checkout config:
#
#   utils/update_checkout/update-checkout-config.json @ swift-6.2.2-RELEASE
#   branch-schemes["release/6.2.2"].repos:
#       swift-foundation     release/6.2.2
#       swift-collections    1.1.3        <-- not 1.2.x
#
# The first build of this port used swift-collections **1.2.1**, which
# satisfies `from: "1.1.0"` and is still the wrong tree -- the same class of
# error as porting from `main` instead of `release/6.2.2`, one dependency down,
# and equally invisible: it compiles.  Re-pinned to 1.1.3 and re-measured; the
# scoreboard was unchanged, which is what makes the habit cheap rather than what
# justifies it.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SC=$ROOT/scratch

fetch() {   # fetch <dir> <url> <ref>
    local dir=$1 url=$2 ref=$3
    if [ -d "$SC/$dir/.git" ] && [ "$(cd "$SC/$dir" && git rev-parse --verify -q HEAD)" ] \
       && (cd "$SC/$dir" && git describe --all --exact-match 2>/dev/null | grep -q "$ref$"); then
        echo "== $dir already at $ref"
    else
        rm -rf "$SC/$dir"
        git clone --depth 1 --branch "$ref" "$url" "$SC/$dir" 2>&1 | tail -1
    fi
    echo "   $dir  $(cd "$SC/$dir" && git rev-parse HEAD)  ($ref)"
}

fetch swift-foundation  https://github.com/swiftlang/swift-foundation.git  release/6.2.2
fetch swift-collections https://github.com/apple/swift-collections.git     1.1.3

# The range in the manifest must still admit the pin -- if upstream ever raises
# it, the pin is stale and this says so rather than building the wrong thing.
range=$(grep -A2 'url: "https://github.com/apple/swift-collections"' \
        "$SC/swift-foundation/Package.swift" | grep -oE 'from: "[0-9.]+"' | head -1)
echo "== swift-foundation declares swift-collections $range; pinned to 1.1.3 by update-checkout-config"
