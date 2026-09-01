import Foundation

// MacDevice.swift normally receives this package-internal helper from
// Data+Extensions.swift. The boundary probe supplies only its declaration;
// the fail-closed IOKit path must never produce data and therefore never call it.
extension Data {
    var uuid: UUID? { nil }
}

@main
struct RevenueCatIOKitRuntimeSupport {
    static func main() {
        precondition(MacDevice.networkInterfaceMacAddressData == nil)
        precondition(MacDevice.identifierForVendor == nil)
        print(
            "REVENUECAT_IOKIT_UNTOUCHED_MACHO_OK "
                + "commit=57043e7 source=247a962 registry=unavailable"
        )
    }
}
