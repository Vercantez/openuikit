@_spi(OpenUIKitHost) import ExtensionFoundation

func testDefinitionBuildBlockNameOnly() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-name-only")
    )
    precondition(point.id == "ef-def-name-only")
    precondition(point.host_userInterface == false)
    precondition(point.host_enhancedSecurity == false)
    precondition(point.host_restriction == .application)
}

func testDefinitionBuildBlockUserInterfaceTrue() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-ui-true"),
        AppExtensionPoint.UserInterface(true)
    )
    precondition(point.host_userInterface == true)
    precondition(point.id == "ef-def-ui-true")
}

func testDefinitionBuildBlockUserInterfaceFalse() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-ui-false"),
        AppExtensionPoint.UserInterface(false)
    )
    precondition(point.host_userInterface == false)
}

func testDefinitionBuildBlockEnhancedSecurity() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-sec"),
        AppExtensionPoint.EnhancedSecurity(true)
    )
    precondition(point.host_enhancedSecurity == true)
}

func testDefinitionBuildBlockScopeNone() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-scope-none"),
        AppExtensionPoint.Scope(restriction: .none)
    )
    precondition(point.host_restriction == .none)
}

func testDefinitionBuildBlockAllAttributes() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-all"),
        AppExtensionPoint.UserInterface(true),
        AppExtensionPoint.EnhancedSecurity(false),
        AppExtensionPoint.Scope(restriction: .none)
    )
    precondition(point.id == "ef-def-all")
    precondition(point.host_userInterface == true)
    precondition(point.host_enhancedSecurity == false)
    precondition(point.host_restriction == .none)
}

func testDefinitionResultBuilderSyntax() {
    let point: AppExtensionPoint = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-def-builder-syntax"),
        AppExtensionPoint.UserInterface()
    )
    precondition(point.host_userInterface == true)
}

func testBindBuildBlockSystemIdentifier() {
    let point = AppExtensionPoint.Bind.buildBlock(
        AppExtensionPoint.Identifier("com.apple.widgetkit-extension")
    )
    precondition(point.id == "com.apple.widgetkit-extension")
    precondition(point.host_userInterface == false)
}

func testBindBuildBlockHostIdentifier() {
    let point = AppExtensionPoint.Bind.buildBlock(
        AppExtensionPoint.Identifier(host: "com.example.host", name: "canvas")
    )
    precondition(point.id == "com.example.host/canvas")
}
