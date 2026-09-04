// Exported-symbol accounting against `reference/tbd-exports.tsv`.
//
// Swift source compatibility (`reference/public-surface.tsv`, 511 identifiers)
// is not the same as Objective-C/binary ABI coverage. The TBD inventory also
// lists SPI/private Swift types (EKPersistent*, Autocompleter, ReadOnlyEventStore)
// that are outside the public overlay this module vends.

import EventKit
import Foundation

enum EventKitTBDAccounting {
    static let publicOverlayObjCClasses: Set<String> = [
        "EKAlarm",
        "EKCalendar",
        "EKCalendarItem",
        "EKEvent",
        "EKEventStore",
        "EKObject",
        "EKParticipant",
        "EKRecurrenceDayOfWeek",
        "EKRecurrenceEnd",
        "EKRecurrenceRule",
        "EKReminder",
        "EKSource",
        "EKStructuredLocation",
        "EKVirtualConferenceDescriptor",
        "EKVirtualConferenceProvider",
        "EKVirtualConferenceRoomTypeDescriptor",
        "EKVirtualConferenceURLDescriptor",
    ]

    static let publicCExports: Set<String> = [
        "EKErrorDomain",
        "EKEventStoreChangedNotification",
    ]

    static func inventoryURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // EventKitTBDAccounting.swift
            .deletingLastPathComponent() // agent
            .deletingLastPathComponent() // tests
            .appendingPathComponent("reference/tbd-exports.tsv")
    }

    static func main() throws {
        _ = EKAlarm.self
        _ = EKCalendar.self
        _ = EKCalendarItem.self
        _ = EKEvent.self
        _ = EKEventStore.self
        _ = EKObject.self
        _ = EKParticipant.self
        _ = EKRecurrenceDayOfWeek.self
        _ = EKRecurrenceEnd.self
        _ = EKRecurrenceRule.self
        _ = EKReminder.self
        _ = EKSource.self
        _ = EKStructuredLocation.self
        _ = EKVirtualConferenceDescriptor.self
        _ = EKVirtualConferenceProvider.self
        _ = EKVirtualConferenceRoomTypeDescriptor.self
        _ = EKVirtualConferenceURLDescriptor.self
        precondition(EKErrorDomain == "EKErrorDomain")
        precondition(
            Notification.Name.EKEventStoreChanged.rawValue == "EKEventStoreChangedNotification"
        )

        let text = try String(contentsOf: inventoryURL(), encoding: .utf8)
        var objcClasses: Set<String> = []
        var cExports: Set<String> = []
        var swiftMangled = 0
        var total = 0
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).dropFirst() {
            let symbol = String(line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
            if symbol.isEmpty || symbol.hasPrefix("/") {
                continue
            }
            total += 1
            if symbol.hasPrefix("_$s") {
                swiftMangled += 1
                continue
            }
            if symbol.hasPrefix("_OBJC_CLASS_$_") {
                objcClasses.insert(String(symbol.dropFirst("_OBJC_CLASS_$_".count)))
                continue
            }
            if symbol.hasPrefix("_EK") && !symbol.contains("$") {
                cExports.insert(String(symbol.dropFirst()))
            }
        }

        let overlayClassesInInventory = publicOverlayObjCClasses.intersection(objcClasses)
        let missingOverlayClasses = publicOverlayObjCClasses.subtracting(objcClasses)
        precondition(
            missingOverlayClasses.isEmpty,
            "public overlay ObjC classes missing from TBD: \(missingOverlayClasses)"
        )
        precondition(overlayClassesInInventory.count == publicOverlayObjCClasses.count)

        let missingC = publicCExports.subtracting(cExports)
        precondition(missingC.isEmpty, "public C exports missing from TBD: \(missingC)")

        let spiObjC = objcClasses.subtracting(publicOverlayObjCClasses)
        let spiC = cExports.subtracting(publicCExports)
        precondition(!spiObjC.isEmpty || !spiC.isEmpty || swiftMangled > 0)
        precondition(total > publicOverlayObjCClasses.count)

        print(
            "EVENTKIT_TBD_ACCOUNTING_OK overlay_objc=\(publicOverlayObjCClasses.count) c_exports=\(publicCExports.count) tbd_total=\(total) tbd_swift=\(swiftMangled) spi_objc=\(spiObjC.count) spi_c=\(spiC.count)"
        )
    }
}

do {
    try EventKitTBDAccounting.main()
} catch {
    fatalError("TBD accounting failed: \(error)")
}
