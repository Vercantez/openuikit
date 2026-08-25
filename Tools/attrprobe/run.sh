#!/bin/zsh
# Build + run one attributed-text probe against REAL UIKit (Mac Catalyst).
#
#   ./Tools/attrprobe/run.sh measure       measurement semantics: kern, pair
#                                          kerning across runs/fonts, mixed-font
#                                          line heights, baselineOffset, paragraph
#                                          style heights, indents
#   ./Tools/attrprobe/run.sh geometry      pixel-level line boxes + underline /
#                                          strikethrough rects (difference imaging)
#   ./Tools/attrprobe/run.sh decorations   the underline/strike size sweep the
#                                          vendored text_decorations.json is fit to
#
# These are the sources of the measurements recorded in docs/SCENE_SPEC.md
# ("attributedText") and docs/KNOWN_GAPS.md ("Attributed text"). They print to
# stdout; nothing here is part of the build.
set -e
cd "$(dirname "$0")"
name="${1:?usage: run.sh measure|geometry|decorations}"
SDK=$(xcrun --show-sdk-path --sdk macosx)
out=$(mktemp -d)
swiftc -O -target arm64-apple-ios26.1-macabi -sdk "$SDK" \
  -Fsystem "$SDK/System/iOSSupport/System/Library/Frameworks" \
  -I "$SDK/System/iOSSupport/usr/lib/swift" \
  -L "$SDK/System/iOSSupport/usr/lib/swift" \
  "$name.swift" -o "$out/$name"
"$out/$name"
rm -rf "$out"
