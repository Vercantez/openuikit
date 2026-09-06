@_spi(OpenUIKitHost) import ExtensionFoundation

func testAppExtensionPointNameStoresStaticString() {
    let name = AppExtensionPoint.Name("photo-editor")
    precondition(name.host_value == "photo-editor")
}

func testAppExtensionPointNameEmptyString() {
    let name = AppExtensionPoint.Name("")
    precondition(name.host_value.isEmpty)
}

func testAppExtensionPointIdentifierSystemName() {
    let identifier = AppExtensionPoint.Identifier("com.apple.widgetkit-extension")
    precondition(identifier.host_bundleIdentifier == nil)
    precondition(identifier.host_pointName == "com.apple.widgetkit-extension")
}

func testAppExtensionPointIdentifierHostAndName() {
    let identifier = AppExtensionPoint.Identifier(
        host: "com.example.host",
        name: "editor"
    )
    precondition(identifier.host_bundleIdentifier == "com.example.host")
    precondition(identifier.host_pointName == "editor")
}

func testUserInterfaceDefaultIsTrue() {
    let interface = AppExtensionPoint.UserInterface()
    precondition(interface.value == true)
}

func testUserInterfaceExplicitFalse() {
    let interface = AppExtensionPoint.UserInterface(false)
    precondition(interface.value == false)
}

func testEnhancedSecurityDefaultIsTrue() {
    let security = AppExtensionPoint.EnhancedSecurity()
    precondition(security.host_value == true)
}

func testEnhancedSecurityExplicitFalse() {
    let security = AppExtensionPoint.EnhancedSecurity(false)
    precondition(security.host_value == false)
}

func testScopeDefaultRestrictionIsApplication() {
    let scope = AppExtensionPoint.Scope()
    precondition(scope.host_restriction == .application)
}

func testScopeExplicitNoneRestriction() {
    let scope = AppExtensionPoint.Scope(restriction: .none)
    precondition(scope.host_restriction == .none)
}

func testScopeRestrictionEnumCases() {
    let application = AppExtensionPoint.Scope.Restriction.application
    let none = AppExtensionPoint.Scope.Restriction.none
    precondition(application == .application)
    precondition(none == .none)
    precondition(application != none)
    precondition(!(application != .application))
}

func testScopeRestrictionHashable() {
    var hasher = Hasher()
    AppExtensionPoint.Scope.Restriction.application.hash(into: &hasher)
    let first = hasher.finalize()
    var hasher2 = Hasher()
    AppExtensionPoint.Scope.Restriction.application.hash(into: &hasher2)
    precondition(first == hasher2.finalize())
    precondition(
        AppExtensionPoint.Scope.Restriction.application.hashValue
            == AppExtensionPoint.Scope.Restriction.application.hashValue
    )
}
