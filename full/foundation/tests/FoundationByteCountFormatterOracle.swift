import Foundation

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

let values: [Int64] = [
    -1_500_000, -1_024, -1, 0, 1, 999, 1_000, 1_023, 1_024,
    1_500, 999_999, 1_000_000, 1_048_576, 1_500_000_000,
]
for style in [
    ByteCountFormatter.CountStyle.file,
    .memory,
    .decimal,
    .binary,
] {
    for value in values {
        emit(
            "static.\(style.rawValue).\(value)",
            ByteCountFormatter.string(fromByteCount: value, countStyle: style)
        )
    }
}

let formatter = ByteCountFormatter()
emit("default.allowed", formatter.allowedUnits.rawValue)
emit("default.style", formatter.countStyle.rawValue)
emit("default.nonnumeric", formatter.allowsNonnumericFormatting)
emit("default.actual", formatter.includesActualByteCount)
emit("default.count", formatter.includesCount)
emit("default.unit", formatter.includesUnit)
emit("default.adaptive", formatter.isAdaptive)
emit("default.zero-pad", formatter.zeroPadsFractionDigits)

formatter.countStyle = .binary
formatter.allowedUnits = [.useKB]
formatter.allowsNonnumericFormatting = false
for value in [Int64(-1_024), 0, 1, 1_024, 1_536, 1_048_576] {
    emit("forced-kb.\(value)", formatter.string(fromByteCount: value))
}

formatter.zeroPadsFractionDigits = true
formatter.isAdaptive = false
for value in [Int64(1_024), 1_536, 10_240, 102_400] {
    emit("fixed-kb.\(value)", formatter.string(fromByteCount: value))
}

formatter.allowedUnits = [.useMB]
formatter.includesActualByteCount = true
formatter.includesCount = true
formatter.includesUnit = true
emit("actual.full", formatter.string(fromByteCount: 1_048_576))
formatter.includesCount = false
emit("actual.no-count", formatter.string(fromByteCount: 1_048_576))
formatter.includesCount = true
formatter.includesUnit = false
emit("actual.no-unit", formatter.string(fromByteCount: 1_048_576))

let bytes = ByteCountFormatter()
bytes.allowedUnits = [.useBytes]
bytes.allowsNonnumericFormatting = true
for value in [Int64(-1), 0, 1, 2] {
    emit("bytes.words.\(value)", bytes.string(fromByteCount: value))
}
bytes.allowsNonnumericFormatting = false
for value in [Int64(-1), 0, 1, 2] {
    emit("bytes.numeric.\(value)", bytes.string(fromByteCount: value))
}

emit(
    "units.raw",
    [
        ByteCountFormatter.Units.useBytes.rawValue,
        ByteCountFormatter.Units.useKB.rawValue,
        ByteCountFormatter.Units.useMB.rawValue,
        ByteCountFormatter.Units.useGB.rawValue,
        ByteCountFormatter.Units.useTB.rawValue,
        ByteCountFormatter.Units.usePB.rawValue,
        ByteCountFormatter.Units.useEB.rawValue,
        ByteCountFormatter.Units.useZB.rawValue,
        ByteCountFormatter.Units.useYBOrHigher.rawValue,
        ByteCountFormatter.Units.useAll.rawValue,
        ByteCountFormatter.Units().rawValue,
    ]
)
