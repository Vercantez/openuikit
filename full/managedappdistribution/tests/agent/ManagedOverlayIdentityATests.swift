import Foundation
import ManagedAppDistribution

// Identity coverage for the synthesized SwiftUI View-modifier census.
// Linux has no SwiftUI layout engine; each modifier is a documented
// no-op returning `self`. Each test calls every overload of one
// modifier on both overlay views and checks the value passes through
// unchanged. All calls are synchronous; no queues, run loops, or semaphores are used.

func testAccentColorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accentColor(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accentColor(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibility(identifier: nil)
    let appOut1 = appView.accessibility(inputLabels: nil)
    let appOut2 = appView.accessibility(removeTraits: nil)
    let appOut3 = appView.accessibility(sortPriority: nil)
    let appOut4 = appView.accessibility(activationPoint: nil)
    let appOut5 = appView.accessibility(selectionIdentifier: nil)
    let appOut6 = appView.accessibility(hint: nil)
    let appOut7 = appView.accessibility(label: nil)
    let appOut8 = appView.accessibility(value: nil)
    let appOut9 = appView.accessibility(hidden: nil)
    let appOut10 = appView.accessibility(addTraits: nil)
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
    precondition(type(of: appOut5) == ManagedAppView.self)
    precondition(appOut5.body.storage == "OverlayProbe")
    precondition(type(of: appOut6) == ManagedAppView.self)
    precondition(appOut6.body.storage == "OverlayProbe")
    precondition(type(of: appOut7) == ManagedAppView.self)
    precondition(appOut7.body.storage == "OverlayProbe")
    precondition(type(of: appOut8) == ManagedAppView.self)
    precondition(appOut8.body.storage == "OverlayProbe")
    precondition(type(of: appOut9) == ManagedAppView.self)
    precondition(appOut9.body.storage == "OverlayProbe")
    precondition(type(of: appOut10) == ManagedAppView.self)
    precondition(appOut10.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibility(identifier: nil)
    let contentOut1 = contentView.accessibility(inputLabels: nil)
    let contentOut2 = contentView.accessibility(removeTraits: nil)
    let contentOut3 = contentView.accessibility(sortPriority: nil)
    let contentOut4 = contentView.accessibility(activationPoint: nil)
    let contentOut5 = contentView.accessibility(selectionIdentifier: nil)
    let contentOut6 = contentView.accessibility(hint: nil)
    let contentOut7 = contentView.accessibility(label: nil)
    let contentOut8 = contentView.accessibility(value: nil)
    let contentOut9 = contentView.accessibility(hidden: nil)
    let contentOut10 = contentView.accessibility(addTraits: nil)
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
    precondition(type(of: contentOut5) == ManagedContentView<Text>.self)
    precondition(contentOut5.body.storage == "ProbeIcon")
    precondition(type(of: contentOut6) == ManagedContentView<Text>.self)
    precondition(contentOut6.body.storage == "ProbeIcon")
    precondition(type(of: contentOut7) == ManagedContentView<Text>.self)
    precondition(contentOut7.body.storage == "ProbeIcon")
    precondition(type(of: contentOut8) == ManagedContentView<Text>.self)
    precondition(contentOut8.body.storage == "ProbeIcon")
    precondition(type(of: contentOut9) == ManagedContentView<Text>.self)
    precondition(contentOut9.body.storage == "ProbeIcon")
    precondition(type(of: contentOut10) == ManagedContentView<Text>.self)
    precondition(contentOut10.body.storage == "ProbeIcon")
}

func testAccessibilityActionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityAction(named: nil, nil)
    let appOut1 = appView.accessibilityAction(action: nil, label: nil)
    let appOut2 = appView.accessibilityAction(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityAction(named: nil, nil)
    let contentOut1 = contentView.accessibilityAction(action: nil, label: nil)
    let contentOut2 = contentView.accessibilityAction(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testAccessibilityActionsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityActions(category: nil, nil)
    let appOut1 = appView.accessibilityActions(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityActions(category: nil, nil)
    let contentOut1 = contentView.accessibilityActions(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityActivationPointIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityActivationPoint(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityActivationPoint(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityActivationPoint(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityActivationPoint(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityAddTraitsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityAddTraits(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityAddTraits(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityAdjustableActionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityAdjustableAction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityAdjustableAction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityChartDescriptorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityChartDescriptor(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityChartDescriptor(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityChildrenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityChildren(children: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityChildren(children: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityCustomContentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityCustomContent(nil, nil, importance: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityCustomContent(nil, nil, importance: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityDefaultFocusIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityDefaultFocus(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityDefaultFocus(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityDirectTouchIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityDirectTouch(nil, options: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityDirectTouch(nil, options: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityDragPointIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityDragPoint(nil, description: nil, isEnabled: nil)
    let appOut1 = appView.accessibilityDragPoint(nil, description: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityDragPoint(nil, description: nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityDragPoint(nil, description: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityDropPointIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityDropPoint(nil, description: nil, isEnabled: nil)
    let appOut1 = appView.accessibilityDropPoint(nil, description: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityDropPoint(nil, description: nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityDropPoint(nil, description: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityElementIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityElement(children: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityElement(children: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityFocusedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityFocused(nil, equals: nil)
    let appOut1 = appView.accessibilityFocused(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityFocused(nil, equals: nil)
    let contentOut1 = contentView.accessibilityFocused(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityHeadingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityHeading(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityHeading(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityHidden(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityHidden(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityHidden(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityHidden(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityHintIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityHint(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityHint(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityHint(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityHint(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityIdentifierIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityIdentifier(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityIdentifier(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityIdentifier(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityIdentifier(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityIgnoresInvertColorsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityIgnoresInvertColors(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityIgnoresInvertColors(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityInputLabelsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityInputLabels(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityInputLabels(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityInputLabels(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityInputLabels(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityLabelIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityLabel(content: nil)
    let appOut1 = appView.accessibilityLabel(nil, isEnabled: nil)
    let appOut2 = appView.accessibilityLabel(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityLabel(content: nil)
    let contentOut1 = contentView.accessibilityLabel(nil, isEnabled: nil)
    let contentOut2 = contentView.accessibilityLabel(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testAccessibilityLabeledPairIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityLabeledPair(role: nil, id: nil, in: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityLabeledPair(role: nil, id: nil, in: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityLinkedGroupIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityLinkedGroup(id: nil, in: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityLinkedGroup(id: nil, in: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityRemoveTraitsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityRemoveTraits(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityRemoveTraits(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityRepresentationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityRepresentation(representation: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityRepresentation(representation: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityRespondsToUserInteractionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityRespondsToUserInteraction(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityRespondsToUserInteraction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityRespondsToUserInteraction(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityRespondsToUserInteraction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityRotorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityRotor(nil, textRanges: nil)
    let appOut1 = appView.accessibilityRotor(nil, entries: nil, entryLabel: nil)
    let appOut2 = appView.accessibilityRotor(nil, entries: nil, entryID: nil, entryLabel: nil)
    let appOut3 = appView.accessibilityRotor(nil, entries: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityRotor(nil, textRanges: nil)
    let contentOut1 = contentView.accessibilityRotor(nil, entries: nil, entryLabel: nil)
    let contentOut2 = contentView.accessibilityRotor(nil, entries: nil, entryID: nil, entryLabel: nil)
    let contentOut3 = contentView.accessibilityRotor(nil, entries: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testAccessibilityRotorEntryIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityRotorEntry(id: nil, in: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityRotorEntry(id: nil, in: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityScrollActionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityScrollAction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityScrollAction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityScrollStatusIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityScrollStatus(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityScrollStatus(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityShowsLargeContentViewerIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityShowsLargeContentViewer()
    let appOut1 = appView.accessibilityShowsLargeContentViewer(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityShowsLargeContentViewer()
    let contentOut1 = contentView.accessibilityShowsLargeContentViewer(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilitySortPriorityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilitySortPriority(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilitySortPriority(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityTextContentTypeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityTextContentType(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityTextContentType(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAccessibilityValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityValue(nil, isEnabled: nil)
    let appOut1 = appView.accessibilityValue(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityValue(nil, isEnabled: nil)
    let contentOut1 = contentView.accessibilityValue(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAccessibilityZoomActionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.accessibilityZoomAction(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.accessibilityZoomAction(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testActionSheetIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.actionSheet(isPresented: nil, content: nil)
    let appOut1 = appView.actionSheet(item: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.actionSheet(isPresented: nil, content: nil)
    let contentOut1 = contentView.actionSheet(item: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAlertIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.alert(isPresented: nil, error: nil, actions: nil, message: nil)
    let appOut1 = appView.alert(isPresented: nil, error: nil, actions: nil)
    let appOut2 = appView.alert(isPresented: nil, content: nil)
    let appOut3 = appView.alert(item: nil, content: nil)
    let appOut4 = appView.alert(nil, isPresented: nil, presenting: nil, actions: nil, message: nil)
    let appOut5 = appView.alert(nil, isPresented: nil, presenting: nil, actions: nil)
    let appOut6 = appView.alert(nil, isPresented: nil, actions: nil, message: nil)
    let appOut7 = appView.alert(nil, isPresented: nil, actions: nil)
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
    precondition(type(of: appOut5) == ManagedAppView.self)
    precondition(appOut5.body.storage == "OverlayProbe")
    precondition(type(of: appOut6) == ManagedAppView.self)
    precondition(appOut6.body.storage == "OverlayProbe")
    precondition(type(of: appOut7) == ManagedAppView.self)
    precondition(appOut7.body.storage == "OverlayProbe")
    let contentOut0 = contentView.alert(isPresented: nil, error: nil, actions: nil, message: nil)
    let contentOut1 = contentView.alert(isPresented: nil, error: nil, actions: nil)
    let contentOut2 = contentView.alert(isPresented: nil, content: nil)
    let contentOut3 = contentView.alert(item: nil, content: nil)
    let contentOut4 = contentView.alert(nil, isPresented: nil, presenting: nil, actions: nil, message: nil)
    let contentOut5 = contentView.alert(nil, isPresented: nil, presenting: nil, actions: nil)
    let contentOut6 = contentView.alert(nil, isPresented: nil, actions: nil, message: nil)
    let contentOut7 = contentView.alert(nil, isPresented: nil, actions: nil)
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
    precondition(type(of: contentOut5) == ManagedContentView<Text>.self)
    precondition(contentOut5.body.storage == "ProbeIcon")
    precondition(type(of: contentOut6) == ManagedContentView<Text>.self)
    precondition(contentOut6.body.storage == "ProbeIcon")
    precondition(type(of: contentOut7) == ManagedContentView<Text>.self)
    precondition(contentOut7.body.storage == "ProbeIcon")
}

func testAlignmentGuideIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.alignmentGuide(nil, computeValue: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.alignmentGuide(nil, computeValue: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAllowedDynamicRangeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.allowedDynamicRange(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.allowedDynamicRange(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAllowsHitTestingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.allowsHitTesting(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.allowsHitTesting(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAllowsTighteningIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.allowsTightening(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.allowsTightening(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAllowsWindowActivationEventsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.allowsWindowActivationEvents()
    let appOut1 = appView.allowsWindowActivationEvents(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.allowsWindowActivationEvents()
    let contentOut1 = contentView.allowsWindowActivationEvents(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAnchorPreferenceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.anchorPreference(key: nil, value: nil, transform: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.anchorPreference(key: nil, value: nil, transform: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAnimationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.animation(nil, body: nil)
    let appOut1 = appView.animation(nil, value: nil)
    let appOut2 = appView.animation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.animation(nil, body: nil)
    let contentOut1 = contentView.animation(nil, value: nil)
    let contentOut2 = contentView.animation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testAspectRatioIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.aspectRatio(nil, contentMode: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.aspectRatio(nil, contentMode: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAssistiveAccessNavigationIconIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.assistiveAccessNavigationIcon(systemImage: nil)
    let appOut1 = appView.assistiveAccessNavigationIcon(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.assistiveAccessNavigationIcon(systemImage: nil)
    let contentOut1 = contentView.assistiveAccessNavigationIcon(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testAttributedTextFormattingDefinitionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.attributedTextFormattingDefinition(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.attributedTextFormattingDefinition(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAutocapitalizationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.autocapitalization(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.autocapitalization(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testAutocorrectionDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.autocorrectionDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.autocorrectionDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBackgroundIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.background(ignoresSafeAreaEdges: nil)
    let appOut1 = appView.background(in: nil, fillStyle: nil)
    let appOut2 = appView.background(alignment: nil, content: nil)
    let appOut3 = appView.background(nil, ignoresSafeAreaEdges: nil)
    let appOut4 = appView.background(nil, in: nil, fillStyle: nil)
    let appOut5 = appView.background(nil, alignment: nil)
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
    precondition(type(of: appOut5) == ManagedAppView.self)
    precondition(appOut5.body.storage == "OverlayProbe")
    let contentOut0 = contentView.background(ignoresSafeAreaEdges: nil)
    let contentOut1 = contentView.background(in: nil, fillStyle: nil)
    let contentOut2 = contentView.background(alignment: nil, content: nil)
    let contentOut3 = contentView.background(nil, ignoresSafeAreaEdges: nil)
    let contentOut4 = contentView.background(nil, in: nil, fillStyle: nil)
    let contentOut5 = contentView.background(nil, alignment: nil)
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
    precondition(type(of: contentOut5) == ManagedContentView<Text>.self)
    precondition(contentOut5.body.storage == "ProbeIcon")
}

func testBackgroundExtensionEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.backgroundExtensionEffect(isEnabled: nil)
    let appOut1 = appView.backgroundExtensionEffect()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.backgroundExtensionEffect(isEnabled: nil)
    let contentOut1 = contentView.backgroundExtensionEffect()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testBackgroundPreferenceValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.backgroundPreferenceValue(nil, alignment: nil, nil)
    let appOut1 = appView.backgroundPreferenceValue(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.backgroundPreferenceValue(nil, alignment: nil, nil)
    let contentOut1 = contentView.backgroundPreferenceValue(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testBackgroundStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.backgroundStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.backgroundStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBadgeProminenceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.badgeProminence(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.badgeProminence(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBaselineOffsetIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.baselineOffset(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.baselineOffset(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBlendModeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.blendMode(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.blendMode(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBlurIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.blur(radius: nil, opaque: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.blur(radius: nil, opaque: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBoldIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.bold(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.bold(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBorderIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.border(nil, width: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.border(nil, width: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testBrightnessIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.brightness(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.brightness(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testButtonBorderShapeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.buttonBorderShape(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.buttonBorderShape(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testButtonRepeatBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.buttonRepeatBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.buttonRepeatBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testButtonSizingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.buttonSizing(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.buttonSizing(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testButtonStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.buttonStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.buttonStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testClipShapeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.clipShape(nil, style: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.clipShape(nil, style: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testClippedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.clipped(antialiased: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.clipped(antialiased: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testColorEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.colorEffect(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.colorEffect(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testColorInvertIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.colorInvert()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.colorInvert()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testColorMultiplyIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.colorMultiply(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.colorMultiply(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testColorSchemeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.colorScheme(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.colorScheme(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testCompositingGroupIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.compositingGroup()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.compositingGroup()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testConfirmationDialogIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil, message: nil)
    let appOut1 = appView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil)
    let appOut2 = appView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil, message: nil)
    let appOut3 = appView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil, message: nil)
    let contentOut1 = contentView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil)
    let contentOut2 = contentView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil, message: nil)
    let contentOut3 = contentView.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testContainerBackgroundIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.containerBackground(for: nil, alignment: nil, content: nil)
    let appOut1 = appView.containerBackground(nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.containerBackground(for: nil, alignment: nil, content: nil)
    let contentOut1 = contentView.containerBackground(nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testContainerCornerOffsetIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.containerCornerOffset(nil, sizeToFit: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.containerCornerOffset(nil, sizeToFit: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testContainerRelativeFrameIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.containerRelativeFrame(nil, count: nil, span: nil, spacing: nil, alignment: nil)
    let appOut1 = appView.containerRelativeFrame(nil, alignment: nil)
    let appOut2 = appView.containerRelativeFrame(nil, alignment: nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.containerRelativeFrame(nil, count: nil, span: nil, spacing: nil, alignment: nil)
    let contentOut1 = contentView.containerRelativeFrame(nil, alignment: nil)
    let contentOut2 = contentView.containerRelativeFrame(nil, alignment: nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testContainerShapeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.containerShape(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.containerShape(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testContainerValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.containerValue(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.containerValue(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testContentMarginsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.contentMargins(nil, for: nil)
    let appOut1 = appView.contentMargins(nil, nil, for: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.contentMargins(nil, for: nil)
    let contentOut1 = contentView.contentMargins(nil, nil, for: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testContentShapeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.contentShape(nil, eoFill: nil)
    let appOut1 = appView.contentShape(nil, nil, eoFill: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.contentShape(nil, eoFill: nil)
    let contentOut1 = contentView.contentShape(nil, nil, eoFill: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testContentToolbarIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.contentToolbar(for: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.contentToolbar(for: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testContentTransitionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.contentTransition(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.contentTransition(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testContextMenuIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.contextMenu(forSelectionType: nil, menu: nil, primaryAction: nil)
    let appOut1 = appView.contextMenu(menuItems: nil, preview: nil)
    let appOut2 = appView.contextMenu(menuItems: nil)
    let appOut3 = appView.contextMenu(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.contextMenu(forSelectionType: nil, menu: nil, primaryAction: nil)
    let contentOut1 = contentView.contextMenu(menuItems: nil, preview: nil)
    let contentOut2 = contentView.contextMenu(menuItems: nil)
    let contentOut3 = contentView.contextMenu(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testContrastIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.contrast(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.contrast(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testControlGroupStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.controlGroupStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.controlGroupStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testControlSizeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.controlSize(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.controlSize(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testCoordinateSpaceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.coordinateSpace(name: nil)
    let appOut1 = appView.coordinateSpace(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.coordinateSpace(name: nil)
    let contentOut1 = contentView.coordinateSpace(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testCornerRadiusIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.cornerRadius(nil, antialiased: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.cornerRadius(nil, antialiased: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDatePickerStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.datePickerStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.datePickerStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDefaultAdaptableTabBarPlacementIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.defaultAdaptableTabBarPlacement(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.defaultAdaptableTabBarPlacement(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDefaultAppStorageIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.defaultAppStorage(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.defaultAppStorage(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDefaultFocusIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.defaultFocus(nil, nil, priority: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.defaultFocus(nil, nil, priority: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDefaultHoverEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.defaultHoverEffect(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.defaultHoverEffect(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDefaultScrollAnchorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.defaultScrollAnchor(nil, for: nil)
    let appOut1 = appView.defaultScrollAnchor(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.defaultScrollAnchor(nil, for: nil)
    let contentOut1 = contentView.defaultScrollAnchor(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testDefersSystemGesturesIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.defersSystemGestures(on: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.defersSystemGestures(on: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDeleteDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.deleteDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.deleteDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDialogIconIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.dialogIcon(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.dialogIcon(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDialogSuppressionToggleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.dialogSuppressionToggle(isSuppressed: nil)
    let appOut1 = appView.dialogSuppressionToggle(nil, isSuppressed: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.dialogSuppressionToggle(isSuppressed: nil)
    let contentOut1 = contentView.dialogSuppressionToggle(nil, isSuppressed: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testDisableAutocorrectionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.disableAutocorrection(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.disableAutocorrection(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}
