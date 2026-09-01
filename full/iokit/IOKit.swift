import Foundation

@_alwaysEmitIntoClient
@discardableResult
public func IOObjectRelease(_ object: io_object_t) -> kern_return_t {
    _ = object
    return kIOReturnUnsupported
}

@_alwaysEmitIntoClient
public func IOIteratorNext(_ iterator: io_iterator_t) -> io_object_t {
    _ = iterator
    return IO_OBJECT_NULL
}

@_alwaysEmitIntoClient
public func IOServiceGetMatchingServices(
    _ mainPort: mach_port_t,
    _ matching: CFDictionary?,
    _ existing: UnsafeMutablePointer<io_iterator_t>?
) -> kern_return_t {
    _ = mainPort
    _ = matching
    existing?.pointee = IO_OBJECT_NULL
    return kIOReturnUnsupported
}

@_alwaysEmitIntoClient
public func IORegistryEntryCreateCFProperty(
    _ entry: io_registry_entry_t,
    _ key: CFString,
    _ allocator: CFAllocator?,
    _ options: IOOptionBits
) -> Unmanaged<AnyObject>? {
    _ = entry
    _ = key
    _ = allocator
    _ = options
    return nil
}

@_alwaysEmitIntoClient
public func IORegistryEntrySearchCFProperty(
    _ entry: io_registry_entry_t,
    _ plane: String,
    _ key: CFString,
    _ allocator: CFAllocator?,
    _ options: IOOptionBits
) -> AnyObject? {
    _ = entry
    _ = plane
    _ = key
    _ = allocator
    _ = options
    return nil
}

@_alwaysEmitIntoClient
public func IOBSDNameMatching(
    _ mainPort: mach_port_t,
    _ options: UInt32,
    _ bsdName: String
) -> CFMutableDictionary? {
    _ = mainPort
    _ = options
    _ = bsdName
    return nil
}

@inline(__always)
private func iokitReturn(_ code: UInt32) -> IOReturn {
    IOReturn(bitPattern: 0xe0000000 | code)
}

public var kIOReturnBusy: IOReturn { iokitReturn(0x2d5) }
public var kIOReturnError: IOReturn { iokitReturn(0x2bc) }
public var kIOReturnAborted: IOReturn { iokitReturn(0x2eb) }
public var kIOReturnIOError: IOReturn { iokitReturn(0x2ca) }
public var kIOReturnInvalid: IOReturn { iokitReturn(0x001) }
public var kIOReturnNoMedia: IOReturn { iokitReturn(0x2e4) }
public var kIOReturnNoPower: IOReturn { iokitReturn(0x2e3) }
public var kIOReturnNoSpace: IOReturn { iokitReturn(0x2db) }
public var kIOReturnNotOpen: IOReturn { iokitReturn(0x2cd) }
public var kIOReturnOffline: IOReturn { iokitReturn(0x2d7) }
public var kIOReturnOverrun: IOReturn { iokitReturn(0x2e8) }
public var kIOReturnTimeout: IOReturn { iokitReturn(0x2d6) }
public var kIOReturnVMError: IOReturn { iokitReturn(0x2c8) }
public var kIOReturnBadMedia: IOReturn { iokitReturn(0x2d1) }
public var kIOReturnDMAError: IOReturn { iokitReturn(0x2d4) }
public var kIOReturnIPCError: IOReturn { iokitReturn(0x2bf) }
public var kIOReturnNoDevice: IOReturn { iokitReturn(0x2c0) }
public var kIOReturnNoFrames: IOReturn { iokitReturn(0x2e0) }
public var kIOReturnNoMemory: IOReturn { iokitReturn(0x2bd) }
public var kIOReturnNotFound: IOReturn { iokitReturn(0x2f0) }
public var kIOReturnNotReady: IOReturn { iokitReturn(0x2d8) }
public var kIOReturnRLDError: IOReturn { iokitReturn(0x2d3) }
public var kIOReturnUnderrun: IOReturn { iokitReturn(0x2e7) }
public var kIOReturnIsoTooNew: IOReturn { iokitReturn(0x2ef) }
public var kIOReturnIsoTooOld: IOReturn { iokitReturn(0x2ee) }
public var kIOReturnStillOpen: IOReturn { iokitReturn(0x2d2) }
public var kIOReturnCannotLock: IOReturn { iokitReturn(0x2cc) }
public var kIOReturnCannotWire: IOReturn { iokitReturn(0x2de) }
public var kIOReturnLockedRead: IOReturn { iokitReturn(0x2c3) }
public var kIOReturnNoChannels: IOReturn { iokitReturn(0x2da) }
public var kIOReturnNotAligned: IOReturn { iokitReturn(0x2d0) }
public var kIOReturnPortExists: IOReturn { iokitReturn(0x2dd) }
public var kIOReturnBadArgument: IOReturn { iokitReturn(0x2c2) }
public var kIOReturnDeviceError: IOReturn { iokitReturn(0x2e9) }
public var kIOReturnLockedWrite: IOReturn { iokitReturn(0x2c4) }
public var kIOReturnNoBandwidth: IOReturn { iokitReturn(0x2ec) }
public var kIOReturnNoInterrupt: IOReturn { iokitReturn(0x2df) }
public var kIOReturnNoResources: IOReturn { iokitReturn(0x2be) }
public var kIOReturnNotAttached: IOReturn { iokitReturn(0x2d9) }
public var kIOReturnNotReadable: IOReturn { iokitReturn(0x2ce) }
public var kIOReturnNotWritable: IOReturn { iokitReturn(0x2cf) }
public var kIOReturnUnsupported: IOReturn { iokitReturn(0x2c7) }
public var kIOReturnBadMessageID: IOReturn { iokitReturn(0x2c6) }
public var kIOReturnNoCompletion: IOReturn { iokitReturn(0x2ea) }
public var kIOReturnNotPermitted: IOReturn { iokitReturn(0x2e2) }
public var kIOReturnInternalError: IOReturn { iokitReturn(0x2c9) }
public var kIOReturnNotPrivileged: IOReturn { iokitReturn(0x2c1) }
public var kIOReturnNotResponding: IOReturn { iokitReturn(0x2ed) }
public var kIOReturnExclusiveAccess: IOReturn { iokitReturn(0x2c5) }
public var kIOReturnMessageTooLarge: IOReturn { iokitReturn(0x2e1) }
public var kIOReturnUnsupportedMode: IOReturn { iokitReturn(0x2e6) }
public var kIOReturnUnformattedMedia: IOReturn { iokitReturn(0x2e5) }
