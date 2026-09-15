import Foundation
import ManagedAppDistribution

// Identity coverage for the synthesized SwiftUI View-modifier census.
// Linux has no SwiftUI layout engine; each modifier is a documented
// no-op returning `self`. Each test calls every overload of one
// modifier on both overlay views and checks the value passes through
// unchanged. All calls are synchronous; no queues, run loops, or semaphores are used.

func testDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.disabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.disabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDisclosureGroupStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.disclosureGroupStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.disclosureGroupStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDistortionEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.distortionEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.distortionEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDocumentBrowserContextMenuIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.documentBrowserContextMenu(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.documentBrowserContextMenu(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDraggableIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.draggable(nil, preview: nil)
    let appOut1 = appView.draggable(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.draggable(nil, preview: nil)
    let contentOut1 = contentView.draggable(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testDrawingGroupIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.drawingGroup(opaque: nil, colorMode: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.drawingGroup(opaque: nil, colorMode: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testDropDestinationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.dropDestination(for: nil, action: nil, isTargeted: nil)
    let appOut1 = appView.dropDestination(for: nil, isEnabled: nil, action: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.dropDestination(for: nil, action: nil, isTargeted: nil)
    let contentOut1 = contentView.dropDestination(for: nil, isEnabled: nil, action: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testDynamicTypeSizeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.dynamicTypeSize(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.dynamicTypeSize(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testEdgesIgnoringSafeAreaIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.edgesIgnoringSafeArea(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.edgesIgnoringSafeArea(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testEnvironmentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.environment(nil)
    let appOut1 = appView.environment(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.environment(nil)
    let contentOut1 = contentView.environment(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testEnvironmentObjectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.environmentObject(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.environmentObject(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogBrowserOptionsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogBrowserOptions(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogBrowserOptions(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogConfirmationLabelIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogConfirmationLabel(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogConfirmationLabel(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogCustomizationIDIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogCustomizationID(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogCustomizationID(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogDefaultDirectoryIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogDefaultDirectory(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogDefaultDirectory(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogImportsUnresolvedAliasesIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogImportsUnresolvedAliases(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogImportsUnresolvedAliases(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogMessageIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogMessage(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogMessage(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileDialogURLEnabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileDialogURLEnabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileDialogURLEnabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileExporterIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileExporter(isPresented: nil, item: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    let appOut1 = appView.fileExporter(isPresented: nil, items: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    let appOut2 = appView.fileExporter(isPresented: nil, document: nil, contentType: nil, defaultFilename: nil, onCompletion: nil)
    let appOut3 = appView.fileExporter(isPresented: nil, document: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    let appOut4 = appView.fileExporter(isPresented: nil, documents: nil, contentType: nil, onCompletion: nil)
    let appOut5 = appView.fileExporter(isPresented: nil, documents: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
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
    let contentOut0 = contentView.fileExporter(isPresented: nil, item: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    let contentOut1 = contentView.fileExporter(isPresented: nil, items: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    let contentOut2 = contentView.fileExporter(isPresented: nil, document: nil, contentType: nil, defaultFilename: nil, onCompletion: nil)
    let contentOut3 = contentView.fileExporter(isPresented: nil, document: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    let contentOut4 = contentView.fileExporter(isPresented: nil, documents: nil, contentType: nil, onCompletion: nil)
    let contentOut5 = contentView.fileExporter(isPresented: nil, documents: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
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

func testFileExporterFilenameLabelIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileExporterFilenameLabel(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileExporterFilenameLabel(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFileImporterIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileImporter(isPresented: nil, allowedContentTypes: nil, onCompletion: nil)
    let appOut1 = appView.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil, onCancellation: nil)
    let appOut2 = appView.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileImporter(isPresented: nil, allowedContentTypes: nil, onCompletion: nil)
    let contentOut1 = contentView.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil, onCancellation: nil)
    let contentOut2 = contentView.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testFileMoverIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fileMover(isPresented: nil, file: nil, onCompletion: nil, onCancellation: nil)
    let appOut1 = appView.fileMover(isPresented: nil, file: nil, onCompletion: nil)
    let appOut2 = appView.fileMover(isPresented: nil, files: nil, onCompletion: nil, onCancellation: nil)
    let appOut3 = appView.fileMover(isPresented: nil, files: nil, onCompletion: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fileMover(isPresented: nil, file: nil, onCompletion: nil, onCancellation: nil)
    let contentOut1 = contentView.fileMover(isPresented: nil, file: nil, onCompletion: nil)
    let contentOut2 = contentView.fileMover(isPresented: nil, files: nil, onCompletion: nil, onCancellation: nil)
    let contentOut3 = contentView.fileMover(isPresented: nil, files: nil, onCompletion: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testFindDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.findDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.findDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFindNavigatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.findNavigator(isPresented: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.findNavigator(isPresented: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFixedSizeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fixedSize(horizontal: nil, vertical: nil)
    let appOut1 = appView.fixedSize()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fixedSize(horizontal: nil, vertical: nil)
    let contentOut1 = contentView.fixedSize()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testFlipsForRightToLeftLayoutDirectionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.flipsForRightToLeftLayoutDirection(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.flipsForRightToLeftLayoutDirection(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFocusEffectDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focusEffectDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focusEffectDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFocusableIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focusable(nil, interactions: nil)
    let appOut1 = appView.focusable(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focusable(nil, interactions: nil)
    let contentOut1 = contentView.focusable(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testFocusedIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focused(nil, equals: nil)
    let appOut1 = appView.focused(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focused(nil, equals: nil)
    let contentOut1 = contentView.focused(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testFocusedObjectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focusedObject(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focusedObject(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFocusedSceneObjectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focusedSceneObject(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focusedSceneObject(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFocusedSceneValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focusedSceneValue(nil)
    let appOut1 = appView.focusedSceneValue(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focusedSceneValue(nil)
    let contentOut1 = contentView.focusedSceneValue(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testFocusedValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.focusedValue(nil)
    let appOut1 = appView.focusedValue(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.focusedValue(nil)
    let contentOut1 = contentView.focusedValue(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testFontIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.font(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.font(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFontDesignIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fontDesign(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fontDesign(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFontWeightIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fontWeight(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fontWeight(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFontWidthIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fontWidth(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fontWidth(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testForegroundColorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.foregroundColor(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.foregroundColor(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testForegroundStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.foregroundStyle(nil)
    let appOut1 = appView.foregroundStyle(nil, nil, nil)
    let appOut2 = appView.foregroundStyle(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.foregroundStyle(nil)
    let contentOut1 = contentView.foregroundStyle(nil, nil, nil)
    let contentOut2 = contentView.foregroundStyle(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testFormStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.formStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.formStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testFrameIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.frame(width: nil, height: nil, alignment: nil)
    let appOut1 = appView.frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: nil)
    let appOut2 = appView.frame()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.frame(width: nil, height: nil, alignment: nil)
    let contentOut1 = contentView.frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: nil)
    let contentOut2 = contentView.frame()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testFullScreenCoverIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.fullScreenCover(isPresented: nil, onDismiss: nil, content: nil)
    let appOut1 = appView.fullScreenCover(item: nil, onDismiss: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.fullScreenCover(isPresented: nil, onDismiss: nil, content: nil)
    let contentOut1 = contentView.fullScreenCover(item: nil, onDismiss: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testGaugeStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.gaugeStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.gaugeStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGeometryGroupIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.geometryGroup()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.geometryGroup()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGestureIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.gesture(nil, name: nil, isEnabled: nil)
    let appOut1 = appView.gesture(nil, including: nil)
    let appOut2 = appView.gesture(nil, isEnabled: nil)
    let appOut3 = appView.gesture(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    precondition(type(of: appOut3) == ManagedAppView.self)
    precondition(appOut3.body.storage == "OverlayProbe")
    let contentOut0 = contentView.gesture(nil, name: nil, isEnabled: nil)
    let contentOut1 = contentView.gesture(nil, including: nil)
    let contentOut2 = contentView.gesture(nil, isEnabled: nil)
    let contentOut3 = contentView.gesture(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
    precondition(type(of: contentOut3) == ManagedContentView<Text>.self)
    precondition(contentOut3.body.storage == "ProbeIcon")
}

func testGlassEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.glassEffect(nil, in: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.glassEffect(nil, in: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGlassEffectIDIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.glassEffectID(nil, in: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.glassEffectID(nil, in: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGlassEffectTransitionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.glassEffectTransition(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.glassEffectTransition(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGlassEffectUnionIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.glassEffectUnion(id: nil, namespace: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.glassEffectUnion(id: nil, namespace: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGrayscaleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.grayscale(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.grayscale(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGridCellAnchorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.gridCellAnchor(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.gridCellAnchor(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGridCellColumnsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.gridCellColumns(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.gridCellColumns(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGridCellUnsizedAxesIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.gridCellUnsizedAxes(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.gridCellUnsizedAxes(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGridColumnAlignmentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.gridColumnAlignment(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.gridColumnAlignment(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testGroupBoxStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.groupBoxStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.groupBoxStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHandGestureShortcutIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.handGestureShortcut(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.handGestureShortcut(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHandlesExternalEventsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.handlesExternalEvents(preferring: nil, allowing: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.handlesExternalEvents(preferring: nil, allowing: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHeaderProminenceIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.headerProminence(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.headerProminence(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHelpIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.help(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.help(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.hidden()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.hidden()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHighPriorityGestureIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.highPriorityGesture(nil, name: nil, isEnabled: nil)
    let appOut1 = appView.highPriorityGesture(nil, including: nil)
    let appOut2 = appView.highPriorityGesture(nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.highPriorityGesture(nil, name: nil, isEnabled: nil)
    let contentOut1 = contentView.highPriorityGesture(nil, including: nil)
    let contentOut2 = contentView.highPriorityGesture(nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testHoverEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.hoverEffect(nil, isEnabled: nil)
    let appOut1 = appView.hoverEffect(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.hoverEffect(nil, isEnabled: nil)
    let contentOut1 = contentView.hoverEffect(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testHoverEffectDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.hoverEffectDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.hoverEffectDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testHueRotationIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.hueRotation(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.hueRotation(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testIdIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.id(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.id(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testIgnoresSafeAreaIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.ignoresSafeArea(nil, edges: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.ignoresSafeArea(nil, edges: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testImageScaleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.imageScale(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.imageScale(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testIndexViewStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.indexViewStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.indexViewStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testInspectorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.inspector(isPresented: nil, content: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.inspector(isPresented: nil, content: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testInspectorColumnWidthIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.inspectorColumnWidth(min: nil, ideal: nil, max: nil)
    let appOut1 = appView.inspectorColumnWidth(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.inspectorColumnWidth(min: nil, ideal: nil, max: nil)
    let contentOut1 = contentView.inspectorColumnWidth(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testInteractionActivityTrackingTagIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.interactionActivityTrackingTag(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.interactionActivityTrackingTag(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testInteractiveDismissDisabledIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.interactiveDismissDisabled(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.interactiveDismissDisabled(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testInvalidatableContentIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.invalidatableContent(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.invalidatableContent(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testItalicIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.italic(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.italic(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testItemProviderIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.itemProvider(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.itemProvider(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testKerningIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.kerning(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.kerning(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testKeyboardShortcutIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.keyboardShortcut(nil, modifiers: nil, localization: nil)
    let appOut1 = appView.keyboardShortcut(nil, modifiers: nil)
    let appOut2 = appView.keyboardShortcut(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    precondition(type(of: appOut2) == ManagedAppView.self)
    precondition(appOut2.body.storage == "OverlayProbe")
    let contentOut0 = contentView.keyboardShortcut(nil, modifiers: nil, localization: nil)
    let contentOut1 = contentView.keyboardShortcut(nil, modifiers: nil)
    let contentOut2 = contentView.keyboardShortcut(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
    precondition(type(of: contentOut2) == ManagedContentView<Text>.self)
    precondition(contentOut2.body.storage == "ProbeIcon")
}

func testKeyboardTypeIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.keyboardType(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.keyboardType(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testKeyframeAnimatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.keyframeAnimator(initialValue: nil, trigger: nil, content: nil, keyframes: nil)
    let appOut1 = appView.keyframeAnimator(initialValue: nil, repeating: nil, content: nil, keyframes: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.keyframeAnimator(initialValue: nil, trigger: nil, content: nil, keyframes: nil)
    let contentOut1 = contentView.keyframeAnimator(initialValue: nil, repeating: nil, content: nil, keyframes: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testLabelIconToTitleSpacingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.labelIconToTitleSpacing(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.labelIconToTitleSpacing(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLabelReservedIconWidthIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.labelReservedIconWidth(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.labelReservedIconWidth(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLabelStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.labelStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.labelStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLabeledContentStyleIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.labeledContentStyle(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.labeledContentStyle(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLabelsHiddenIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.labelsHidden()
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.labelsHidden()
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLabelsVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.labelsVisibility(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.labelsVisibility(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLayerEffectIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.layerEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.layerEffect(nil, maxSampleOffset: nil, isEnabled: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLayoutDirectionBehaviorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.layoutDirectionBehavior(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.layoutDirectionBehavior(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLayoutPriorityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.layoutPriority(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.layoutPriority(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLayoutValueIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.layoutValue(key: nil, value: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.layoutValue(key: nil, value: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLineHeightIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.lineHeight(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.lineHeight(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testLineLimitIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.lineLimit(nil, reservesSpace: nil)
    let appOut1 = appView.lineLimit(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.lineLimit(nil, reservesSpace: nil)
    let contentOut1 = contentView.lineLimit(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testLineSpacingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.lineSpacing(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.lineSpacing(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListItemTintIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listItemTint(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listItemTint(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListRowBackgroundIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listRowBackground(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listRowBackground(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListRowInsetsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listRowInsets(nil)
    let appOut1 = appView.listRowInsets(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    precondition(type(of: appOut1) == ManagedAppView.self)
    precondition(appOut1.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listRowInsets(nil)
    let contentOut1 = contentView.listRowInsets(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
    precondition(type(of: contentOut1) == ManagedContentView<Text>.self)
    precondition(contentOut1.body.storage == "ProbeIcon")
}

func testListRowSeparatorIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listRowSeparator(nil, edges: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listRowSeparator(nil, edges: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListRowSeparatorTintIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listRowSeparatorTint(nil, edges: nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listRowSeparatorTint(nil, edges: nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListRowSpacingIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listRowSpacing(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listRowSpacing(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListSectionIndexVisibilityIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listSectionIndexVisibility(nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listSectionIndexVisibility(nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}

func testListSectionMarginsIdentity() {
    let app = ManagedApp(id: "com.example.overlay", name: "OverlayProbe")
    let appView = ManagedAppView(app: app)
    let contentView = ManagedContentView(
        primaryLabel: LocalizedStringKey("Probe"),
        offerState: .installed,
        icon: { Text("ProbeIcon") }
    )
    let appOut0 = appView.listSectionMargins(nil, nil)
    precondition(type(of: appOut0) == ManagedAppView.self)
    precondition(appOut0.body.storage == "OverlayProbe")
    let contentOut0 = contentView.listSectionMargins(nil, nil)
    precondition(type(of: contentOut0) == ManagedContentView<Text>.self)
    precondition(contentOut0.body.storage == "ProbeIcon")
}
