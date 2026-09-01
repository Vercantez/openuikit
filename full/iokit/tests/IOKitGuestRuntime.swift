import Foundation
import IOKit

@main
struct IOKitGuestRuntime {
    static func main() {
        precondition(IO_OBJECT_NULL == 0)
        precondition(kIORegistryIterateRecursively == 1)
        precondition(kIORegistryIterateParents == 2)
        precondition(IOBSDNameMatching(0, 0, "en0") == nil)

        var iterator: io_iterator_t = 99
        let status = IOServiceGetMatchingServices(0, nil, &iterator)
        precondition(UInt32(bitPattern: status) == 0xe00002c7)
        precondition(iterator == IO_OBJECT_NULL)
        precondition(IOIteratorNext(99) == IO_OBJECT_NULL)
        precondition(
            IORegistryEntryCreateCFProperty(99, "missing", nil, 0) == nil
        )
        precondition(
            IORegistryEntrySearchCFProperty(
                99,
                kIOServicePlane,
                "missing",
                nil,
                IOOptionBits(
                    kIORegistryIterateRecursively | kIORegistryIterateParents
                )
            ) == nil
        )
        precondition(UInt32(bitPattern: IOObjectRelease(99)) == 0xe00002c7)
        print("IOKIT_GUEST_OK matching=nil services=unsupported iterator=nil properties=nil")
    }
}
