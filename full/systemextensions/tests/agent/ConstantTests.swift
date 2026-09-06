import Foundation
import SystemExtensions

func testNSSystemExtensionUsageDescriptionKey() {
    precondition(NSSystemExtensionUsageDescriptionKey == "NSSystemExtensionUsageDescription")
    precondition(type(of: NSSystemExtensionUsageDescriptionKey) == String.self)
    precondition(!NSSystemExtensionUsageDescriptionKey.isEmpty)
}

func testOSBundleUsageDescriptionKey() {
    precondition(OSBundleUsageDescriptionKey == "OSBundleUsageDescription")
    precondition(type(of: OSBundleUsageDescriptionKey) == String.self)
    precondition(OSBundleUsageDescriptionKey != NSSystemExtensionUsageDescriptionKey)
}

func testOSSystemExtensionErrorDomain() {
    precondition(OSSystemExtensionErrorDomain == "OSSystemExtensionErrorDomain")
    precondition(type(of: OSSystemExtensionErrorDomain) == String.self)
    precondition(OSSystemExtensionErrorDomain == OSSystemExtensionError.errorDomain)
}
