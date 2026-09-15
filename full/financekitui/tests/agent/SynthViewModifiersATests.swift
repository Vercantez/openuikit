import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testSynthAccentColor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accentColor(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accentColor(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityAdjustableAction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityAdjustableAction(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityAdjustableAction(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityDragPoint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityDragPoint(nil, description: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityDragPoint(nil, description: nil, isEnabled: nil)
    precondition(type(of: button.accessibilityDragPoint(nil, description: nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityDragPoint(nil, description: nil, isEnabled: nil)
}

func testSynthAccessibilityHint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityHint(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityHint(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityHint(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityHint(nil, isEnabled: nil)
}

func testSynthAccessibilityLinkedGroup() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityLinkedGroup(id: nil, in: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityLinkedGroup(id: nil, in: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityScrollAction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityScrollAction(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityScrollAction(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityZoomAction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityZoomAction(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityZoomAction(nil)) == AddOrderToWalletButton.self)
}

func testSynthAllowsTightening() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.allowsTightening(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.allowsTightening(nil)) == AddOrderToWalletButton.self)
}

func testSynthAttributedTextFormattingDefinition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.attributedTextFormattingDefinition(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.attributedTextFormattingDefinition(nil)) == AddOrderToWalletButton.self)
}

func testSynthBackgroundStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.backgroundStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.backgroundStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthBold() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.bold(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.bold(nil)) == AddOrderToWalletButton.self)
}

func testSynthButtonStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.buttonStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.buttonStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthColorScheme() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.colorScheme(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.colorScheme(nil)) == AddOrderToWalletButton.self)
}

func testSynthContainerShape() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.containerShape(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.containerShape(nil)) == AddOrderToWalletButton.self)
}

func testSynthContextMenu() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.contextMenu(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.contextMenu(forSelectionType: nil, menu: nil, primaryAction: nil)
    _ = picker.contextMenu(menuItems: nil)
    _ = picker.contextMenu(menuItems: nil, preview: nil)
    precondition(type(of: button.contextMenu(nil)) == AddOrderToWalletButton.self)
    _ = button.contextMenu(forSelectionType: nil, menu: nil, primaryAction: nil)
    _ = button.contextMenu(menuItems: nil)
    _ = button.contextMenu(menuItems: nil, preview: nil)
}

func testSynthDatePickerStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.datePickerStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.datePickerStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthDefersSystemGestures() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.defersSystemGestures(on: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.defersSystemGestures(on: nil)) == AddOrderToWalletButton.self)
}

func testSynthDisclosureGroupStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.disclosureGroupStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.disclosureGroupStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthDynamicTypeSize() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.dynamicTypeSize(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.dynamicTypeSize(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileDialogCustomizationID() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogCustomizationID(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogCustomizationID(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileExporterFilenameLabel() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileExporterFilenameLabel(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileExporterFilenameLabel(nil)) == AddOrderToWalletButton.self)
}

func testSynthFlipsForRightToLeftLayoutDirection() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.flipsForRightToLeftLayoutDirection(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.flipsForRightToLeftLayoutDirection(nil)) == AddOrderToWalletButton.self)
}

func testSynthFocusedSceneValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focusedSceneValue(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.focusedSceneValue(nil, nil)
    precondition(type(of: button.focusedSceneValue(nil)) == AddOrderToWalletButton.self)
    _ = button.focusedSceneValue(nil, nil)
}

func testSynthForegroundColor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.foregroundColor(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.foregroundColor(nil)) == AddOrderToWalletButton.self)
}

func testSynthGeometryGroup() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.geometryGroup()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.geometryGroup()) == AddOrderToWalletButton.self)
}

func testSynthGrayscale() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.grayscale(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.grayscale(nil)) == AddOrderToWalletButton.self)
}

func testSynthHandGestureShortcut() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.handGestureShortcut(nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.handGestureShortcut(nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthHoverEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.hoverEffect(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.hoverEffect(nil, isEnabled: nil)
    precondition(type(of: button.hoverEffect(nil)) == AddOrderToWalletButton.self)
    _ = button.hoverEffect(nil, isEnabled: nil)
}

func testSynthIndexViewStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.indexViewStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.indexViewStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthItalic() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.italic(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.italic(nil)) == AddOrderToWalletButton.self)
}

func testSynthLabelIconToTitleSpacing() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.labelIconToTitleSpacing(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.labelIconToTitleSpacing(nil)) == AddOrderToWalletButton.self)
}

func testSynthLayerEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.layerEffect(nil, maxSampleOffset: nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.layerEffect(nil, maxSampleOffset: nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthLineSpacing() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.lineSpacing(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.lineSpacing(nil)) == AddOrderToWalletButton.self)
}

func testSynthListRowSpacing() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listRowSpacing(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listRowSpacing(nil)) == AddOrderToWalletButton.self)
}

func testSynthListStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthMenuActionDismissBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.menuActionDismissBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.menuActionDismissBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthMonospaced() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.monospaced(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.monospaced(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationBarItems() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationBarItems(leading: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.navigationBarItems(leading: nil, trailing: nil)
    _ = picker.navigationBarItems(trailing: nil)
    precondition(type(of: button.navigationBarItems(leading: nil)) == AddOrderToWalletButton.self)
    _ = button.navigationBarItems(leading: nil, trailing: nil)
    _ = button.navigationBarItems(trailing: nil)
}

func testSynthNavigationSplitViewColumnWidth() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationSplitViewColumnWidth(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.navigationSplitViewColumnWidth(min: nil, ideal: nil, max: nil)
    precondition(type(of: button.navigationSplitViewColumnWidth(nil)) == AddOrderToWalletButton.self)
    _ = button.navigationSplitViewColumnWidth(min: nil, ideal: nil, max: nil)
}

func testSynthOffset() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.offset(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.offset(x: nil, y: nil)
    precondition(type(of: button.offset(nil)) == AddOrderToWalletButton.self)
    _ = button.offset(x: nil, y: nil)
}

func testSynthOnDrag() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onDrag(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onDrag(nil, preview: nil)
    precondition(type(of: button.onDrag(nil)) == AddOrderToWalletButton.self)
    _ = button.onDrag(nil, preview: nil)
}

func testSynthOnLongPressGesture() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, perform: nil, onPressingChanged: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, pressing: nil, perform: nil)
    _ = picker.onLongPressGesture(minimumDuration: nil, perform: nil, onPressingChanged: nil)
    _ = picker.onLongPressGesture(minimumDuration: nil, pressing: nil, perform: nil)
    precondition(type(of: button.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, perform: nil, onPressingChanged: nil)) == AddOrderToWalletButton.self)
    _ = button.onLongPressGesture(minimumDuration: nil, maximumDistance: nil, pressing: nil, perform: nil)
    _ = button.onLongPressGesture(minimumDuration: nil, perform: nil, onPressingChanged: nil)
    _ = button.onLongPressGesture(minimumDuration: nil, pressing: nil, perform: nil)
}

func testSynthOnScrollGeometryChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onScrollGeometryChange(for: nil, of: nil, action: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onScrollGeometryChange(for: nil, of: nil, action: nil)) == AddOrderToWalletButton.self)
}

func testSynthOpacity() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.opacity(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.opacity(nil)) == AddOrderToWalletButton.self)
}

func testSynthPhaseAnimator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.phaseAnimator(nil, content: nil, animation: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.phaseAnimator(nil, trigger: nil, content: nil, animation: nil)
    precondition(type(of: button.phaseAnimator(nil, content: nil, animation: nil)) == AddOrderToWalletButton.self)
    _ = button.phaseAnimator(nil, trigger: nil, content: nil, animation: nil)
}

func testSynthPresentationBackground() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationBackground(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.presentationBackground(alignment: nil, content: nil)
    precondition(type(of: button.presentationBackground(nil)) == AddOrderToWalletButton.self)
    _ = button.presentationBackground(alignment: nil, content: nil)
}

func testSynthPresentationDragIndicator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationDragIndicator(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.presentationDragIndicator(nil)) == AddOrderToWalletButton.self)
}

func testSynthPreviewLayout() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.previewLayout(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.previewLayout(nil)) == AddOrderToWalletButton.self)
}

func testSynthRenameAction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.renameAction(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.renameAction(nil)) == AddOrderToWalletButton.self)
}

func testSynthSafeAreaPadding() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.safeAreaPadding(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.safeAreaPadding(nil, nil)
    precondition(type(of: button.safeAreaPadding(nil)) == AddOrderToWalletButton.self)
    _ = button.safeAreaPadding(nil, nil)
}

func testSynthScrollBounceBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollBounceBehavior(nil, axes: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollBounceBehavior(nil, axes: nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollEdgeEffectStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollEdgeEffectStyle(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollEdgeEffectStyle(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollTargetLayout() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollTargetLayout(isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollTargetLayout(isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthSearchScopes() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchScopes(nil, activation: nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.searchScopes(nil, scopes: nil)
    precondition(type(of: button.searchScopes(nil, activation: nil, nil)) == AddOrderToWalletButton.self)
    _ = button.searchScopes(nil, scopes: nil)
}

func testSynthSectionIndexLabel() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.sectionIndexLabel(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.sectionIndexLabel(nil)) == AddOrderToWalletButton.self)
}

func testSynthSliderThumbVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.sliderThumbVisibility(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.sliderThumbVisibility(nil)) == AddOrderToWalletButton.self)
}

func testSynthStatusBar() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.statusBar(hidden: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.statusBar(hidden: nil)) == AddOrderToWalletButton.self)
}

func testSynthSymbolColorRenderingMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.symbolColorRenderingMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.symbolColorRenderingMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabBarMinimizeBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabBarMinimizeBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabBarMinimizeBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewSidebarFooter() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewSidebarFooter(content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewSidebarFooter(content: nil)) == AddOrderToWalletButton.self)
}

func testSynthTask() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.task(id: nil, name: nil, executorPreference: nil, priority: nil, file: nil, line: nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.task(id: nil, priority: nil, nil)
    _ = picker.task(priority: nil, nil)
    precondition(type(of: button.task(id: nil, name: nil, executorPreference: nil, priority: nil, file: nil, line: nil, nil)) == AddOrderToWalletButton.self)
    _ = button.task(id: nil, priority: nil, nil)
    _ = button.task(priority: nil, nil)
}

func testSynthTextInputFormattingControlVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textInputFormattingControlVisibility(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textInputFormattingControlVisibility(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthToggleStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toggleStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toggleStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarRole() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarRole(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarRole(nil)) == AddOrderToWalletButton.self)
}

func testSynthTransformAnchorPreference() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.transformAnchorPreference(key: nil, value: nil, transform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.transformAnchorPreference(key: nil, value: nil, transform: nil)) == AddOrderToWalletButton.self)
}

func testSynthTypeSelectEquivalent() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.typeSelectEquivalent(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.typeSelectEquivalent(nil)) == AddOrderToWalletButton.self)
}

func testSynthWindowToolbarFullScreenVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.windowToolbarFullScreenVisibility(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.windowToolbarFullScreenVisibility(nil)) == AddOrderToWalletButton.self)
}
