#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
WORK="$(mktemp -d /private/tmp/openui-swiftui-app-oracle.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

xcrun swiftc \
  -swift-version 6 \
  -parse-as-library \
  -typecheck \
  -target arm64-apple-ios26.0-simulator \
  -sdk "$SDK" \
  -module-cache-path "$WORK/module-cache" \
  "$ROOT/Tools/swiftuiapplifecycleoracle/main.swift"

echo "SWIFTUI_APP_LIFECYCLE_NATIVE_ORACLE_OK"
xcrun swiftc --version | sed -n '1p'
