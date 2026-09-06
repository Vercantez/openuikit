@_spi(OpenUIKitHost) import ExtensionFoundation

func testAppExtensionPointInitLooksUpDefinition() {
    let defined = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-lookup-defined"),
        AppExtensionPoint.UserInterface(true)
    )
    do {
        let found = try AppExtensionPoint(identifier: "ef-lookup-defined")
        precondition(found == defined)
        precondition(found.host_userInterface == true)
    } catch {
        preconditionFailure("lookup of a defined point must succeed: \(error)")
    }
}

func testAppExtensionPointInitEmptyThrowsUnspecified() {
    do {
        _ = try AppExtensionPoint(identifier: "")
        preconditionFailure("empty identifier must throw")
    } catch let error as AppExtensionPoint.Error {
        switch error {
        case .unspecifiedAppExtensionPointName:
            break
        default:
            preconditionFailure("expected unspecifiedAppExtensionPointName")
        }
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAppExtensionPointInitUnknownThrowsInvalid() {
    do {
        _ = try AppExtensionPoint(identifier: "ef-lookup-missing-zzzz")
        preconditionFailure("unknown identifier must throw")
    } catch let error as AppExtensionPoint.Error {
        switch error {
        case .invalidAppExtensionPoint:
            break
        default:
            preconditionFailure("expected invalidAppExtensionPoint")
        }
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAppExtensionPointEqualityAndInequality() {
    let a = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-eq-a")
    )
    let b = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-eq-a")
    )
    let c = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-eq-c"),
        AppExtensionPoint.UserInterface(true)
    )
    precondition(a == b)
    precondition(!(a != b))
    precondition(a != c)
    precondition(a.id == "ef-eq-a")
    precondition(c.id == "ef-eq-c")
}

func testAppExtensionPointHashableAgreesWithEquality() {
    let a = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-hash-a")
    )
    let b = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-hash-a")
    )
    precondition(a.hashValue == b.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    let first = hasher.finalize()
    var hasher2 = Hasher()
    b.hash(into: &hasher2)
    precondition(first == hasher2.finalize())
}

func testAppExtensionPointIDTypealias() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-id-alias")
    )
    let identity: AppExtensionPoint.ID = point.id
    precondition(identity == "ef-id-alias")
    precondition(type(of: identity) == String.self)
}

func testAppExtensionPointConformsToExtensionPointDefining() {
    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-defining")
    )
    func takeDefining(_ value: any ExtensionPointDefining) -> String {
        String(describing: type(of: value))
    }
    precondition(takeDefining(point).contains("AppExtensionPoint"))
}

func testAppExtensionPointAttributeExistential() {
    let attributes: [any AppExtensionPoint.Attribute] = [
        AppExtensionPoint.UserInterface(true),
        AppExtensionPoint.EnhancedSecurity(false),
        AppExtensionPoint.Scope(restriction: .none),
    ]
    precondition(attributes.count == 3)
}
