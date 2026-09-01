#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
BUILD=$(mktemp -d /private/tmp/charts-host-gate-20260831.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT

declare -a SOURCES=(
  'Packages/Account/Sources/Account/Metrics/AccountMetricsComponents.swift:1d555e8e8c2e274ca24ece27ae0c68ed821d2bf274a1c15d5d7858cda63b678f'
  'Packages/Account/Sources/Account/Metrics/AccountMetricsView.swift:1b7d251e7a431932427800c4f4dcb6ad91cc990796ebb0e85b19541d286f4453'
  'Packages/Account/Sources/Account/Metrics/MetricsChartSelectionOverlay.swift:1cd24e4e914e52ef06b7b5a4afb5c25e085ac515f2f0ce96c658951bc1da2dd1'
  'Packages/DesignSystem/Sources/DesignSystem/Views/TagChartView.swift:31dfd8955414778a94dbdae0452a6f9852f2f60658ddcfee87a5e0d87d37fbcf'
  'Packages/Timeline/Sources/Timeline/View/TimelineListView.swift:82210c81f62339c03439e8c58a090faa412f35bb3d3966f3a96099675f6996c0'
  'Packages/Timeline/Sources/Timeline/View/TimelineView.swift:d03ad8892758aa30cdf16fda9a4fd489bbb6eed29d6e648953ad8bc440c27889'
)

[ -d "$APP/.git" ] || { echo "missing app checkout: $APP" >&2; exit 2; }
[ -z "$(git -C "$APP" status --short)" ] || {
  echo 'app checkout is not untouched' >&2
  exit 2
}
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
for entry in "${SOURCES[@]}"; do
  path=${entry%%:*}
  expected=${entry##*:}
  [ "$(shasum -a 256 "$APP/$path" | awk '{print $1}')" = "$expected" ]
done

grep -Fq 'Chart(sortedHistory)' \
  "$APP/Packages/DesignSystem/Sources/DesignSystem/Views/TagChartView.swift"
grep -Fq '.interpolationMethod(.catmullRom)' \
  "$APP/Packages/DesignSystem/Sources/DesignSystem/Views/TagChartView.swift"
grep -Fq '.chartXSelection(value: $selectedDate)' \
  "$APP/Packages/Account/Sources/Account/Metrics/AccountMetricsComponents.swift"
grep -Fq '.lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))' \
  "$APP/Packages/Account/Sources/Account/Metrics/AccountMetricsComponents.swift"
grep -Fq 'proxy.position(forX: selectedData.dayStart)' \
  "$APP/Packages/Account/Sources/Account/Metrics/MetricsChartSelectionOverlay.swift"

mkdir -p "$BUILD/modules" "$BUILD/lib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -emit-module -emit-library -module-name Charts \
  "$ROOT/full/charts/Charts.swift" \
  -emit-module-path "$BUILD/modules/Charts.swiftmodule" \
  -o "$BUILD/lib/libCharts.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -I "$BUILD/modules" -L "$BUILD/lib" -lCharts \
  "$ROOT/full/charts/tests/ChartsHostRuntime.swift" \
  -o "$BUILD/ChartsHostRuntime"
DYLD_LIBRARY_PATH="$BUILD/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$BUILD/ChartsHostRuntime" | tee "$BUILD/runtime.log"
grep -Fxq \
  'CHARTS_HOST_OK marks=bar,line,area,rule scalar=numeric,date interaction=fail-closed,host-driven stroke=retained rendering=basic' \
  "$BUILD/runtime.log"

xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -parse-as-library -I "$BUILD/modules" \
  "$ROOT/full/charts/tests/IceCubesChartsConsumer.swift"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -parse-as-library \
  "$ROOT/full/charts/tests/IceCubesChartsConsumer.swift"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -parse-as-library -target arm64-apple-ios18.0 -sdk "$SDK" \
  "$ROOT/full/charts/tests/IceCubesChartsConsumer.swift"

if otool -L "$BUILD/lib/libCharts.dylib" | grep -Fq Charts.framework; then
  echo 'portable libCharts unexpectedly loads Apple Charts.framework' >&2
  exit 1
fi

echo 'CHARTS_HOST_GATE_OK module=Charts semantics=basic-marks,scalar,host-driven,fail-closed,stroke-retention'
printf 'CHARTS_EXACT_CONSUMER_OK app=%s:%s sources=%s\n' \
  "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" "${#SOURCES[@]}"
