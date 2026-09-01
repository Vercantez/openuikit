#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)
ICECUBES=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
SIMPLENOTE=${2:-/private/tmp/app-wave-20260830/simplenote-ios}
FRONTIER=$ROOT/full/widgetkit/tests/icecubes-widgetkit-frontier.tsv
BUILD=$(mktemp -d /private/tmp/widgetkit-host-gate-20260901.XXXXXX)
cleanup() {
    [ ! -e "$BUILD" ] || /usr/bin/trash "$BUILD"
}
trap cleanup EXIT

EXPECTED_ICECUBES_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_ICECUBES_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
EXPECTED_SIMPLENOTE_COMMIT=9b1bb17d8ec224a709d306e0ec34cee38bc7d933
EXPECTED_SIMPLENOTE_TREE=ce311e62f98384abb7e73c0806b9d11001d5136a

for checkout in "$ICECUBES" "$SIMPLENOTE"; do
    [ -d "$checkout/.git" ] || {
        echo "missing untouched app checkout: $checkout" >&2
        exit 2
    }
    [ -z "$(git -C "$checkout" status --short)" ] || {
        echo "app checkout is not untouched: $checkout" >&2
        exit 2
    }
done
[ "$(git -C "$ICECUBES" rev-parse HEAD^{commit})" = \
    "$EXPECTED_ICECUBES_COMMIT" ]
[ "$(git -C "$ICECUBES" rev-parse HEAD^{tree})" = \
    "$EXPECTED_ICECUBES_TREE" ]
[ "$(git -C "$SIMPLENOTE" rev-parse HEAD^{commit})" = \
    "$EXPECTED_SIMPLENOTE_COMMIT" ]
[ "$(git -C "$SIMPLENOTE" rev-parse HEAD^{tree})" = \
    "$EXPECTED_SIMPLENOTE_TREE" ]

frontier_source_count=0
current_checkout=''
while IFS=$'\t' read -r record first second _; do
    case "$record" in
        format)
            [ "$first" = untouched-widgetkit-frontier-v1 ]
            ;;
        repository)
            case "$first" in
                IceCubesApp) current_checkout=$ICECUBES ;;
                simplenote-ios) current_checkout=$SIMPLENOTE ;;
                *) echo "unexpected frontier repository: $first" >&2; exit 2 ;;
            esac
            ;;
        source)
            [ -n "$current_checkout" ]
            source_file=$current_checkout/$first
            [ -f "$source_file" ] && [ ! -L "$source_file" ]
            actual=$(/usr/bin/shasum -a 256 "$source_file" \
                | /usr/bin/awk '{print $1}')
            [ "$actual" = "$second" ] || {
                echo "untouched WidgetKit source drifted: $first" >&2
                exit 2
            }
            frontier_source_count=$((frontier_source_count + 1))
            ;;
        '') ;;
        *) echo "unexpected frontier record: $record" >&2; exit 2 ;;
    esac
done < "$FRONTIER"
[ "$frontier_source_count" -eq 18 ]

grep -Fq 'struct AccountWidgetProvider: AppIntentTimelineProvider' \
    "$ICECUBES/IceCubesAppWidgetsExtension/AccountWidget/AccountWidget.swift"
grep -Fq 'AppIntentConfiguration(' \
    "$ICECUBES/IceCubesAppWidgetsExtension/AccountWidget/AccountWidget.swift"
grep -Fq '.containerBackground(Color("WidgetBackground").gradient, for: .widget)' \
    "$ICECUBES/IceCubesAppWidgetsExtension/AccountWidget/AccountWidget.swift"
grep -Fq 'struct IceCubesAppWidgetsExtensionBundle: WidgetBundle' \
    "$ICECUBES/IceCubesAppWidgetsExtension/IceCubesAppWidgetsExtensionBundle.swift"
grep -Fq 'WidgetCenter.shared.getCurrentConfigurations' \
    "$SIMPLENOTE/Simplenote/Controllers/WidgetController.swift"
grep -Fq 'WidgetCenter.shared.reloadAllTimelines()' \
    "$SIMPLENOTE/Simplenote/Controllers/WidgetController.swift"

mkdir -p "$BUILD/modules" "$BUILD/lib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -parse-as-library -emit-module -emit-library \
    -module-name AppIntents "$ROOT/full/appintents/AppIntents.swift" \
    -emit-module-path "$BUILD/modules/AppIntents.swiftmodule" \
    -o "$BUILD/lib/libAppIntents.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -parse-as-library -I "$BUILD/modules" \
    -L "$BUILD/lib" -lAppIntents -emit-module -emit-library \
    -module-name WidgetKit "$ROOT/full/widgetkit/WidgetKit.swift" \
    -emit-module-path "$BUILD/modules/WidgetKit.swiftmodule" \
    -o "$BUILD/lib/libWidgetKit.dylib"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -parse-as-library -I "$BUILD/modules" \
    -L "$BUILD/lib" -lWidgetKit -lAppIntents \
    "$ROOT/full/widgetkit/tests/WidgetKitHostRuntime.swift" \
    -o "$BUILD/WidgetKitHostRuntime"
DYLD_LIBRARY_PATH="$BUILD/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$BUILD/WidgetKitHostRuntime" | tee "$BUILD/runtime.log"
grep -Fxq \
    'WIDGETKIT_HOST_OK timeline=validated,scheduled providers=app-intent,sirikit reload=process-local,ordered configuration=retained presentation=host-driven' \
    "$BUILD/runtime.log"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library -I "$BUILD/modules" \
    "$ROOT/full/widgetkit/tests/IceCubesWidgetKitConsumer.swift"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library -I "$BUILD/modules" \
    "$ROOT/full/widgetkit/tests/SimplenoteWidgetKitConsumer.swift"

# Compile an exact untouched multi-widget @main bundle against the portable
# module.  Only the other target declarations are supplied by the harness.
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library -I "$BUILD/modules" \
    "$ROOT/full/widgetkit/tests/IceCubesWidgetBundleSupport.swift" \
    "$ICECUBES/IceCubesAppWidgetsExtension/IceCubesAppWidgetsExtensionBundle.swift"

# This is main-application source, not an extension: it proves WidgetInfo's
# Intents boundary and WidgetCenter's reload path without changing the app.
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library -I "$BUILD/modules" \
    "$ROOT/full/widgetkit/tests/SimplenoteWidgetControllerSupport.swift" \
    "$SIMPLENOTE/Simplenote/Controllers/WidgetController.swift"

# Compile the exact untouched legacy SiriKit provider, configuration, and
# three-widget @main bundle. Only generated-intent/app model dependencies are
# supplied by the harness.
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library -I "$BUILD/modules" \
    "$ROOT/full/widgetkit/tests/SimplenoteExactWidgetSupport.swift" \
    "$SIMPLENOTE/SimplenoteWidgets/Providers/NoteWidgetProvider.swift" \
    "$SIMPLENOTE/SimplenoteWidgets/Widgets/NoteWidget.swift" \
    "$SIMPLENOTE/SimplenoteWidgets/SimplenoteWidgets.swift"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library \
    -target arm64-apple-ios18.0 -sdk "$SDK" \
    "$ROOT/full/widgetkit/tests/IceCubesWidgetKitConsumer.swift"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -typecheck -parse-as-library \
    -target arm64-apple-ios18.0 -sdk "$SDK" \
    "$ROOT/full/widgetkit/tests/SimplenoteWidgetKitConsumer.swift"

if otool -L "$BUILD/lib/libWidgetKit.dylib" \
    | grep -Fq '/WidgetKit.framework/'; then
    echo 'portable libWidgetKit unexpectedly loads Apple WidgetKit.framework' >&2
    exit 1
fi

echo 'WIDGETKIT_HOST_GATE_OK module=WidgetKit semantics=timelines,reload,metadata,host-driven'
printf 'WIDGETKIT_UNTOUCHED_FRONTIER_OK icecubes=%s:%s simplenote=%s:%s sources=%s\n' \
    "$EXPECTED_ICECUBES_COMMIT" "$EXPECTED_ICECUBES_TREE" \
    "$EXPECTED_SIMPLENOTE_COMMIT" "$EXPECTED_SIMPLENOTE_TREE" \
    "$frontier_source_count"
