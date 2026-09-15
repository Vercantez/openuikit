import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testSynthAccessibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibility(activationPoint: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibility(addTraits: nil)
    _ = picker.accessibility(hidden: nil)
    _ = picker.accessibility(hint: nil)
    _ = picker.accessibility(identifier: nil)
    _ = picker.accessibility(inputLabels: nil)
    _ = picker.accessibility(label: nil)
    _ = picker.accessibility(removeTraits: nil)
    _ = picker.accessibility(selectionIdentifier: nil)
    _ = picker.accessibility(sortPriority: nil)
    _ = picker.accessibility(value: nil)
    precondition(type(of: button.accessibility(activationPoint: nil)) == AddOrderToWalletButton.self)
    _ = button.accessibility(addTraits: nil)
    _ = button.accessibility(hidden: nil)
    _ = button.accessibility(hint: nil)
    _ = button.accessibility(identifier: nil)
    _ = button.accessibility(inputLabels: nil)
    _ = button.accessibility(label: nil)
    _ = button.accessibility(removeTraits: nil)
    _ = button.accessibility(selectionIdentifier: nil)
    _ = button.accessibility(sortPriority: nil)
    _ = button.accessibility(value: nil)
}

func testSynthAccessibilityChartDescriptor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityChartDescriptor(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityChartDescriptor(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityDropPoint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityDropPoint(nil, description: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityDropPoint(nil, description: nil, isEnabled: nil)
    precondition(type(of: button.accessibilityDropPoint(nil, description: nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityDropPoint(nil, description: nil, isEnabled: nil)
}

func testSynthAccessibilityIdentifier() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityIdentifier(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.accessibilityIdentifier(nil, isEnabled: nil)
    precondition(type(of: button.accessibilityIdentifier(nil)) == AddOrderToWalletButton.self)
    _ = button.accessibilityIdentifier(nil, isEnabled: nil)
}

func testSynthAccessibilityRemoveTraits() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityRemoveTraits(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityRemoveTraits(nil)) == AddOrderToWalletButton.self)
}

func testSynthAccessibilityScrollStatus() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.accessibilityScrollStatus(nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.accessibilityScrollStatus(nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthActionSheet() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.actionSheet(isPresented: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.actionSheet(item: nil, content: nil)
    precondition(type(of: button.actionSheet(isPresented: nil, content: nil)) == AddOrderToWalletButton.self)
    _ = button.actionSheet(item: nil, content: nil)
}

func testSynthAllowsWindowActivationEvents() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.allowsWindowActivationEvents()) == TransactionPicker<EmptyView>.self)
    _ = picker.allowsWindowActivationEvents(nil)
    precondition(type(of: button.allowsWindowActivationEvents()) == AddOrderToWalletButton.self)
    _ = button.allowsWindowActivationEvents(nil)
}

func testSynthAutocapitalization() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.autocapitalization(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.autocapitalization(nil)) == AddOrderToWalletButton.self)
}

func testSynthBadge() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.badge(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.badge(nil)) == AddOrderToWalletButton.self)
}

func testSynthBorder() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.border(nil, width: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.border(nil, width: nil)) == AddOrderToWalletButton.self)
}

func testSynthClipShape() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.clipShape(nil, style: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.clipShape(nil, style: nil)) == AddOrderToWalletButton.self)
}

func testSynthCompositingGroup() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.compositingGroup()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.compositingGroup()) == AddOrderToWalletButton.self)
}

func testSynthContainerValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.containerValue(nil, nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.containerValue(nil, nil)) == AddOrderToWalletButton.self)
}

func testSynthContrast() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.contrast(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.contrast(nil)) == AddOrderToWalletButton.self)
}

func testSynthDefaultAdaptableTabBarPlacement() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.defaultAdaptableTabBarPlacement(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.defaultAdaptableTabBarPlacement(nil)) == AddOrderToWalletButton.self)
}

func testSynthDeleteDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.deleteDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.deleteDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthDistortionEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.distortionEffect(nil, maxSampleOffset: nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.distortionEffect(nil, maxSampleOffset: nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthEdgesIgnoringSafeArea() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.edgesIgnoringSafeArea(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.edgesIgnoringSafeArea(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileDialogDefaultDirectory() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileDialogDefaultDirectory(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.fileDialogDefaultDirectory(nil)) == AddOrderToWalletButton.self)
}

func testSynthFileImporter() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil, onCancellation: nil)
    _ = picker.fileImporter(isPresented: nil, allowedContentTypes: nil, onCompletion: nil)
    precondition(type(of: button.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil)) == AddOrderToWalletButton.self)
    _ = button.fileImporter(isPresented: nil, allowedContentTypes: nil, allowsMultipleSelection: nil, onCompletion: nil, onCancellation: nil)
    _ = button.fileImporter(isPresented: nil, allowedContentTypes: nil, onCompletion: nil)
}

func testSynthFocusEffectDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focusEffectDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.focusEffectDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthFocusedValue() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.focusedValue(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.focusedValue(nil, nil)
    precondition(type(of: button.focusedValue(nil)) == AddOrderToWalletButton.self)
    _ = button.focusedValue(nil, nil)
}

func testSynthForegroundStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.foregroundStyle(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.foregroundStyle(nil, nil)
    _ = picker.foregroundStyle(nil, nil, nil)
    precondition(type(of: button.foregroundStyle(nil)) == AddOrderToWalletButton.self)
    _ = button.foregroundStyle(nil, nil)
    _ = button.foregroundStyle(nil, nil, nil)
}

func testSynthGesture() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.gesture(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.gesture(nil, including: nil)
    _ = picker.gesture(nil, isEnabled: nil)
    _ = picker.gesture(nil, name: nil, isEnabled: nil)
    precondition(type(of: button.gesture(nil)) == AddOrderToWalletButton.self)
    _ = button.gesture(nil, including: nil)
    _ = button.gesture(nil, isEnabled: nil)
    _ = button.gesture(nil, name: nil, isEnabled: nil)
}

func testSynthGridCellAnchor() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.gridCellAnchor(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.gridCellAnchor(nil)) == AddOrderToWalletButton.self)
}

func testSynthHandlesExternalEvents() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.handlesExternalEvents(preferring: nil, allowing: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.handlesExternalEvents(preferring: nil, allowing: nil)) == AddOrderToWalletButton.self)
}

func testSynthHoverEffectDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.hoverEffectDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.hoverEffectDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthInspector() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.inspector(isPresented: nil, content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.inspector(isPresented: nil, content: nil)) == AddOrderToWalletButton.self)
}

func testSynthItemProvider() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.itemProvider(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.itemProvider(nil)) == AddOrderToWalletButton.self)
}

func testSynthLabelReservedIconWidth() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.labelReservedIconWidth(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.labelReservedIconWidth(nil)) == AddOrderToWalletButton.self)
}

func testSynthLayoutDirectionBehavior() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.layoutDirectionBehavior(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.layoutDirectionBehavior(nil)) == AddOrderToWalletButton.self)
}

func testSynthListItemTint() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listItemTint(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listItemTint(nil)) == AddOrderToWalletButton.self)
}

func testSynthListSectionIndexVisibility() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.listSectionIndexVisibility(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.listSectionIndexVisibility(nil)) == AddOrderToWalletButton.self)
}

func testSynthLuminanceToAlpha() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.luminanceToAlpha()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.luminanceToAlpha()) == AddOrderToWalletButton.self)
}

func testSynthMenuIndicator() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.menuIndicator(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.menuIndicator(nil)) == AddOrderToWalletButton.self)
}

func testSynthMonospacedDigit() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.monospacedDigit()) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.monospacedDigit()) == AddOrderToWalletButton.self)
}

func testSynthNavigationBarTitle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationBarTitle(nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.navigationBarTitle(nil, displayMode: nil)
    precondition(type(of: button.navigationBarTitle(nil)) == AddOrderToWalletButton.self)
    _ = button.navigationBarTitle(nil, displayMode: nil)
}

func testSynthNavigationSplitViewStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.navigationSplitViewStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.navigationSplitViewStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthOnAppear() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onAppear(perform: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onAppear(perform: nil)) == AddOrderToWalletButton.self)
}

func testSynthOnDrop() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onDrop(of: nil, delegate: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onDrop(of: nil, isTargeted: nil, perform: nil)
    precondition(type(of: button.onDrop(of: nil, delegate: nil)) == AddOrderToWalletButton.self)
    _ = button.onDrop(of: nil, isTargeted: nil, perform: nil)
}

func testSynthOnOpenURL() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onOpenURL(perform: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.onOpenURL(prefersInApp: nil)
    precondition(type(of: button.onOpenURL(perform: nil)) == AddOrderToWalletButton.self)
    _ = button.onOpenURL(prefersInApp: nil)
}

func testSynthOnScrollPhaseChange() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.onScrollPhaseChange(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.onScrollPhaseChange(nil)) == AddOrderToWalletButton.self)
}

func testSynthOverlay() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.overlay(nil, alignment: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.overlay(nil, ignoresSafeAreaEdges: nil)
    _ = picker.overlay(nil, in: nil, fillStyle: nil)
    _ = picker.overlay(alignment: nil, content: nil)
    precondition(type(of: button.overlay(nil, alignment: nil)) == AddOrderToWalletButton.self)
    _ = button.overlay(nil, ignoresSafeAreaEdges: nil)
    _ = button.overlay(nil, in: nil, fillStyle: nil)
    _ = button.overlay(alignment: nil, content: nil)
}

func testSynthPickerStyle() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.pickerStyle(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.pickerStyle(nil)) == AddOrderToWalletButton.self)
}

func testSynthPresentationBackgroundInteraction() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationBackgroundInteraction(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.presentationBackgroundInteraction(nil)) == AddOrderToWalletButton.self)
}

func testSynthPresentationSizing() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.presentationSizing(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.presentationSizing(nil)) == AddOrderToWalletButton.self)
}

func testSynthPrivacySensitive() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.privacySensitive(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.privacySensitive(nil)) == AddOrderToWalletButton.self)
}

func testSynthReplaceDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.replaceDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.replaceDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthSaturation() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.saturation(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.saturation(nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollClipDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollClipDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollClipDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollIndicators() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollIndicators(nil, axes: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.scrollIndicators(nil, axes: nil)) == AddOrderToWalletButton.self)
}

func testSynthScrollTransition() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.scrollTransition(nil, axis: nil, transition: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.scrollTransition(topLeading: nil, bottomTrailing: nil, axis: nil, transition: nil)
    precondition(type(of: button.scrollTransition(nil, axis: nil, transition: nil)) == AddOrderToWalletButton.self)
    _ = button.scrollTransition(topLeading: nil, bottomTrailing: nil, axis: nil, transition: nil)
}

func testSynthSearchSelection() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.searchSelection(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.searchSelection(nil)) == AddOrderToWalletButton.self)
}

func testSynthSelectionDisabled() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.selectionDisabled(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.selectionDisabled(nil)) == AddOrderToWalletButton.self)
}

func testSynthSpeechAdjustedPitch() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.speechAdjustedPitch(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.speechAdjustedPitch(nil)) == AddOrderToWalletButton.self)
}

func testSynthStatusBarHidden() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.statusBarHidden(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.statusBarHidden(nil)) == AddOrderToWalletButton.self)
}

func testSynthSymbolEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.symbolEffect(nil, options: nil, isActive: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.symbolEffect(nil, options: nil, value: nil)
    precondition(type(of: button.symbolEffect(nil, options: nil, isActive: nil)) == AddOrderToWalletButton.self)
    _ = button.symbolEffect(nil, options: nil, value: nil)
}

func testSynthTabItem() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabItem(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabItem(nil)) == AddOrderToWalletButton.self)
}

func testSynthTabViewSidebarHeader() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.tabViewSidebarHeader(content: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.tabViewSidebarHeader(content: nil)) == AddOrderToWalletButton.self)
}

func testSynthTextCase() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textCase(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textCase(nil)) == AddOrderToWalletButton.self)
}

func testSynthTextRenderer() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.textRenderer(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.textRenderer(nil)) == AddOrderToWalletButton.self)
}

func testSynthToolbar() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbar(nil, for: nil)) == TransactionPicker<EmptyView>.self)
    _ = picker.toolbar(content: nil)
    _ = picker.toolbar(id: nil, content: nil)
    _ = picker.toolbar(removing: nil)
    precondition(type(of: button.toolbar(nil, for: nil)) == AddOrderToWalletButton.self)
    _ = button.toolbar(content: nil)
    _ = button.toolbar(id: nil, content: nil)
    _ = button.toolbar(removing: nil)
}

func testSynthToolbarTitleDisplayMode() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.toolbarTitleDisplayMode(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.toolbarTitleDisplayMode(nil)) == AddOrderToWalletButton.self)
}

func testSynthTransformEffect() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.transformEffect(nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.transformEffect(nil)) == AddOrderToWalletButton.self)
}

func testSynthTypesettingLanguage() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.typesettingLanguage(nil, isEnabled: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.typesettingLanguage(nil, isEnabled: nil)) == AddOrderToWalletButton.self)
}

func testSynthWritingDirection() {
    var pickerSelection: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { pickerSelection }, set: { pickerSelection = $0 }),
        label: { EmptyView() }
    )
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: picker.writingDirection(strategy: nil)) == TransactionPicker<EmptyView>.self)
    precondition(type(of: button.writingDirection(strategy: nil)) == AddOrderToWalletButton.self)
}
