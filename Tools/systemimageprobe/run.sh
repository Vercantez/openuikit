#!/bin/zsh
# Compile and run the bounded system-image oracle against real UIKit 26.1
# through Mac Catalyst. No OpenUIKit code or generated artifact is involved.
set -euo pipefail
cd "$(dirname "$0")"

sdk="$(xcrun --show-sdk-path --sdk macosx)"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

swiftc -O -target arm64-apple-ios26.1-macabi -sdk "$sdk" \
  -Fsystem "$sdk/System/iOSSupport/System/Library/Frameworks" \
  -I "$sdk/System/iOSSupport/usr/lib/swift" \
  -L "$sdk/System/iOSSupport/usr/lib/swift" \
  main.swift -o "$temporary/systemimageprobe"
"$temporary/systemimageprobe" > "$temporary/actual.txt"
diff -u expected.txt "$temporary/actual.txt"
cat "$temporary/actual.txt"
