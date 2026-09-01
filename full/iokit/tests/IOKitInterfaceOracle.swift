import Foundation
import IOKit

private func reflectedType<T>(of value: T) -> String {
    String(reflecting: T.self)
}

#if PORTABLE_IOKIT
private let portableBSDNameMatching:
    (mach_port_t, UInt32, String) -> CFMutableDictionary? = IOBSDNameMatching
private let portableServiceGetMatchingServices:
    (mach_port_t, CFDictionary?, UnsafeMutablePointer<io_iterator_t>?)
        -> kern_return_t = IOServiceGetMatchingServices
private let portableIteratorNext:
    (io_iterator_t) -> io_object_t = IOIteratorNext
private let portableObjectRelease:
    (io_object_t) -> kern_return_t = IOObjectRelease
private let portableCreateProperty:
    (io_registry_entry_t, CFString, CFAllocator?, IOOptionBits)
        -> Unmanaged<AnyObject>? = IORegistryEntryCreateCFProperty
private let portableSearchProperty:
    (io_registry_entry_t, String, CFString, CFAllocator?, IOOptionBits)
        -> AnyObject? = IORegistryEntrySearchCFProperty
#endif

private let returnValues: [(String, IOReturn)] = [
    ("aborted", kIOReturnAborted),
    ("bad-argument", kIOReturnBadArgument),
    ("bad-media", kIOReturnBadMedia),
    ("bad-message-id", kIOReturnBadMessageID),
    ("busy", kIOReturnBusy),
    ("cannot-lock", kIOReturnCannotLock),
    ("cannot-wire", kIOReturnCannotWire),
    ("device-error", kIOReturnDeviceError),
    ("dma-error", kIOReturnDMAError),
    ("error", kIOReturnError),
    ("exclusive-access", kIOReturnExclusiveAccess),
    ("internal-error", kIOReturnInternalError),
    ("invalid", kIOReturnInvalid),
    ("io-error", kIOReturnIOError),
    ("ipc-error", kIOReturnIPCError),
    ("iso-too-new", kIOReturnIsoTooNew),
    ("iso-too-old", kIOReturnIsoTooOld),
    ("locked-read", kIOReturnLockedRead),
    ("locked-write", kIOReturnLockedWrite),
    ("message-too-large", kIOReturnMessageTooLarge),
    ("no-bandwidth", kIOReturnNoBandwidth),
    ("no-channels", kIOReturnNoChannels),
    ("no-completion", kIOReturnNoCompletion),
    ("no-device", kIOReturnNoDevice),
    ("no-frames", kIOReturnNoFrames),
    ("no-interrupt", kIOReturnNoInterrupt),
    ("no-media", kIOReturnNoMedia),
    ("no-memory", kIOReturnNoMemory),
    ("no-power", kIOReturnNoPower),
    ("no-resources", kIOReturnNoResources),
    ("no-space", kIOReturnNoSpace),
    ("not-aligned", kIOReturnNotAligned),
    ("not-attached", kIOReturnNotAttached),
    ("not-found", kIOReturnNotFound),
    ("not-open", kIOReturnNotOpen),
    ("not-permitted", kIOReturnNotPermitted),
    ("not-privileged", kIOReturnNotPrivileged),
    ("not-readable", kIOReturnNotReadable),
    ("not-ready", kIOReturnNotReady),
    ("not-responding", kIOReturnNotResponding),
    ("not-writable", kIOReturnNotWritable),
    ("offline", kIOReturnOffline),
    ("overrun", kIOReturnOverrun),
    ("port-exists", kIOReturnPortExists),
    ("rld-error", kIOReturnRLDError),
    ("still-open", kIOReturnStillOpen),
    ("timeout", kIOReturnTimeout),
    ("underrun", kIOReturnUnderrun),
    ("unformatted-media", kIOReturnUnformattedMedia),
    ("unsupported", kIOReturnUnsupported),
    ("unsupported-mode", kIOReturnUnsupportedMode),
    ("vm-error", kIOReturnVMError),
]

@main
struct IOKitInterfaceOracle {
    static func main() {
        print("sdk=macOS26.1,xcode=17B55")
        print("types=mach-port:\(MemoryLayout<mach_port_t>.size),io-object:\(MemoryLayout<io_object_t>.size),io-option:\(MemoryLayout<IOOptionBits>.size),kern-return:\(MemoryLayout<kern_return_t>.size)")
        let unsupported = UInt32(bitPattern: kIOReturnUnsupported)
        print("constants=null:\(IO_OBJECT_NULL),recursive:\(kIORegistryIterateRecursively),parents:\(kIORegistryIterateParents),unsupported:\(unsupported)")
#if PORTABLE_IOKIT
        _ = portableBSDNameMatching
        _ = portableServiceGetMatchingServices
        _ = portableIteratorNext
        _ = portableObjectRelease
        _ = portableCreateProperty
        _ = portableSearchProperty
        print("signature-bsd=(mach_port_t,UInt32,String)->CFMutableDictionary?")
        print("signature-services=(mach_port_t,CFDictionary?,UnsafeMutablePointer<io_iterator_t>?)->kern_return_t")
        print("signature-next=(io_iterator_t)->io_object_t")
        print("signature-release=(io_object_t)->kern_return_t")
        print("signature-property=(io_registry_entry_t,CFString,CFAllocator?,IOOptionBits)->Unmanaged<AnyObject>?")
        print("signature-search=(io_registry_entry_t,String,CFString,CFAllocator?,IOOptionBits)->AnyObject?")
#else
        print("signature-bsd=\(reflectedType(of: IOBSDNameMatching))")
        print("signature-services=\(reflectedType(of: IOServiceGetMatchingServices))")
        print("signature-next=\(reflectedType(of: IOIteratorNext))")
        print("signature-release=\(reflectedType(of: IOObjectRelease))")
        print("signature-property=\(reflectedType(of: IORegistryEntryCreateCFProperty))")
        print("signature-search=\(reflectedType(of: IORegistryEntrySearchCFProperty))")
#endif
        print(
            "returns="
                + returnValues.map { name, value in
                    "\(name):\(UInt32(bitPattern: value))"
                }.joined(separator: ",")
        )

        let missingName = "__open_uikit_portable_iokit_missing_interface__"
        guard let matching = IOBSDNameMatching(0, 0, missingName) else {
            print("missing=matching:nil")
            return
        }
        var iterator = io_iterator_t()
        let status = IOServiceGetMatchingServices(0, matching, &iterator)
        let next = iterator == IO_OBJECT_NULL ? IO_OBJECT_NULL : IOIteratorNext(iterator)
        let releaseStatus = iterator == IO_OBJECT_NULL
            ? KERN_SUCCESS
            : IOObjectRelease(iterator)
        print("missing=matching:value,status:\(UInt32(bitPattern: status)),iterator:\(iterator == IO_OBJECT_NULL ? "null" : "value"),next:\(next == IO_OBJECT_NULL ? "null" : "value"),release:\(UInt32(bitPattern: releaseStatus))")
        if next != IO_OBJECT_NULL {
            _ = IOObjectRelease(next)
        }
    }
}
