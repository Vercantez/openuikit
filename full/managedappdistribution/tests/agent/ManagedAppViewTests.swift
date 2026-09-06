import Foundation
@_spi(OpenUIKitHost) import ManagedAppDistribution

func testManagedAppViewStoresApp() {
    let app = ManagedApp(id: "com.example.view", name: "Viewed")
    let view = ManagedAppView(app: app)
    precondition(view.app.id == "com.example.view")
    precondition(view.app.name == "Viewed")
}

func testManagedAppViewBody() {
    let app = ManagedApp(id: "com.example.body", name: "BodyApp")
    let view = ManagedAppView(app: app)
    precondition(view.body.storage == "BodyApp")
}

func testManagedContentViewStoresLabels() {
    var tapped = false
    let view = ManagedContentView(
        primaryLabel: LocalizedStringKey("Primary"),
        secondaryLabel: LocalizedStringKey("Secondary"),
        tertiaryLabel: LocalizedStringKey("Tertiary"),
        quaternaryLabel: LocalizedStringKey("Quaternary"),
        offerState: .installed,
        offerAction: { tapped = true },
        icon: { Text("icon") }
    )
    precondition(view.primaryLabel == "Primary")
    precondition(view.secondaryLabel == "Secondary")
    precondition(view.tertiaryLabel == "Tertiary")
    precondition(view.quaternaryLabel == "Quaternary")
    precondition(view.offerState == .installed)
    view.offerAction?()
    precondition(tapped)
    precondition(view.body.storage == "icon")
}

func testManagedContentViewStringProtocolInit() {
    let view = ManagedContentView(
        primaryLabel: "Name",
        secondaryLabel: "Seller",
        offerState: .notInstalled,
        icon: { EmptyView() }
    )
    precondition(view.primaryLabel == "Name")
    precondition(view.secondaryLabel == "Seller")
    precondition(view.tertiaryLabel == "")
    precondition(view.quaternaryLabel == "")
    precondition(view.offerState == .notInstalled)
    precondition(view.offerAction == nil)
}

func testNavigationTitleIdentity() {
    let app = ManagedApp(id: "com.example.nav", name: "Nav")
    let view = ManagedAppView(app: app)
    let out = view.navigationTitle("Title")
    precondition(out.app.name == "Nav")
}

func testBadgeIdentity() {
    let app = ManagedApp(id: "com.example.badge", name: "Badge")
    let view = ManagedAppView(app: app)
    let out = view.badge("1")
    precondition(out.app.id == "com.example.badge")
}
