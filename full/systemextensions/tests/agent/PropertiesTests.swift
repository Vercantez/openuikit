import Foundation
@_spi(OpenUIKitHost) import SystemExtensions

func testOSSystemExtensionPropertiesType() {
    let empty = OSSystemExtensionProperties()
    precondition(type(of: empty) == OSSystemExtensionProperties.self)
    let object: NSObject = empty
    precondition(object === empty)
    let other = OSSystemExtensionProperties()
    precondition(empty != other)
}

func testOSSystemExtensionPropertiesBundleIdentifier() {
    let empty = OSSystemExtensionProperties()
    precondition(empty.bundleIdentifier == "")
    let populated = SystemExtensionsHostControl.makeProperties(
        bundleIdentifier: "com.example.network-filter",
        bundleVersion: "10",
        bundleShortVersion: "1.0.0",
        isEnabled: false
    )
    precondition(populated.bundleIdentifier == "com.example.network-filter")
    let spaced = SystemExtensionsHostControl.makeProperties(
        bundleIdentifier: "  ",
        bundleVersion: "1",
        bundleShortVersion: "1.0",
        isEnabled: false
    )
    precondition(spaced.bundleIdentifier == "  ")
}

func testOSSystemExtensionPropertiesBundleVersion() {
    let empty = OSSystemExtensionProperties()
    precondition(empty.bundleVersion == "")
    let populated = SystemExtensionsHostControl.makeProperties(
        bundleIdentifier: "com.example.ext",
        bundleVersion: "42",
        bundleShortVersion: "2.1",
        isEnabled: false
    )
    precondition(populated.bundleVersion == "42")
    precondition(populated.bundleVersion != populated.bundleShortVersion)
}

func testOSSystemExtensionPropertiesBundleShortVersion() {
    let empty = OSSystemExtensionProperties()
    precondition(empty.bundleShortVersion == "")
    let populated = SystemExtensionsHostControl.makeProperties(
        bundleIdentifier: "com.example.ext",
        bundleVersion: "100",
        bundleShortVersion: "3.2.1",
        isEnabled: false
    )
    precondition(populated.bundleShortVersion == "3.2.1")
}

func testOSSystemExtensionPropertiesIsEnabled() {
    let empty = OSSystemExtensionProperties()
    precondition(empty.isEnabled == false)
    let disabled = SystemExtensionsHostControl.makeProperties(
        bundleIdentifier: "com.example.ext",
        bundleVersion: "1",
        bundleShortVersion: "1.0",
        isEnabled: false
    )
    precondition(disabled.isEnabled == false)
    let enabledFixture = SystemExtensionsHostControl.makeProperties(
        bundleIdentifier: "com.example.ext",
        bundleVersion: "1",
        bundleShortVersion: "1.0",
        isEnabled: true
    )
    precondition(enabledFixture.isEnabled == true)
}
