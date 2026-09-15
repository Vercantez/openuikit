import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testSynthAccessibilityAddTraits() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityAddTraits(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityAddTraits(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityDirectTouch() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityDirectTouch(nil, options: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityDirectTouch(nil, options: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityHidden(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityHidden(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityHidden(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityHidden(nil, isEnabled: nil)
}

func testSynthAccessibilityLabeledPair() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityLabeledPair(role: nil, id: nil, in: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityLabeledPair(role: nil, id: nil, in: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityRotorEntry() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityRotorEntry(id: nil, in: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityRotorEntry(id: nil, in: nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityValue(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityValue(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityValue(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityValue(nil, isEnabled: nil)
}

func testSynthAllowsHitTesting() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.allowsHitTesting(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.allowsHitTesting(nil)) == AddOrderToWalletButton.self)
}

func testSynthAssistiveAccessNavigationIcon() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.assistiveAccessNavigationIcon(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.assistiveAccessNavigationIcon(systemImage: nil)
    precondition(type(of: button.assistiveAccessNavigationIcon(nil)) == AddOrderToWalletButton.self)
    _ = button.assistiveAccessNavigationIcon(systemImage: nil)
}

func testSynthBackgroundPreferenceValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.backgroundPreferenceValue(nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.backgroundPreferenceValue(nil, alignment: nil, nil)
    precondition(type(of: button.backgroundPreferenceValue(nil, nil)) == AddOrderToWalletButton.self)
    _ = button.backgroundPreferenceValue(nil, alignment: nil, nil)
}

func testSynthBlur() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.blur(radius: nil, opaque: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.blur(radius: nil, opaque: nil)) == AddOrderToWalletButton.self)
}

func testSynthButtonSizing() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.buttonSizing(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.buttonSizing(nil)) == AddOrderToWalletButton.self)
}

func testSynthColorMultiply() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.colorMultiply(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.colorMultiply(nil)) == AddOrderToWalletButton.self)
}

func testSynthContainerRelativeFrame() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.containerRelativeFrame(nil, alignment: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.containerRelativeFrame(nil, alignment: nil, nil)
    _ = picker.containerRelativeFrame(nil, count: nil, span: nil, spacing: nil, alignment: nil)
    precondition(type(of: button.containerRelativeFrame(nil, alignment: nil)) == AddOrderToWalletButton.self)
    _ = button.containerRelativeFrame(nil, alignment: nil, nil)
    _ = button.containerRelativeFrame(nil, count: nil, span: nil, spacing: nil, alignment: nil)
}

func testSynthContentTransition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.contentTransition(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.contentTransition(nil)) == AddOrderToWalletButton.self)
}

func testSynthCornerRadius() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.cornerRadius(nil, antialiased: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.cornerRadius(nil, antialiased: nil)) == AddOrderToWalletButton.self)
}

func testSynthDefaultScrollAnchor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.defaultScrollAnchor(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.defaultScrollAnchor(nil, for: nil)
    precondition(type(of: button.defaultScrollAnchor(nil)) == AddOrderToWalletButton.self)
    _ = button.defaultScrollAnchor(nil, for: nil)
}

func testSynthDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.disabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.disabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthDropDestination() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.dropDestination(for: nil, action: nil, isTargeted: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.dropDestination(for: nil, isEnabled: nil, action: nil)
    precondition(type(of: button.dropDestination(for: nil, action: nil, isTargeted: nil)) == AddOrderToWalletButton.self)
    _ = button.dropDestination(for: nil, isEnabled: nil, action: nil)
}

func testSynthFileDialogConfirmationLabel() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogConfirmationLabel(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogConfirmationLabel(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileExporter() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileExporter(isPresented: nil, document: nil, contentType: nil, defaultFilename: nil, onCompletion: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.fileExporter(isPresented: nil, document: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = picker.fileExporter(isPresented: nil, documents: nil, contentType: nil, onCompletion: nil)
    _ = picker.fileExporter(isPresented: nil, documents: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    _ = picker.fileExporter(isPresented: nil, item: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = picker.fileExporter(isPresented: nil, items: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    precondition(type(of: button.fileExporter(isPresented: nil, document: nil, contentType: nil, defaultFilename: nil, onCompletion: nil)) == AddOrderToWalletButton.self)
    _ = button.fileExporter(isPresented: nil, document: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileExporter(isPresented: nil, documents: nil, contentType: nil, onCompletion: nil)
    _ = button.fileExporter(isPresented: nil, documents: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileExporter(isPresented: nil, item: nil, contentTypes: nil, defaultFilename: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileExporter(isPresented: nil, items: nil, contentTypes: nil, onCompletion: nil, onCancellation: nil)
}

func testSynthFixedSize() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fixedSize()) == TransactionPicker<EmptyView>.self)
    _ = picker.fixedSize(horizontal: nil, vertical: nil)
    precondition(type(of: button.fixedSize()) == AddOrderToWalletButton.self)
    _ = button.fixedSize(horizontal: nil, vertical: nil)
}

func testSynthFocusedSceneObject() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focusedSceneObject(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.focusedSceneObject(nil)) == AddOrderToWalletButton.self)
}

func testSynthFontWidth() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fontWidth(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fontWidth(nil)) == AddOrderToWalletButton.self)
}

func testSynthGaugeStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.gaugeStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.gaugeStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthGlassEffectUnion() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.glassEffectUnion(id: nil, namespace: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.glassEffectUnion(id: nil, namespace: nil)) == AddOrderToWalletButton.self)
}

func testSynthGroupBoxStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.groupBoxStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.groupBoxStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthHighPriorityGesture() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.highPriorityGesture(nil, including: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.highPriorityGesture(nil, isEnabled: nil)
    _ = picker.highPriorityGesture(nil, name: nil, isEnabled: nil)
    precondition(type(of: button.highPriorityGesture(nil, including: nil)) == AddOrderToWalletButton.self)
    _ = button.highPriorityGesture(nil, isEnabled: nil)
    _ = button.highPriorityGesture(nil, name: nil, isEnabled: nil)
}

func testSynthImageScale() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.imageScale(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.imageScale(nil)) == AddOrderToWalletButton.self)
}

func testSynthInvalidatableContent() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.invalidatableContent(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.invalidatableContent(nil)) == AddOrderToWalletButton.self)
}

func testSynthKeyframeAnimator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.keyframeAnimator(initialValue: nil, repeating: nil, content: nil, keyframes: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.keyframeAnimator(initialValue: nil, trigger: nil, content: nil, keyframes: nil)
    precondition(type(of: button.keyframeAnimator(initialValue: nil, repeating: nil, content: nil, keyframes: nil)) == AddOrderToWalletButton.self)
    _ = button.keyframeAnimator(initialValue: nil, trigger: nil, content: nil, keyframes: nil)
}

func testSynthLabelsVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.labelsVisibility(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.labelsVisibility(nil)) == AddOrderToWalletButton.self)
}

func testSynthLineLimit() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.lineLimit(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.lineLimit(nil, reservesSpace: nil)
    precondition(type(of: button.lineLimit(nil)) == AddOrderToWalletButton.self)
    _ = button.lineLimit(nil, reservesSpace: nil)
}

func testSynthListRowSeparatorTint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listRowSeparatorTint(nil, edges: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listRowSeparatorTint(nil, edges: nil)) == AddOrderToWalletButton.self)
}

func testSynthListSectionSpacing() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listSectionSpacing(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listSectionSpacing(nil)) == AddOrderToWalletButton.self)
}

func testSynthMaterialActiveAppearance() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.materialActiveAppearance(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.materialActiveAppearance(nil)) == AddOrderToWalletButton.self)
}

func testSynthModifier() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.modifier(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.modifier(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationBarHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationBarHidden(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationBarHidden(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationLinkIndicatorVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationLinkIndicatorVisibility(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationLinkIndicatorVisibility(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationViewStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationViewStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationViewStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthOnDisappear() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onDisappear(perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onDisappear(perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnKeyPress() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onKeyPress(nil, action: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onKeyPress(nil, phases: nil, action: nil)
    _ = picker.onKeyPress(characters: nil, phases: nil, action: nil)
    _ = picker.onKeyPress(keys: nil, phases: nil, action: nil)
    _ = picker.onKeyPress(phases: nil, action: nil)
    precondition(type(of: button.onKeyPress(nil, action: nil)) == AddOrderToWalletButton.self)
    _ = button.onKeyPress(nil, phases: nil, action: nil)
    _ = button.onKeyPress(characters: nil, phases: nil, action: nil)
    _ = button.onKeyPress(keys: nil, phases: nil, action: nil)
    _ = button.onKeyPress(phases: nil, action: nil)
}

func testSynthOnReceive() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onReceive(nil, perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onReceive(nil, perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnTapGesture() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onTapGesture(count: nil, coordinateSpace: nil, perform: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onTapGesture(count: nil, perform: nil)
    precondition(type(of: button.onTapGesture(count: nil, coordinateSpace: nil, perform: nil)) == AddOrderToWalletButton.self)
    _ = button.onTapGesture(count: nil, perform: nil)
}

func testSynthPersistentSystemOverlays() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.persistentSystemOverlays(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.persistentSystemOverlays(nil)) == AddOrderToWalletButton.self)
}

func testSynthPreferredColorScheme() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.preferredColorScheme(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.preferredColorScheme(nil)) == AddOrderToWalletButton.self)
}

func testSynthPresentationDetents() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationDetents(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.presentationDetents(nil, selection: nil)
    precondition(type(of: button.presentationDetents(nil)) == AddOrderToWalletButton.self)
    _ = button.presentationDetents(nil, selection: nil)
}

func testSynthPreviewInterfaceOrientation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.previewInterfaceOrientation(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.previewInterfaceOrientation(nil)) == AddOrderToWalletButton.self)
}

func testSynthRefreshable() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.refreshable(action: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.refreshable(action: nil)) == AddOrderToWalletButton.self)
}

func testSynthSafeAreaInset() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.safeAreaInset(edge: nil, alignment: nil, spacing: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.safeAreaInset(edge: nil, alignment: nil, spacing: nil, content: nil)) == AddOrderToWalletButton.self)
}

func testSynthScenePadding() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scenePadding(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.scenePadding(nil, edges: nil)
    precondition(type(of: button.scenePadding(nil)) == AddOrderToWalletButton.self)
    _ = button.scenePadding(nil, edges: nil)
}

func testSynthScrollEdgeEffectHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollEdgeEffectHidden(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollEdgeEffectHidden(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollTargetBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollTargetBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollTargetBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthSearchPresentationToolbarBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchPresentationToolbarBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.searchPresentationToolbarBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthSectionActions() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.sectionActions(content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.sectionActions(content: nil)) == AddOrderToWalletButton.self)
}

func testSynthSimultaneousGesture() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.simultaneousGesture(nil, including: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.simultaneousGesture(nil, isEnabled: nil)
    _ = picker.simultaneousGesture(nil, name: nil, isEnabled: nil)
    precondition(type(of: button.simultaneousGesture(nil, including: nil)) == AddOrderToWalletButton.self)
    _ = button.simultaneousGesture(nil, isEnabled: nil)
    _ = button.simultaneousGesture(nil, name: nil, isEnabled: nil)
}

func testSynthSpringLoadingBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.springLoadingBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.springLoadingBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthSwipeActions() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.swipeActions(edge: nil, allowsFullSwipe: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.swipeActions(edge: nil, allowsFullSwipe: nil, content: nil)) == AddOrderToWalletButton.self)
}

func testSynthSymbolVariant() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.symbolVariant(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.symbolVariant(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewSidebarBottomBar() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewSidebarBottomBar(content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewSidebarBottomBar(content: nil)) == AddOrderToWalletButton.self)
}

func testSynthTag() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tag(nil, includeOptional: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tag(nil, includeOptional: nil)) == AddOrderToWalletButton.self)
}

func testSynthTextInputAutocapitalization() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textInputAutocapitalization(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textInputAutocapitalization(nil)) == AddOrderToWalletButton.self)
}

func testSynthTint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tint(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tint(nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarForegroundStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarForegroundStyle(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarForegroundStyle(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthTransaction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.transaction(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.transaction(nil, body: nil)
    _ = picker.transaction(value: nil, nil)
    precondition(type(of: button.transaction(nil)) == AddOrderToWalletButton.self)
    _ = button.transaction(nil, body: nil)
    _ = button.transaction(value: nil, nil)
}

func testSynthTruncationMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.truncationMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.truncationMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthVisualEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.visualEffect(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.visualEffect(nil)) == AddOrderToWalletButton.self)
}
