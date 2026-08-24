#!/bin/zsh
# Builds (if needed) and launches the OpenUIKit Playground.
set -e
cd "$(dirname "$0")/.."
if [ ! -x .build/release/openrender ] && [ ! -x .build/debug/openrender ]; then
  echo "building openrender…"; swift build -c release
fi
[ -x Tools/oracle/oracle ] || ./scripts/build_oracle.sh
if [ ! -x Tools/playground/playground ] || [ Tools/playground/main.swift -nt Tools/playground/playground ]; then
  echo "building playground…"
  swiftc -O Tools/playground/main.swift -o Tools/playground/playground
fi
exec Tools/playground/playground
