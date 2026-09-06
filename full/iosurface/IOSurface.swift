import Foundation

/// Linux starting implementation of Apple's public `IOSurface` module.
///
/// Real: in-process surface allocation from width/height or alloc-size
/// properties, packed BGRA/RGBA/ARGB and biplanar 4:2:0 layouts, lock/unlock
/// seed, use-count, attachments, purgeability, in-process ID lookup, and
/// NSSecureCoding of pixel bytes.
///
/// Fail-closed: Mach-port share, `task_id_token` ownership identity, and
/// any hardware/GPU cache mode that would require an IOKit daemon.

public func IOSurfaceGetTypeID() -> CFTypeID {
    iosurfaceTypeID
}

public func IOSurfaceCreate(_ properties: CFDictionary) -> IOSurfaceRef? {
    IOSurface(cfProperties: properties)
}

public func IOSurfaceGetID(_ buffer: IOSurfaceRef) -> IOSurfaceID {
    buffer.surfaceID
}

public func IOSurfaceLookup(_ csid: IOSurfaceID) -> IOSurfaceRef? {
    IOSurfaceRegistry.lookup(csid)
}

public func IOSurfaceGetAllocSize(_ buffer: IOSurfaceRef) -> Int {
    buffer.allocationSize
}

public func IOSurfaceGetWidth(_ buffer: IOSurfaceRef) -> Int {
    buffer.width
}

public func IOSurfaceGetHeight(_ buffer: IOSurfaceRef) -> Int {
    buffer.height
}

public func IOSurfaceGetBytesPerRow(_ buffer: IOSurfaceRef) -> Int {
    buffer.bytesPerRow
}

public func IOSurfaceGetBytesPerElement(_ buffer: IOSurfaceRef) -> Int {
    buffer.bytesPerElement
}

public func IOSurfaceGetElementWidth(_ buffer: IOSurfaceRef) -> Int {
    buffer.elementWidth
}

public func IOSurfaceGetElementHeight(_ buffer: IOSurfaceRef) -> Int {
    buffer.elementHeight
}

public func IOSurfaceGetPixelFormat(_ buffer: IOSurfaceRef) -> OSType {
    buffer.pixelFormat
}

public func IOSurfaceGetBaseAddress(_ buffer: IOSurfaceRef) -> UnsafeMutableRawPointer {
    buffer.baseAddress
}

public func IOSurfaceGetPlaneCount(_ buffer: IOSurfaceRef) -> Int {
    buffer.planeCount
}

public func IOSurfaceGetWidthOfPlane(_ buffer: IOSurfaceRef, _ planeIndex: Int) -> Int {
    buffer.widthOfPlane(at: planeIndex)
}

public func IOSurfaceGetHeightOfPlane(_ buffer: IOSurfaceRef, _ planeIndex: Int) -> Int {
    buffer.heightOfPlane(at: planeIndex)
}

public func IOSurfaceGetBytesPerRowOfPlane(_ buffer: IOSurfaceRef, _ planeIndex: Int) -> Int {
    buffer.bytesPerRowOfPlane(at: planeIndex)
}

public func IOSurfaceGetBytesPerElementOfPlane(_ buffer: IOSurfaceRef, _ planeIndex: Int) -> Int {
    buffer.bytesPerElementOfPlane(at: planeIndex)
}

public func IOSurfaceGetElementWidthOfPlane(_ buffer: IOSurfaceRef, _ planeIndex: Int) -> Int {
    buffer.elementWidthOfPlane(at: planeIndex)
}

public func IOSurfaceGetElementHeightOfPlane(_ buffer: IOSurfaceRef, _ planeIndex: Int) -> Int {
    buffer.elementHeightOfPlane(at: planeIndex)
}

public func IOSurfaceGetBaseAddressOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int
) -> UnsafeMutableRawPointer {
    buffer.baseAddressOfPlane(at: planeIndex)
}

public func IOSurfaceGetNumberOfComponentsOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int
) -> Int {
    buffer.componentCount(planeIndex: planeIndex)
}

public func IOSurfaceGetNameOfComponentOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int,
    _ componentIndex: Int
) -> IOSurfaceComponentName {
    buffer.component(planeIndex, componentIndex)?.name ?? .unknown
}

public func IOSurfaceGetTypeOfComponentOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int,
    _ componentIndex: Int
) -> IOSurfaceComponentType {
    buffer.component(planeIndex, componentIndex)?.type ?? .unknown
}

public func IOSurfaceGetRangeOfComponentOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int,
    _ componentIndex: Int
) -> IOSurfaceComponentRange {
    buffer.component(planeIndex, componentIndex)?.range ?? .unknown
}

public func IOSurfaceGetBitDepthOfComponentOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int,
    _ componentIndex: Int
) -> Int {
    buffer.component(planeIndex, componentIndex)?.bitDepth ?? 0
}

public func IOSurfaceGetBitOffsetOfComponentOfPlane(
    _ buffer: IOSurfaceRef,
    _ planeIndex: Int,
    _ componentIndex: Int
) -> Int {
    buffer.component(planeIndex, componentIndex)?.bitOffset ?? 0
}

public func IOSurfaceGetSubsampling(_ buffer: IOSurfaceRef) -> IOSurfaceSubsampling {
    buffer.storage.subsampling
}

public func IOSurfaceGetSeed(_ buffer: IOSurfaceRef) -> UInt32 {
    buffer.seed
}

public func IOSurfaceLock(
    _ buffer: IOSurfaceRef,
    _ options: IOSurfaceLockOptions,
    _ seed: UnsafeMutablePointer<UInt32>?
) -> kern_return_t {
    buffer.lock(options: options, seed: seed)
}

public func IOSurfaceUnlock(
    _ buffer: IOSurfaceRef,
    _ options: IOSurfaceLockOptions,
    _ seed: UnsafeMutablePointer<UInt32>?
) -> kern_return_t {
    buffer.unlock(options: options, seed: seed)
}

public func IOSurfaceGetUseCount(_ buffer: IOSurfaceRef) -> Int32 {
    buffer.localUseCount
}

public func IOSurfaceIncrementUseCount(_ buffer: IOSurfaceRef) {
    buffer.incrementUseCount()
}

public func IOSurfaceDecrementUseCount(_ buffer: IOSurfaceRef) {
    buffer.decrementUseCount()
}

public func IOSurfaceIsInUse(_ buffer: IOSurfaceRef) -> Bool {
    buffer.isInUse
}

public func IOSurfaceAllowsPixelSizeCasting(_ buffer: IOSurfaceRef) -> Bool {
    buffer.allowsPixelSizeCasting
}

public func IOSurfaceSetValue(_ buffer: IOSurfaceRef, _ key: CFString, _ value: CFTypeRef) {
    buffer.setAttachment(iosurfaceSendable(value), forKey: key as String)
}

public func IOSurfaceCopyValue(_ buffer: IOSurfaceRef, _ key: CFString) -> CFTypeRef? {
    guard let value = buffer.attachment(forKey: key as String) else { return nil }
    return iosurfaceObject(value)
}

public func IOSurfaceRemoveValue(_ buffer: IOSurfaceRef, _ key: CFString) {
    buffer.removeAttachment(forKey: key as String)
}

public func IOSurfaceSetValues(_ buffer: IOSurfaceRef, _ keysAndValues: CFDictionary) {
    var copy: [String: any Sendable] = buffer.allAttachments() ?? [:]
    keysAndValues.enumerateKeysAndObjects { key, value, _ in
        copy[iosurfaceKeyString(key)] = iosurfaceSendable(value)
    }
    buffer.setAllAttachments(copy)
}

public func IOSurfaceCopyAllValues(_ buffer: IOSurfaceRef) -> CFDictionary? {
    guard let attachments = buffer.allAttachments() else { return nil }
    let copy = NSMutableDictionary()
    for (key, value) in attachments {
        copy[key as NSString] = iosurfaceObject(value)
    }
    return copy
}

public func IOSurfaceRemoveAllValues(_ buffer: IOSurfaceRef) {
    buffer.removeAllAttachments()
}

public func IOSurfaceSetPurgeable(
    _ buffer: IOSurfaceRef,
    _ newState: UInt32,
    _ oldState: UnsafeMutablePointer<UInt32>?
) -> kern_return_t {
    var previous = IOSurfacePurgeabilityState(rawValue: 0)
    let status = buffer.setPurgeable(
        IOSurfacePurgeabilityState(rawValue: newState),
        oldState: &previous
    )
    oldState?.pointee = previous.rawValue
    return status
}

public func IOSurfaceGetPropertyMaximum(_ property: CFString) -> Int {
    iosurfacePropertyMaximum(property as String)
}

public func IOSurfaceGetPropertyAlignment(_ property: CFString) -> Int {
    iosurfacePropertyAlignment(property as String)
}

public func IOSurfaceAlignProperty(_ property: CFString, _ value: Int) -> Int {
    iosurfaceAlignUp(value, iosurfacePropertyAlignment(property as String))
}

/// Mach ports do not exist on this Linux host. Always returns `MACH_PORT_NULL`.
public func IOSurfaceCreateMachPort(_ buffer: IOSurfaceRef) -> mach_port_t {
    _ = buffer
    return iosurfaceMachPortNull
}

/// Inverse of `IOSurfaceCreateMachPort`. Always `nil` on Linux.
public func IOSurfaceLookupFromMachPort(_ port: mach_port_t) -> IOSurfaceRef? {
    _ = port
    return nil
}

/// Kernel task-identity ledgers do not exist on Linux. Returns `KERN_FAILURE`.
public func IOSurfaceSetOwnershipIdentity(
    _ buffer: IOSurfaceRef,
    _ task_id_token: task_id_token_t,
    _ newLedgerTag: Int32,
    _ newLedgerOptions: UInt32
) -> kern_return_t {
    _ = buffer
    _ = task_id_token
    _ = newLedgerTag
    _ = newLedgerOptions
    return iosurfaceKERNFailure
}

func iosurfaceSendable(_ value: Any) -> any Sendable {
    if let string = value as? String {
        return string
    }
    if let string = value as? NSString {
        return string as String
    }
    if let number = value as? NSNumber {
        return number.intValue
    }
    if let number = value as? Int {
        return number
    }
    if let flag = value as? Bool {
        return flag
    }
    return String(describing: value)
}
