@_exported import Foundation
import CoreFoundation
import Dispatch

/// Linux EventKit overlay: in-memory object model plus an on-disk local
/// calendar/reminder store under Application Support `/OpenUIKit/EventKit`.
///
/// The store is not Calendar.app / TCC / CalDAV. Authorization starts
/// `.notDetermined` and `requestFullAccessToEvents` / `requestFullAccessToReminders`
/// / `requestAccess(to:)` grant this sandbox. See `README.md`.

/// AddressBook opaque refs in the public overlay. These are CoreFoundation
/// `CFTypeRef` values, not EventKit-local types.
public typealias ABAddressBook = CFTypeRef
public typealias ABRecord = CFTypeRef

public typealias EKEventSearchCallback = (EKEvent, UnsafeMutablePointer<ObjCBool>) -> Void
public typealias EKEventStoreRequestAccessCompletionHandler = (Bool, (any Error)?) -> Void
public typealias EKVirtualConferenceRoomTypeIdentifier = String

enum EKCallbackDelivery {
    /// Header contract: completions run on an arbitrary queue, never reentrantly
    /// on the caller. Isolated tests assert the token/call returns before the
    /// block runs rather than a specific queue identity.
    static func asynchronously(_ body: @escaping () -> Void) {
        let work = UncheckedWork(body: body)
        DispatchQueue.global(qos: .utility).async {
            work.run()
        }
    }

    /// EventKit completions are not `@Sendable` in the public overlay.
    private struct UncheckedWork: @unchecked Sendable {
        let body: () -> Void
        func run() { body() }
    }
}
