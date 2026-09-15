import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testSynthAccessibilityAction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityAction(nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityAction(action: nil, label: nil)
    _ = picker.accessibilityAction(named: nil, nil)
    precondition(type(of: button.accessibilityAction(nil, nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityAction(action: nil, label: nil)
    _ = button.accessibilityAction(named: nil, nil)
}

func testSynthAccessibilityChildren() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityChildren(children: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityChildren(children: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityElement() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityElement(children: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityElement(children: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityIgnoresInvertColors() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityIgnoresInvertColors(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityIgnoresInvertColors(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityRepresentation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityRepresentation(representation: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityRepresentation(representation: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityShowsLargeContentViewer() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityShowsLargeContentViewer()) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityShowsLargeContentViewer(nil)
    precondition(type(of: button.accessibilityShowsLargeContentViewer()) == AddOrderToWalletButton.self)
    _ = button.accessibilityShowsLargeContentViewer(nil)
}

func testSynthAlert() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.alert(nil, isPresented: nil, actions: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.alert(nil, isPresented: nil, actions: nil, message: nil)
    _ = picker.alert(nil, isPresented: nil, presenting: nil, actions: nil)
    _ = picker.alert(nil, isPresented: nil, presenting: nil, actions: nil, message: nil)
    _ = picker.alert(isPresented: nil, content: nil)
    _ = picker.alert(isPresented: nil, error: nil, actions: nil)
    _ = picker.alert(isPresented: nil, error: nil, actions: nil, message: nil)
    _ = picker.alert(item: nil, content: nil)
    precondition(type(of: button.alert(nil, isPresented: nil, actions: nil)) == AddOrderToWalletButton.self)
    _ = button.alert(nil, isPresented: nil, actions: nil, message: nil)
    _ = button.alert(nil, isPresented: nil, presenting: nil, actions: nil)
    _ = button.alert(nil, isPresented: nil, presenting: nil, actions: nil, message: nil)
    _ = button.alert(isPresented: nil, content: nil)
    _ = button.alert(isPresented: nil, error: nil, actions: nil)
    _ = button.alert(isPresented: nil, error: nil, actions: nil, message: nil)
    _ = button.alert(item: nil, content: nil)
}

func testSynthAnchorPreference() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.anchorPreference(key: nil, value: nil, transform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.anchorPreference(key: nil, value: nil, transform: nil)) == AddOrderToWalletButton.self)
}

func testSynthAutocorrectionDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.autocorrectionDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.autocorrectionDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthBadgeProminence() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.badgeProminence(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.badgeProminence(nil)) == AddOrderToWalletButton.self)
}

func testSynthBrightness() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.brightness(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.brightness(nil)) == AddOrderToWalletButton.self)
}

func testSynthClipped() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.clipped(antialiased: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.clipped(antialiased: nil)) == AddOrderToWalletButton.self)
}

func testSynthConfirmationDialog() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil, message: nil)
    _ = picker.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil)
    _ = picker.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil, message: nil)
    precondition(type(of: button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil)) == AddOrderToWalletButton.self)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, actions: nil, message: nil)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil)
    _ = button.confirmationDialog(nil, isPresented: nil, titleVisibility: nil, presenting: nil, actions: nil, message: nil)
}

func testSynthContentMargins() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.contentMargins(nil, nil, for: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.contentMargins(nil, for: nil)
    precondition(type(of: button.contentMargins(nil, nil, for: nil)) == AddOrderToWalletButton.self)
    _ = button.contentMargins(nil, for: nil)
}

func testSynthControlGroupStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.controlGroupStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.controlGroupStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthDefaultAppStorage() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.defaultAppStorage(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.defaultAppStorage(nil)) == AddOrderToWalletButton.self)
}

func testSynthDialogIcon() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.dialogIcon(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.dialogIcon(nil)) == AddOrderToWalletButton.self)
}

func testSynthDocumentBrowserContextMenu() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.documentBrowserContextMenu(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.documentBrowserContextMenu(nil)) == AddOrderToWalletButton.self)
}

func testSynthEnvironment() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.environment(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.environment(nil, nil)
    precondition(type(of: button.environment(nil)) == AddOrderToWalletButton.self)
    _ = button.environment(nil, nil)
}

func testSynthFileDialogImportsUnresolvedAliases() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogImportsUnresolvedAliases(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogImportsUnresolvedAliases(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileMover() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileMover(isPresented: nil, file: nil, onCompletion: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.fileMover(isPresented: nil, file: nil, onCompletion: nil, onCancellation: nil)
    _ = picker.fileMover(isPresented: nil, files: nil, onCompletion: nil)
    _ = picker.fileMover(isPresented: nil, files: nil, onCompletion: nil, onCancellation: nil)
    precondition(type(of: button.fileMover(isPresented: nil, file: nil, onCompletion: nil)) == AddOrderToWalletButton.self)
    _ = button.fileMover(isPresented: nil, file: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileMover(isPresented: nil, files: nil, onCompletion: nil)
    _ = button.fileMover(isPresented: nil, files: nil, onCompletion: nil, onCancellation: nil)
}

func testSynthFocusable() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focusable(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.focusable(nil, interactions: nil)
    precondition(type(of: button.focusable(nil)) == AddOrderToWalletButton.self)
    _ = button.focusable(nil, interactions: nil)
}

func testSynthFont() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.font(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.font(nil)) == AddOrderToWalletButton.self)
}

func testSynthFormStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.formStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.formStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthGlassEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.glassEffect(nil, in: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.glassEffect(nil, in: nil)) == AddOrderToWalletButton.self)
}

func testSynthGridCellColumns() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.gridCellColumns(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.gridCellColumns(nil)) == AddOrderToWalletButton.self)
}

func testSynthHeaderProminence() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.headerProminence(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.headerProminence(nil)) == AddOrderToWalletButton.self)
}

func testSynthHueRotation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.hueRotation(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.hueRotation(nil)) == AddOrderToWalletButton.self)
}

func testSynthInspectorColumnWidth() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.inspectorColumnWidth(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.inspectorColumnWidth(min: nil, ideal: nil, max: nil)
    precondition(type(of: button.inspectorColumnWidth(nil)) == AddOrderToWalletButton.self)
    _ = button.inspectorColumnWidth(min: nil, ideal: nil, max: nil)
}

func testSynthKerning() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.kerning(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.kerning(nil)) == AddOrderToWalletButton.self)
}

func testSynthLabelStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.labelStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.labelStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthLayoutPriority() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.layoutPriority(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.layoutPriority(nil)) == AddOrderToWalletButton.self)
}

func testSynthListRowBackground() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listRowBackground(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listRowBackground(nil)) == AddOrderToWalletButton.self)
}

func testSynthListSectionMargins() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listSectionMargins(nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listSectionMargins(nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthMask() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.mask(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.mask(alignment: nil, nil)
    precondition(type(of: button.mask(nil)) == AddOrderToWalletButton.self)
    _ = button.mask(alignment: nil, nil)
}

func testSynthMenuOrder() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.menuOrder(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.menuOrder(nil)) == AddOrderToWalletButton.self)
}

func testSynthMoveDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.moveDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.moveDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationBarTitleDisplayMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationBarTitleDisplayMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationBarTitleDisplayMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationSubtitle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationSubtitle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationSubtitle(nil)) == AddOrderToWalletButton.self)
}

func testSynthOnChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onChange(of: nil, initial: nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onChange(of: nil, perform: nil)
    precondition(type(of: button.onChange(of: nil, initial: nil, nil)) == AddOrderToWalletButton.self)
    _ = button.onChange(of: nil, perform: nil)
}

func testSynthOnGeometryChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onGeometryChange(for: nil, of: nil, action: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onGeometryChange(for: nil, of: nil, action: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnPencilDoubleTap() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onPencilDoubleTap(perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onPencilDoubleTap(perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnScrollTargetVisibilityChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onScrollTargetVisibilityChange(idType: nil, threshold: nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onScrollTargetVisibilityChange(idType: nil, threshold: nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthOverlayPreferenceValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.overlayPreferenceValue(nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.overlayPreferenceValue(nil, alignment: nil, nil)
    precondition(type(of: button.overlayPreferenceValue(nil, nil)) == AddOrderToWalletButton.self)
    _ = button.overlayPreferenceValue(nil, alignment: nil, nil)
}

func testSynthPopover() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.popover(isPresented: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.popover(item: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
    precondition(type(of: button.popover(isPresented: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)) == AddOrderToWalletButton.self)
    _ = button.popover(item: nil, attachmentAnchor: nil, arrowEdge: nil, content: nil)
}

func testSynthPresentationCompactAdaptation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationCompactAdaptation(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.presentationCompactAdaptation(horizontal: nil, vertical: nil)
    precondition(type(of: button.presentationCompactAdaptation(nil)) == AddOrderToWalletButton.self)
    _ = button.presentationCompactAdaptation(horizontal: nil, vertical: nil)
}

func testSynthPreviewContext() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.previewContext(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.previewContext(nil)) == AddOrderToWalletButton.self)
}

func testSynthProgressViewStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.progressViewStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.progressViewStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthRotation3DEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.rotation3DEffect(nil, axis: nil, anchor: nil, anchorZ: nil, perspective: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.rotation3DEffect(nil, axis: nil, anchor: nil, anchorZ: nil, perspective: nil)) == AddOrderToWalletButton.self)
}

func testSynthScaleEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scaleEffect(nil, anchor: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.scaleEffect(x: nil, y: nil, anchor: nil)
    precondition(type(of: button.scaleEffect(nil, anchor: nil)) == AddOrderToWalletButton.self)
    _ = button.scaleEffect(x: nil, y: nil, anchor: nil)
}

func testSynthScrollContentBackground() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollContentBackground(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollContentBackground(nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollIndicatorsFlash() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollIndicatorsFlash(onAppear: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.scrollIndicatorsFlash(trigger: nil)
    precondition(type(of: button.scrollIndicatorsFlash(onAppear: nil)) == AddOrderToWalletButton.self)
    _ = button.scrollIndicatorsFlash(trigger: nil)
}

func testSynthSearchCompletion() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchCompletion(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.searchCompletion(nil)) == AddOrderToWalletButton.self)
}

func testSynthSearchSuggestions() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchSuggestions(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.searchSuggestions(nil, for: nil)
    precondition(type(of: button.searchSuggestions(nil)) == AddOrderToWalletButton.self)
    _ = button.searchSuggestions(nil, for: nil)
}

func testSynthSensoryFeedback() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.sensoryFeedback(nil, trigger: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.sensoryFeedback(nil, trigger: nil, condition: nil)
    _ = picker.sensoryFeedback(trigger: nil, nil)
    precondition(type(of: button.sensoryFeedback(nil, trigger: nil)) == AddOrderToWalletButton.self)
    _ = button.sensoryFeedback(nil, trigger: nil, condition: nil)
    _ = button.sensoryFeedback(trigger: nil, nil)
}

func testSynthSpeechAlwaysIncludesPunctuation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.speechAlwaysIncludesPunctuation(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.speechAlwaysIncludesPunctuation(nil)) == AddOrderToWalletButton.self)
}

func testSynthStrikethrough() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.strikethrough(nil, pattern: nil, color: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.strikethrough(nil, pattern: nil, color: nil)) == AddOrderToWalletButton.self)
}

func testSynthSymbolEffectsRemoved() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.symbolEffectsRemoved(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.symbolEffectsRemoved(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewBottomAccessory() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewBottomAccessory(content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewBottomAccessory(content: nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextContentType() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textContentType(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textContentType(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextScale() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textScale(nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textScale(nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarBackground() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarBackground(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarBackground(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarTitleMenu() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarTitleMenu(content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarTitleMenu(content: nil)) == AddOrderToWalletButton.self)
}

func testSynthTransformEnvironment() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.transformEnvironment(nil, transform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.transformEnvironment(nil, transform: nil)) == AddOrderToWalletButton.self)
}

func testSynthUnderline() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.underline(nil, pattern: nil, color: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.underline(nil, pattern: nil, color: nil)) == AddOrderToWalletButton.self)
}

func testSynthWritingToolsAffordanceVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.writingToolsAffordanceVisibility(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.writingToolsAffordanceVisibility(nil)) == AddOrderToWalletButton.self)
}
