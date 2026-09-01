// EventKit dependency-identity client for a future clean EC2 run.
//
// Isolated `tests/acceptance/test_host.sh` does not build guest Foundation or
// CoreFoundation and must not be treated as integrated Linux success.
//
// Expected EC2 recipe (no local Docker):
//   1. Build the real guest Foundation and CoreFoundation modules/dylibs.
//   2. Build EventKit with those -I/-L paths:
//        swiftc -parse-as-library -emit-library -emit-module \
//          -module-name EventKit -I "$FOUNDATION_MOD" -I "$COREFOUNDATION_MOD" \
//          -L "$FOUNDATION_LIB" -L "$COREFOUNDATION_LIB" \
//          @eventkit_guest_sources.txt -o libEventKit.dylib
//   3. Link this client importing EventKit, Foundation, and CoreFoundation,
//      passing real dependency values through public APIs.
//   4. Run with LD_LIBRARY_PATH including libEventKit.dylib and confirm that
//      dylib is loaded (e.g. /proc/self/maps or dyld equivalent).
//   5. Confirm the exact marker EVENTKIT_DEPENDENCY_IDENTITY_OK.

@_spi(OpenUIKitHost) import EventKit
import CoreFoundation
import Foundation

enum EventKitDependencyIdentity {
    static func requireLoadedEventKitImage() {
        #if os(Linux)
        let maps = (try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8)) ?? ""
        precondition(
            maps.contains("libEventKit"),
            "libEventKit.dylib/so must be mapped; isolated host is not integrated proof"
        )
        #endif
    }

    static func main() async {
        requireLoadedEventKitImage()

        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        event.startDate = start
        event.endDate = start.addingTimeInterval(3600)
        event.timeZone = TimeZone(secondsFromGMT: 0)
        event.url = URL(string: "https://example.invalid/eventkit")
        event.title = UUID().uuidString

        let reminder = EKReminder(eventStore: store)
        reminder.dueDateComponents = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 9,
            day: 1
        )
        let predicate = store.predicateForEvents(
            withStart: start,
            end: start.addingTimeInterval(7200),
            calendars: nil
        )
        precondition(predicate.evaluate(with: event))

        let notificationName: Notification.Name = .EKEventStoreChanged
        precondition(notificationName.rawValue == "EKEventStoreChangedNotification")

        let cfValue: CFTypeRef = NSObject()
        let addressBook: ABAddressBook = cfValue
        let participant = EKParticipant()
        let record: ABRecord? = participant.abRecord(with: addressBook)
        precondition(record == nil)

        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let typedName = EKEventStore.EventStoreChanged.name
        precondition(typedName == Notification.Name.EKEventStoreChanged)
        let identifier: NotificationCenter.BaseMessageIdentifier<EKEventStore.EventStoreChanged> =
            .changed
        _ = identifier
        #endif

        print("EVENTKIT_DEPENDENCY_IDENTITY_OK")
    }
}

await EventKitDependencyIdentity.main()
