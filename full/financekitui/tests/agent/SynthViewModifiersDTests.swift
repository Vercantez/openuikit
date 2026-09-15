import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testSynthAccessibilityActions() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityActions(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityActions(category: nil, nil)
    precondition(type(of: button.accessibilityActions(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityActions(category: nil, nil)
}

func testSynthAccessibilityCustomContent() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityCustomContent(nil, nil, importance: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityCustomContent(nil, nil, importance: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityFocused() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityFocused(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityFocused(nil, equals: nil)
    precondition(type(of: button.accessibilityFocused(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityFocused(nil, equals: nil)
}

func testSynthAccessibilityInputLabels() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityInputLabels(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityInputLabels(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityInputLabels(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityInputLabels(nil, isEnabled: nil)
}

func testSynthAccessibilityRespondsToUserInteraction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityRespondsToUserInteraction(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityRespondsToUserInteraction(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityRespondsToUserInteraction(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityRespondsToUserInteraction(nil, isEnabled: nil)
}

func testSynthAccessibilitySortPriority() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilitySortPriority(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilitySortPriority(nil)) == AddOrderToWalletButton.self)
}

func testSynthAlignmentGuide() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.alignmentGuide(nil, computeValue: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.alignmentGuide(nil, computeValue: nil)) == AddOrderToWalletButton.self)
}

func testSynthAnimation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.animation(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.animation(nil, body: nil)
    _ = picker.animation(nil, value: nil)
    precondition(type(of: button.animation(nil)) == AddOrderToWalletButton.self)
    _ = button.animation(nil, body: nil)
    _ = button.animation(nil, value: nil)
}

func testSynthBackground() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.background(nil, alignment: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.background(nil, ignoresSafeAreaEdges: nil)
    _ = picker.background(nil, in: nil, fillStyle: nil)
    _ = picker.background(alignment: nil, content: nil)
    _ = picker.background(ignoresSafeAreaEdges: nil)
    _ = picker.background(in: nil, fillStyle: nil)
    precondition(type(of: button.background(nil, alignment: nil)) == AddOrderToWalletButton.self)
    _ = button.background(nil, ignoresSafeAreaEdges: nil)
    _ = button.background(nil, in: nil, fillStyle: nil)
    _ = button.background(alignment: nil, content: nil)
    _ = button.background(ignoresSafeAreaEdges: nil)
    _ = button.background(in: nil, fillStyle: nil)
}

func testSynthBaselineOffset() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.baselineOffset(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.baselineOffset(nil)) == AddOrderToWalletButton.self)
}

func testSynthButtonBorderShape() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.buttonBorderShape(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.buttonBorderShape(nil)) == AddOrderToWalletButton.self)
}

func testSynthColorEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.colorEffect(nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.colorEffect(nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthContainerBackground() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.containerBackground(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.containerBackground(for: nil, alignment: nil, content: nil)
    precondition(type(of: button.containerBackground(nil, for: nil)) == AddOrderToWalletButton.self)
    _ = button.containerBackground(for: nil, alignment: nil, content: nil)
}

func testSynthContentShape() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.contentShape(nil, nil, eoFill: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.contentShape(nil, eoFill: nil)
    precondition(type(of: button.contentShape(nil, nil, eoFill: nil)) == AddOrderToWalletButton.self)
    _ = button.contentShape(nil, eoFill: nil)
}

func testSynthControlSize() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.controlSize(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.controlSize(nil)) == AddOrderToWalletButton.self)
}

func testSynthDefaultFocus() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.defaultFocus(nil, nil, priority: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.defaultFocus(nil, nil, priority: nil)) == AddOrderToWalletButton.self)
}

func testSynthDialogSuppressionToggle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.dialogSuppressionToggle(nil, isSuppressed: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.dialogSuppressionToggle(isSuppressed: nil)
    precondition(type(of: button.dialogSuppressionToggle(nil, isSuppressed: nil)) == AddOrderToWalletButton.self)
    _ = button.dialogSuppressionToggle(isSuppressed: nil)
}

func testSynthDraggable() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.draggable(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.draggable(nil, preview: nil)
    precondition(type(of: button.draggable(nil)) == AddOrderToWalletButton.self)
    _ = button.draggable(nil, preview: nil)
}

func testSynthEnvironmentObject() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.environmentObject(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.environmentObject(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileDialogMessage() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogMessage(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogMessage(nil)) == AddOrderToWalletButton.self)
}

func testSynthFindDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.findDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.findDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthFocused() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focused(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.focused(nil, equals: nil)
    precondition(type(of: button.focused(nil)) == AddOrderToWalletButton.self)
    _ = button.focused(nil, equals: nil)
}

func testSynthFontDesign() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fontDesign(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fontDesign(nil)) == AddOrderToWalletButton.self)
}

func testSynthFrame() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.frame()) == TransactionPicker<EmptyView>.self)
    _ = picker.frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: nil)
    _ = picker.frame(width: nil, height: nil, alignment: nil)
    precondition(type(of: button.frame()) == AddOrderToWalletButton.self)
    _ = button.frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: nil)
    _ = button.frame(width: nil, height: nil, alignment: nil)
}

func testSynthGlassEffectID() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.glassEffectID(nil, in: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.glassEffectID(nil, in: nil)) == AddOrderToWalletButton.self)
}

func testSynthGridCellUnsizedAxes() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.gridCellUnsizedAxes(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.gridCellUnsizedAxes(nil)) == AddOrderToWalletButton.self)
}

func testSynthHelp() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.help(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.help(nil)) == AddOrderToWalletButton.self)
}

func testSynthId() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.id(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.id(nil)) == AddOrderToWalletButton.self)
}

func testSynthInteractionActivityTrackingTag() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.interactionActivityTrackingTag(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.interactionActivityTrackingTag(nil)) == AddOrderToWalletButton.self)
}

func testSynthKeyboardShortcut() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.keyboardShortcut(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.keyboardShortcut(nil, modifiers: nil)
    _ = picker.keyboardShortcut(nil, modifiers: nil, localization: nil)
    precondition(type(of: button.keyboardShortcut(nil)) == AddOrderToWalletButton.self)
    _ = button.keyboardShortcut(nil, modifiers: nil)
    _ = button.keyboardShortcut(nil, modifiers: nil, localization: nil)
}

func testSynthLabeledContentStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.labeledContentStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.labeledContentStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthLayoutValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.layoutValue(key: nil, value: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.layoutValue(key: nil, value: nil)) == AddOrderToWalletButton.self)
}

func testSynthListRowInsets() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listRowInsets(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.listRowInsets(nil, nil)
    precondition(type(of: button.listRowInsets(nil)) == AddOrderToWalletButton.self)
    _ = button.listRowInsets(nil, nil)
}

func testSynthListSectionSeparator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listSectionSeparator(nil, edges: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listSectionSeparator(nil, edges: nil)) == AddOrderToWalletButton.self)
}

func testSynthMatchedGeometryEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.matchedGeometryEffect(id: nil, in: nil, properties: nil, anchor: nil, isSource: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.matchedGeometryEffect(id: nil, in: nil, properties: nil, anchor: nil, isSource: nil)) == AddOrderToWalletButton.self)
}

func testSynthMenuStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.menuStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.menuStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthMultilineTextAlignment() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.multilineTextAlignment(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.multilineTextAlignment(strategy: nil)
    precondition(type(of: button.multilineTextAlignment(nil)) == AddOrderToWalletButton.self)
    _ = button.multilineTextAlignment(strategy: nil)
}

func testSynthNavigationDestination() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationDestination(for: nil, destination: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.navigationDestination(isPresented: nil, destination: nil)
    _ = picker.navigationDestination(item: nil, destination: nil)
    precondition(type(of: button.navigationDestination(for: nil, destination: nil)) == AddOrderToWalletButton.self)
    _ = button.navigationDestination(isPresented: nil, destination: nil)
    _ = button.navigationDestination(item: nil, destination: nil)
}

func testSynthNavigationTitle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationTitle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationTitle(nil)) == AddOrderToWalletButton.self)
}

func testSynthOnContinueUserActivity() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onContinueUserActivity(nil, perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onContinueUserActivity(nil, perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnHover() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onHover(perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onHover(perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnPencilSqueeze() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onPencilSqueeze(perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onPencilSqueeze(perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnScrollVisibilityChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onScrollVisibilityChange(threshold: nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onScrollVisibilityChange(threshold: nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthPadding() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.padding(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.padding(nil, nil)
    precondition(type(of: button.padding(nil)) == AddOrderToWalletButton.self)
    _ = button.padding(nil, nil)
}

func testSynthPosition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.position(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.position(x: nil, y: nil)
    precondition(type(of: button.position(nil)) == AddOrderToWalletButton.self)
    _ = button.position(x: nil, y: nil)
}

func testSynthPresentationContentInteraction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationContentInteraction(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.presentationContentInteraction(nil)) == AddOrderToWalletButton.self)
}

func testSynthPreviewDevice() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.previewDevice(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.previewDevice(nil)) == AddOrderToWalletButton.self)
}

func testSynthProjectionEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.projectionEffect(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.projectionEffect(nil)) == AddOrderToWalletButton.self)
}

func testSynthRotationEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.rotationEffect(nil, anchor: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.rotationEffect(nil, anchor: nil)) == AddOrderToWalletButton.self)
}

func testSynthScaledToFill() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scaledToFill()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scaledToFill()) == AddOrderToWalletButton.self)
}

func testSynthScrollDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollInputBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollInputBehavior(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollInputBehavior(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthSearchDictationBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchDictationBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.searchDictationBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthSearchToolbarBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchToolbarBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.searchToolbarBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthShadow() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.shadow(color: nil, radius: nil, x: nil, y: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.shadow(color: nil, radius: nil, x: nil, y: nil)) == AddOrderToWalletButton.self)
}

func testSynthSpeechAnnouncementsQueued() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.speechAnnouncementsQueued(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.speechAnnouncementsQueued(nil)) == AddOrderToWalletButton.self)
}

func testSynthSubmitLabel() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.submitLabel(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.submitLabel(nil)) == AddOrderToWalletButton.self)
}

func testSynthSymbolRenderingMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.symbolRenderingMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.symbolRenderingMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewCustomization() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewCustomization(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewCustomization(nil)) == AddOrderToWalletButton.self)
}

func testSynthTableColumnHeaders() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tableColumnHeaders(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tableColumnHeaders(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextEditorStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textEditorStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textEditorStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextSelection() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textSelection(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textSelection(nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarBackgroundVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarBackgroundVisibility(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarBackgroundVisibility(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarVisibility(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarVisibility(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthTransformPreference() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.transformPreference(nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.transformPreference(nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthUnredacted() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.unredacted()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.unredacted()) == AddOrderToWalletButton.self)
}

func testSynthWritingToolsBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.writingToolsBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.writingToolsBehavior(nil)) == AddOrderToWalletButton.self)
}
