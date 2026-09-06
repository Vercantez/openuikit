import ExtensionFoundation

func testAppExtensionPointErrorCases() {
    let unspecified = AppExtensionPoint.Error.unspecifiedAppExtensionPointName
    let unsupportedTarget = AppExtensionPoint.Error.hostMustBeApplicationOrAppExtension
    let missingBundle = AppExtensionPoint.Error.hostMustHaveBundleIdentifier
    let outsideApp = AppExtensionPoint.Error.hostMustDefineAppExtensionPoint("photos")
    let invalid = AppExtensionPoint.Error.invalidAppExtensionPoint

    func same(_ lhs: AppExtensionPoint.Error, _ rhs: AppExtensionPoint.Error) -> Bool {
        switch (lhs, rhs) {
        case (.unspecifiedAppExtensionPointName, .unspecifiedAppExtensionPointName):
            return true
        case (.hostMustBeApplicationOrAppExtension, .hostMustBeApplicationOrAppExtension):
            return true
        case (.hostMustHaveBundleIdentifier, .hostMustHaveBundleIdentifier):
            return true
        case (.hostMustDefineAppExtensionPoint(let a), .hostMustDefineAppExtensionPoint(let b)):
            return a == b
        case (.invalidAppExtensionPoint, .invalidAppExtensionPoint):
            return true
        default:
            return false
        }
    }

    precondition(same(unspecified, .unspecifiedAppExtensionPointName))
    precondition(same(unsupportedTarget, .hostMustBeApplicationOrAppExtension))
    precondition(same(missingBundle, .hostMustHaveBundleIdentifier))
    precondition(same(outsideApp, .hostMustDefineAppExtensionPoint("photos")))
    precondition(!same(outsideApp, .hostMustDefineAppExtensionPoint("other")))
    precondition(same(invalid, .invalidAppExtensionPoint))
    precondition(!same(unspecified, invalid))
}

func testAppExtensionPointErrorLocalizedDescription() {
    let unspecified = AppExtensionPoint.Error.unspecifiedAppExtensionPointName
    let defined = AppExtensionPoint.Error.hostMustDefineAppExtensionPoint("editor")
    precondition(!unspecified.localizedDescription.isEmpty)
    precondition(defined.localizedDescription.contains("editor"))
    precondition(
        AppExtensionPoint.Error.invalidAppExtensionPoint.localizedDescription
            != unspecified.localizedDescription
    )
}

func testAppExtensionPointErrorHostMustHaveBundleIdentifierMessage() {
    let error = AppExtensionPoint.Error.hostMustHaveBundleIdentifier
    precondition(error.localizedDescription.lowercased().contains("bundle"))
}

func testAppExtensionPointErrorHostMustBeApplicationMessage() {
    let error = AppExtensionPoint.Error.hostMustBeApplicationOrAppExtension
    precondition(error.localizedDescription.lowercased().contains("application"))
}
