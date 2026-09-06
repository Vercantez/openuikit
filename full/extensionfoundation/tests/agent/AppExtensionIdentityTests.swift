@_spi(OpenUIKitHost) import ExtensionFoundation

func testAppExtensionIdentityStoresFields() {
    let identity = AppExtensionIdentity(
        bundleIdentifier: "com.example.photoext",
        extensionPointIdentifier: "photo-editor",
        localizedName: "Photo Editor"
    )
    precondition(identity.bundleIdentifier == "com.example.photoext")
    precondition(identity.extensionPointIdentifier == "photo-editor")
    precondition(identity.localizedName == "Photo Editor")
}

func testAppExtensionIdentityIDComposition() {
    let identity = AppExtensionIdentity(
        bundleIdentifier: "com.example.photoext",
        extensionPointIdentifier: "photo-editor",
        localizedName: "Photo Editor"
    )
    precondition(identity.id == "com.example.photoext|photo-editor")
    let typed: AppExtensionIdentity.ID = identity.id
    precondition(type(of: typed) == String.self)
}

func testAppExtensionIdentityEquality() {
    let a = AppExtensionIdentity(
        bundleIdentifier: "com.example.a",
        extensionPointIdentifier: "point",
        localizedName: "A"
    )
    let b = AppExtensionIdentity(
        bundleIdentifier: "com.example.a",
        extensionPointIdentifier: "point",
        localizedName: "A"
    )
    let c = AppExtensionIdentity(
        bundleIdentifier: "com.example.b",
        extensionPointIdentifier: "point",
        localizedName: "A"
    )
    precondition(a == b)
    precondition(!(a != b))
    precondition(a != c)
}

func testAppExtensionIdentityHashable() {
    let a = AppExtensionIdentity(
        bundleIdentifier: "com.example.hash",
        extensionPointIdentifier: "point",
        localizedName: "Hash"
    )
    let b = AppExtensionIdentity(
        bundleIdentifier: "com.example.hash",
        extensionPointIdentifier: "point",
        localizedName: "Hash"
    )
    precondition(a.hashValue == b.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    var hasher2 = Hasher()
    b.hash(into: &hasher2)
    precondition(hasher.finalize() == hasher2.finalize())
}

func testAppExtensionIdentityLocalizedNameDistinctFromBundle() {
    let identity = AppExtensionIdentity(
        bundleIdentifier: "com.example.bundle",
        extensionPointIdentifier: "pt",
        localizedName: "Visible Name"
    )
    precondition(identity.localizedName != identity.bundleIdentifier)
}
