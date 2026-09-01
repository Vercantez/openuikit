#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
BUILD=$(mktemp -d /private/tmp/nssortdescriptor-native-20260831.XXXXXX)

xcrun swiftc -parse-as-library -swift-version 6 -strict-concurrency=complete \
  -warnings-as-errors \
  "$ROOT/full/foundation/tests/FoundationNSSortDescriptorNativeOracle.swift" \
  -o "$BUILD/FoundationNSSortDescriptorNativeOracle"
"$BUILD/FoundationNSSortDescriptorNativeOracle" | tee "$BUILD/runtime.log"
grep -Fxq \
  'FOUNDATION_NSSORTDESCRIPTOR_APPLE_OK key=creationDate ascending=false reversed=true' \
  "$BUILD/runtime.log"

printf 'FOUNDATION_NSSORTDESCRIPTOR_NATIVE_GATE_OK key=retained direction=retained,reversed\n'
