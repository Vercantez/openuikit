import Foundation

// Identity View modifiers synthesized onto ContactAccessButton: View.
// Linux has no SwiftUI layout engine; these compile as no-ops so the
// overlay census can be declared without inventing Apple layout.
// Compiled only when SwiftUI is absent (isolated host).

#if !canImport(SwiftUI)
extension View {
    func contactsUIApplyingModifier(_ tag: String) -> Self {
        if let button = self as? ContactAccessButton {
            return button.applyingLinuxModifier(tag) as! Self
        }
        return self
    }

    public func accentColor(_ p0: Any? = nil) -> Self { self }
    public func accessibility(activationPoint p0: Any? = nil) -> Self { self }
    public func accessibility(addTraits p0: Any? = nil) -> Self { self }
    public func accessibility(hidden p0: Any? = nil) -> Self { self }
    public func accessibility(hint p0: Any? = nil) -> Self { self }
    public func accessibility(identifier p0: Any? = nil) -> Self { self }
    public func accessibility(inputLabels p0: Any? = nil) -> Self { self }
    public func accessibility(label p0: Any? = nil) -> Self { self }
    public func accessibility(removeTraits p0: Any? = nil) -> Self { self }
    public func accessibility(selectionIdentifier p0: Any? = nil) -> Self { self }
    public func accessibility(sortPriority p0: Any? = nil) -> Self { self }
    public func accessibility(value p0: Any? = nil) -> Self { self }
    public func accessibilityAction(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func accessibilityAction(action p0: Any? = nil, label p1: Any? = nil) -> Self { self }
    public func accessibilityAction(named p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func accessibilityActions(_ p0: Any? = nil) -> Self { self }
    public func accessibilityActions(category p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func accessibilityActivationPoint(_ p0: Any? = nil) -> Self { self }
    public func accessibilityActivationPoint(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityAddTraits(_ p0: Any? = nil) -> Self { self }
    public func accessibilityAdjustableAction(_ p0: Any? = nil) -> Self { self }
    public func accessibilityChartDescriptor(_ p0: Any? = nil) -> Self { self }
    public func accessibilityChildren(children p0: Any? = nil) -> Self { self }
    public func accessibilityCustomContent(_ p0: Any? = nil, _ p1: Any? = nil, importance p2: Any? = nil) -> Self { self }
    public func accessibilityDefaultFocus(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func accessibilityDirectTouch(_ p0: Any? = nil, options p1: Any? = nil) -> Self { self }
    public func accessibilityDragPoint(_ p0: Any? = nil, description p1: Any? = nil) -> Self { self }
    public func accessibilityDragPoint(_ p0: Any? = nil, description p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func accessibilityDropPoint(_ p0: Any? = nil, description p1: Any? = nil) -> Self { self }
    public func accessibilityDropPoint(_ p0: Any? = nil, description p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func accessibilityElement(children p0: Any? = nil) -> Self { self }
    public func accessibilityFocused(_ p0: Any? = nil) -> Self { self }
    public func accessibilityFocused(_ p0: Any? = nil, equals p1: Any? = nil) -> Self { self }
    public func accessibilityHeading(_ p0: Any? = nil) -> Self { self }
    public func accessibilityHidden(_ p0: Any? = nil) -> Self { self }
    public func accessibilityHidden(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityHint(_ p0: Any? = nil) -> Self { self }
    public func accessibilityHint(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityIdentifier(_ p0: Any? = nil) -> Self { self }
    public func accessibilityIdentifier(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityIgnoresInvertColors(_ p0: Any? = nil) -> Self { self }
    public func accessibilityInputLabels(_ p0: Any? = nil) -> Self { self }
    public func accessibilityInputLabels(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityLabel(_ p0: Any? = nil) -> Self { self }
    public func accessibilityLabel(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityLabel(content p0: Any? = nil) -> Self { self }
    public func accessibilityLabeledPair(role p0: Any? = nil, id p1: Any? = nil, `in` p2: Any? = nil) -> Self { self }
    public func accessibilityLinkedGroup(id p0: Any? = nil, `in` p1: Any? = nil) -> Self { self }
    public func accessibilityRemoveTraits(_ p0: Any? = nil) -> Self { self }
    public func accessibilityRepresentation(representation p0: Any? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction(_ p0: Any? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ p0: Any? = nil, entries p1: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ p0: Any? = nil, entries p1: Any? = nil, entryID p2: Any? = nil, entryLabel p3: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ p0: Any? = nil, entries p1: Any? = nil, entryLabel p2: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ p0: Any? = nil, textRanges p1: Any? = nil) -> Self { self }
    public func accessibilityRotorEntry(id p0: Any? = nil, `in` p1: Any? = nil) -> Self { self }
    public func accessibilityScrollAction(_ p0: Any? = nil) -> Self { self }
    public func accessibilityScrollStatus(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityShowsLargeContentViewer() -> Self { self }
    public func accessibilityShowsLargeContentViewer(_ p0: Any? = nil) -> Self { self }
    public func accessibilitySortPriority(_ p0: Any? = nil) -> Self { self }
    public func accessibilityTextContentType(_ p0: Any? = nil) -> Self { self }
    public func accessibilityValue(_ p0: Any? = nil) -> Self { self }
    public func accessibilityValue(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func accessibilityZoomAction(_ p0: Any? = nil) -> Self { self }
    public func actionSheet(isPresented p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func actionSheet(item p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func alert(_ p0: Any? = nil, isPresented p1: Any? = nil, actions p2: Any? = nil) -> Self { self }
    public func alert(_ p0: Any? = nil, isPresented p1: Any? = nil, actions p2: Any? = nil, message p3: Any? = nil) -> Self { self }
    public func alert(_ p0: Any? = nil, isPresented p1: Any? = nil, presenting p2: Any? = nil, actions p3: Any? = nil) -> Self { self }
    public func alert(_ p0: Any? = nil, isPresented p1: Any? = nil, presenting p2: Any? = nil, actions p3: Any? = nil, message p4: Any? = nil) -> Self { self }
    public func alert(isPresented p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func alert(isPresented p0: Any? = nil, error p1: Any? = nil, actions p2: Any? = nil) -> Self { self }
    public func alert(isPresented p0: Any? = nil, error p1: Any? = nil, actions p2: Any? = nil, message p3: Any? = nil) -> Self { self }
    public func alert(item p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func alignmentGuide(_ p0: Any? = nil, computeValue p1: Any? = nil) -> Self { self }
    public func allowedDynamicRange(_ p0: Any? = nil) -> Self { self }
    public func allowsHitTesting(_ enabled: Bool) -> Self { contactsUIApplyingModifier("allowsHitTesting(\(enabled))") }
    public func allowsTightening(_ flag: Bool) -> Self { contactsUIApplyingModifier("allowsTightening(\(flag))") }
    public func allowsWindowActivationEvents() -> Self { self }
    public func allowsWindowActivationEvents(_ p0: Any? = nil) -> Self { self }
    public func anchorPreference(key p0: Any? = nil, value p1: Any? = nil, transform p2: Any? = nil) -> Self { self }
    public func animation(_ p0: Any? = nil) -> Self { self }
    public func animation(_ p0: Any? = nil, body p1: Any? = nil) -> Self { self }
    public func animation(_ p0: Any? = nil, value p1: Any? = nil) -> Self { self }
    public func aspectRatio(_ p0: Any? = nil, contentMode p1: Any? = nil) -> Self { self }
    public func assistiveAccessNavigationIcon(_ p0: Any? = nil) -> Self { self }
    public func assistiveAccessNavigationIcon(systemImage p0: Any? = nil) -> Self { self }
    public func attributedTextFormattingDefinition(_ p0: Any? = nil) -> Self { self }
    public func autocapitalization(_ p0: Any? = nil) -> Self { self }
    public func autocorrectionDisabled(_ p0: Any? = nil) -> Self { self }
    public func background(_ p0: Any? = nil, `in` p1: Any? = nil, fillStyle p2: Any? = nil) -> Self { self }
    public func background(_ p0: Any? = nil, alignment p1: Any? = nil) -> Self { self }
    public func background(_ p0: Any? = nil, ignoresSafeAreaEdges p1: Any? = nil) -> Self { self }
    public func background(`in` p0: Any? = nil, fillStyle p1: Any? = nil) -> Self { self }
    public func background(alignment p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func background(ignoresSafeAreaEdges p0: Any? = nil) -> Self { self }
    public func backgroundExtensionEffect() -> Self { self }
    public func backgroundExtensionEffect(isEnabled p0: Any? = nil) -> Self { self }
    public func backgroundPreferenceValue(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func backgroundPreferenceValue(_ p0: Any? = nil, alignment p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func backgroundStyle(_ p0: Any? = nil) -> Self { self }
    public func badge(_ count: Int) -> Self { contactsUIApplyingModifier("badge(count:\(count))") }
    public func badge(_ key: LocalizedStringKey?) -> Self { contactsUIApplyingModifier("badge(key:\(key?.linuxRaw ?? "nil"))") }
    public func badge(_ label: Text?) -> Self { contactsUIApplyingModifier("badge(text:\(label?.linuxRaw ?? "nil"))") }
    public func badge(_ resource: LocalizedStringResource?) -> Self { contactsUIApplyingModifier("badge(resource:\(resource?.linuxRaw ?? "nil"))") }
    public func badge<S: StringProtocol>(_ label: S?) -> Self { contactsUIApplyingModifier("badge(string:\(label.map { String(describing: $0) } ?? "nil"))") }
    public func badgeProminence(_ p0: Any? = nil) -> Self { self }
    public func baselineOffset(_ baselineOffset: CGFloat) -> Self { contactsUIApplyingModifier("baselineOffset(\(Double(baselineOffset)))") }
    public func blendMode(_ p0: Any? = nil) -> Self { self }
    public func blur(radius p0: Any? = nil, opaque p1: Any? = nil) -> Self { self }
    public func bold(_ isActive: Bool = true) -> Self { contactsUIApplyingModifier("bold(\(isActive))") }
    public func border(_ p0: Any? = nil, width p1: Any? = nil) -> Self { self }
    public func brightness(_ amount: Double) -> Self { contactsUIApplyingModifier("brightness(\(amount))") }
    public func buttonBorderShape(_ p0: Any? = nil) -> Self { self }
    public func buttonRepeatBehavior(_ p0: Any? = nil) -> Self { self }
    public func buttonSizing(_ p0: Any? = nil) -> Self { self }
    public func buttonStyle(_ p0: Any? = nil) -> Self { self }
    public func clipShape(_ p0: Any? = nil, style p1: Any? = nil) -> Self { self }
    public func clipped(antialiased: Bool = false) -> Self { contactsUIApplyingModifier("clipped(antialiased:\(antialiased))") }
    public func colorEffect(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func colorInvert() -> Self { contactsUIApplyingModifier("colorInvert()") }
    public func colorMultiply(_ p0: Any? = nil) -> Self { self }
    public func colorScheme(_ p0: Any? = nil) -> Self { self }
    public func compositingGroup() -> Self { contactsUIApplyingModifier("compositingGroup()") }
    public func confirmationDialog(_ p0: Any? = nil, isPresented p1: Any? = nil, titleVisibility p2: Any? = nil, actions p3: Any? = nil) -> Self { self }
    public func confirmationDialog(_ p0: Any? = nil, isPresented p1: Any? = nil, titleVisibility p2: Any? = nil, actions p3: Any? = nil, message p4: Any? = nil) -> Self { self }
    public func confirmationDialog(_ p0: Any? = nil, isPresented p1: Any? = nil, titleVisibility p2: Any? = nil, presenting p3: Any? = nil, actions p4: Any? = nil) -> Self { self }
    public func confirmationDialog(_ p0: Any? = nil, isPresented p1: Any? = nil, titleVisibility p2: Any? = nil, presenting p3: Any? = nil, actions p4: Any? = nil, message p5: Any? = nil) -> Self { self }
    public func containerBackground(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func containerBackground(`for` p0: Any? = nil, alignment p1: Any? = nil, content p2: Any? = nil) -> Self { self }
    public func containerCornerOffset(_ p0: Any? = nil, sizeToFit p1: Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ p0: Any? = nil, alignment p1: Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ p0: Any? = nil, alignment p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ p0: Any? = nil, count p1: Any? = nil, span p2: Any? = nil, spacing p3: Any? = nil, alignment p4: Any? = nil) -> Self { self }
    public func containerShape(_ p0: Any? = nil) -> Self { self }
    public func containerValue(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func contentMargins(_ p0: Any? = nil, _ p1: Any? = nil, `for` p2: Any? = nil) -> Self { self }
    public func contentMargins(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func contentShape(_ p0: Any? = nil, _ p1: Any? = nil, eoFill p2: Any? = nil) -> Self { self }
    public func contentShape(_ p0: Any? = nil, eoFill p1: Any? = nil) -> Self { self }
    public func contentToolbar(`for` p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func contentTransition(_ p0: Any? = nil) -> Self { self }
    public func contextMenu(_ p0: Any? = nil) -> Self { self }
    public func contextMenu(forSelectionType p0: Any? = nil, menu p1: Any? = nil, primaryAction p2: Any? = nil) -> Self { self }
    public func contextMenu(menuItems p0: Any? = nil) -> Self { self }
    public func contextMenu(menuItems p0: Any? = nil, preview p1: Any? = nil) -> Self { self }
    public func contrast(_ amount: Double) -> Self { contactsUIApplyingModifier("contrast(\(amount))") }
    public func controlGroupStyle(_ p0: Any? = nil) -> Self { self }
    public func controlSize(_ p0: Any? = nil) -> Self { self }
    public func coordinateSpace(_ p0: Any? = nil) -> Self { self }
    public func coordinateSpace(name p0: Any? = nil) -> Self { self }
    public func cornerRadius(_ p0: Any? = nil, antialiased p1: Any? = nil) -> Self { self }
    public func datePickerStyle(_ p0: Any? = nil) -> Self { self }
    public func defaultAdaptableTabBarPlacement(_ p0: Any? = nil) -> Self { self }
    public func defaultAppStorage(_ store: UserDefaults) -> Self { contactsUIApplyingModifier("defaultAppStorage") }
    public func defaultFocus(_ p0: Any? = nil, _ p1: Any? = nil, priority p2: Any? = nil) -> Self { self }
    public func defaultHoverEffect(_ p0: Any? = nil) -> Self { self }
    public func defaultScrollAnchor(_ p0: Any? = nil) -> Self { self }
    public func defaultScrollAnchor(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func defersSystemGestures(on p0: Any? = nil) -> Self { self }
    public func deleteDisabled(_ isDisabled: Bool) -> Self { contactsUIApplyingModifier("deleteDisabled(\(isDisabled))") }
    public func dialogIcon(_ p0: Any? = nil) -> Self { self }
    public func dialogSuppressionToggle(_ p0: Any? = nil, isSuppressed p1: Any? = nil) -> Self { self }
    public func dialogSuppressionToggle(isSuppressed p0: Any? = nil) -> Self { self }
    public func disableAutocorrection(_ disable: Bool?) -> Self { contactsUIApplyingModifier("disableAutocorrection(\(disable.map { String(describing: $0) } ?? "nil"))") }
    public func disabled(_ disabled: Bool) -> Self { contactsUIApplyingModifier("disabled(\(disabled))") }
    public func disclosureGroupStyle(_ p0: Any? = nil) -> Self { self }
    public func distortionEffect(_ p0: Any? = nil, maxSampleOffset p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func documentBrowserContextMenu(_ p0: Any? = nil) -> Self { self }
    public func draggable(_ p0: Any? = nil) -> Self { self }
    public func draggable(_ p0: Any? = nil, preview p1: Any? = nil) -> Self { self }
    public func drawingGroup(opaque p0: Any? = nil, colorMode p1: Any? = nil) -> Self { self }
    public func dropDestination(`for` p0: Any? = nil, action p1: Any? = nil, isTargeted p2: Any? = nil) -> Self { self }
    public func dropDestination(`for` p0: Any? = nil, isEnabled p1: Any? = nil, action p2: Any? = nil) -> Self { self }
    public func dynamicTypeSize(_ p0: Any? = nil) -> Self { self }
    public func edgesIgnoringSafeArea(_ p0: Any? = nil) -> Self { self }
    public func environment(_ p0: Any? = nil) -> Self { self }
    public func environment(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func environmentObject(_ p0: Any? = nil) -> Self { self }
    public func fileDialogBrowserOptions(_ p0: Any? = nil) -> Self { self }
    public func fileDialogConfirmationLabel(_ p0: Any? = nil) -> Self { self }
    public func fileDialogCustomizationID(_ p0: Any? = nil) -> Self { self }
    public func fileDialogDefaultDirectory(_ p0: Any? = nil) -> Self { self }
    public func fileDialogImportsUnresolvedAliases(_ p0: Any? = nil) -> Self { self }
    public func fileDialogMessage(_ p0: Any? = nil) -> Self { self }
    public func fileDialogURLEnabled(_ p0: Any? = nil) -> Self { self }
    public func fileExporter(isPresented p0: Any? = nil, document p1: Any? = nil, contentType p2: Any? = nil, defaultFilename p3: Any? = nil, onCompletion p4: Any? = nil) -> Self { self }
    public func fileExporter(isPresented p0: Any? = nil, document p1: Any? = nil, contentTypes p2: Any? = nil, defaultFilename p3: Any? = nil, onCompletion p4: Any? = nil, onCancellation p5: Any? = nil) -> Self { self }
    public func fileExporter(isPresented p0: Any? = nil, documents p1: Any? = nil, contentType p2: Any? = nil, onCompletion p3: Any? = nil) -> Self { self }
    public func fileExporter(isPresented p0: Any? = nil, documents p1: Any? = nil, contentTypes p2: Any? = nil, onCompletion p3: Any? = nil, onCancellation p4: Any? = nil) -> Self { self }
    public func fileExporter(isPresented p0: Any? = nil, item p1: Any? = nil, contentTypes p2: Any? = nil, defaultFilename p3: Any? = nil, onCompletion p4: Any? = nil, onCancellation p5: Any? = nil) -> Self { self }
    public func fileExporter(isPresented p0: Any? = nil, items p1: Any? = nil, contentTypes p2: Any? = nil, onCompletion p3: Any? = nil, onCancellation p4: Any? = nil) -> Self { self }
    public func fileExporterFilenameLabel(_ p0: Any? = nil) -> Self { self }
    public func fileImporter(isPresented p0: Any? = nil, allowedContentTypes p1: Any? = nil, allowsMultipleSelection p2: Any? = nil, onCompletion p3: Any? = nil) -> Self { self }
    public func fileImporter(isPresented p0: Any? = nil, allowedContentTypes p1: Any? = nil, allowsMultipleSelection p2: Any? = nil, onCompletion p3: Any? = nil, onCancellation p4: Any? = nil) -> Self { self }
    public func fileImporter(isPresented p0: Any? = nil, allowedContentTypes p1: Any? = nil, onCompletion p2: Any? = nil) -> Self { self }
    public func fileMover(isPresented p0: Any? = nil, file p1: Any? = nil, onCompletion p2: Any? = nil) -> Self { self }
    public func fileMover(isPresented p0: Any? = nil, file p1: Any? = nil, onCompletion p2: Any? = nil, onCancellation p3: Any? = nil) -> Self { self }
    public func fileMover(isPresented p0: Any? = nil, files p1: Any? = nil, onCompletion p2: Any? = nil) -> Self { self }
    public func fileMover(isPresented p0: Any? = nil, files p1: Any? = nil, onCompletion p2: Any? = nil, onCancellation p3: Any? = nil) -> Self { self }
    public func findDisabled(_ isDisabled: Bool = true) -> Self { contactsUIApplyingModifier("findDisabled(\(isDisabled))") }
    public func findNavigator(isPresented p0: Any? = nil) -> Self { self }
    public func fixedSize() -> Self { contactsUIApplyingModifier("fixedSize()") }
    public func fixedSize(horizontal: Bool, vertical: Bool) -> Self { contactsUIApplyingModifier("fixedSize(horizontal:\(horizontal),vertical:\(vertical))") }
    public func flipsForRightToLeftLayoutDirection(_ p0: Any? = nil) -> Self { self }
    public func focusEffectDisabled(_ p0: Any? = nil) -> Self { self }
    public func focusable(_ isFocusable: Bool = true) -> Self { contactsUIApplyingModifier("focusable(\(isFocusable))") }
    public func focusable(_ isFocusable: Bool = true, interactions: FocusInteractions) -> Self { contactsUIApplyingModifier("focusable(interactions:automatic)") }
    public func focused(_ p0: Any? = nil) -> Self { self }
    public func focused(_ p0: Any? = nil, equals p1: Any? = nil) -> Self { self }
    public func focusedObject(_ p0: Any? = nil) -> Self { self }
    public func focusedSceneObject(_ p0: Any? = nil) -> Self { self }
    public func focusedSceneValue(_ p0: Any? = nil) -> Self { self }
    public func focusedSceneValue(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func focusedValue(_ p0: Any? = nil) -> Self { self }
    public func focusedValue(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func font(_ p0: Any? = nil) -> Self { self }
    public func fontDesign(_ p0: Any? = nil) -> Self { self }
    public func fontWeight(_ p0: Any? = nil) -> Self { self }
    public func fontWidth(_ p0: Any? = nil) -> Self { self }
    public func foregroundColor(_ p0: Any? = nil) -> Self { self }
    public func foregroundStyle(_ p0: Any? = nil) -> Self { self }
    public func foregroundStyle(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func foregroundStyle(_ p0: Any? = nil, _ p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func formStyle(_ p0: Any? = nil) -> Self { self }
    public func frame() -> Self { contactsUIApplyingModifier("frame()") }
    public func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> Self {
        func fmt(_ value: CGFloat?) -> String { value.map { String(Double($0)) } ?? "nil" }
        return contactsUIApplyingModifier(
            "frame(minIdealMax:\(fmt(minWidth)),\(fmt(idealWidth)),\(fmt(maxWidth)),\(fmt(minHeight)),\(fmt(idealHeight)),\(fmt(maxHeight)))"
        )
    }
    public func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> Self {
        func fmt(_ value: CGFloat?) -> String { value.map { String(Double($0)) } ?? "nil" }
        return contactsUIApplyingModifier("frame(width:\(fmt(width)),height:\(fmt(height)))")
    }
    public func fullScreenCover(isPresented p0: Any? = nil, onDismiss p1: Any? = nil, content p2: Any? = nil) -> Self { self }
    public func fullScreenCover(item p0: Any? = nil, onDismiss p1: Any? = nil, content p2: Any? = nil) -> Self { self }
    public func gaugeStyle(_ p0: Any? = nil) -> Self { self }
    public func geometryGroup() -> Self { contactsUIApplyingModifier("geometryGroup()") }
    public func gesture(_ p0: Any? = nil) -> Self { self }
    public func gesture(_ p0: Any? = nil, including p1: Any? = nil) -> Self { self }
    public func gesture(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func gesture(_ p0: Any? = nil, name p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func glassEffect(_ p0: Any? = nil, `in` p1: Any? = nil) -> Self { self }
    public func glassEffectID(_ p0: Any? = nil, `in` p1: Any? = nil) -> Self { self }
    public func glassEffectTransition(_ p0: Any? = nil) -> Self { self }
    public func glassEffectUnion(id p0: Any? = nil, namespace p1: Any? = nil) -> Self { self }
    public func grayscale(_ amount: Double) -> Self { contactsUIApplyingModifier("grayscale(\(amount))") }
    public func gridCellAnchor(_ p0: Any? = nil) -> Self { self }
    public func gridCellColumns(_ count: Int) -> Self { contactsUIApplyingModifier("gridCellColumns(\(count))") }
    public func gridCellUnsizedAxes(_ p0: Any? = nil) -> Self { self }
    public func gridColumnAlignment(_ p0: Any? = nil) -> Self { self }
    public func groupBoxStyle(_ p0: Any? = nil) -> Self { self }
    public func handGestureShortcut(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func handlesExternalEvents(preferring p0: Any? = nil, allowing p1: Any? = nil) -> Self { self }
    public func headerProminence(_ p0: Any? = nil) -> Self { self }
    public func help(_ p0: Any? = nil) -> Self { self }
    public func hidden() -> Self { contactsUIApplyingModifier("hidden()") }
    public func highPriorityGesture(_ p0: Any? = nil, including p1: Any? = nil) -> Self { self }
    public func highPriorityGesture(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func highPriorityGesture(_ p0: Any? = nil, name p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func hoverEffect(_ p0: Any? = nil) -> Self { self }
    public func hoverEffect(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func hoverEffectDisabled(_ p0: Any? = nil) -> Self { self }
    public func hueRotation(_ p0: Any? = nil) -> Self { self }
    public func id(_ p0: Any? = nil) -> Self { self }
    public func ignoresSafeArea(_ p0: Any? = nil, edges p1: Any? = nil) -> Self { self }
    public func imageScale(_ p0: Any? = nil) -> Self { self }
    public func indexViewStyle(_ p0: Any? = nil) -> Self { self }
    public func inspector(isPresented p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func inspectorColumnWidth(_ p0: Any? = nil) -> Self { self }
    public func inspectorColumnWidth(min p0: Any? = nil, ideal p1: Any? = nil, max p2: Any? = nil) -> Self { self }
    public func interactionActivityTrackingTag(_ p0: Any? = nil) -> Self { self }
    public func interactiveDismissDisabled(_ p0: Any? = nil) -> Self { self }
    public func invalidatableContent(_ p0: Any? = nil) -> Self { self }
    public func italic(_ isActive: Bool = true) -> Self { contactsUIApplyingModifier("italic(\(isActive))") }
    public func itemProvider(_ p0: Any? = nil) -> Self { self }
    public func kerning(_ kerning: CGFloat) -> Self { contactsUIApplyingModifier("kerning(\(Double(kerning)))") }
    public func keyboardShortcut(_ p0: Any? = nil) -> Self { self }
    public func keyboardShortcut(_ p0: Any? = nil, modifiers p1: Any? = nil) -> Self { self }
    public func keyboardShortcut(_ p0: Any? = nil, modifiers p1: Any? = nil, localization p2: Any? = nil) -> Self { self }
    public func keyboardType(_ p0: Any? = nil) -> Self { self }
    public func keyframeAnimator(initialValue p0: Any? = nil, repeating p1: Any? = nil, content p2: Any? = nil, keyframes p3: Any? = nil) -> Self { self }
    public func keyframeAnimator(initialValue p0: Any? = nil, trigger p1: Any? = nil, content p2: Any? = nil, keyframes p3: Any? = nil) -> Self { self }
    public func labelIconToTitleSpacing(_ value: CGFloat) -> Self { contactsUIApplyingModifier("labelIconToTitleSpacing(\(Double(value)))") }
    public func labelReservedIconWidth(_ value: CGFloat) -> Self { contactsUIApplyingModifier("labelReservedIconWidth(\(Double(value)))") }
    public func labelStyle(_ p0: Any? = nil) -> Self { self }
    public func labeledContentStyle(_ p0: Any? = nil) -> Self { self }
    public func labelsHidden() -> Self { contactsUIApplyingModifier("labelsHidden()") }
    public func labelsVisibility(_ p0: Any? = nil) -> Self { self }
    public func layerEffect(_ p0: Any? = nil, maxSampleOffset p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func layoutDirectionBehavior(_ p0: Any? = nil) -> Self { self }
    public func layoutPriority(_ value: Double) -> Self { contactsUIApplyingModifier("layoutPriority(\(value))") }
    public func layoutValue(key p0: Any? = nil, value p1: Any? = nil) -> Self { self }
    public func lineHeight(_ p0: Any? = nil) -> Self { self }
    public func lineLimit(_ number: Int?) -> Self { contactsUIApplyingModifier("lineLimit(optional:\(number.map(String.init) ?? "nil"))") }
    public func lineLimit(_ limit: ClosedRange<Int>) -> Self { contactsUIApplyingModifier("lineLimit(closed:\(limit.lowerBound)...\(limit.upperBound))") }
    public func lineLimit(_ limit: PartialRangeFrom<Int>) -> Self { contactsUIApplyingModifier("lineLimit(from:\(limit.lowerBound))") }
    public func lineLimit(_ limit: PartialRangeThrough<Int>) -> Self { contactsUIApplyingModifier("lineLimit(through:\(limit.upperBound))") }
    public func lineLimit(_ limit: Int, reservesSpace: Bool) -> Self { contactsUIApplyingModifier("lineLimit(\(limit),reservesSpace:\(reservesSpace))") }
    public func lineSpacing(_ lineSpacing: CGFloat) -> Self { contactsUIApplyingModifier("lineSpacing(\(Double(lineSpacing)))") }
    public func listItemTint(_ p0: Any? = nil) -> Self { self }
    public func listRowBackground(_ p0: Any? = nil) -> Self { self }
    public func listRowInsets(_ p0: Any? = nil) -> Self { self }
    public func listRowInsets(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func listRowSeparator(_ p0: Any? = nil, edges p1: Any? = nil) -> Self { self }
    public func listRowSeparatorTint(_ p0: Any? = nil, edges p1: Any? = nil) -> Self { self }
    public func listRowSpacing(_ spacing: CGFloat?) -> Self { contactsUIApplyingModifier("listRowSpacing(\(spacing.map { String(Double($0)) } ?? "nil"))") }
    public func listSectionIndexVisibility(_ p0: Any? = nil) -> Self { self }
    public func listSectionMargins(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func listSectionSeparator(_ p0: Any? = nil, edges p1: Any? = nil) -> Self { self }
    public func listSectionSeparatorTint(_ p0: Any? = nil, edges p1: Any? = nil) -> Self { self }
    public func listSectionSpacing(_ spacing: CGFloat) -> Self { contactsUIApplyingModifier("listSectionSpacing(length:\(Double(spacing)))") }
    public func listSectionSpacing(_ spacing: ListSectionSpacing) -> Self { contactsUIApplyingModifier("listSectionSpacing(token:default)") }
    public func listStyle(_ p0: Any? = nil) -> Self { self }
    public func luminanceToAlpha() -> Self { contactsUIApplyingModifier("luminanceToAlpha()") }
    public func mask(_ p0: Any? = nil) -> Self { self }
    public func mask(alignment p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func matchedGeometryEffect(id p0: Any? = nil, `in` p1: Any? = nil, properties p2: Any? = nil, anchor p3: Any? = nil, isSource p4: Any? = nil) -> Self { self }
    public func matchedTransitionSource(id p0: Any? = nil, `in` p1: Any? = nil) -> Self { self }
    public func matchedTransitionSource(id p0: Any? = nil, `in` p1: Any? = nil, configuration p2: Any? = nil) -> Self { self }
    public func materialActiveAppearance(_ p0: Any? = nil) -> Self { self }
    public func menuActionDismissBehavior(_ p0: Any? = nil) -> Self { self }
    public func menuIndicator(_ p0: Any? = nil) -> Self { self }
    public func menuOrder(_ p0: Any? = nil) -> Self { self }
    public func menuStyle(_ p0: Any? = nil) -> Self { self }
    public func minimumScaleFactor(_ factor: CGFloat) -> Self { contactsUIApplyingModifier("minimumScaleFactor(\(Double(factor)))") }
    public func modifier(_ p0: Any? = nil) -> Self { self }
    public func monospaced(_ isActive: Bool = true) -> Self { contactsUIApplyingModifier("monospaced(\(isActive))") }
    public func monospacedDigit() -> Self { contactsUIApplyingModifier("monospacedDigit()") }
    public func moveDisabled(_ isDisabled: Bool) -> Self { contactsUIApplyingModifier("moveDisabled(\(isDisabled))") }
    public func multilineTextAlignment(_ p0: Any? = nil) -> Self { self }
    public func multilineTextAlignment(strategy p0: Any? = nil) -> Self { self }
    public func navigationBarBackButtonHidden(_ p0: Any? = nil) -> Self { self }
    public func navigationBarHidden(_ hidden: Bool) -> Self { contactsUIApplyingModifier("navigationBarHidden(\(hidden))") }
    public func navigationBarItems(leading p0: Any? = nil) -> Self { self }
    public func navigationBarItems(leading p0: Any? = nil, trailing p1: Any? = nil) -> Self { self }
    public func navigationBarItems(trailing p0: Any? = nil) -> Self { self }
    public func navigationBarTitle(_ p0: Any? = nil) -> Self { self }
    public func navigationBarTitle(_ p0: Any? = nil, displayMode p1: Any? = nil) -> Self { self }
    public func navigationBarTitleDisplayMode(_ p0: Any? = nil) -> Self { self }
    public func navigationDestination(`for` p0: Any? = nil, destination p1: Any? = nil) -> Self { self }
    public func navigationDestination(isPresented p0: Any? = nil, destination p1: Any? = nil) -> Self { self }
    public func navigationDestination(item p0: Any? = nil, destination p1: Any? = nil) -> Self { self }
    public func navigationDocument(_ url: URL) -> Self { contactsUIApplyingModifier("navigationDocument(url:\(url.absoluteString))") }
    public func navigationDocument<D: Transferable>(_ document: D) -> Self { contactsUIApplyingModifier("navigationDocument(transferable:\(String(describing: document)))") }
    public func navigationDocument<D: Transferable, Icon, Label>(
        _ document: D,
        preview: SharePreview<Icon, Label>
    ) -> Self {
        contactsUIApplyingModifier(
            "navigationDocument(preview:\(String(describing: Icon.self)),\(String(describing: Label.self)))"
        )
    }
    public func navigationLinkIndicatorVisibility(_ p0: Any? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth(_ p0: Any? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth(min p0: Any? = nil, ideal p1: Any? = nil, max p2: Any? = nil) -> Self { self }
    public func navigationSplitViewStyle(_ p0: Any? = nil) -> Self { self }
    public func navigationSubtitle(_ p0: Any? = nil) -> Self { self }
    public func navigationTitle(_ p0: Any? = nil) -> Self { self }
    public func navigationTransition(_ p0: Any? = nil) -> Self { self }
    public func navigationViewStyle(_ p0: Any? = nil) -> Self { self }
    public func offset(_ offset: CGSize) -> Self { contactsUIApplyingModifier("offset(size:\(Double(offset.width))x\(Double(offset.height)))") }
    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> Self { contactsUIApplyingModifier("offset(x:\(Double(x)),y:\(Double(y)))") }
    public func onAppear(perform p0: Any? = nil) -> Self { self }
    public func onChange(of p0: Any? = nil, initial p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func onChange(of p0: Any? = nil, perform p1: Any? = nil) -> Self { self }
    public func onContinueUserActivity(_ p0: Any? = nil, perform p1: Any? = nil) -> Self { self }
    public func onContinuousHover(coordinateSpace p0: Any? = nil, perform p1: Any? = nil) -> Self { self }
    public func onDisappear(perform p0: Any? = nil) -> Self { self }
    public func onDrag(_ p0: Any? = nil) -> Self { self }
    public func onDrag(_ p0: Any? = nil, preview p1: Any? = nil) -> Self { self }
    public func onDrop(of p0: Any? = nil, delegate p1: Any? = nil) -> Self { self }
    public func onDrop(of p0: Any? = nil, isTargeted p1: Any? = nil, perform p2: Any? = nil) -> Self { self }
    public func onGeometryChange(`for` p0: Any? = nil, of p1: Any? = nil, action p2: Any? = nil) -> Self { self }
    public func onHover(perform p0: Any? = nil) -> Self { self }
    public func onInteractiveResizeChange(_ p0: Any? = nil) -> Self { self }
    public func onKeyPress(_ p0: Any? = nil, action p1: Any? = nil) -> Self { self }
    public func onKeyPress(_ p0: Any? = nil, phases p1: Any? = nil, action p2: Any? = nil) -> Self { self }
    public func onKeyPress(characters p0: Any? = nil, phases p1: Any? = nil, action p2: Any? = nil) -> Self { self }
    public func onKeyPress(keys p0: Any? = nil, phases p1: Any? = nil, action p2: Any? = nil) -> Self { self }
    public func onKeyPress(phases p0: Any? = nil, action p1: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration p0: Any? = nil, maximumDistance p1: Any? = nil, perform p2: Any? = nil, onPressingChanged p3: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration p0: Any? = nil, maximumDistance p1: Any? = nil, pressing p2: Any? = nil, perform p3: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration p0: Any? = nil, perform p1: Any? = nil, onPressingChanged p2: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration p0: Any? = nil, pressing p1: Any? = nil, perform p2: Any? = nil) -> Self { self }
    public func onOpenURL(perform p0: Any? = nil) -> Self { self }
    public func onOpenURL(prefersInApp p0: Any? = nil) -> Self { self }
    public func onPencilDoubleTap(perform p0: Any? = nil) -> Self { self }
    public func onPencilSqueeze(perform p0: Any? = nil) -> Self { self }
    public func onPreferenceChange(_ p0: Any? = nil, perform p1: Any? = nil) -> Self { self }
    public func onReceive(_ p0: Any? = nil, perform p1: Any? = nil) -> Self { self }
    public func onScrollGeometryChange(`for` p0: Any? = nil, of p1: Any? = nil, action p2: Any? = nil) -> Self { self }
    public func onScrollPhaseChange(_ p0: Any? = nil) -> Self { self }
    public func onScrollTargetVisibilityChange(idType p0: Any? = nil, threshold p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func onScrollVisibilityChange(threshold p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func onSubmit(of p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func onTapGesture(count p0: Any? = nil, coordinateSpace p1: Any? = nil, perform p2: Any? = nil) -> Self { self }
    public func onTapGesture(count p0: Any? = nil, perform p1: Any? = nil) -> Self { self }
    public func opacity(_ opacity: Double) -> Self { contactsUIApplyingModifier("opacity(\(opacity))") }
    public func overlay(_ p0: Any? = nil, `in` p1: Any? = nil, fillStyle p2: Any? = nil) -> Self { self }
    public func overlay(_ p0: Any? = nil, alignment p1: Any? = nil) -> Self { self }
    public func overlay(_ p0: Any? = nil, ignoresSafeAreaEdges p1: Any? = nil) -> Self { self }
    public func overlay(alignment p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func overlayPreferenceValue(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func overlayPreferenceValue(_ p0: Any? = nil, alignment p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func padding(_ length: CGFloat) -> Self { contactsUIApplyingModifier("padding(length:\(Double(length)))") }
    public func padding(_ insets: EdgeInsets) -> Self { contactsUIApplyingModifier("padding(insets:\(Double(insets.top)),\(Double(insets.leading)),\(Double(insets.bottom)),\(Double(insets.trailing)))") }
    public func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> Self { contactsUIApplyingModifier("padding(edges:\(edges.rawValue),\(length.map { String(Double($0)) } ?? "nil"))") }
    public func paletteSelectionEffect(_ p0: Any? = nil) -> Self { self }
    public func persistentSystemOverlays(_ p0: Any? = nil) -> Self { self }
    public func phaseAnimator(_ p0: Any? = nil, content p1: Any? = nil, animation p2: Any? = nil) -> Self { self }
    public func phaseAnimator(_ p0: Any? = nil, trigger p1: Any? = nil, content p2: Any? = nil, animation p3: Any? = nil) -> Self { self }
    public func pickerStyle(_ p0: Any? = nil) -> Self { self }
    public func popover(isPresented p0: Any? = nil, attachmentAnchor p1: Any? = nil, arrowEdge p2: Any? = nil, content p3: Any? = nil) -> Self { self }
    public func popover(item p0: Any? = nil, attachmentAnchor p1: Any? = nil, arrowEdge p2: Any? = nil, content p3: Any? = nil) -> Self { self }
    public func position(_ p0: Any? = nil) -> Self { self }
    public func position(x p0: Any? = nil, y p1: Any? = nil) -> Self { self }
    public func preference(key p0: Any? = nil, value p1: Any? = nil) -> Self { self }
    public func preferredColorScheme(_ p0: Any? = nil) -> Self { self }
    public func presentationBackground(_ p0: Any? = nil) -> Self { self }
    public func presentationBackground(alignment p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func presentationBackgroundInteraction(_ p0: Any? = nil) -> Self { self }
    public func presentationCompactAdaptation(_ p0: Any? = nil) -> Self { self }
    public func presentationCompactAdaptation(horizontal p0: Any? = nil, vertical p1: Any? = nil) -> Self { self }
    public func presentationContentInteraction(_ p0: Any? = nil) -> Self { self }
    public func presentationCornerRadius(_ p0: Any? = nil) -> Self { self }
    public func presentationDetents(_ p0: Any? = nil) -> Self { self }
    public func presentationDetents(_ p0: Any? = nil, selection p1: Any? = nil) -> Self { self }
    public func presentationDragIndicator(_ p0: Any? = nil) -> Self { self }
    public func presentationSizing(_ p0: Any? = nil) -> Self { self }
    public func previewContext(_ p0: Any? = nil) -> Self { self }
    public func previewDevice(_ p0: Any? = nil) -> Self { self }
    public func previewDisplayName(_ p0: Any? = nil) -> Self { self }
    public func previewInterfaceOrientation(_ p0: Any? = nil) -> Self { self }
    public func previewLayout(_ p0: Any? = nil) -> Self { self }
    public func privacySensitive(_ sensitive: Bool = true) -> Self { contactsUIApplyingModifier("privacySensitive(\(sensitive))") }
    public func progressViewStyle(_ p0: Any? = nil) -> Self { self }
    public func projectionEffect(_ p0: Any? = nil) -> Self { self }
    public func redacted(reason p0: Any? = nil) -> Self { self }
    public func refreshable(action p0: Any? = nil) -> Self { self }
    public func renameAction(_ p0: Any? = nil) -> Self { self }
    public func replaceDisabled(_ isDisabled: Bool = true) -> Self { contactsUIApplyingModifier("replaceDisabled(\(isDisabled))") }
    public func rotation3DEffect(_ p0: Any? = nil, axis p1: Any? = nil, anchor p2: Any? = nil, anchorZ p3: Any? = nil, perspective p4: Any? = nil) -> Self { self }
    public func rotationEffect(_ p0: Any? = nil, anchor p1: Any? = nil) -> Self { self }
    public func safeAreaBar(edge p0: Any? = nil, alignment p1: Any? = nil, spacing p2: Any? = nil, content p3: Any? = nil) -> Self { self }
    public func safeAreaInset(edge p0: Any? = nil, alignment p1: Any? = nil, spacing p2: Any? = nil, content p3: Any? = nil) -> Self { self }
    public func safeAreaPadding(_ length: CGFloat) -> Self { contactsUIApplyingModifier("safeAreaPadding(length:\(Double(length)))") }
    public func safeAreaPadding(_ insets: EdgeInsets) -> Self { contactsUIApplyingModifier("safeAreaPadding(insets:\(Double(insets.top)),\(Double(insets.leading)),\(Double(insets.bottom)),\(Double(insets.trailing)))") }
    public func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> Self { contactsUIApplyingModifier("safeAreaPadding(edges:\(edges.rawValue),\(length.map { String(Double($0)) } ?? "nil"))") }
    public func saturation(_ amount: Double) -> Self { contactsUIApplyingModifier("saturation(\(amount))") }
    public func scaleEffect(_ p0: Any? = nil, anchor p1: Any? = nil) -> Self { self }
    public func scaleEffect(x p0: Any? = nil, y p1: Any? = nil, anchor p2: Any? = nil) -> Self { self }
    public func scaledToFill() -> Self { contactsUIApplyingModifier("scaledToFill()") }
    public func scaledToFit() -> Self { contactsUIApplyingModifier("scaledToFit()") }
    public func scenePadding(_ p0: Any? = nil) -> Self { self }
    public func scenePadding(_ p0: Any? = nil, edges p1: Any? = nil) -> Self { self }
    public func scrollBounceBehavior(_ p0: Any? = nil, axes p1: Any? = nil) -> Self { self }
    public func scrollClipDisabled(_ p0: Any? = nil) -> Self { self }
    public func scrollContentBackground(_ p0: Any? = nil) -> Self { self }
    public func scrollDisabled(_ disabled: Bool) -> Self { contactsUIApplyingModifier("scrollDisabled(\(disabled))") }
    public func scrollDismissesKeyboard(_ p0: Any? = nil) -> Self { self }
    public func scrollEdgeEffectHidden(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func scrollEdgeEffectStyle(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func scrollIndicators(_ p0: Any? = nil, axes p1: Any? = nil) -> Self { self }
    public func scrollIndicatorsFlash(onAppear p0: Any? = nil) -> Self { self }
    public func scrollIndicatorsFlash(trigger p0: Any? = nil) -> Self { self }
    public func scrollInputBehavior(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func scrollPosition(_ p0: Any? = nil, anchor p1: Any? = nil) -> Self { self }
    public func scrollPosition(id p0: Any? = nil, anchor p1: Any? = nil) -> Self { self }
    public func scrollTargetBehavior(_ p0: Any? = nil) -> Self { self }
    public func scrollTargetLayout(isEnabled p0: Any? = nil) -> Self { self }
    public func scrollTransition(_ p0: Any? = nil, axis p1: Any? = nil, transition p2: Any? = nil) -> Self { self }
    public func scrollTransition(topLeading p0: Any? = nil, bottomTrailing p1: Any? = nil, axis p2: Any? = nil, transition p3: Any? = nil) -> Self { self }
    public func searchCompletion(_ p0: Any? = nil) -> Self { self }
    public func searchDictationBehavior(_ p0: Any? = nil) -> Self { self }
    public func searchFocused(_ p0: Any? = nil) -> Self { self }
    public func searchFocused(_ p0: Any? = nil, equals p1: Any? = nil) -> Self { self }
    public func searchPresentationToolbarBehavior(_ p0: Any? = nil) -> Self { self }
    public func searchScopes(_ p0: Any? = nil, activation p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func searchScopes(_ p0: Any? = nil, scopes p1: Any? = nil) -> Self { self }
    public func searchSelection(_ p0: Any? = nil) -> Self { self }
    public func searchSuggestions(_ p0: Any? = nil) -> Self { self }
    public func searchSuggestions(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func searchToolbarBehavior(_ p0: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, editableTokens p1: Any? = nil, isPresented p2: Any? = nil, placement p3: Any? = nil, prompt p4: Any? = nil, token p5: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, editableTokens p1: Any? = nil, placement p2: Any? = nil, prompt p3: Any? = nil, token p4: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, isPresented p1: Any? = nil, placement p2: Any? = nil, prompt p3: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, placement p1: Any? = nil, prompt p2: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, placement p1: Any? = nil, prompt p2: Any? = nil, suggestions p3: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, tokens p1: Any? = nil, isPresented p2: Any? = nil, placement p3: Any? = nil, prompt p4: Any? = nil, token p5: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, tokens p1: Any? = nil, placement p2: Any? = nil, prompt p3: Any? = nil, token p4: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, tokens p1: Any? = nil, suggestedTokens p2: Any? = nil, isPresented p3: Any? = nil, placement p4: Any? = nil, prompt p5: Any? = nil, token p6: Any? = nil) -> Self { self }
    public func searchable(text p0: Any? = nil, tokens p1: Any? = nil, suggestedTokens p2: Any? = nil, placement p3: Any? = nil, prompt p4: Any? = nil, token p5: Any? = nil) -> Self { self }
    public func sectionActions(content p0: Any? = nil) -> Self { self }
    public func sectionIndexLabel(_ p0: Any? = nil) -> Self { self }
    public func selectionDisabled(_ isDisabled: Bool = true) -> Self { contactsUIApplyingModifier("selectionDisabled(\(isDisabled))") }
    public func sensoryFeedback(_ p0: Any? = nil, trigger p1: Any? = nil) -> Self { self }
    public func sensoryFeedback(_ p0: Any? = nil, trigger p1: Any? = nil, condition p2: Any? = nil) -> Self { self }
    public func sensoryFeedback(trigger p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func shadow(color p0: Any? = nil, radius p1: Any? = nil, x p2: Any? = nil, y p3: Any? = nil) -> Self { self }
    public func sheet(isPresented p0: Any? = nil, onDismiss p1: Any? = nil, content p2: Any? = nil) -> Self { self }
    public func sheet(item p0: Any? = nil, onDismiss p1: Any? = nil, content p2: Any? = nil) -> Self { self }
    public func simultaneousGesture(_ p0: Any? = nil, including p1: Any? = nil) -> Self { self }
    public func simultaneousGesture(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func simultaneousGesture(_ p0: Any? = nil, name p1: Any? = nil, isEnabled p2: Any? = nil) -> Self { self }
    public func sliderThumbVisibility(_ p0: Any? = nil) -> Self { self }
    public func speechAdjustedPitch(_ p0: Any? = nil) -> Self { self }
    public func speechAlwaysIncludesPunctuation(_ p0: Any? = nil) -> Self { self }
    public func speechAnnouncementsQueued(_ p0: Any? = nil) -> Self { self }
    public func speechSpellsOutCharacters(_ p0: Any? = nil) -> Self { self }
    public func springLoadingBehavior(_ p0: Any? = nil) -> Self { self }
    public func statusBar(hidden p0: Any? = nil) -> Self { self }
    public func statusBarHidden(_ hidden: Bool = true) -> Self { contactsUIApplyingModifier("statusBarHidden(\(hidden))") }
    public func strikethrough(_ p0: Any? = nil, pattern p1: Any? = nil, color p2: Any? = nil) -> Self { self }
    public func submitLabel(_ p0: Any? = nil) -> Self { self }
    public func submitScope(_ isBlocking: Bool = true) -> Self { contactsUIApplyingModifier("submitScope(\(isBlocking))") }
    public func swipeActions(edge p0: Any? = nil, allowsFullSwipe p1: Any? = nil, content p2: Any? = nil) -> Self { self }
    public func symbolColorRenderingMode(_ p0: Any? = nil) -> Self { self }
    public func symbolEffect(_ p0: Any? = nil, options p1: Any? = nil, isActive p2: Any? = nil) -> Self { self }
    public func symbolEffect(_ p0: Any? = nil, options p1: Any? = nil, value p2: Any? = nil) -> Self { self }
    public func symbolEffectsRemoved(_ p0: Any? = nil) -> Self { self }
    public func symbolRenderingMode(_ p0: Any? = nil) -> Self { self }
    public func symbolVariableValueMode(_ p0: Any? = nil) -> Self { self }
    public func symbolVariant(_ p0: Any? = nil) -> Self { self }
    public func tabBarMinimizeBehavior(_ p0: Any? = nil) -> Self { self }
    public func tabItem(_ p0: Any? = nil) -> Self { self }
    public func tabViewBottomAccessory(content p0: Any? = nil) -> Self { self }
    public func tabViewCustomization(_ p0: Any? = nil) -> Self { self }
    public func tabViewSearchActivation(_ p0: Any? = nil) -> Self { self }
    public func tabViewSidebarBottomBar(content p0: Any? = nil) -> Self { self }
    public func tabViewSidebarFooter(content p0: Any? = nil) -> Self { self }
    public func tabViewSidebarHeader(content p0: Any? = nil) -> Self { self }
    public func tabViewStyle(_ p0: Any? = nil) -> Self { self }
    public func tableColumnHeaders(_ p0: Any? = nil) -> Self { self }
    public func tableStyle(_ p0: Any? = nil) -> Self { self }
    public func tag(_ p0: Any? = nil, includeOptional p1: Any? = nil) -> Self { self }
    public func task(id p0: Any? = nil, name p1: Any? = nil, executorPreference p2: Any? = nil, priority p3: Any? = nil, file p4: Any? = nil, line p5: Any? = nil, _ p6: Any? = nil) -> Self { self }
    public func task(id p0: Any? = nil, priority p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func task(priority p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func textCase(_ p0: Any? = nil) -> Self { self }
    public func textContentType(_ p0: Any? = nil) -> Self { self }
    public func textEditorStyle(_ p0: Any? = nil) -> Self { self }
    public func textFieldStyle(_ p0: Any? = nil) -> Self { self }
    public func textInputAutocapitalization(_ p0: Any? = nil) -> Self { self }
    public func textInputFormattingControlVisibility(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func textRenderer(_ p0: Any? = nil) -> Self { self }
    public func textScale(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func textSelection(_ p0: Any? = nil) -> Self { self }
    public func textSelectionAffinity(_ p0: Any? = nil) -> Self { self }
    public func tint(_ p0: Any? = nil) -> Self { self }
    public func toggleStyle(_ p0: Any? = nil) -> Self { self }
    public func toolbar(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func toolbar(content p0: Any? = nil) -> Self { self }
    public func toolbar(id p0: Any? = nil, content p1: Any? = nil) -> Self { self }
    public func toolbar(removing p0: Any? = nil) -> Self { self }
    public func toolbarBackground(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func toolbarBackgroundVisibility(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func toolbarColorScheme(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func toolbarForegroundStyle(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func toolbarRole(_ p0: Any? = nil) -> Self { self }
    public func toolbarTitleDisplayMode(_ p0: Any? = nil) -> Self { self }
    public func toolbarTitleMenu(content p0: Any? = nil) -> Self { self }
    public func toolbarVisibility(_ p0: Any? = nil, `for` p1: Any? = nil) -> Self { self }
    public func tracking(_ tracking: CGFloat) -> Self { contactsUIApplyingModifier("tracking(\(Double(tracking)))") }
    public func transaction(_ p0: Any? = nil) -> Self { self }
    public func transaction(_ p0: Any? = nil, body p1: Any? = nil) -> Self { self }
    public func transaction(value p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func transformAnchorPreference(key p0: Any? = nil, value p1: Any? = nil, transform p2: Any? = nil) -> Self { self }
    public func transformEffect(_ p0: Any? = nil) -> Self { self }
    public func transformEnvironment(_ p0: Any? = nil, transform p1: Any? = nil) -> Self { self }
    public func transformPreference(_ p0: Any? = nil, _ p1: Any? = nil) -> Self { self }
    public func transition(_ p0: Any? = nil) -> Self { self }
    public func truncationMode(_ p0: Any? = nil) -> Self { self }
    public func typeSelectEquivalent(_ p0: Any? = nil) -> Self { self }
    public func typesettingLanguage(_ p0: Any? = nil, isEnabled p1: Any? = nil) -> Self { self }
    public func underline(_ p0: Any? = nil, pattern p1: Any? = nil, color p2: Any? = nil) -> Self { self }
    public func unredacted() -> Self { contactsUIApplyingModifier("unredacted()") }
    public func userActivity(_ p0: Any? = nil, element p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func userActivity(_ p0: Any? = nil, isActive p1: Any? = nil, _ p2: Any? = nil) -> Self { self }
    public func visualEffect(_ p0: Any? = nil) -> Self { self }
    public func windowToolbarFullScreenVisibility(_ p0: Any? = nil) -> Self { self }
    public func writingDirection(strategy p0: Any? = nil) -> Self { self }
    public func writingToolsAffordanceVisibility(_ p0: Any? = nil) -> Self { self }
    public func writingToolsBehavior(_ p0: Any? = nil) -> Self { self }
    public func zIndex(_ value: Double) -> Self { contactsUIApplyingModifier("zIndex(\(value))") }
}

extension ContactAccessButton {
    /// Calls a representative set of identity View modifiers so coverage
    /// claims for those identifiers are exercised, not merely compiled.
    @_spi(OpenUIKitHost)
    public func linuxExerciseIdentityModifiers() -> ContactAccessButton {
        var result = self
        result = result.hidden()
        result = result.disabled(true)
        result = result.opacity(0.5)
        result = result.padding(8)
        result = result.zIndex(1)
        result = result.bold(true)
        result = result.italic(true)
        result = result.frame()
        result = result.fixedSize()
        result = result.colorInvert()
        result = result.scaledToFit()
        result = result.scaledToFill()
        result = result.labelsHidden()
        result = result.unredacted()
        result = result.grayscale(0.2)
        result = result.brightness(0.1)
        result = result.contrast(1.1)
        result = result.saturation(0.9)
        result = result.kerning(0.2)
        result = result.tracking(0.1)
        result = result.lineSpacing(2)
        result = result.lineLimit(2)
        result = result.layoutPriority(1)
        result = result.minimumScaleFactor(0.8)
        result = result.allowsTightening(true)
        result = result.allowsHitTesting(true)
        result = result.moveDisabled(true)
        result = result.deleteDisabled(true)
        result = result.scrollDisabled(true)
        result = result.focusable(true)
        result = result.monospaced(true)
        result = result.monospacedDigit()
        result = result.compositingGroup()
        result = result.luminanceToAlpha()
        result = result.geometryGroup()
        result = result.clipped()
        result = result.privacySensitive(true)
        result = result.selectionDisabled(true)
        result = result.replaceDisabled(true)
        result = result.findDisabled(true)
        result = result.submitScope(true)
        result = result.disableAutocorrection(true)
        result = result.statusBarHidden(true)
        result = result.navigationBarHidden(true)
        result = result.safeAreaPadding(4)
        result = result.gridCellColumns(2)
        result = result.listRowSpacing(4)
        result = result.listSectionSpacing(8)
        result = result.baselineOffset(1)
        result = result.labelReservedIconWidth(12)
        result = result.labelIconToTitleSpacing(4)
        result = result.defaultAppStorage(UserDefaults.standard)
        result = result.navigationDocument(URL(string: "https://example.com")!)
        result = result.badge(1)
        result = result.offset(x: 1, y: 1)
        result = result.brightness(0)
        return result.applyingLinuxModifier("linuxExerciseIdentityModifiers()")
    }
}
#endif

