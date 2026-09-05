#!/bin/zsh
# Native Mac differential: compile each oracle against Apple (must match the
# pinned golden) and against the portable implementation.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
TESTS=$ROOT/full/foundation/tests
SRC=$ROOT/full/foundation
WORK=$(mktemp -d /tmp/foundation-oracles-host.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

fail=0

run_family() {
    local name=$1
    local define=$2
    local module=$3
    local sources=$4
    local golden=$TESTS/foundation-$5-apple-2026-09-05.txt
    local oracle=$TESTS/Foundation${name}Oracle.swift
    local extra_src_defines=${6:-}

    echo "== $name"
    xcrun swiftc "$oracle" -o "$WORK/apple-$name"
    "$WORK/apple-$name" > "$WORK/apple-$name.txt"
    if ! cmp -s "$WORK/apple-$name.txt" "$golden"; then
        echo "APPLE GOLDEN DRIFT $name" >&2
        diff -u "$golden" "$WORK/apple-$name.txt" | head -40 >&2
        fail=1
        return
    fi

    mkdir -p "$WORK/$module"
    # shellcheck disable=SC2086
    xcrun swiftc -parse-as-library -wmo -D FOUNDATION_GUEST_SERVICES_HOST \
        $extra_src_defines \
        -module-name "$module" \
        -emit-module -emit-module-path "$WORK/$module/$module.swiftmodule" \
        -emit-object -o "$WORK/$module/$module.o" \
        $sources
    xcrun swiftc -D "$define" -I "$WORK/$module" \
        "$oracle" "$WORK/$module/$module.o" \
        -o "$WORK/port-$name"
    "$WORK/port-$name" > "$WORK/port-$name.txt"
    if ! cmp -s "$WORK/port-$name.txt" "$golden"; then
        echo "PORT MISMATCH $name" >&2
        diff -u "$golden" "$WORK/port-$name.txt" | head -80 >&2
        fail=1
        return
    fi
    echo "OK $name rows=$(wc -l < "$golden" | tr -d ' ')"
}

run_family DateFormatter DATEFORMATTER_PORT DateFormatterPort \
    "$SRC/DateFormatter.swift" date-formatter
run_family JSONSerialization JSONSERIALIZATION_PORT JSONSerializationPort \
    "$SRC/JSONSerialization.swift" json-serialization
run_family NSRegularExpression NSREGULAREXPRESSION_PORT NSRegularExpressionPort \
    "$SRC/NSRegularExpression.swift" nsregularexpression
run_family NumberFormatter NUMBERFORMATTER_PORT NumberFormatterPort \
    "$SRC/NumberFormatter.swift" number-formatter
run_family ISO8601DateFormatter ISO8601DATEFORMATTER_PORT ISO8601DateFormatterPort \
    "$SRC/ISO8601DateFormatter.swift" iso8601-date-formatter
run_family DateComponentsFormatter DATECOMPONENTSFORMATTER_PORT DateComponentsFormatterPort \
    "$SRC/DateComponentsFormatter.swift" date-components-formatter
run_family HTTPCookie HTTPCOOKIE_PORT HTTPCookiePort \
    "$SRC/URLSession.swift" httpcookie "-D HTTPCOOKIE_PORT"

if [ "$fail" -ne 0 ]; then
    echo "FOUNDATION_ORACLES_HOST failed" >&2
    exit 2
fi
echo "FOUNDATION_ORACLES_HOST_OK"
