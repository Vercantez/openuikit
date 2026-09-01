#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PROOF=$(mktemp -d /private/tmp/background-spotlight-host.XXXXXX)
cleanup() {
  /usr/bin/trash "$PROOF" 2>/dev/null || true
}
trap cleanup EXIT

swiftc -parse-as-library -emit-module \
  -emit-module-path "$PROOF/BackgroundTasks.swiftmodule" \
  -emit-library -module-name BackgroundTasks \
  "$ROOT/full/backgroundtasks/BackgroundTasks.swift" \
  -o "$PROOF/libBackgroundTasks.dylib"
swiftc -parse-as-library -emit-module \
  -emit-module-path "$PROOF/CoreSpotlight.swiftmodule" \
  -emit-library -module-name CoreSpotlight \
  "$ROOT/full/corespotlight/CoreSpotlight.swift" \
  -o "$PROOF/libCoreSpotlight.dylib"

# First prove that the call shapes are accepted by Apple's native modules,
# then by the project-owned replacements without changing the consumer source.
IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
swiftc -parse-as-library -typecheck -target arm64-apple-ios18.0 \
  -sdk "$IPHONEOS_SDK" \
  "$ROOT/full/corespotlight/tests/CorpusConsumerSurface.swift"
swiftc -parse-as-library -typecheck -I "$PROOF" \
  "$ROOT/full/corespotlight/tests/CorpusConsumerSurface.swift"

swiftc -parse-as-library -I "$PROOF" -L "$PROOF" -lBackgroundTasks \
  "$ROOT/full/backgroundtasks/tests/BackgroundTasksHostRuntime.swift" \
  -o "$PROOF/backgroundtasks-host"
swiftc -parse-as-library -I "$PROOF" -L "$PROOF" -lCoreSpotlight \
  "$ROOT/full/corespotlight/tests/CoreSpotlightHostRuntime.swift" \
  -o "$PROOF/corespotlight-host"

DYLD_LIBRARY_PATH="$PROOF${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$PROOF/backgroundtasks-host" | tee "$PROOF/backgroundtasks.log"
DYLD_LIBRARY_PATH="$PROOF${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$PROOF/corespotlight-host" | tee "$PROOF/corespotlight.log"

grep -Fxq \
  'BACKGROUNDTASKS_HOST_OK requests=refresh,processing scheduler=register,copy,pending,cancel queue=honored lifecycle=launch,expire,complete errors=darwin-shaped' \
  "$PROOF/backgroundtasks.log"
grep -Fxq \
  'CORESPOTLIGHT_HOST_OK index=named,isolated crud=sync,async,domain,all snapshots=owned query=terms expiry=filtered batch=client-state app-entities=index,delete' \
  "$PROOF/corespotlight.log"
printf '%s\n' 'BACKGROUND_SPOTLIGHT_HOST_GATE_OK oracle=apple-call-shape runtime=project-owned'
