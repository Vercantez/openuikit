@_exported import Foundation
@preconcurrency import Dispatch

// Linux starting point for Apple's AccessorySetupKit. There is no accessory
// setup daemon, Bluetooth/Wi-Fi Aware picker UI, pairing entitlement, or
// UIKit product-image pipeline on this host. Value types, error codes,
// option-set algebra, discovery-descriptor matching, and the session state
// machine are implemented here. Picker presentation, authorization, rename,
// and hardware discovery always fail closed with documented `ASError` codes.

// MARK: - Undeclared foreign types
//
// UIKit and CoreBluetooth are not declared dependencies of this seed.
// Product images and BLE service UUIDs type-check as `NSObject` so the
// public selectors exist. They are never decoded as bitmaps or mixed with
// a live `CBUUID` database. See oracle-questions.tsv.

/// UIKit is not a declared dependency. Picker product images are stored as
/// `NSObject` identity only.
public typealias UIImage = NSObject

/// CoreBluetooth is not a declared dependency. Service UUID filters store an
/// opaque `NSObject` identity.
public typealias CBUUID = NSObject

/// Darwin `dispatch_queue_t` overlay used by `ASAccessorySession.activate`.
public typealias dispatch_queue_t = DispatchQueue

/// `NSError` domain for `ASError`. Identity matches the TBD export
/// `_ASErrorDomain` and the pinned dotnet-macios `[ErrorDomain ("ASErrorDomain")]`.
public let ASErrorDomain: String = "ASErrorDomain"

/// Bluetooth company identifier (`UInt16` newtype). `init(_:)` and
/// `init(rawValue:)` are equivalent.
public struct ASBluetoothCompanyIdentifier: RawRepresentable, Hashable, Sendable {
    public var rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }
}
