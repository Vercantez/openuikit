import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testSynthAccessibilityActivationPoint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityActivationPoint(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityActivationPoint(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityActivationPoint(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityActivationPoint(nil, isEnabled: nil)
}

func testSynthAccessibilityDefaultFocus() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityDefaultFocus(nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityDefaultFocus(nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityHeading() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityHeading(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityHeading(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityLabel() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityLabel(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityLabel(nil, isEnabled: nil)
    _ = picker.accessibilityLabel(content: nil)
    precondition(type(of: button.accessibilityLabel(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityLabel(nil, isEnabled: nil)
    _ = button.accessibilityLabel(content: nil)
}

func testSynthAccessibilityRotor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityRotor(nil, entries: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityRotor(nil, entries: nil, entryID: nil, entryLabel: nil)
    _ = picker.accessibilityRotor(nil, entries: nil, entryLabel: nil)
    _ = picker.accessibilityRotor(nil, textRanges: nil)
    precondition(type(of: button.accessibilityRotor(nil, entries: nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityRotor(nil, entries: nil, entryID: nil, entryLabel: nil)
    _ = button.accessibilityRotor(nil, entries: nil, entryLabel: nil)
    _ = button.accessibilityRotor(nil, textRanges: nil)
}

func testSynthAccessibilityTextContentType() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityTextContentType(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityTextContentType(nil)) == AddOrderToWalletButton.self)
}

func testSynthAllowedDynamicRange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.allowedDynamicRange(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.allowedDynamicRange(nil)) == AddOrderToWalletButton.self)
}

func testSynthAspectRatio() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.aspectRatio(nil, contentMode: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.aspectRatio(nil, contentMode: nil)) == AddOrderToWalletButton.self)
}

func testSynthBackgroundExtensionEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.backgroundExtensionEffect()) == TransactionPicker<EmptyView>.self)
    _ = picker.backgroundExtensionEffect(isEnabled: nil)
    precondition(type(of: button.backgroundExtensionEffect()) == AddOrderToWalletButton.self)
    _ = button.backgroundExtensionEffect(isEnabled: nil)
}

func testSynthBlendMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.blendMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.blendMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthButtonRepeatBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.buttonRepeatBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.buttonRepeatBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthColorInvert() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.colorInvert()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.colorInvert()) == AddOrderToWalletButton.self)
}

func testSynthContainerCornerOffset() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.containerCornerOffset(nil, sizeToFit: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.containerCornerOffset(nil, sizeToFit: nil)) == AddOrderToWalletButton.self)
}

func testSynthContentToolbar() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.contentToolbar(for: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.contentToolbar(for: nil, content: nil)) == AddOrderToWalletButton.self)
}

func testSynthCoordinateSpace() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.coordinateSpace(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.coordinateSpace(name: nil)
    precondition(type(of: button.coordinateSpace(nil)) == AddOrderToWalletButton.self)
    _ = button.coordinateSpace(name: nil)
}

func testSynthDefaultHoverEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.defaultHoverEffect(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.defaultHoverEffect(nil)) == AddOrderToWalletButton.self)
}

func testSynthDisableAutocorrection() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.disableAutocorrection(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.disableAutocorrection(nil)) == AddOrderToWalletButton.self)
}

func testSynthDrawingGroup() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.drawingGroup(opaque: nil, colorMode: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.drawingGroup(opaque: nil, colorMode: nil)) == AddOrderToWalletButton.self)
}

func testSynthFileDialogBrowserOptions() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogBrowserOptions(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogBrowserOptions(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileDialogURLEnabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogURLEnabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogURLEnabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthFindNavigator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.findNavigator(isPresented: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.findNavigator(isPresented: nil)) == AddOrderToWalletButton.self)
}

func testSynthFocusedObject() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focusedObject(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.focusedObject(nil)) == AddOrderToWalletButton.self)
}

func testSynthFontWeight() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fontWeight(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fontWeight(nil)) == AddOrderToWalletButton.self)
}

func testSynthFullScreenCover() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fullScreenCover(isPresented: nil, onDismiss: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.fullScreenCover(item: nil, onDismiss: nil, content: nil)
    precondition(type(of: button.fullScreenCover(isPresented: nil, onDismiss: nil, content: nil)) == AddOrderToWalletButton.self)
    _ = button.fullScreenCover(item: nil, onDismiss: nil, content: nil)
}

func testSynthGlassEffectTransition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.glassEffectTransition(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.glassEffectTransition(nil)) == AddOrderToWalletButton.self)
}

func testSynthGridColumnAlignment() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.gridColumnAlignment(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.gridColumnAlignment(nil)) == AddOrderToWalletButton.self)
}

func testSynthHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.hidden()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.hidden()) == AddOrderToWalletButton.self)
}

func testSynthIgnoresSafeArea() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.ignoresSafeArea(nil, edges: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.ignoresSafeArea(nil, edges: nil)) == AddOrderToWalletButton.self)
}

func testSynthInteractiveDismissDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.interactiveDismissDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.interactiveDismissDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthKeyboardType() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.keyboardType(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.keyboardType(nil)) == AddOrderToWalletButton.self)
}

func testSynthLabelsHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.labelsHidden()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.labelsHidden()) == AddOrderToWalletButton.self)
}

func testSynthLineHeight() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.lineHeight(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.lineHeight(nil)) == AddOrderToWalletButton.self)
}

func testSynthListRowSeparator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listRowSeparator(nil, edges: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listRowSeparator(nil, edges: nil)) == AddOrderToWalletButton.self)
}

func testSynthListSectionSeparatorTint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listSectionSeparatorTint(nil, edges: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listSectionSeparatorTint(nil, edges: nil)) == AddOrderToWalletButton.self)
}

func testSynthMatchedTransitionSource() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.matchedTransitionSource(id: nil, in: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.matchedTransitionSource(id: nil, in: nil, configuration: nil)
    precondition(type(of: button.matchedTransitionSource(id: nil, in: nil)) == AddOrderToWalletButton.self)
    _ = button.matchedTransitionSource(id: nil, in: nil, configuration: nil)
}

func testSynthMinimumScaleFactor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.minimumScaleFactor(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.minimumScaleFactor(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationBarBackButtonHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationBarBackButtonHidden(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationBarBackButtonHidden(nil)) == AddOrderToWalletButton.self)
}

func testSynthNavigationDocument() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationDocument(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.navigationDocument(nil, preview: nil)
    precondition(type(of: button.navigationDocument(nil)) == AddOrderToWalletButton.self)
    _ = button.navigationDocument(nil, preview: nil)
}

func testSynthNavigationTransition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationTransition(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationTransition(nil)) == AddOrderToWalletButton.self)
}

func testSynthOnContinuousHover() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onContinuousHover(coordinateSpace: nil, perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onContinuousHover(coordinateSpace: nil, perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnInteractiveResizeChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onInteractiveResizeChange(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onInteractiveResizeChange(nil)) == AddOrderToWalletButton.self)
}

func testSynthOnPreferenceChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onPreferenceChange(nil, perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onPreferenceChange(nil, perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnSubmit() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onSubmit(of: nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onSubmit(of: nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthPaletteSelectionEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.paletteSelectionEffect(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.paletteSelectionEffect(nil)) == AddOrderToWalletButton.self)
}

func testSynthPreference() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.preference(key: nil, value: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.preference(key: nil, value: nil)) == AddOrderToWalletButton.self)
}

func testSynthPresentationCornerRadius() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationCornerRadius(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.presentationCornerRadius(nil)) == AddOrderToWalletButton.self)
}

func testSynthPreviewDisplayName() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.previewDisplayName(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.previewDisplayName(nil)) == AddOrderToWalletButton.self)
}

func testSynthRedacted() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.redacted(reason: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.redacted(reason: nil)) == AddOrderToWalletButton.self)
}

func testSynthSafeAreaBar() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.safeAreaBar(edge: nil, alignment: nil, spacing: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.safeAreaBar(edge: nil, alignment: nil, spacing: nil, content: nil)) == AddOrderToWalletButton.self)
}

func testSynthScaledToFit() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scaledToFit()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scaledToFit()) == AddOrderToWalletButton.self)
}

func testSynthScrollDismissesKeyboard() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollDismissesKeyboard(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollDismissesKeyboard(nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollPosition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollPosition(nil, anchor: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.scrollPosition(id: nil, anchor: nil)
    precondition(type(of: button.scrollPosition(nil, anchor: nil)) == AddOrderToWalletButton.self)
    _ = button.scrollPosition(id: nil, anchor: nil)
}

func testSynthSearchFocused() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchFocused(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.searchFocused(nil, equals: nil)
    precondition(type(of: button.searchFocused(nil)) == AddOrderToWalletButton.self)
    _ = button.searchFocused(nil, equals: nil)
}

func testSynthSearchable() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchable(text: nil, editableTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.searchable(text: nil, editableTokens: nil, placement: nil, prompt: nil, token: nil)
    _ = picker.searchable(text: nil, isPresented: nil, placement: nil, prompt: nil)
    _ = picker.searchable(text: nil, placement: nil, prompt: nil)
    _ = picker.searchable(text: nil, placement: nil, prompt: nil, suggestions: nil)
    _ = picker.searchable(text: nil, tokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = picker.searchable(text: nil, tokens: nil, placement: nil, prompt: nil, token: nil)
    _ = picker.searchable(text: nil, tokens: nil, suggestedTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = picker.searchable(text: nil, tokens: nil, suggestedTokens: nil, placement: nil, prompt: nil, token: nil)
    precondition(type(of: button.searchable(text: nil, editableTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)) == AddOrderToWalletButton.self)
    _ = button.searchable(text: nil, editableTokens: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, isPresented: nil, placement: nil, prompt: nil)
    _ = button.searchable(text: nil, placement: nil, prompt: nil)
    _ = button.searchable(text: nil, placement: nil, prompt: nil, suggestions: nil)
    _ = button.searchable(text: nil, tokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, tokens: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, tokens: nil, suggestedTokens: nil, isPresented: nil, placement: nil, prompt: nil, token: nil)
    _ = button.searchable(text: nil, tokens: nil, suggestedTokens: nil, placement: nil, prompt: nil, token: nil)
}

func testSynthSheet() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.sheet(isPresented: nil, onDismiss: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.sheet(item: nil, onDismiss: nil, content: nil)
    precondition(type(of: button.sheet(isPresented: nil, onDismiss: nil, content: nil)) == AddOrderToWalletButton.self)
    _ = button.sheet(item: nil, onDismiss: nil, content: nil)
}

func testSynthSpeechSpellsOutCharacters() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.speechSpellsOutCharacters(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.speechSpellsOutCharacters(nil)) == AddOrderToWalletButton.self)
}

func testSynthSubmitScope() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.submitScope(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.submitScope(nil)) == AddOrderToWalletButton.self)
}

func testSynthSymbolVariableValueMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.symbolVariableValueMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.symbolVariableValueMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewSearchActivation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewSearchActivation(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewSearchActivation(nil)) == AddOrderToWalletButton.self)
}

func testSynthTableStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tableStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tableStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextFieldStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textFieldStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textFieldStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextSelectionAffinity() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textSelectionAffinity(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textSelectionAffinity(nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbarColorScheme() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarColorScheme(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarColorScheme(nil, for: nil)) == AddOrderToWalletButton.self)
}

func testSynthTracking() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tracking(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tracking(nil)) == AddOrderToWalletButton.self)
}

func testSynthTransition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.transition(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.transition(nil)) == AddOrderToWalletButton.self)
}

func testSynthUserActivity() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.userActivity(nil, element: nil, nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.userActivity(nil, isActive: nil, nil)
    precondition(type(of: button.userActivity(nil, element: nil, nil)) == AddOrderToWalletButton.self)
    _ = button.userActivity(nil, isActive: nil, nil)
}

func testSynthZIndex() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.zIndex(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.zIndex(nil)) == AddOrderToWalletButton.self)
}
