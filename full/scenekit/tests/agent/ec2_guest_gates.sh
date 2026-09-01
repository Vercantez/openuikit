#!/usr/bin/env bash
# EC2 guest gates for SceneKit. Not invoked by tests/acceptance/test_host.sh.
# Isolated Linux success of that host gate is not integrated Linux success.
#
# Required before this script:
#   1. Build guest Foundation, CoreGraphics, QuartzCore, Metal, and the shared
#      staged simd module, plus libSceneKit.dylib that compiles SceneKitMath.c
#      with -I full/scenekit/include and installs include/SceneKit/SceneKit.h
#      plus include/module.modulemap so Swift can `import CSceneKit`.
#   2. Export LD_LIBRARY_PATH so libSceneKit.dylib and guest dylibs resolve.
# No local Docker. Run on a clean EC2 guest with the C/Clang toolchain.

set -euo pipefail

die() {
    printf 'SCENEKIT_AGENT_EC2_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)

INCLUDE_DIR=${SCENEKIT_INCLUDE_DIR:-"$FRAMEWORK_ROOT/include"}
LIB_DIR=${SCENEKIT_LIB_DIR:-}
SWIFT_MODULE_DIR=${SCENEKIT_SWIFTMODULE_DIR:-}

[ -n "$LIB_DIR" ] || die 'set SCENEKIT_LIB_DIR to the directory that contains libSceneKit.dylib'
[ -f "$LIB_DIR/libSceneKit.dylib" ] || die "libSceneKit.dylib is missing under $LIB_DIR"
[ -f "$INCLUDE_DIR/SceneKit/SceneKit.h" ] || die "canonical SceneKit.h is not installed at $INCLUDE_DIR/SceneKit/SceneKit.h"
[ -f "$INCLUDE_DIR/module.modulemap" ] || die "CSceneKit modulemap is not installed at $INCLUDE_DIR/module.modulemap"

command -v clang >/dev/null 2>&1 || die 'clang is unavailable'
command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'
command -v nm >/dev/null 2>&1 || die 'nm is unavailable'

export LD_LIBRARY_PATH="$LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/scenekit-ec2-gates.XXXXXX")
cleanup() { rm -rf -- "$TMP"; }
trap cleanup EXIT HUP INT TERM

# Symbol-inventory gate: TBD-exported C math helpers and globals must be unmangled.
for symbol in \
    SCNVector3EqualToVector3 \
    SCNVector4EqualToVector4 \
    SCNMatrix4EqualToMatrix4 \
    SCNMatrix4IsIdentity \
    SCNMatrix4Invert \
    SCNMatrix4MakeRotation \
    SCNMatrix4Mult \
    SCNMatrix4Rotate \
    SCNMatrix4Scale \
    SCNVector3Zero \
    SCNVector4Zero \
    SCNMatrix4Identity
do
    nm -D --defined-only "$LIB_DIR/libSceneKit.dylib" 2>/dev/null | grep -E "[[:space:]]${symbol}$" >/dev/null \
        || die "symbol inventory missing unmangled $symbol"
done
printf 'SCENEKIT_AGENT_SYMBOL_INVENTORY_OK\n'

# C-link gate: independent C client against the canonical header and dylib.
clang -Wall -Werror -I "$INCLUDE_DIR" \
    "$FRAMEWORK_ROOT/tests/agent/SceneKitCABI.c" \
    -L "$LIB_DIR" -lSceneKit -ldl \
    -o "$TMP/scenekit-cabi"
cabi_output=$(LD_LIBRARY_PATH="$LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$TMP/scenekit-cabi")
printf '%s\n' "$cabi_output" | grep -Fqx -- 'SCENEKIT_AGENT_CABI_OK' \
    || die 'C ABI probe did not emit SCENEKIT_AGENT_CABI_OK'
printf 'SCENEKIT_AGENT_CLINK_OK\n'

# CoreGraphics / QuartzCore / Metal / simd identity gate.
swift_flags=(-warnings-as-errors)
[ -n "$SWIFT_MODULE_DIR" ] && swift_flags+=(-I "$SWIFT_MODULE_DIR")
swift_flags+=(-I "$INCLUDE_DIR" -L "$LIB_DIR" -lSceneKit)
swiftc "${swift_flags[@]}" \
    "$FRAMEWORK_ROOT/tests/agent/SceneKitDependencyIdentity.swift" \
    -o "$TMP/scenekit-identity"
identity_output=$(LD_LIBRARY_PATH="$LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$TMP/scenekit-identity")
printf '%s\n' "$identity_output" | grep -Fqx -- 'SCENEKIT_AGENT_DEPENDENCY_IDENTITY_OK' \
    || die 'dependency identity probe did not emit SCENEKIT_AGENT_DEPENDENCY_IDENTITY_OK'
printf 'SCENEKIT_AGENT_COREGRAPHICS_QUARTZCORE_METAL_SIMD_OK\n'

printf 'SCENEKIT_AGENT_EC2_GATES_PREPARED_OK\n'
