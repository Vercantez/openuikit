#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PLATFORM=${PLATFORM_PACKAGE:-/private/tmp/hackers-platform-next-integration-20260831/build/true-ios-platform}
ICECUBES=${ICECUBES_CHECKOUT:-/private/tmp/app-wave-20260831/IceCubesApp}
IMAGE=${FOUNDATIONMODELS_IMAGE:-swift-macho-spike:python3-nosde-preflight-20260830}
OUTPUT=${1:-}

die() {
    echo "build_foundationmodels_guest: $*" >&2
    exit 2
}

[ -d "$ROOT/.git" ] || [ -f "$ROOT/.git" ] || die 'project checkout is missing'
[ -f "$PLATFORM/PLATFORM_COMPLETE" ] || die 'true-iOS platform package is missing'
[ -d "$ICECUBES/.git" ] || die 'IceCubes checkout is missing'
[ -z "$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all -- \
    full/foundationmodels)" ] \
    || die 'FoundationModels source tranche must be committed and clean'

if [ -z "$OUTPUT" ]; then
    OUTPUT=$(mktemp -d /private/tmp/foundationmodels-arm64-proof.XXXXXX)
else
    case "$OUTPUT" in
        /private/tmp/foundationmodels-arm64-proof-[A-Za-z0-9._-]*|/private/tmp/foundationmodels-arm64-proof.[A-Za-z0-9._-]*) ;;
        *) die "output path is not narrowly named: $OUTPUT" ;;
    esac
    [ ! -e "$OUTPUT" ] || die 'explicit output path already exists'
    mkdir -p "$OUTPUT"
fi

SOURCE_COMMIT=$(git -C "$ROOT" rev-parse HEAD^{commit})
SOURCE_TREE=$(git -C "$ROOT" rev-parse HEAD^{tree})

docker run --rm \
    -e W=/w -e PLATFORM=/platform -e ICECUBES=/icecubes -e OUTPUT=/out \
    -e SOURCE_COMMIT="$SOURCE_COMMIT" -e SOURCE_TREE="$SOURCE_TREE" \
    -v "$ROOT:/w:ro" \
    -v "$PLATFORM:/platform:ro" \
    -v "$ICECUBES:/icecubes:ro" \
    -v "$OUTPUT:/out" \
    "$IMAGE" \
    bash /w/full/foundationmodels/tests/build_foundationmodels_guest_in_container.sh

printf 'FOUNDATIONMODELS_GUEST_OUTPUT=%s\n' "$OUTPUT"
