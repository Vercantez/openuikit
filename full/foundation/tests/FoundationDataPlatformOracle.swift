import Foundation
import os

private func escape(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\n", with: "\\n")
}

private func emit(_ key: String, _ value: String) {
    print("\(key)\t\(escape(value))")
}

let formatter = RelativeDateTimeFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
var calendar = Calendar(identifier: .gregorian)
calendar.locale = formatter.locale
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
formatter.calendar = calendar

for style in [
    RelativeDateTimeFormatter.UnitsStyle.full,
    .spellOut,
    .short,
    .abbreviated,
] {
    formatter.unitsStyle = style
    formatter.dateTimeStyle = .numeric
    for interval in [-31_556_952.0, -2_629_746, -604_800, -86_400, -3_600,
                     -61, -60, -59, -1, 0, 1, 59, 60, 61, 3_600, 86_400,
                     604_800, 2_629_746, 31_556_952] {
        emit("interval.\(style.rawValue).\(Int(interval))",
             formatter.localizedString(fromTimeInterval: interval))
    }
}

formatter.unitsStyle = .full
formatter.dateTimeStyle = .named
for value in -2...2 {
    var component = DateComponents()
    component.day = value
    emit("named.day.\(value)", formatter.localizedString(from: component))
}

var mixed = DateComponents()
mixed.year = 1
mixed.day = 2
mixed.second = 3
emit("components.mixed", formatter.localizedString(from: mixed))

let reference = Date(timeIntervalSince1970: 1_700_000_000)
formatter.dateTimeStyle = .numeric
for delta in [-90_000.0, -3_661, -61, 61, 3_661, 90_000] {
    emit("date.\(Int(delta))", formatter.localizedString(
        for: reference.addingTimeInterval(delta),
        relativeTo: reference
    ))
}

let stateLock = OSAllocatedUnfairLock<[Int]>(initialState: [])
let stateLockCopy = stateLock
stateLock.withLock { $0.append(1) }
stateLockCopy.withLock { $0.append(2) }
emit("lock.shared-state", stateLock.withLock { $0.map(String.init).joined(separator: ",") })
emit("lock.try", String(stateLock.withLockIfAvailable { $0.count } ?? -1))

let _: NSUbiquitousKeyValueStore.Type = NSUbiquitousKeyValueStore.self
let _: Notification.Name = NSUbiquitousKeyValueStore.didChangeExternallyNotification
emit("ubiquitous.default-identity", String(
    NSUbiquitousKeyValueStore.default === NSUbiquitousKeyValueStore.default
))

let fileManager = FileManager.default
let enumerationRoot = URL(
    fileURLWithPath: "/tmp/open-foundation-data-platform-oracle",
    isDirectory: true
)
try? fileManager.removeItem(at: enumerationRoot)
defer { try? fileManager.removeItem(at: enumerationRoot) }
try fileManager.createDirectory(
    at: enumerationRoot.appendingPathComponent("Nested", isDirectory: true),
    withIntermediateDirectories: true
)
try fileManager.createDirectory(
    at: enumerationRoot.appendingPathComponent("Example.bundle", isDirectory: true),
    withIntermediateDirectories: true
)
try Data([1, 2, 3]).write(
    to: enumerationRoot.appendingPathComponent("visible.bin")
)
try Data([4]).write(
    to: enumerationRoot.appendingPathComponent(".hidden")
)
try Data([5]).write(
    to: enumerationRoot.appendingPathComponent("Nested/inside")
)
try Data([6]).write(
    to: enumerationRoot.appendingPathComponent("Example.bundle/inside")
)
let fileKeys: Set<URLResourceKey> = [
    .isRegularFileKey,
    .fileAllocatedSizeKey,
    .totalFileAllocatedSizeKey,
]
let enumerated = fileManager.enumerator(
    at: enumerationRoot,
    includingPropertiesForKeys: Array(fileKeys),
    options: [.skipsHiddenFiles, .skipsPackageDescendants]
)!.compactMap { value -> String? in
    guard let url = value as? URL,
          let rootIndex = url.pathComponents.lastIndex(
            of: enumerationRoot.lastPathComponent
          ) else { return nil }
    return url.pathComponents.dropFirst(rootIndex + 1).joined(separator: "/")
}.sorted()
emit("filesystem.enumeration", enumerated.joined(separator: ","))
let visibleValues = try enumerationRoot.appendingPathComponent("visible.bin")
    .resourceValues(forKeys: fileKeys)
emit("filesystem.regular", String(visibleValues.isRegularFile == true))
emit("filesystem.allocated-present", String(
    (visibleValues.totalFileAllocatedSize ?? visibleValues.fileAllocatedSize ?? 0) >= 3
))
