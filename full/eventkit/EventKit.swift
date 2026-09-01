@_exported import Foundation
import CoreFoundation
import Dispatch

/// Linux starting point for Apple's public `EventKit` module.
///
/// The object model (events, reminders, calendars, alarms, recurrence, errors)
/// is real and in-memory. Calendar privacy, the Apple Calendar/Reminders
/// database, virtual-conference providers, and geofenced host delivery are
/// fail-closed. `ABAddressBook` / `ABRecord` are the staged CoreFoundation
/// `CFTypeRef` identity, not module-local stand-ins. See `README.md`.

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
        DispatchQueue.global(qos: .utility).async(execute: body)
    }
}
