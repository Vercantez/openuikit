#!/usr/bin/env bash
# Supplement the immutable v1 gate by compiling the actual cited test files.
set -euo pipefail
FRAMEWORK_ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/vision-evidence.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM

python3 -B - "$FRAMEWORK_ROOT" "$TMP" <<'PYTHON'
import collections
import csv
from pathlib import Path
import re
import sys

root, out = map(Path, sys.argv[1:])
rows = list(csv.DictReader((root / "coverage.tsv").open(), delimiter="\t"))
implemented = [row for row in rows if row["status"] == "implemented"]
counts = collections.Counter(row["evidence"] for row in implemented)
assert implemented, "no implemented evidence"
assert max(counts.values()) <= len(implemented) * 0.4, "single-test evidence exceeds 40%"
tests = {}
for anchor in sorted(counts):
    match = re.fullmatch(r"test:full/vision/tests/agent/(\w+Tests\.swift)#(test\w+)", anchor)
    assert match, f"invalid evidence: {anchor}"
    filename, name = match.groups()
    text = (root / "tests/agent" / filename).read_text()
    assert len(re.findall(r"^func " + name + r"\(\)\s*\{", text, re.M)) == 1, anchor
    assert name not in tests, f"ambiguous test: {name}"
    tests[name] = filename
for path in (root / "tests/agent").glob("*Tests.swift"):
    assert not re.search(r"\b(?:DispatchSemaphore|Task|await)\b", path.read_text()), path
for row in rows:
    if row["status"] == "not-applicable":
        assert "::SYNTHESIZED::" in row["precise"] or "SwiftUI" in row["precise"], row["precise"]
runner = ["import Foundation", "@_spi(OpenUIKitHost) import Vision", "switch CommandLine.arguments[1] {"]
for name in sorted(tests):
    runner.append(f'case "{name}": {name}()')
runner += ['default: fatalError("unknown evidence test")', '}']
(out / "main.swift").write_text("\n".join(runner) + "\n")
(out / "names.txt").write_text("\n".join(sorted(tests)) + "\n")
print(f"VISION_EVIDENCE_LEDGER_OK implemented={len(implemented)} tests={len(tests)} largest={max(counts.values())}")
PYTHON

SOURCES=()
while IFS= read -r relative; do
    SOURCES+=("$REPO_ROOT/$relative")
done < "$FRAMEWORK_ROOT/vision_guest_sources.txt"
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Vision -emit-module-path "$TMP/Vision.swiftmodule" \
    -o "$TMP/libVision.dylib" "${SOURCES[@]}"
swiftc -warnings-as-errors -I "$TMP" \
    "$FRAMEWORK_ROOT"/tests/agent/*Tests.swift "$TMP/main.swift" \
    "$TMP/libVision.dylib" -o "$TMP/evidence-tests"
while IFS= read -r name; do
    # Each cited test starts in a fresh process and must finish synchronously.
    LD_LIBRARY_PATH="$TMP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        timeout 30 "$TMP/evidence-tests" "$name"
    printf 'VISION_EVIDENCE_TEST_OK %s\n' "$name"
done < "$TMP/names.txt"
printf 'VISION_EVIDENCE_OK\n'
