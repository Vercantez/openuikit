import Foundation
import ManagedAppDistribution

// Identity coverage for the synthesized SwiftUI View-modifier census.
// Linux has no SwiftUI layout engine; each modifier is a documented
// no-op returning `self`. Each test calls every overload of one
// modifier on both overlay views and checks the value passes through
// unchanged. All calls are synchronous; no queues, run loops, or semaphores are used.

func testListSectionSeparatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listSectionSeparator(nil, edges: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listSectionSeparator(nil, edges: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListSectionSeparatorTintIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listSectionSeparatorTint(nil, edges: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listSectionSeparatorTint(nil, edges: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListSectionSpacingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listSectionSpacing(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listSectionSpacing(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLuminanceToAlphaIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.luminanceToAlpha()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.luminanceToAlpha()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMaskIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.mask(alignment: nil, nil)
    let appOut1 = appView.mask(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.mask(alignment: nil, nil)
    let contentOut1 = contentView.mask(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testMatchedGeometryEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.matchedGeometryEffect(id: nil, in: nil, properties: nil, anchor: nil, isSource: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.matchedGeometryEffect(id: nil, in: nil, properties: nil, anchor: nil, isSource: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMatchedTransitionSourceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.matchedTransitionSource(id: nil, in: nil, configuration: nil)
    let appOut1 = appView.matchedTransitionSource(id: nil, in: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.matchedTransitionSource(id: nil, in: nil, configuration: nil)
    let contentOut1 = contentView.matchedTransitionSource(id: nil, in: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testMaterialActiveAppearanceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.materialActiveAppearance(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.materialActiveAppearance(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMenuActionDismissBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.menuActionDismissBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.menuActionDismissBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMenuIndicatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.menuIndicator(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.menuIndicator(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMenuOrderIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.menuOrder(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.menuOrder(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMenuStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.menuStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.menuStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMinimumScaleFactorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.minimumScaleFactor(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.minimumScaleFactor(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testModifierIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.modifier(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.modifier(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMonospacedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.monospaced(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.monospaced(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMonospacedDigitIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.monospacedDigit()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.monospacedDigit()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMoveDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.moveDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.moveDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testMultilineTextAlignmentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.multilineTextAlignment(strategy: nil)
    let appOut1 = appView.multilineTextAlignment(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.multilineTextAlignment(strategy: nil)
    let contentOut1 = contentView.multilineTextAlignment(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testNavigationBarBackButtonHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationBarBackButtonHidden(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationBarBackButtonHidden(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationBarHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationBarHidden(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationBarHidden(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationBarItemsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationBarItems(leading: nil, trailing: nil)
    let appOut1 = appView.navigationBarItems(leading: nil)
    let appOut2 = appView.navigationBarItems(trailing: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationBarItems(leading: nil, trailing: nil)
    let contentOut1 = contentView.navigationBarItems(leading: nil)
    let contentOut2 = contentView.navigationBarItems(trailing: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testNavigationBarTitleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationBarTitle(nil, displayMode: nil)
    let appOut1 = appView.navigationBarTitle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationBarTitle(nil, displayMode: nil)
    let contentOut1 = contentView.navigationBarTitle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testNavigationBarTitleDisplayModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationBarTitleDisplayMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationBarTitleDisplayMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationDestinationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationDestination(isPresented: nil, destination: nil)
    let appOut1 = appView.navigationDestination(for: nil, destination: nil)
    let appOut2 = appView.navigationDestination(item: nil, destination: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationDestination(isPresented: nil, destination: nil)
    let contentOut1 = contentView.navigationDestination(for: nil, destination: nil)
    let contentOut2 = contentView.navigationDestination(item: nil, destination: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testNavigationDocumentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationDocument(nil, preview: nil)
    let appOut1 = appView.navigationDocument(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationDocument(nil, preview: nil)
    let contentOut1 = contentView.navigationDocument(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testNavigationLinkIndicatorVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationLinkIndicatorVisibility(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationLinkIndicatorVisibility(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationSplitViewColumnWidthIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationSplitViewColumnWidth(min: nil, ideal: nil, max: nil)
    let appOut1 = appView.navigationSplitViewColumnWidth(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationSplitViewColumnWidth(min: nil, ideal: nil, max: nil)
    let contentOut1 = contentView.navigationSplitViewColumnWidth(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testNavigationSplitViewStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationSplitViewStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationSplitViewStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationSubtitleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationSubtitle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationSubtitle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationTransitionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationTransition(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationTransition(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testNavigationViewStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.navigationViewStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.navigationViewStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOffsetIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.offset(x: nil, y: nil)
    let appOut1 = appView.offset(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.offset(x: nil, y: nil)
    let contentOut1 = contentView.offset(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testOnAppearIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onAppear(perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onAppear(perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onChange(of: nil, initial: nil, nil)
    let appOut1 = appView.onChange(of: nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onChange(of: nil, initial: nil, nil)
    let contentOut1 = contentView.onChange(of: nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testOnContinueUserActivityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onContinueUserActivity(nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onContinueUserActivity(nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnContinuousHoverIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onContinuousHover(coordinateSpace: nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onContinuousHover(coordinateSpace: nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnDisappearIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onDisappear(perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onDisappear(perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnDragIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onDrag(nil, preview: nil)
    let appOut1 = appView.onDrag(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onDrag(nil, preview: nil)
    let contentOut1 = contentView.onDrag(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testOnDropIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onDrop(of: nil, isTargeted: nil, perform: nil)
    let appOut1 = appView.onDrop(of: nil, delegate: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onDrop(of: nil, isTargeted: nil, perform: nil)
    let contentOut1 = contentView.onDrop(of: nil, delegate: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testOnGeometryChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onGeometryChange(for: nil, of: nil, action: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onGeometryChange(for: nil, of: nil, action: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnHoverIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onHover(perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onHover(perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnInteractiveResizeChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onInteractiveResizeChange(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onInteractiveResizeChange(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnKeyPressIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onKeyPress(characters: nil, phases: nil, action: nil)
    let appOut1 = appView.onKeyPress(keys: nil, phases: nil, action: nil)
    let appOut2 = appView.onKeyPress(phases: nil, action: nil)
    let appOut3 = appView.onKeyPress(nil, action: nil)
    let appOut4 = appView.onKeyPress(nil, phases: nil, action: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    precondition(type(of: appOut4) == ManagedAppView.self)
    precondition(appOut4.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onKeyPress(characters: nil, phases: nil, action: nil)
    let contentOut1 = contentView.onKeyPress(keys: nil, phases: nil, action: nil)
    let contentOut2 = contentView.onKeyPress(phases: nil, action: nil)
    let contentOut3 = contentView.onKeyPress(nil, action: nil)
    let contentOut4 = contentView.onKeyPress(nil, phases: nil, action: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
    precondition(type(of: contentOut4) == ManagedContentView<Text>.self)
    precondition(contentOut4.body.storage == "ProbeIcon")
}

func testOnLongPressGestureIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, perform: nil, onPressingChanged: nil)
    let appOut1 = appView.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, pressing: nil, perform: nil)
    let appOut2 = appView.onLongPressGesture(minimumDuration: nil, perform: nil, onPressingChanged: nil)
    let appOut3 = appView.onLongPressGesture(minimumDuration: nil, pressing: nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, perform: nil, onPressingChanged: nil)
    let contentOut1 = contentView.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, pressing: nil, perform: nil)
    let contentOut2 = contentView.onLongPressGesture(minimumDuration: nil, perform: nil, onPressingChanged: nil)
    let contentOut3 = contentView.onLongPressGesture(minimumDuration: nil, pressing: nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testOnOpenURLIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onOpenURL(prefersInApp: nil)
    let appOut1 = appView.onOpenURL(perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onOpenURL(prefersInApp: nil)
    let contentOut1 = contentView.onOpenURL(perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testOnPencilDoubleTapIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onPencilDoubleTap(perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onPencilDoubleTap(perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnPencilSqueezeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onPencilSqueeze(perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onPencilSqueeze(perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnPreferenceChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onPreferenceChange(nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onPreferenceChange(nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnReceiveIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onReceive(nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onReceive(nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnScrollGeometryChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onScrollGeometryChange(for: nil, of: nil, action: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onScrollGeometryChange(for: nil, of: nil, action: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnScrollPhaseChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onScrollPhaseChange(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onScrollPhaseChange(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnScrollTargetVisibilityChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onScrollTargetVisibilityChange(idType: nil, threshold: nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onScrollTargetVisibilityChange(idType: nil, threshold: nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnScrollVisibilityChangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onScrollVisibilityChange(threshold: nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onScrollVisibilityChange(threshold: nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnSubmitIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onSubmit(of: nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onSubmit(of: nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOnTapGestureIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.onTapGesture(count: nil, coordinateSpace: nil, perform: nil)
    let appOut1 = appView.onTapGesture(count: nil, perform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.onTapGesture(count: nil, coordinateSpace: nil, perform: nil)
    let contentOut1 = contentView.onTapGesture(count: nil, perform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testOpacityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.opacity(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.opacity(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testOverlayIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.overlay(alignment: nil, content: nil)
    let appOut1 = appView.overlay(nil, ignoresSafeAreaEdges: nil)
    let appOut2 = appView.overlay(nil, in: nil, fillStyle: nil)
    let appOut3 = appView.overlay(nil, alignment: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.overlay(alignment: nil, content: nil)
    let contentOut1 = contentView.overlay(nil, ignoresSafeAreaEdges: nil)
    let contentOut2 = contentView.overlay(nil, in: nil, fillStyle: nil)
    let contentOut3 = contentView.overlay(nil, alignment: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testOverlayPreferenceValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.overlayPreferenceValue(nil, alignment: nil, nil)
    let appOut1 = appView.overlayPreferenceValue(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.overlayPreferenceValue(nil, alignment: nil, nil)
    let contentOut1 = contentView.overlayPreferenceValue(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPaddingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.padding(nil)
    let appOut1 = appView.padding(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.padding(nil)
    let contentOut1 = contentView.padding(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPaletteSelectionEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.paletteSelectionEffect(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.paletteSelectionEffect(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPersistentSystemOverlaysIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.persistentSystemOverlays(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.persistentSystemOverlays(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPhaseAnimatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.phaseAnimator(nil, content: nil, animation: nil)
    let appOut1 = appView.phaseAnimator(nil, trigger: nil, content: nil, animation: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.phaseAnimator(nil, content: nil, animation: nil)
    let contentOut1 = contentView.phaseAnimator(nil, trigger: nil, content: nil, animation: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPickerStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.pickerStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.pickerStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPopoverIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.popover(isPresented: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    let appOut1 = appView.popover(item: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.popover(isPresented: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    let contentOut1 = contentView.popover(item: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPositionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.position(x: nil, y: nil)
    let appOut1 = appView.position(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.position(x: nil, y: nil)
    let contentOut1 = contentView.position(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPreferenceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.preference(key: nil, value: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.preference(key: nil, value: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPreferredColorSchemeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.preferredColorScheme(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.preferredColorScheme(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPresentationBackgroundIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationBackground(alignment: nil, content: nil)
    let appOut1 = appView.presentationBackground(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationBackground(alignment: nil, content: nil)
    let contentOut1 = contentView.presentationBackground(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPresentationBackgroundInteractionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationBackgroundInteraction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationBackgroundInteraction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPresentationCompactAdaptationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationCompactAdaptation(horizontal: nil, vertical: nil)
    let appOut1 = appView.presentationCompactAdaptation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationCompactAdaptation(horizontal: nil, vertical: nil)
    let contentOut1 = contentView.presentationCompactAdaptation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPresentationContentInteractionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationContentInteraction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationContentInteraction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPresentationCornerRadiusIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationCornerRadius(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationCornerRadius(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPresentationDetentsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationDetents(nil, selection: nil)
    let appOut1 = appView.presentationDetents(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationDetents(nil, selection: nil)
    let contentOut1 = contentView.presentationDetents(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testPresentationDragIndicatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationDragIndicator(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationDragIndicator(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPresentationSizingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.presentationSizing(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.presentationSizing(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPreviewContextIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.previewContext(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.previewContext(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPreviewDeviceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.previewDevice(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.previewDevice(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPreviewDisplayNameIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.previewDisplayName(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.previewDisplayName(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPreviewInterfaceOrientationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.previewInterfaceOrientation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.previewInterfaceOrientation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPreviewLayoutIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.previewLayout(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.previewLayout(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testPrivacySensitiveIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.privacySensitive(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.privacySensitive(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testProgressViewStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.progressViewStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.progressViewStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testProjectionEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.projectionEffect(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.projectionEffect(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testRedactedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.redacted(reason: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.redacted(reason: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testRefreshableIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.refreshable(action: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.refreshable(action: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testRenameActionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.renameAction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.renameAction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testReplaceDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.replaceDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.replaceDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testRotation3DEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.rotation3DEffect(nil, axis: nil, anchor: nil, anchorZ: nil, perspective: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.rotation3DEffect(nil, axis: nil, anchor: nil, anchorZ: nil, perspective: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testRotationEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.rotationEffect(nil, anchor: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.rotationEffect(nil, anchor: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSafeAreaBarIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.safeAreaBar(edge: nil, alignment: nil, spacing: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.safeAreaBar(edge: nil, alignment: nil, spacing: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSafeAreaInsetIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.safeAreaInset(edge: nil, alignment: nil, spacing: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.safeAreaInset(edge: nil, alignment: nil, spacing: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testSafeAreaPaddingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.safeAreaPadding(nil)
    let appOut1 = appView.safeAreaPadding(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.safeAreaPadding(nil)
    let contentOut1 = contentView.safeAreaPadding(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testSaturationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.saturation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.saturation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScaleEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scaleEffect(x: nil, y: nil, anchor: nil)
    let appOut1 = appView.scaleEffect(nil, anchor: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scaleEffect(x: nil, y: nil, anchor: nil)
    let contentOut1 = contentView.scaleEffect(nil, anchor: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testScaledToFillIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scaledToFill()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scaledToFill()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScaledToFitIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scaledToFit()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scaledToFit()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScenePaddingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scenePadding(nil, edges: nil)
    let appOut1 = appView.scenePadding(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scenePadding(nil, edges: nil)
    let contentOut1 = contentView.scenePadding(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testScrollBounceBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollBounceBehavior(nil, axes: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollBounceBehavior(nil, axes: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testScrollClipDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.scrollClipDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.scrollClipDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}
