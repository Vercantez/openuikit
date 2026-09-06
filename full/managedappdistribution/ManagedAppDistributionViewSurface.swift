import Foundation

// Identity View modifiers that exist because ManagedAppView and
// ManagedContentView conform to View. Linux has no SwiftUI layout
// engine; these compile as no-ops so the synthesized overlay census can
// be declared without inventing layout. Compiled only when SwiftUI is
// absent (isolated host).

#if !canImport(SwiftUI)
extension View {
    public func navigationViewStyle(_ : Any? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth(min _: Any? = nil, ideal _: Any? = nil, max _: Any? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth(_ : Any? = nil) -> Self { self }
    public func navigationSplitViewStyle(_ : Any? = nil) -> Self { self }
    public func tabViewCustomization(_ : Any? = nil) -> Self { self }
    public func tabViewSidebarFooter(content _: Any? = nil) -> Self { self }
    public func tabViewSidebarHeader(content _: Any? = nil) -> Self { self }
    public func tabViewBottomAccessory(content _: Any? = nil) -> Self { self }
    public func tabViewSearchActivation(_ : Any? = nil) -> Self { self }
    public func tabViewSidebarBottomBar(content _: Any? = nil) -> Self { self }
    public func tabViewStyle(_ : Any? = nil) -> Self { self }
    public func indexViewStyle(_ : Any? = nil) -> Self { self }
    public func progressViewStyle(_ : Any? = nil) -> Self { self }
    public func background(ignoresSafeAreaEdges _: Any? = nil) -> Self { self }
    public func background(in _: Any? = nil, fillStyle _: Any? = nil) -> Self { self }
    public func background(alignment _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func background(_ : Any? = nil, ignoresSafeAreaEdges _: Any? = nil) -> Self { self }
    public func background(_ : Any? = nil, in _: Any? = nil, fillStyle _: Any? = nil) -> Self { self }
    public func background(_ : Any? = nil, alignment _: Any? = nil) -> Self { self }
    public func brightness(_ : Any? = nil) -> Self { self }
    public func dialogIcon(_ : Any? = nil) -> Self { self }
    public func fontDesign(_ : Any? = nil) -> Self { self }
    public func fontWeight(_ : Any? = nil) -> Self { self }
    public func gaugeStyle(_ : Any? = nil) -> Self { self }
    public func imageScale(_ : Any? = nil) -> Self { self }
    public func labelStyle(_ : Any? = nil) -> Self { self }
    public func lineHeight(_ : Any? = nil) -> Self { self }
    public func monospaced(_ : Any? = nil) -> Self { self }
    public func onKeyPress(characters _: Any? = nil, phases _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func onKeyPress(keys _: Any? = nil, phases _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func onKeyPress(phases _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func onKeyPress(_ : Any? = nil, action _: Any? = nil) -> Self { self }
    public func onKeyPress(_ : Any? = nil, phases _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func preference(key _: Any? = nil, value _: Any? = nil) -> Self { self }
    public func saturation(_ : Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, isPresented _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, editableTokens _: Any? = nil, isPresented _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, token _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, editableTokens _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, token _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, tokens _: Any? = nil, isPresented _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, token _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, tokens _: Any? = nil, suggestedTokens _: Any? = nil, isPresented _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, token _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, tokens _: Any? = nil, suggestedTokens _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, token _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, tokens _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, token _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil, suggestions _: Any? = nil) -> Self { self }
    public func searchable(text _: Any? = nil, placement _: Any? = nil, prompt _: Any? = nil) -> Self { self }
    public func tableStyle(_ : Any? = nil) -> Self { self }
    public func transition(_ : Any? = nil) -> Self { self }
    public func unredacted() -> Self { self }
    public func accentColor(_ : Any? = nil) -> Self { self }
    public func actionSheet(isPresented _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func actionSheet(item _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func aspectRatio(_ : Any? = nil, contentMode _: Any? = nil) -> Self { self }
    public func buttonStyle(_ : Any? = nil) -> Self { self }
    public func colorEffect(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func colorInvert() -> Self { self }
    public func colorScheme(_ : Any? = nil) -> Self { self }
    public func contextMenu(forSelectionType _: Any? = nil, menu _: Any? = nil, primaryAction _: Any? = nil) -> Self { self }
    public func contextMenu(menuItems _: Any? = nil, preview _: Any? = nil) -> Self { self }
    public func contextMenu(menuItems _: Any? = nil) -> Self { self }
    public func contextMenu(_ : Any? = nil) -> Self { self }
    public func controlSize(_ : Any? = nil) -> Self { self }
    public func environment(_ : Any? = nil) -> Self { self }
    public func environment(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func glassEffect(_ : Any? = nil, in _: Any? = nil) -> Self { self }
    public func hoverEffect(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func hoverEffect(_ : Any? = nil) -> Self { self }
    public func hueRotation(_ : Any? = nil) -> Self { self }
    public func layerEffect(_ : Any? = nil, maxSampleOffset _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func layoutValue(key _: Any? = nil, value _: Any? = nil) -> Self { self }
    public func lineSpacing(_ : Any? = nil) -> Self { self }
    public func onDisappear(perform _: Any? = nil) -> Self { self }
    public func pickerStyle(_ : Any? = nil) -> Self { self }
    public func refreshable(action _: Any? = nil) -> Self { self }
    public func safeAreaBar(edge _: Any? = nil, alignment _: Any? = nil, spacing _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func scaleEffect(x _: Any? = nil, y _: Any? = nil, anchor _: Any? = nil) -> Self { self }
    public func scaleEffect(_ : Any? = nil, anchor _: Any? = nil) -> Self { self }
    public func scaledToFit() -> Self { self }
    public func submitLabel(_ : Any? = nil) -> Self { self }
    public func submitScope(_ : Any? = nil) -> Self { self }
    public func toggleStyle(_ : Any? = nil) -> Self { self }
    public func toolbarRole(_ : Any? = nil) -> Self { self }
    public func transaction(value _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func transaction(_ : Any? = nil, body _: Any? = nil) -> Self { self }
    public func transaction(_ : Any? = nil) -> Self { self }
    public func buttonSizing(_ : Any? = nil) -> Self { self }
    public func contentShape(_ : Any? = nil, eoFill _: Any? = nil) -> Self { self }
    public func contentShape(_ : Any? = nil, _ : Any? = nil, eoFill _: Any? = nil) -> Self { self }
    public func cornerRadius(_ : Any? = nil, antialiased _: Any? = nil) -> Self { self }
    public func defaultFocus(_ : Any? = nil, _ : Any? = nil, priority _: Any? = nil) -> Self { self }
    public func drawingGroup(opaque _: Any? = nil, colorMode _: Any? = nil) -> Self { self }
    public func fileExporter(isPresented _: Any? = nil, item _: Any? = nil, contentTypes _: Any? = nil, defaultFilename _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileExporter(isPresented _: Any? = nil, items _: Any? = nil, contentTypes _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileExporter(isPresented _: Any? = nil, document _: Any? = nil, contentType _: Any? = nil, defaultFilename _: Any? = nil, onCompletion _: Any? = nil) -> Self { self }
    public func fileExporter(isPresented _: Any? = nil, document _: Any? = nil, contentTypes _: Any? = nil, defaultFilename _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileExporter(isPresented _: Any? = nil, documents _: Any? = nil, contentType _: Any? = nil, onCompletion _: Any? = nil) -> Self { self }
    public func fileExporter(isPresented _: Any? = nil, documents _: Any? = nil, contentTypes _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileImporter(isPresented _: Any? = nil, allowedContentTypes _: Any? = nil, onCompletion _: Any? = nil) -> Self { self }
    public func fileImporter(isPresented _: Any? = nil, allowedContentTypes _: Any? = nil, allowsMultipleSelection _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileImporter(isPresented _: Any? = nil, allowedContentTypes _: Any? = nil, allowsMultipleSelection _: Any? = nil, onCompletion _: Any? = nil) -> Self { self }
    public func findDisabled(_ : Any? = nil) -> Self { self }
    public func focusedValue(_ : Any? = nil) -> Self { self }
    public func focusedValue(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func itemProvider(_ : Any? = nil) -> Self { self }
    public func keyboardType(_ : Any? = nil) -> Self { self }
    public func labelsHidden() -> Self { self }
    public func listItemTint(_ : Any? = nil) -> Self { self }
    public func moveDisabled(_ : Any? = nil) -> Self { self }
    public func onTapGesture(count _: Any? = nil, coordinateSpace _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onTapGesture(count _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func renameAction(_ : Any? = nil) -> Self { self }
    public func scaledToFill() -> Self { self }
    public func scenePadding(_ : Any? = nil, edges _: Any? = nil) -> Self { self }
    public func scenePadding(_ : Any? = nil) -> Self { self }
    public func searchScopes(_ : Any? = nil, activation _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func searchScopes(_ : Any? = nil, scopes _: Any? = nil) -> Self { self }
    public func swipeActions(edge _: Any? = nil, allowsFullSwipe _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func symbolEffect(_ : Any? = nil, options _: Any? = nil, value _: Any? = nil) -> Self { self }
    public func symbolEffect(_ : Any? = nil, options _: Any? = nil, isActive _: Any? = nil) -> Self { self }
    public func textRenderer(_ : Any? = nil) -> Self { self }
    public func userActivity(_ : Any? = nil, element _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func userActivity(_ : Any? = nil, isActive _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func visualEffect(_ : Any? = nil) -> Self { self }
    public func accessibility(identifier _: Any? = nil) -> Self { self }
    public func accessibility(inputLabels _: Any? = nil) -> Self { self }
    public func accessibility(removeTraits _: Any? = nil) -> Self { self }
    public func accessibility(sortPriority _: Any? = nil) -> Self { self }
    public func accessibility(activationPoint _: Any? = nil) -> Self { self }
    public func accessibility(selectionIdentifier _: Any? = nil) -> Self { self }
    public func accessibility(hint _: Any? = nil) -> Self { self }
    public func accessibility(label _: Any? = nil) -> Self { self }
    public func accessibility(value _: Any? = nil) -> Self { self }
    public func accessibility(hidden _: Any? = nil) -> Self { self }
    public func accessibility(addTraits _: Any? = nil) -> Self { self }
    public func colorMultiply(_ : Any? = nil) -> Self { self }
    public func findNavigator(isPresented _: Any? = nil) -> Self { self }
    public func focusedObject(_ : Any? = nil) -> Self { self }
    public func geometryGroup() -> Self { self }
    public func glassEffectID(_ : Any? = nil, in _: Any? = nil) -> Self { self }
    public func groupBoxStyle(_ : Any? = nil) -> Self { self }
    public func listRowInsets(_ : Any? = nil) -> Self { self }
    public func listRowInsets(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func menuIndicator(_ : Any? = nil) -> Self { self }
    public func phaseAnimator(_ : Any? = nil, content _: Any? = nil, animation _: Any? = nil) -> Self { self }
    public func phaseAnimator(_ : Any? = nil, trigger _: Any? = nil, content _: Any? = nil, animation _: Any? = nil) -> Self { self }
    public func previewDevice(_ : Any? = nil) -> Self { self }
    public func previewLayout(_ : Any? = nil) -> Self { self }
    public func safeAreaInset(edge _: Any? = nil, alignment _: Any? = nil, spacing _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func searchFocused(_ : Any? = nil, equals _: Any? = nil) -> Self { self }
    public func searchFocused(_ : Any? = nil) -> Self { self }
    public func strikethrough(_ : Any? = nil, pattern _: Any? = nil, color _: Any? = nil) -> Self { self }
    public func symbolVariant(_ : Any? = nil) -> Self { self }
    public func textSelection(_ : Any? = nil) -> Self { self }
    public func alignmentGuide(_ : Any? = nil, computeValue _: Any? = nil) -> Self { self }
    public func baselineOffset(_ : Any? = nil) -> Self { self }
    public func containerShape(_ : Any? = nil) -> Self { self }
    public func containerValue(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func contentMargins(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func contentMargins(_ : Any? = nil, _ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func contentToolbar(for _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func deleteDisabled(_ : Any? = nil) -> Self { self }
    public func gridCellAnchor(_ : Any? = nil) -> Self { self }
    public func layoutPriority(_ : Any? = nil) -> Self { self }
    public func listRowSpacing(_ : Any? = nil) -> Self { self }
    public func previewContext(_ : Any? = nil) -> Self { self }
    public func rotationEffect(_ : Any? = nil, anchor _: Any? = nil) -> Self { self }
    public func scrollDisabled(_ : Any? = nil) -> Self { self }
    public func scrollPosition(id _: Any? = nil, anchor _: Any? = nil) -> Self { self }
    public func scrollPosition(_ : Any? = nil, anchor _: Any? = nil) -> Self { self }
    public func sectionActions(content _: Any? = nil) -> Self { self }
    public func textFieldStyle(_ : Any? = nil) -> Self { self }
    public func truncationMode(_ : Any? = nil) -> Self { self }
    public func backgroundStyle(_ : Any? = nil) -> Self { self }
    public func badgeProminence(_ : Any? = nil) -> Self { self }
    public func coordinateSpace(name _: Any? = nil) -> Self { self }
    public func coordinateSpace(_ : Any? = nil) -> Self { self }
    public func datePickerStyle(_ : Any? = nil) -> Self { self }
    public func dropDestination(for _: Any? = nil, action _: Any? = nil, isTargeted _: Any? = nil) -> Self { self }
    public func dropDestination(for _: Any? = nil, isEnabled _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func dynamicTypeSize(_ : Any? = nil) -> Self { self }
    public func foregroundColor(_ : Any? = nil) -> Self { self }
    public func foregroundStyle(_ : Any? = nil) -> Self { self }
    public func foregroundStyle(_ : Any? = nil, _ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func foregroundStyle(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func fullScreenCover(isPresented _: Any? = nil, onDismiss _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func fullScreenCover(item _: Any? = nil, onDismiss _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func gridCellColumns(_ : Any? = nil) -> Self { self }
    public func ignoresSafeArea(_ : Any? = nil, edges _: Any? = nil) -> Self { self }
    public func monospacedDigit() -> Self { self }
    public func navigationTitle(_ : Any? = nil) -> Self { self }
    public func onPencilSqueeze(perform _: Any? = nil) -> Self { self }
    public func replaceDisabled(_ : Any? = nil) -> Self { self }
    public func safeAreaPadding(_ : Any? = nil) -> Self { self }
    public func safeAreaPadding(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func searchSelection(_ : Any? = nil) -> Self { self }
    public func sensoryFeedback(trigger _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func sensoryFeedback(_ : Any? = nil, trigger _: Any? = nil, condition _: Any? = nil) -> Self { self }
    public func sensoryFeedback(_ : Any? = nil, trigger _: Any? = nil) -> Self { self }
    public func statusBarHidden(_ : Any? = nil) -> Self { self }
    public func textContentType(_ : Any? = nil) -> Self { self }
    public func textEditorStyle(_ : Any? = nil) -> Self { self }
    public func transformEffect(_ : Any? = nil) -> Self { self }
    public func allowsHitTesting(_ : Any? = nil) -> Self { self }
    public func allowsTightening(_ : Any? = nil) -> Self { self }
    public func anchorPreference(key _: Any? = nil, value _: Any? = nil, transform _: Any? = nil) -> Self { self }
    public func compositingGroup() -> Self { self }
    public func distortionEffect(_ : Any? = nil, maxSampleOffset _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func glassEffectUnion(id _: Any? = nil, namespace _: Any? = nil) -> Self { self }
    public func headerProminence(_ : Any? = nil) -> Self { self }
    public func keyboardShortcut(_ : Any? = nil, modifiers _: Any? = nil, localization _: Any? = nil) -> Self { self }
    public func keyboardShortcut(_ : Any? = nil, modifiers _: Any? = nil) -> Self { self }
    public func keyboardShortcut(_ : Any? = nil) -> Self { self }
    public func keyframeAnimator(initialValue _: Any? = nil, trigger _: Any? = nil, content _: Any? = nil, keyframes _: Any? = nil) -> Self { self }
    public func keyframeAnimator(initialValue _: Any? = nil, repeating _: Any? = nil, content _: Any? = nil, keyframes _: Any? = nil) -> Self { self }
    public func labelsVisibility(_ : Any? = nil) -> Self { self }
    public func listRowSeparator(_ : Any? = nil, edges _: Any? = nil) -> Self { self }
    public func luminanceToAlpha() -> Self { self }
    public func onGeometryChange(for _: Any? = nil, of _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func privacySensitive(_ : Any? = nil) -> Self { self }
    public func projectionEffect(_ : Any? = nil) -> Self { self }
    public func rotation3DEffect(_ : Any? = nil, axis _: Any? = nil, anchor _: Any? = nil, anchorZ _: Any? = nil, perspective _: Any? = nil) -> Self { self }
    public func scrollIndicators(_ : Any? = nil, axes _: Any? = nil) -> Self { self }
    public func scrollTransition(topLeading _: Any? = nil, bottomTrailing _: Any? = nil, axis _: Any? = nil, transition _: Any? = nil) -> Self { self }
    public func scrollTransition(_ : Any? = nil, axis _: Any? = nil, transition _: Any? = nil) -> Self { self }
    public func searchCompletion(_ : Any? = nil) -> Self { self }
    public func toolbarTitleMenu(content _: Any? = nil) -> Self { self }
    public func writingDirection(strategy _: Any? = nil) -> Self { self }
    public func accessibilityHint(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityHint(_ : Any? = nil) -> Self { self }
    public func buttonBorderShape(_ : Any? = nil) -> Self { self }
    public func contentTransition(_ : Any? = nil) -> Self { self }
    public func controlGroupStyle(_ : Any? = nil) -> Self { self }
    public func defaultAppStorage(_ : Any? = nil) -> Self { self }
    public func environmentObject(_ : Any? = nil) -> Self { self }
    public func fileDialogMessage(_ : Any? = nil) -> Self { self }
    public func focusedSceneValue(_ : Any? = nil) -> Self { self }
    public func focusedSceneValue(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func listRowBackground(_ : Any? = nil) -> Self { self }
    public func onContinuousHover(coordinateSpace _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onPencilDoubleTap(perform _: Any? = nil) -> Self { self }
    public func searchSuggestions(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func searchSuggestions(_ : Any? = nil) -> Self { self }
    public func sectionIndexLabel(_ : Any? = nil) -> Self { self }
    public func selectionDisabled(_ : Any? = nil) -> Self { self }
    public func toolbarBackground(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func toolbarVisibility(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func accessibilityLabel(content _: Any? = nil) -> Self { self }
    public func accessibilityLabel(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityLabel(_ : Any? = nil) -> Self { self }
    public func accessibilityRotor(_ : Any? = nil, textRanges _: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ : Any? = nil, entries _: Any? = nil, entryLabel _: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ : Any? = nil, entries _: Any? = nil, entryID _: Any? = nil, entryLabel _: Any? = nil) -> Self { self }
    public func accessibilityRotor(_ : Any? = nil, entries _: Any? = nil) -> Self { self }
    public func accessibilityValue(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityValue(_ : Any? = nil) -> Self { self }
    public func autocapitalization(_ : Any? = nil) -> Self { self }
    public func confirmationDialog(_ : Any? = nil, isPresented _: Any? = nil, titleVisibility _: Any? = nil, presenting _: Any? = nil, actions _: Any? = nil, message _: Any? = nil) -> Self { self }
    public func confirmationDialog(_ : Any? = nil, isPresented _: Any? = nil, titleVisibility _: Any? = nil, presenting _: Any? = nil, actions _: Any? = nil) -> Self { self }
    public func confirmationDialog(_ : Any? = nil, isPresented _: Any? = nil, titleVisibility _: Any? = nil, actions _: Any? = nil, message _: Any? = nil) -> Self { self }
    public func confirmationDialog(_ : Any? = nil, isPresented _: Any? = nil, titleVisibility _: Any? = nil, actions _: Any? = nil) -> Self { self }
    public func defaultHoverEffect(_ : Any? = nil) -> Self { self }
    public func focusedSceneObject(_ : Any? = nil) -> Self { self }
    public func listSectionMargins(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func listSectionSpacing(_ : Any? = nil) -> Self { self }
    public func minimumScaleFactor(_ : Any? = nil) -> Self { self }
    public func navigationBarItems(leading _: Any? = nil, trailing _: Any? = nil) -> Self { self }
    public func navigationBarItems(leading _: Any? = nil) -> Self { self }
    public func navigationBarItems(trailing _: Any? = nil) -> Self { self }
    public func navigationBarTitle(_ : Any? = nil, displayMode _: Any? = nil) -> Self { self }
    public func navigationBarTitle(_ : Any? = nil) -> Self { self }
    public func navigationDocument(_ : Any? = nil, preview _: Any? = nil) -> Self { self }
    public func navigationDocument(_ : Any? = nil) -> Self { self }
    public func navigationSubtitle(_ : Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration _: Any? = nil, maximumDistance _: Any? = nil, perform _: Any? = nil, onPressingChanged _: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration _: Any? = nil, maximumDistance _: Any? = nil, pressing _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration _: Any? = nil, perform _: Any? = nil, onPressingChanged _: Any? = nil) -> Self { self }
    public func onLongPressGesture(minimumDuration _: Any? = nil, pressing _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onPreferenceChange(_ : Any? = nil, perform _: Any? = nil) -> Self { self }
    public func presentationSizing(_ : Any? = nil) -> Self { self }
    public func previewDisplayName(_ : Any? = nil) -> Self { self }
    public func scrollClipDisabled(_ : Any? = nil) -> Self { self }
    public func scrollTargetLayout(isEnabled _: Any? = nil) -> Self { self }
    public func tableColumnHeaders(_ : Any? = nil) -> Self { self }
    public func toolbarColorScheme(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func accessibilityAction(named _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func accessibilityAction(action _: Any? = nil, label _: Any? = nil) -> Self { self }
    public func accessibilityAction(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func accessibilityHidden(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityHidden(_ : Any? = nil) -> Self { self }
    public func allowedDynamicRange(_ : Any? = nil) -> Self { self }
    public func containerBackground(for _: Any? = nil, alignment _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func containerBackground(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func defaultScrollAnchor(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func defaultScrollAnchor(_ : Any? = nil) -> Self { self }
    public func focusEffectDisabled(_ : Any? = nil) -> Self { self }
    public func gridCellUnsizedAxes(_ : Any? = nil) -> Self { self }
    public func gridColumnAlignment(_ : Any? = nil) -> Self { self }
    public func handGestureShortcut(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func highPriorityGesture(_ : Any? = nil, name _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func highPriorityGesture(_ : Any? = nil, including _: Any? = nil) -> Self { self }
    public func highPriorityGesture(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func hoverEffectDisabled(_ : Any? = nil) -> Self { self }
    public func labeledContentStyle(_ : Any? = nil) -> Self { self }
    public func navigationBarHidden(_ : Any? = nil) -> Self { self }
    public func onScrollPhaseChange(_ : Any? = nil) -> Self { self }
    public func presentationDetents(_ : Any? = nil, selection _: Any? = nil) -> Self { self }
    public func presentationDetents(_ : Any? = nil) -> Self { self }
    public func scrollInputBehavior(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func simultaneousGesture(_ : Any? = nil, name _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func simultaneousGesture(_ : Any? = nil, including _: Any? = nil) -> Self { self }
    public func simultaneousGesture(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func speechAdjustedPitch(_ : Any? = nil) -> Self { self }
    public func symbolRenderingMode(_ : Any? = nil) -> Self { self }
    public func transformPreference(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func typesettingLanguage(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityActions(category _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func accessibilityActions(_ : Any? = nil) -> Self { self }
    public func accessibilityElement(children _: Any? = nil) -> Self { self }
    public func accessibilityFocused(_ : Any? = nil, equals _: Any? = nil) -> Self { self }
    public func accessibilityFocused(_ : Any? = nil) -> Self { self }
    public func accessibilityHeading(_ : Any? = nil) -> Self { self }
    public func buttonRepeatBehavior(_ : Any? = nil) -> Self { self }
    public func defersSystemGestures(on _: Any? = nil) -> Self { self }
    public func disclosureGroupStyle(_ : Any? = nil) -> Self { self }
    public func fileDialogURLEnabled(_ : Any? = nil) -> Self { self }
    public func inspectorColumnWidth(min _: Any? = nil, ideal _: Any? = nil, max _: Any? = nil) -> Self { self }
    public func inspectorColumnWidth(_ : Any? = nil) -> Self { self }
    public func invalidatableContent(_ : Any? = nil) -> Self { self }
    public func listRowSeparatorTint(_ : Any? = nil, edges _: Any? = nil) -> Self { self }
    public func listSectionSeparator(_ : Any? = nil, edges _: Any? = nil) -> Self { self }
    public func navigationTransition(_ : Any? = nil) -> Self { self }
    public func preferredColorScheme(_ : Any? = nil) -> Self { self }
    public func scrollBounceBehavior(_ : Any? = nil, axes _: Any? = nil) -> Self { self }
    public func scrollTargetBehavior(_ : Any? = nil) -> Self { self }
    public func symbolEffectsRemoved(_ : Any? = nil) -> Self { self }
    public func transformEnvironment(_ : Any? = nil, transform _: Any? = nil) -> Self { self }
    public func typeSelectEquivalent(_ : Any? = nil) -> Self { self }
    public func writingToolsBehavior(_ : Any? = nil) -> Self { self }
    public func accessibilityChildren(children _: Any? = nil) -> Self { self }
    public func containerCornerOffset(_ : Any? = nil, sizeToFit _: Any? = nil) -> Self { self }
    public func disableAutocorrection(_ : Any? = nil) -> Self { self }
    public func edgesIgnoringSafeArea(_ : Any? = nil) -> Self { self }
    public func glassEffectTransition(_ : Any? = nil) -> Self { self }
    public func handlesExternalEvents(preferring _: Any? = nil, allowing _: Any? = nil) -> Self { self }
    public func matchedGeometryEffect(id _: Any? = nil, in _: Any? = nil, properties _: Any? = nil, anchor _: Any? = nil, isSource _: Any? = nil) -> Self { self }
    public func navigationDestination(isPresented _: Any? = nil, destination _: Any? = nil) -> Self { self }
    public func navigationDestination(for _: Any? = nil, destination _: Any? = nil) -> Self { self }
    public func navigationDestination(item _: Any? = nil, destination _: Any? = nil) -> Self { self }
    public func scrollEdgeEffectStyle(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func scrollIndicatorsFlash(trigger _: Any? = nil) -> Self { self }
    public func scrollIndicatorsFlash(onAppear _: Any? = nil) -> Self { self }
    public func searchToolbarBehavior(_ : Any? = nil) -> Self { self }
    public func sliderThumbVisibility(_ : Any? = nil) -> Self { self }
    public func springLoadingBehavior(_ : Any? = nil) -> Self { self }
    public func textSelectionAffinity(_ : Any? = nil) -> Self { self }
    public func accessibilityAddTraits(_ : Any? = nil) -> Self { self }
    public func accessibilityDragPoint(_ : Any? = nil, description _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityDragPoint(_ : Any? = nil, description _: Any? = nil) -> Self { self }
    public func accessibilityDropPoint(_ : Any? = nil, description _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityDropPoint(_ : Any? = nil, description _: Any? = nil) -> Self { self }
    public func autocorrectionDisabled(_ : Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ : Any? = nil, count _: Any? = nil, span _: Any? = nil, spacing _: Any? = nil, alignment _: Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ : Any? = nil, alignment _: Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ : Any? = nil, alignment _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func labelReservedIconWidth(_ : Any? = nil) -> Self { self }
    public func multilineTextAlignment(strategy _: Any? = nil) -> Self { self }
    public func multilineTextAlignment(_ : Any? = nil) -> Self { self }
    public func onContinueUserActivity(_ : Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onScrollGeometryChange(for _: Any? = nil, of _: Any? = nil, action _: Any? = nil) -> Self { self }
    public func overlayPreferenceValue(_ : Any? = nil, alignment _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func overlayPreferenceValue(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func paletteSelectionEffect(_ : Any? = nil) -> Self { self }
    public func presentationBackground(alignment _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func presentationBackground(_ : Any? = nil) -> Self { self }
    public func scrollEdgeEffectHidden(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func tabBarMinimizeBehavior(_ : Any? = nil) -> Self { self }
    public func toolbarForegroundStyle(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func accessibilityIdentifier(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityIdentifier(_ : Any? = nil) -> Self { self }
    public func accessibilityRotorEntry(id _: Any? = nil, in _: Any? = nil) -> Self { self }
    public func accessibilityZoomAction(_ : Any? = nil) -> Self { self }
    public func dialogSuppressionToggle(isSuppressed _: Any? = nil) -> Self { self }
    public func dialogSuppressionToggle(_ : Any? = nil, isSuppressed _: Any? = nil) -> Self { self }
    public func labelIconToTitleSpacing(_ : Any? = nil) -> Self { self }
    public func layoutDirectionBehavior(_ : Any? = nil) -> Self { self }
    public func matchedTransitionSource(id _: Any? = nil, in _: Any? = nil, configuration _: Any? = nil) -> Self { self }
    public func matchedTransitionSource(id _: Any? = nil, in _: Any? = nil) -> Self { self }
    public func scrollContentBackground(_ : Any? = nil) -> Self { self }
    public func scrollDismissesKeyboard(_ : Any? = nil) -> Self { self }
    public func searchDictationBehavior(_ : Any? = nil) -> Self { self }
    public func symbolVariableValueMode(_ : Any? = nil) -> Self { self }
    public func toolbarTitleDisplayMode(_ : Any? = nil) -> Self { self }
    public func accessibilityDirectTouch(_ : Any? = nil, options _: Any? = nil) -> Self { self }
    public func accessibilityInputLabels(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityInputLabels(_ : Any? = nil) -> Self { self }
    public func accessibilityLabeledPair(role _: Any? = nil, id _: Any? = nil, in _: Any? = nil) -> Self { self }
    public func accessibilityLinkedGroup(id _: Any? = nil, in _: Any? = nil) -> Self { self }
    public func fileDialogBrowserOptions(_ : Any? = nil) -> Self { self }
    public func listSectionSeparatorTint(_ : Any? = nil, edges _: Any? = nil) -> Self { self }
    public func materialActiveAppearance(_ : Any? = nil) -> Self { self }
    public func onScrollVisibilityChange(threshold _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func persistentSystemOverlays(_ : Any? = nil) -> Self { self }
    public func presentationCornerRadius(_ : Any? = nil) -> Self { self }
    public func symbolColorRenderingMode(_ : Any? = nil) -> Self { self }
    public func accessibilityDefaultFocus(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func accessibilityRemoveTraits(_ : Any? = nil) -> Self { self }
    public func accessibilityScrollAction(_ : Any? = nil) -> Self { self }
    public func accessibilityScrollStatus(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilitySortPriority(_ : Any? = nil) -> Self { self }
    public func backgroundExtensionEffect(isEnabled _: Any? = nil) -> Self { self }
    public func backgroundExtensionEffect() -> Self { self }
    public func backgroundPreferenceValue(_ : Any? = nil, alignment _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func backgroundPreferenceValue(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func fileDialogCustomizationID(_ : Any? = nil) -> Self { self }
    public func fileExporterFilenameLabel(_ : Any? = nil) -> Self { self }
    public func menuActionDismissBehavior(_ : Any? = nil) -> Self { self }
    public func onInteractiveResizeChange(_ : Any? = nil) -> Self { self }
    public func presentationDragIndicator(_ : Any? = nil) -> Self { self }
    public func speechAnnouncementsQueued(_ : Any? = nil) -> Self { self }
    public func speechSpellsOutCharacters(_ : Any? = nil) -> Self { self }
    public func transformAnchorPreference(key _: Any? = nil, value _: Any? = nil, transform _: Any? = nil) -> Self { self }
    public func accessibilityCustomContent(_ : Any? = nil, _ : Any? = nil, importance _: Any? = nil) -> Self { self }
    public func documentBrowserContextMenu(_ : Any? = nil) -> Self { self }
    public func fileDialogDefaultDirectory(_ : Any? = nil) -> Self { self }
    public func interactiveDismissDisabled(_ : Any? = nil) -> Self { self }
    public func listSectionIndexVisibility(_ : Any? = nil) -> Self { self }
    public func accessibilityRepresentation(representation _: Any? = nil) -> Self { self }
    public func fileDialogConfirmationLabel(_ : Any? = nil) -> Self { self }
    public func previewInterfaceOrientation(_ : Any? = nil) -> Self { self }
    public func textInputAutocapitalization(_ : Any? = nil) -> Self { self }
    public func toolbarBackgroundVisibility(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func accessibilityActivationPoint(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityActivationPoint(_ : Any? = nil) -> Self { self }
    public func accessibilityChartDescriptor(_ : Any? = nil) -> Self { self }
    public func accessibilityTextContentType(_ : Any? = nil) -> Self { self }
    public func allowsWindowActivationEvents() -> Self { self }
    public func allowsWindowActivationEvents(_ : Any? = nil) -> Self { self }
    public func accessibilityAdjustableAction(_ : Any? = nil) -> Self { self }
    public func assistiveAccessNavigationIcon(systemImage _: Any? = nil) -> Self { self }
    public func assistiveAccessNavigationIcon(_ : Any? = nil) -> Self { self }
    public func navigationBarBackButtonHidden(_ : Any? = nil) -> Self { self }
    public func navigationBarTitleDisplayMode(_ : Any? = nil) -> Self { self }
    public func presentationCompactAdaptation(horizontal _: Any? = nil, vertical _: Any? = nil) -> Self { self }
    public func presentationCompactAdaptation(_ : Any? = nil) -> Self { self }
    public func id(_ : Any? = nil) -> Self { self }
    public func interactionActivityTrackingTag(_ : Any? = nil) -> Self { self }
    public func onScrollTargetVisibilityChange(idType _: Any? = nil, threshold _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func presentationContentInteraction(_ : Any? = nil) -> Self { self }
    public func defaultAdaptableTabBarPlacement(_ : Any? = nil) -> Self { self }
    public func speechAlwaysIncludesPunctuation(_ : Any? = nil) -> Self { self }
    public func accessibilityIgnoresInvertColors(_ : Any? = nil) -> Self { self }
    public func writingToolsAffordanceVisibility(_ : Any? = nil) -> Self { self }
    public func navigationLinkIndicatorVisibility(_ : Any? = nil) -> Self { self }
    public func presentationBackgroundInteraction(_ : Any? = nil) -> Self { self }
    public func searchPresentationToolbarBehavior(_ : Any? = nil) -> Self { self }
    public func windowToolbarFullScreenVisibility(_ : Any? = nil) -> Self { self }
    public func attributedTextFormattingDefinition(_ : Any? = nil) -> Self { self }
    public func fileDialogImportsUnresolvedAliases(_ : Any? = nil) -> Self { self }
    public func flipsForRightToLeftLayoutDirection(_ : Any? = nil) -> Self { self }
    public func accessibilityShowsLargeContentViewer() -> Self { self }
    public func accessibilityShowsLargeContentViewer(_ : Any? = nil) -> Self { self }
    public func textInputFormattingControlVisibility(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction(_ : Any? = nil) -> Self { self }
    public func tag(_ : Any? = nil, includeOptional _: Any? = nil) -> Self { self }
    public func blur(radius _: Any? = nil, opaque _: Any? = nil) -> Self { self }
    public func bold(_ : Any? = nil) -> Self { self }
    public func font(_ : Any? = nil) -> Self { self }
    public func help(_ : Any? = nil) -> Self { self }
    public func mask(alignment _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func mask(_ : Any? = nil) -> Self { self }
    public func task(id _: Any? = nil, name _: Any? = nil, executorPreference _: Any? = nil, priority _: Any? = nil, file _: Any? = nil, line _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func task(id _: Any? = nil, priority _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func task(priority _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func tint(_ : Any? = nil) -> Self { self }
    public func alert(isPresented _: Any? = nil, error _: Any? = nil, actions _: Any? = nil, message _: Any? = nil) -> Self { self }
    public func alert(isPresented _: Any? = nil, error _: Any? = nil, actions _: Any? = nil) -> Self { self }
    public func alert(isPresented _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func alert(item _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func alert(_ : Any? = nil, isPresented _: Any? = nil, presenting _: Any? = nil, actions _: Any? = nil, message _: Any? = nil) -> Self { self }
    public func alert(_ : Any? = nil, isPresented _: Any? = nil, presenting _: Any? = nil, actions _: Any? = nil) -> Self { self }
    public func alert(_ : Any? = nil, isPresented _: Any? = nil, actions _: Any? = nil, message _: Any? = nil) -> Self { self }
    public func alert(_ : Any? = nil, isPresented _: Any? = nil, actions _: Any? = nil) -> Self { self }
    public func badge(_ : Any? = nil) -> Self { self }
    public func frame(width _: Any? = nil, height _: Any? = nil, alignment _: Any? = nil) -> Self { self }
    public func frame(minWidth _: Any? = nil, idealWidth _: Any? = nil, maxWidth _: Any? = nil, minHeight _: Any? = nil, idealHeight _: Any? = nil, maxHeight _: Any? = nil, alignment _: Any? = nil) -> Self { self }
    public func frame() -> Self { self }
    public func sheet(isPresented _: Any? = nil, onDismiss _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func sheet(item _: Any? = nil, onDismiss _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func border(_ : Any? = nil, width _: Any? = nil) -> Self { self }
    public func hidden() -> Self { self }
    public func italic(_ : Any? = nil) -> Self { self }
    public func offset(x _: Any? = nil, y _: Any? = nil) -> Self { self }
    public func offset(_ : Any? = nil) -> Self { self }
    public func onDrag(_ : Any? = nil, preview _: Any? = nil) -> Self { self }
    public func onDrag(_ : Any? = nil) -> Self { self }
    public func onDrop(of _: Any? = nil, isTargeted _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onDrop(of _: Any? = nil, delegate _: Any? = nil) -> Self { self }
    public func shadow(color _: Any? = nil, radius _: Any? = nil, x _: Any? = nil, y _: Any? = nil) -> Self { self }
    public func zIndex(_ : Any? = nil) -> Self { self }
    public func clipped(antialiased _: Any? = nil) -> Self { self }
    public func focused(_ : Any? = nil, equals _: Any? = nil) -> Self { self }
    public func focused(_ : Any? = nil) -> Self { self }
    public func gesture(_ : Any? = nil, name _: Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func gesture(_ : Any? = nil, including _: Any? = nil) -> Self { self }
    public func gesture(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func gesture(_ : Any? = nil) -> Self { self }
    public func kerning(_ : Any? = nil) -> Self { self }
    public func onHover(perform _: Any? = nil) -> Self { self }
    public func opacity(_ : Any? = nil) -> Self { self }
    public func overlay(alignment _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func overlay(_ : Any? = nil, ignoresSafeAreaEdges _: Any? = nil) -> Self { self }
    public func overlay(_ : Any? = nil, in _: Any? = nil, fillStyle _: Any? = nil) -> Self { self }
    public func overlay(_ : Any? = nil, alignment _: Any? = nil) -> Self { self }
    public func padding(_ : Any? = nil) -> Self { self }
    public func padding(_ : Any? = nil, _ : Any? = nil) -> Self { self }
    public func popover(isPresented _: Any? = nil, attachmentAnchor _: Any? = nil, arrowEdge _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func popover(item _: Any? = nil, attachmentAnchor _: Any? = nil, arrowEdge _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func tabItem(_ : Any? = nil) -> Self { self }
    public func toolbar(id _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func toolbar(content _: Any? = nil) -> Self { self }
    public func toolbar(removing _: Any? = nil) -> Self { self }
    public func toolbar(_ : Any? = nil, for _: Any? = nil) -> Self { self }
    public func contrast(_ : Any? = nil) -> Self { self }
    public func disabled(_ : Any? = nil) -> Self { self }
    public func modifier(_ : Any? = nil) -> Self { self }
    public func onAppear(perform _: Any? = nil) -> Self { self }
    public func onChange(of _: Any? = nil, initial _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func onChange(of _: Any? = nil, perform _: Any? = nil) -> Self { self }
    public func onSubmit(of _: Any? = nil, _ : Any? = nil) -> Self { self }
    public func position(x _: Any? = nil, y _: Any? = nil) -> Self { self }
    public func position(_ : Any? = nil) -> Self { self }
    public func redacted(reason _: Any? = nil) -> Self { self }
    public func textCase(_ : Any? = nil) -> Self { self }
    public func tracking(_ : Any? = nil) -> Self { self }
    public func animation(_ : Any? = nil, body _: Any? = nil) -> Self { self }
    public func animation(_ : Any? = nil, value _: Any? = nil) -> Self { self }
    public func animation(_ : Any? = nil) -> Self { self }
    public func blendMode(_ : Any? = nil) -> Self { self }
    public func clipShape(_ : Any? = nil, style _: Any? = nil) -> Self { self }
    public func draggable(_ : Any? = nil, preview _: Any? = nil) -> Self { self }
    public func draggable(_ : Any? = nil) -> Self { self }
    public func fileMover(isPresented _: Any? = nil, file _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileMover(isPresented _: Any? = nil, file _: Any? = nil, onCompletion _: Any? = nil) -> Self { self }
    public func fileMover(isPresented _: Any? = nil, files _: Any? = nil, onCompletion _: Any? = nil, onCancellation _: Any? = nil) -> Self { self }
    public func fileMover(isPresented _: Any? = nil, files _: Any? = nil, onCompletion _: Any? = nil) -> Self { self }
    public func fixedSize(horizontal _: Any? = nil, vertical _: Any? = nil) -> Self { self }
    public func fixedSize() -> Self { self }
    public func focusable(_ : Any? = nil, interactions _: Any? = nil) -> Self { self }
    public func focusable(_ : Any? = nil) -> Self { self }
    public func fontWidth(_ : Any? = nil) -> Self { self }
    public func formStyle(_ : Any? = nil) -> Self { self }
    public func grayscale(_ : Any? = nil) -> Self { self }
    public func inspector(isPresented _: Any? = nil, content _: Any? = nil) -> Self { self }
    public func lineLimit(_ : Any? = nil, reservesSpace _: Any? = nil) -> Self { self }
    public func lineLimit(_ : Any? = nil) -> Self { self }
    public func listStyle(_ : Any? = nil) -> Self { self }
    public func menuOrder(_ : Any? = nil) -> Self { self }
    public func menuStyle(_ : Any? = nil) -> Self { self }
    public func onOpenURL(prefersInApp _: Any? = nil) -> Self { self }
    public func onOpenURL(perform _: Any? = nil) -> Self { self }
    public func onReceive(_ : Any? = nil, perform _: Any? = nil) -> Self { self }
    public func statusBar(hidden _: Any? = nil) -> Self { self }
    public func textScale(_ : Any? = nil, isEnabled _: Any? = nil) -> Self { self }
    public func underline(_ : Any? = nil, pattern _: Any? = nil, color _: Any? = nil) -> Self { self }
}
#endif
