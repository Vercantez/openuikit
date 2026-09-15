import Foundation

// Identity View overlays synthesized onto Chart types.
// Linux has no SwiftUI layout engine; these compile as no-ops so the
// overlay census can be exercised without inventing Apple layout.
// Compiled only when SwiftUI is absent (isolated host).

#if !canImport(SwiftUI)
extension View {
    public func accentColor() -> Self { self }
    public func accessibility() -> Self { self }
    public func accessibilityAction() -> Self { self }
    public func accessibilityActions() -> Self { self }
    public func accessibilityActivationPoint(_ p0: Any? = nil) -> Self { self }
    public func accessibilityAddTraits(_ p0: Any? = nil) -> Self { self }
    public func accessibilityAdjustableAction(_ p0: Any? = nil) -> Self { self }
    public func accessibilityChartDescriptor(_ p0: Any? = nil) -> Self { self }
    public func accessibilityChildren(_ p0: Any? = nil) -> Self { self }
    public func accessibilityCustomContent(_ p0: Any? = nil) -> Self { self }
    public func accessibilityDefaultFocus(_ p0: Any? = nil) -> Self { self }
    public func accessibilityDirectTouch(_ p0: Any? = nil) -> Self { self }
    public func accessibilityDragPoint(_ p0: Any? = nil) -> Self { self }
    public func accessibilityDropPoint(_ p0: Any? = nil) -> Self { self }
    public func accessibilityFocused() -> Self { self }
    public func accessibilityHeading() -> Self { self }
    public func accessibilityHidden() -> Self { self }
    public func accessibilityHint() -> Self { self }
    public func accessibilityIdentifier(_ p0: Any? = nil) -> Self { self }
    public func accessibilityIgnoresInvertColors(_ p0: Any? = nil) -> Self { self }
    public func accessibilityInputLabels(_ p0: Any? = nil) -> Self { self }
    public func accessibilityLabel() -> Self { self }
    public func accessibilityLabeledPair(_ p0: Any? = nil) -> Self { self }
    public func accessibilityLinkedGroup(_ p0: Any? = nil) -> Self { self }
    public func accessibilityRemoveTraits(_ p0: Any? = nil) -> Self { self }
    public func accessibilityRepresentation(_ p0: Any? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction(_ p0: Any? = nil) -> Self { self }
    public func accessibilityRotor() -> Self { self }
    public func accessibilityRotorEntry(_ p0: Any? = nil) -> Self { self }
    public func accessibilityScrollAction(_ p0: Any? = nil) -> Self { self }
    public func accessibilityScrollStatus(_ p0: Any? = nil) -> Self { self }
    public func accessibilitySortPriority(_ p0: Any? = nil) -> Self { self }
    public func accessibilityTextContentType(_ p0: Any? = nil) -> Self { self }
    public func accessibilityValue() -> Self { self }
    public func accessibilityZoomAction(_ p0: Any? = nil) -> Self { self }
    public func actionSheet() -> Self { self }
    public func alert(_ p0: Any? = nil) -> Self { self }
    public func alignmentGuide() -> Self { self }
    public func allowedDynamicRange() -> Self { self }
    public func allowsHitTesting() -> Self { self }
    public func allowsTightening() -> Self { self }
    public func anchorPreference() -> Self { self }
    public func animation(_ p0: Any? = nil) -> Self { self }
    public func aspectRatio() -> Self { self }
    public func assistiveAccessNavigationIcon(_ p0: Any? = nil) -> Self { self }
    public func attributedTextFormattingDefinition(_ p0: Any? = nil) -> Self { self }
    public func autocapitalization() -> Self { self }
    public func autocorrectionDisabled(_ p0: Any? = nil) -> Self { self }
    public func background() -> Self { self }
    public func backgroundPreferenceValue(_ p0: Any? = nil) -> Self { self }
    public func backgroundStyle() -> Self { self }
    public func badge(_ p0: Any? = nil) -> Self { self }
    public func badgeProminence() -> Self { self }
    public func baselineOffset() -> Self { self }
    public func blendMode(_ p0: Any? = nil) -> Self { self }
    public func blur(_ p0: Any? = nil) -> Self { self }
    public func bold(_ p0: Any? = nil) -> Self { self }
    public func border(_ p0: Any? = nil) -> Self { self }
    public func brightness() -> Self { self }
    public func buttonBorderShape() -> Self { self }
    public func buttonRepeatBehavior() -> Self { self }
    public func buttonSizing() -> Self { self }
    public func buttonStyle() -> Self { self }
    public func clipped(_ p0: Any? = nil) -> Self { self }
    public func clipShape(_ p0: Any? = nil) -> Self { self }
    public func colorEffect() -> Self { self }
    public func colorMultiply() -> Self { self }
    public func colorScheme() -> Self { self }
    public func confirmationDialog() -> Self { self }
    public func containerBackground() -> Self { self }
    public func containerCornerOffset(_ p0: Any? = nil) -> Self { self }
    public func containerRelativeFrame(_ p0: Any? = nil) -> Self { self }
    public func containerShape() -> Self { self }
    public func containerValue() -> Self { self }
    public func contentMargins() -> Self { self }
    public func contentShape() -> Self { self }
    public func contentToolbar() -> Self { self }
    public func contentTransition() -> Self { self }
    public func contextMenu() -> Self { self }
    public func contrast(_ p0: Any? = nil) -> Self { self }
    public func controlGroupStyle() -> Self { self }
    public func controlSize() -> Self { self }
    public func coordinateSpace() -> Self { self }
    public func cornerRadius() -> Self { self }
    public func datePickerStyle() -> Self { self }
    public func defaultAdaptableTabBarPlacement(_ p0: Any? = nil) -> Self { self }
    public func defaultAppStorage() -> Self { self }
    public func defaultFocus() -> Self { self }
    public func defaultHoverEffect() -> Self { self }
    public func defaultScrollAnchor() -> Self { self }
    public func defersSystemGestures() -> Self { self }
    public func deleteDisabled() -> Self { self }
    public func dialogIcon() -> Self { self }
    public func dialogSuppressionToggle(_ p0: Any? = nil) -> Self { self }
    public func disableAutocorrection(_ p0: Any? = nil) -> Self { self }
    public func disabled(_ p0: Any? = nil) -> Self { self }
    public func disclosureGroupStyle() -> Self { self }
    public func distortionEffect() -> Self { self }
    public func documentBrowserContextMenu(_ p0: Any? = nil) -> Self { self }
    public func draggable(_ p0: Any? = nil) -> Self { self }
    public func drawingGroup() -> Self { self }
    public func dropDestination() -> Self { self }
    public func dynamicTypeSize() -> Self { self }
    public func edgesIgnoringSafeArea(_ p0: Any? = nil) -> Self { self }
    public func environment() -> Self { self }
    public func environmentObject() -> Self { self }
    public func fileDialogBrowserOptions(_ p0: Any? = nil) -> Self { self }
    public func fileDialogConfirmationLabel(_ p0: Any? = nil) -> Self { self }
    public func fileDialogCustomizationID(_ p0: Any? = nil) -> Self { self }
    public func fileDialogDefaultDirectory(_ p0: Any? = nil) -> Self { self }
    public func fileDialogImportsUnresolvedAliases(_ p0: Any? = nil) -> Self { self }
    public func fileDialogMessage() -> Self { self }
    public func fileDialogURLEnabled() -> Self { self }
    public func fileExporter() -> Self { self }
    public func fileExporterFilenameLabel(_ p0: Any? = nil) -> Self { self }
    public func fileImporter() -> Self { self }
    public func fileMover(_ p0: Any? = nil) -> Self { self }
    public func findDisabled() -> Self { self }
    public func findNavigator() -> Self { self }
    public func flipsForRightToLeftLayoutDirection(_ p0: Any? = nil) -> Self { self }
    public func focusable(_ p0: Any? = nil) -> Self { self }
    public func focused(_ p0: Any? = nil) -> Self { self }
    public func focusedObject() -> Self { self }
    public func focusedSceneObject() -> Self { self }
    public func focusedSceneValue() -> Self { self }
    public func focusedValue() -> Self { self }
    public func focusEffectDisabled() -> Self { self }
    public func font(_ p0: Any? = nil) -> Self { self }
    public func fontDesign() -> Self { self }
    public func fontWeight() -> Self { self }
    public func fontWidth(_ p0: Any? = nil) -> Self { self }
    public func foregroundColor() -> Self { self }
    public func foregroundStyle() -> Self { self }
    public func formStyle(_ p0: Any? = nil) -> Self { self }
    public func fullScreenCover() -> Self { self }
    public func gaugeStyle() -> Self { self }
    public func gesture(_ p0: Any? = nil) -> Self { self }
    public func glassEffect() -> Self { self }
    public func glassEffectID() -> Self { self }
    public func glassEffectTransition(_ p0: Any? = nil) -> Self { self }
    public func glassEffectUnion() -> Self { self }
    public func grayscale(_ p0: Any? = nil) -> Self { self }
    public func gridCellAnchor() -> Self { self }
    public func gridCellColumns() -> Self { self }
    public func gridCellUnsizedAxes() -> Self { self }
    public func gridColumnAlignment() -> Self { self }
    public func groupBoxStyle() -> Self { self }
    public func handGestureShortcut() -> Self { self }
    public func handlesExternalEvents(_ p0: Any? = nil) -> Self { self }
    public func headerProminence() -> Self { self }
    public func help(_ p0: Any? = nil) -> Self { self }
    public func highPriorityGesture() -> Self { self }
    public func hoverEffect() -> Self { self }
    public func hoverEffectDisabled() -> Self { self }
    public func hueRotation() -> Self { self }
    public func id(_ p0: Any? = nil) -> Self { self }
    public func ignoresSafeArea() -> Self { self }
    public func imageScale() -> Self { self }
    public func indexViewStyle() -> Self { self }
    public func inspector(_ p0: Any? = nil) -> Self { self }
    public func inspectorColumnWidth() -> Self { self }
    public func interactionActivityTrackingTag(_ p0: Any? = nil) -> Self { self }
    public func interactiveDismissDisabled(_ p0: Any? = nil) -> Self { self }
    public func invalidatableContent() -> Self { self }
    public func italic(_ p0: Any? = nil) -> Self { self }
    public func itemProvider() -> Self { self }
    public func kerning(_ p0: Any? = nil) -> Self { self }
    public func keyboardShortcut() -> Self { self }
    public func keyboardType() -> Self { self }
    public func keyframeAnimator() -> Self { self }
    public func labeledContentStyle() -> Self { self }
    public func labelIconToTitleSpacing(_ p0: Any? = nil) -> Self { self }
    public func labelReservedIconWidth(_ p0: Any? = nil) -> Self { self }
    public func labelStyle() -> Self { self }
    public func labelsVisibility() -> Self { self }
    public func layerEffect() -> Self { self }
    public func layoutDirectionBehavior(_ p0: Any? = nil) -> Self { self }
    public func layoutPriority() -> Self { self }
    public func layoutValue() -> Self { self }
    public func lineHeight() -> Self { self }
    public func lineLimit(_ p0: Any? = nil) -> Self { self }
    public func lineSpacing() -> Self { self }
    public func listItemTint() -> Self { self }
    public func listRowBackground() -> Self { self }
    public func listRowInsets() -> Self { self }
    public func listRowSeparator() -> Self { self }
    public func listRowSeparatorTint() -> Self { self }
    public func listRowSpacing() -> Self { self }
    public func listSectionIndexVisibility(_ p0: Any? = nil) -> Self { self }
    public func listSectionMargins() -> Self { self }
    public func listSectionSeparator() -> Self { self }
    public func listSectionSeparatorTint(_ p0: Any? = nil) -> Self { self }
    public func listSectionSpacing() -> Self { self }
    public func listStyle(_ p0: Any? = nil) -> Self { self }
    public func mask(_ p0: Any? = nil) -> Self { self }
    public func matchedGeometryEffect(_ p0: Any? = nil) -> Self { self }
    public func matchedTransitionSource(_ p0: Any? = nil) -> Self { self }
    public func materialActiveAppearance(_ p0: Any? = nil) -> Self { self }
    public func menuActionDismissBehavior(_ p0: Any? = nil) -> Self { self }
    public func menuIndicator() -> Self { self }
    public func menuOrder(_ p0: Any? = nil) -> Self { self }
    public func menuStyle(_ p0: Any? = nil) -> Self { self }
    public func minimumScaleFactor() -> Self { self }
    public func modifier(_ p0: Any? = nil) -> Self { self }
    public func monospaced() -> Self { self }
    public func moveDisabled() -> Self { self }
    public func multilineTextAlignment(_ p0: Any? = nil) -> Self { self }
    public func navigationBarBackButtonHidden(_ p0: Any? = nil) -> Self { self }
    public func navigationBarHidden() -> Self { self }
    public func navigationBarItems() -> Self { self }
    public func navigationBarTitle() -> Self { self }
    public func navigationBarTitleDisplayMode(_ p0: Any? = nil) -> Self { self }
    public func navigationDestination(_ p0: Any? = nil) -> Self { self }
    public func navigationDocument() -> Self { self }
    public func navigationLinkIndicatorVisibility(_ p0: Any? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth() -> Self { self }
    public func navigationSplitViewStyle() -> Self { self }
    public func navigationSubtitle() -> Self { self }
    public func navigationTitle() -> Self { self }
    public func navigationTransition() -> Self { self }
    public func navigationViewStyle() -> Self { self }
    public func offset(_ p0: Any? = nil) -> Self { self }
    public func onAppear(_ p0: Any? = nil) -> Self { self }
    public func onChange(_ p0: Any? = nil) -> Self { self }
    public func onContinueUserActivity(_ p0: Any? = nil) -> Self { self }
    public func onContinuousHover() -> Self { self }
    public func onDisappear() -> Self { self }
    public func onDrag(_ p0: Any? = nil) -> Self { self }
    public func onDrop(_ p0: Any? = nil) -> Self { self }
    public func onGeometryChange() -> Self { self }
    public func onHover(_ p0: Any? = nil) -> Self { self }
    public func onInteractiveResizeChange(_ p0: Any? = nil) -> Self { self }
    public func onKeyPress() -> Self { self }
    public func onLongPressGesture() -> Self { self }
    public func onOpenURL(_ p0: Any? = nil) -> Self { self }
    public func onPencilDoubleTap() -> Self { self }
    public func onPencilSqueeze() -> Self { self }
    public func onPreferenceChange() -> Self { self }
    public func onReceive(_ p0: Any? = nil) -> Self { self }
    public func onScrollGeometryChange(_ p0: Any? = nil) -> Self { self }
    public func onScrollPhaseChange() -> Self { self }
    public func onScrollTargetVisibilityChange(_ p0: Any? = nil) -> Self { self }
    public func onScrollVisibilityChange(_ p0: Any? = nil) -> Self { self }
    public func onSubmit(_ p0: Any? = nil) -> Self { self }
    public func onTapGesture() -> Self { self }
    public func opacity(_ p0: Any? = nil) -> Self { self }
    public func overlay(_ p0: Any? = nil) -> Self { self }
    public func overlayPreferenceValue(_ p0: Any? = nil) -> Self { self }
    public func padding(_ p0: Any? = nil) -> Self { self }
    public func paletteSelectionEffect(_ p0: Any? = nil) -> Self { self }
    public func persistentSystemOverlays(_ p0: Any? = nil) -> Self { self }
    public func phaseAnimator() -> Self { self }
    public func pickerStyle() -> Self { self }
    public func popover(_ p0: Any? = nil) -> Self { self }
    public func position(_ p0: Any? = nil) -> Self { self }
    public func preference() -> Self { self }
    public func preferredColorScheme() -> Self { self }
    public func presentationBackground(_ p0: Any? = nil) -> Self { self }
    public func presentationBackgroundInteraction(_ p0: Any? = nil) -> Self { self }
    public func presentationCompactAdaptation(_ p0: Any? = nil) -> Self { self }
    public func presentationContentInteraction(_ p0: Any? = nil) -> Self { self }
    public func presentationCornerRadius(_ p0: Any? = nil) -> Self { self }
    public func presentationDetents() -> Self { self }
    public func presentationDragIndicator(_ p0: Any? = nil) -> Self { self }
    public func presentationSizing() -> Self { self }
    public func previewContext() -> Self { self }
    public func previewDevice() -> Self { self }
    public func previewDisplayName() -> Self { self }
    public func previewInterfaceOrientation(_ p0: Any? = nil) -> Self { self }
    public func previewLayout() -> Self { self }
    public func privacySensitive() -> Self { self }
    public func progressViewStyle() -> Self { self }
    public func projectionEffect() -> Self { self }
    public func redacted(_ p0: Any? = nil) -> Self { self }
    public func refreshable() -> Self { self }
    public func renameAction() -> Self { self }
    public func replaceDisabled() -> Self { self }
    public func rotation3DEffect() -> Self { self }
    public func rotationEffect() -> Self { self }
    public func safeAreaBar() -> Self { self }
    public func safeAreaInset() -> Self { self }
    public func safeAreaPadding() -> Self { self }
    public func saturation() -> Self { self }
    public func scaleEffect() -> Self { self }
    public func scenePadding() -> Self { self }
    public func scrollBounceBehavior() -> Self { self }
    public func scrollClipDisabled() -> Self { self }
    public func scrollContentBackground(_ p0: Any? = nil) -> Self { self }
    public func scrollDisabled() -> Self { self }
    public func scrollDismissesKeyboard(_ p0: Any? = nil) -> Self { self }
    public func scrollEdgeEffectHidden(_ p0: Any? = nil) -> Self { self }
    public func scrollEdgeEffectStyle(_ p0: Any? = nil) -> Self { self }
    public func scrollIndicators() -> Self { self }
    public func scrollIndicatorsFlash(_ p0: Any? = nil) -> Self { self }
    public func scrollInputBehavior() -> Self { self }
    public func scrollPosition() -> Self { self }
    public func scrollTargetBehavior() -> Self { self }
    public func scrollTargetLayout() -> Self { self }
    public func scrollTransition() -> Self { self }
    public func searchable() -> Self { self }
    public func searchCompletion() -> Self { self }
    public func searchDictationBehavior(_ p0: Any? = nil) -> Self { self }
    public func searchFocused() -> Self { self }
    public func searchPresentationToolbarBehavior(_ p0: Any? = nil) -> Self { self }
    public func searchScopes() -> Self { self }
    public func searchSelection() -> Self { self }
    public func searchSuggestions() -> Self { self }
    public func searchToolbarBehavior(_ p0: Any? = nil) -> Self { self }
    public func sectionActions() -> Self { self }
    public func sectionIndexLabel() -> Self { self }
    public func selectionDisabled() -> Self { self }
    public func sensoryFeedback() -> Self { self }
    public func shadow(_ p0: Any? = nil) -> Self { self }
    public func sheet(_ p0: Any? = nil) -> Self { self }
    public func simultaneousGesture() -> Self { self }
    public func sliderThumbVisibility(_ p0: Any? = nil) -> Self { self }
    public func speechAdjustedPitch() -> Self { self }
    public func speechAlwaysIncludesPunctuation(_ p0: Any? = nil) -> Self { self }
    public func speechAnnouncementsQueued(_ p0: Any? = nil) -> Self { self }
    public func speechSpellsOutCharacters(_ p0: Any? = nil) -> Self { self }
    public func springLoadingBehavior(_ p0: Any? = nil) -> Self { self }
    public func statusBar(_ p0: Any? = nil) -> Self { self }
    public func statusBarHidden() -> Self { self }
    public func strikethrough() -> Self { self }
    public func submitLabel() -> Self { self }
    public func submitScope() -> Self { self }
    public func swipeActions() -> Self { self }
    public func symbolColorRenderingMode(_ p0: Any? = nil) -> Self { self }
    public func symbolEffect() -> Self { self }
    public func symbolEffectsRemoved() -> Self { self }
    public func symbolRenderingMode() -> Self { self }
    public func symbolVariableValueMode(_ p0: Any? = nil) -> Self { self }
    public func symbolVariant() -> Self { self }
    public func tabBarMinimizeBehavior(_ p0: Any? = nil) -> Self { self }
    public func tabItem(_ p0: Any? = nil) -> Self { self }
    public func tableColumnHeaders() -> Self { self }
    public func tableStyle() -> Self { self }
    public func tabViewBottomAccessory() -> Self { self }
    public func tabViewCustomization() -> Self { self }
    public func tabViewSearchActivation() -> Self { self }
    public func tabViewSidebarBottomBar() -> Self { self }
    public func tabViewSidebarFooter() -> Self { self }
    public func tabViewSidebarHeader() -> Self { self }
    public func tabViewStyle() -> Self { self }
    public func tag(_ p0: Any? = nil) -> Self { self }
    public func task(_ p0: Any? = nil) -> Self { self }
    public func textCase(_ p0: Any? = nil) -> Self { self }
    public func textContentType() -> Self { self }
    public func textEditorStyle() -> Self { self }
    public func textFieldStyle() -> Self { self }
    public func textInputAutocapitalization(_ p0: Any? = nil) -> Self { self }
    public func textInputFormattingControlVisibility(_ p0: Any? = nil) -> Self { self }
    public func textRenderer() -> Self { self }
    public func textScale(_ p0: Any? = nil) -> Self { self }
    public func textSelection() -> Self { self }
    public func textSelectionAffinity(_ p0: Any? = nil) -> Self { self }
    public func tint(_ p0: Any? = nil) -> Self { self }
    public func toggleStyle() -> Self { self }
    public func toolbar(_ p0: Any? = nil) -> Self { self }
    public func toolbarBackground() -> Self { self }
    public func toolbarBackgroundVisibility(_ p0: Any? = nil) -> Self { self }
    public func toolbarColorScheme() -> Self { self }
    public func toolbarForegroundStyle(_ p0: Any? = nil) -> Self { self }
    public func toolbarRole() -> Self { self }
    public func toolbarTitleDisplayMode(_ p0: Any? = nil) -> Self { self }
    public func toolbarTitleMenu() -> Self { self }
    public func toolbarVisibility() -> Self { self }
    public func tracking(_ p0: Any? = nil) -> Self { self }
    public func transaction() -> Self { self }
    public func transformAnchorPreference(_ p0: Any? = nil) -> Self { self }
    public func transformEffect() -> Self { self }
    public func transformEnvironment() -> Self { self }
    public func transformPreference() -> Self { self }
    public func transition() -> Self { self }
    public func truncationMode() -> Self { self }
    public func typeSelectEquivalent() -> Self { self }
    public func typesettingLanguage() -> Self { self }
    public func underline(_ p0: Any? = nil) -> Self { self }
    public func userActivity() -> Self { self }
    public func visualEffect() -> Self { self }
    public func windowToolbarFullScreenVisibility(_ p0: Any? = nil) -> Self { self }
    public func writingDirection() -> Self { self }
    public func writingToolsAffordanceVisibility(_ p0: Any? = nil) -> Self { self }
    public func writingToolsBehavior(_ p0: Any? = nil) -> Self { self }
    public func zIndex(_ p0: Any? = nil) -> Self { self }
}
#endif
