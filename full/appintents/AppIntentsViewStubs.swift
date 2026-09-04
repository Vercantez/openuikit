#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Inert Linux-host View members matching the synthesized SiriTipView/
/// ShortcutsLink SwiftUI overlay so those precise IDs have source anchors.
enum _AppIntentsViewStubsMarker {}

#if !canImport(SwiftUI)
extension View {
    public func accentColor<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(activationPoint p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(addTraits p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(hidden p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(hint p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(identifier p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(inputLabels p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(label p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(removeTraits p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(selectionIdentifier p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(sortPriority p0: T0? = nil) -> Self { self }
    public func accessibility<T0>(value p0: T0? = nil) -> Self { self }
    public func accessibilityAction<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func accessibilityAction<T0, T1>(_ p0: T0? = nil, intent p1: T1? = nil) -> Self { self }
    public func accessibilityAction<T0, T1>(action p0: T0? = nil, label p1: T1? = nil) -> Self { self }
    public func accessibilityAction<T0, T1>(intent p0: T0? = nil, label p1: T1? = nil) -> Self { self }
    public func accessibilityAction<T0, T1>(named p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func accessibilityAction<T0, T1>(named p0: T0? = nil, intent p1: T1? = nil) -> Self { self }
    public func accessibilityActions<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityActions<T0, T1>(category p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func accessibilityActivationPoint<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityActivationPoint<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityAddTraits<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityAdjustableAction<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityChartDescriptor<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityChildren<T0>(children p0: T0? = nil) -> Self { self }
    public func accessibilityCustomContent<T0, T1, T2>(_ p0: T0? = nil, _ p1: T1? = nil, importance p2: T2? = nil) -> Self { self }
    public func accessibilityDefaultFocus<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func accessibilityDirectTouch<T0, T1>(_ p0: T0? = nil, options p1: T1? = nil) -> Self { self }
    public func accessibilityDragPoint<T0, T1>(_ p0: T0? = nil, description p1: T1? = nil) -> Self { self }
    public func accessibilityDragPoint<T0, T1, T2>(_ p0: T0? = nil, description p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func accessibilityDropPoint<T0, T1>(_ p0: T0? = nil, description p1: T1? = nil) -> Self { self }
    public func accessibilityDropPoint<T0, T1, T2>(_ p0: T0? = nil, description p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func accessibilityElement<T0>(children p0: T0? = nil) -> Self { self }
    public func accessibilityFocused<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityFocused<T0, T1>(_ p0: T0? = nil, equals p1: T1? = nil) -> Self { self }
    public func accessibilityHeading<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityHidden<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityHidden<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityHint<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityHint<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityIdentifier<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityIdentifier<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityIgnoresInvertColors<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityInputLabels<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityInputLabels<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityLabel<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityLabel<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityLabel<T0>(content p0: T0? = nil) -> Self { self }
    public func accessibilityLabeledPair<T0, T1, T2>(role p0: T0? = nil, id p1: T1? = nil, `in` p2: T2? = nil) -> Self { self }
    public func accessibilityLinkedGroup<T0, T1>(id p0: T0? = nil, `in` p1: T1? = nil) -> Self { self }
    public func accessibilityRemoveTraits<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityRepresentation<T0>(representation p0: T0? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityRespondsToUserInteraction<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityRotor<T0, T1>(_ p0: T0? = nil, entries p1: T1? = nil) -> Self { self }
    public func accessibilityRotor<T0, T1, T2, T3>(_ p0: T0? = nil, entries p1: T1? = nil, entryID p2: T2? = nil, entryLabel p3: T3? = nil) -> Self { self }
    public func accessibilityRotor<T0, T1, T2>(_ p0: T0? = nil, entries p1: T1? = nil, entryLabel p2: T2? = nil) -> Self { self }
    public func accessibilityRotor<T0, T1>(_ p0: T0? = nil, textRanges p1: T1? = nil) -> Self { self }
    public func accessibilityRotorEntry<T0, T1>(id p0: T0? = nil, `in` p1: T1? = nil) -> Self { self }
    public func accessibilityScrollAction<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityScrollStatus<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityShowsLargeContentViewer() -> Self { self }
    public func accessibilityShowsLargeContentViewer<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilitySortPriority<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityTextContentType<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityValue<T0>(_ p0: T0? = nil) -> Self { self }
    public func accessibilityValue<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func accessibilityZoomAction<T0>(_ p0: T0? = nil) -> Self { self }
    public func actionSheet<T0, T1>(isPresented p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func actionSheet<T0, T1>(item p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func alert<T0, T1, T2>(_ p0: T0? = nil, isPresented p1: T1? = nil, actions p2: T2? = nil) -> Self { self }
    public func alert<T0, T1, T2, T3>(_ p0: T0? = nil, isPresented p1: T1? = nil, actions p2: T2? = nil, message p3: T3? = nil) -> Self { self }
    public func alert<T0, T1, T2, T3>(_ p0: T0? = nil, isPresented p1: T1? = nil, presenting p2: T2? = nil, actions p3: T3? = nil) -> Self { self }
    public func alert<T0, T1, T2, T3, T4>(_ p0: T0? = nil, isPresented p1: T1? = nil, presenting p2: T2? = nil, actions p3: T3? = nil, message p4: T4? = nil) -> Self { self }
    public func alert<T0, T1>(isPresented p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func alert<T0, T1, T2>(isPresented p0: T0? = nil, error p1: T1? = nil, actions p2: T2? = nil) -> Self { self }
    public func alert<T0, T1, T2, T3>(isPresented p0: T0? = nil, error p1: T1? = nil, actions p2: T2? = nil, message p3: T3? = nil) -> Self { self }
    public func alert<T0, T1>(item p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func alignmentGuide<T0, T1>(_ p0: T0? = nil, computeValue p1: T1? = nil) -> Self { self }
    public func allowedDynamicRange<T0>(_ p0: T0? = nil) -> Self { self }
    public func allowsHitTesting<T0>(_ p0: T0? = nil) -> Self { self }
    public func allowsTightening<T0>(_ p0: T0? = nil) -> Self { self }
    public func allowsWindowActivationEvents() -> Self { self }
    public func allowsWindowActivationEvents<T0>(_ p0: T0? = nil) -> Self { self }
    public func anchorPreference<T0, T1, T2>(key p0: T0? = nil, value p1: T1? = nil, transform p2: T2? = nil) -> Self { self }
    public func animation<T0>(_ p0: T0? = nil) -> Self { self }
    public func animation<T0, T1>(_ p0: T0? = nil, body p1: T1? = nil) -> Self { self }
    public func animation<T0, T1>(_ p0: T0? = nil, value p1: T1? = nil) -> Self { self }
    public func aspectRatio<T0, T1>(_ p0: T0? = nil, contentMode p1: T1? = nil) -> Self { self }
    public func assistiveAccessNavigationIcon<T0>(_ p0: T0? = nil) -> Self { self }
    public func assistiveAccessNavigationIcon<T0>(systemImage p0: T0? = nil) -> Self { self }
    public func attributedTextFormattingDefinition<T0>(_ p0: T0? = nil) -> Self { self }
    public func autocapitalization<T0>(_ p0: T0? = nil) -> Self { self }
    public func autocorrectionDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func background<T0, T1>(_ p0: T0? = nil, alignment p1: T1? = nil) -> Self { self }
    public func background<T0, T1>(_ p0: T0? = nil, ignoresSafeAreaEdges p1: T1? = nil) -> Self { self }
    public func background<T0, T1, T2>(_ p0: T0? = nil, `in` p1: T1? = nil, fillStyle p2: T2? = nil) -> Self { self }
    public func background<T0, T1>(alignment p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func background<T0>(ignoresSafeAreaEdges p0: T0? = nil) -> Self { self }
    public func background<T0, T1>(`in` p0: T0? = nil, fillStyle p1: T1? = nil) -> Self { self }
    public func backgroundExtensionEffect() -> Self { self }
    public func backgroundExtensionEffect<T0>(isEnabled p0: T0? = nil) -> Self { self }
    public func backgroundPreferenceValue<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func backgroundPreferenceValue<T0, T1, T2>(_ p0: T0? = nil, alignment p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func backgroundStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func badge<T0>(_ p0: T0? = nil) -> Self { self }
    public func badgeProminence<T0>(_ p0: T0? = nil) -> Self { self }
    public func baselineOffset<T0>(_ p0: T0? = nil) -> Self { self }
    public func blendMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func blur<T0, T1>(radius p0: T0? = nil, opaque p1: T1? = nil) -> Self { self }
    public func bold<T0>(_ p0: T0? = nil) -> Self { self }
    public func border<T0, T1>(_ p0: T0? = nil, width p1: T1? = nil) -> Self { self }
    public func brightness<T0>(_ p0: T0? = nil) -> Self { self }
    public func buttonBorderShape<T0>(_ p0: T0? = nil) -> Self { self }
    public func buttonRepeatBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func buttonSizing<T0>(_ p0: T0? = nil) -> Self { self }
    public func buttonStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func clipShape<T0, T1>(_ p0: T0? = nil, style p1: T1? = nil) -> Self { self }
    public func clipped<T0>(antialiased p0: T0? = nil) -> Self { self }
    public func colorEffect<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func colorInvert() -> Self { self }
    public func colorMultiply<T0>(_ p0: T0? = nil) -> Self { self }
    public func colorScheme<T0>(_ p0: T0? = nil) -> Self { self }
    public func compositingGroup() -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3>(_ p0: T0? = nil, isPresented p1: T1? = nil, titleVisibility p2: T2? = nil, actions p3: T3? = nil) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3, T4>(_ p0: T0? = nil, isPresented p1: T1? = nil, titleVisibility p2: T2? = nil, actions p3: T3? = nil, message p4: T4? = nil) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3, T4>(_ p0: T0? = nil, isPresented p1: T1? = nil, titleVisibility p2: T2? = nil, presenting p3: T3? = nil, actions p4: T4? = nil) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3, T4, T5>(_ p0: T0? = nil, isPresented p1: T1? = nil, titleVisibility p2: T2? = nil, presenting p3: T3? = nil, actions p4: T4? = nil, message p5: T5? = nil) -> Self { self }
    public func containerBackground<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func containerBackground<T0, T1, T2>(`for` p0: T0? = nil, alignment p1: T1? = nil, content p2: T2? = nil) -> Self { self }
    public func containerCornerOffset<T0, T1>(_ p0: T0? = nil, sizeToFit p1: T1? = nil) -> Self { self }
    public func containerRelativeFrame<T0, T1>(_ p0: T0? = nil, alignment p1: T1? = nil) -> Self { self }
    public func containerRelativeFrame<T0, T1, T2>(_ p0: T0? = nil, alignment p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func containerRelativeFrame<T0, T1, T2, T3, T4>(_ p0: T0? = nil, count p1: T1? = nil, span p2: T2? = nil, spacing p3: T3? = nil, alignment p4: T4? = nil) -> Self { self }
    public func containerShape<T0>(_ p0: T0? = nil) -> Self { self }
    public func containerValue<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func contentMargins<T0, T1, T2>(_ p0: T0? = nil, _ p1: T1? = nil, `for` p2: T2? = nil) -> Self { self }
    public func contentMargins<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func contentShape<T0, T1, T2>(_ p0: T0? = nil, _ p1: T1? = nil, eoFill p2: T2? = nil) -> Self { self }
    public func contentShape<T0, T1>(_ p0: T0? = nil, eoFill p1: T1? = nil) -> Self { self }
    public func contentToolbar<T0, T1>(`for` p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func contentTransition<T0>(_ p0: T0? = nil) -> Self { self }
    public func contextMenu<T0>(_ p0: T0? = nil) -> Self { self }
    public func contextMenu<T0, T1, T2>(forSelectionType p0: T0? = nil, menu p1: T1? = nil, primaryAction p2: T2? = nil) -> Self { self }
    public func contextMenu<T0>(menuItems p0: T0? = nil) -> Self { self }
    public func contextMenu<T0, T1>(menuItems p0: T0? = nil, preview p1: T1? = nil) -> Self { self }
    public func contrast<T0>(_ p0: T0? = nil) -> Self { self }
    public func controlGroupStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func controlSize<T0>(_ p0: T0? = nil) -> Self { self }
    public func coordinateSpace<T0>(_ p0: T0? = nil) -> Self { self }
    public func coordinateSpace<T0>(name p0: T0? = nil) -> Self { self }
    public func cornerRadius<T0, T1>(_ p0: T0? = nil, antialiased p1: T1? = nil) -> Self { self }
    public func datePickerStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func defaultAdaptableTabBarPlacement<T0>(_ p0: T0? = nil) -> Self { self }
    public func defaultAppStorage<T0>(_ p0: T0? = nil) -> Self { self }
    public func defaultFocus<T0, T1, T2>(_ p0: T0? = nil, _ p1: T1? = nil, priority p2: T2? = nil) -> Self { self }
    public func defaultHoverEffect<T0>(_ p0: T0? = nil) -> Self { self }
    public func defaultScrollAnchor<T0>(_ p0: T0? = nil) -> Self { self }
    public func defaultScrollAnchor<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func defersSystemGestures<T0>(on p0: T0? = nil) -> Self { self }
    public func deleteDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func dialogIcon<T0>(_ p0: T0? = nil) -> Self { self }
    public func dialogSuppressionToggle<T0, T1>(_ p0: T0? = nil, isSuppressed p1: T1? = nil) -> Self { self }
    public func dialogSuppressionToggle<T0>(isSuppressed p0: T0? = nil) -> Self { self }
    public func disableAutocorrection<T0>(_ p0: T0? = nil) -> Self { self }
    public func disabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func disclosureGroupStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func distortionEffect<T0, T1, T2>(_ p0: T0? = nil, maxSampleOffset p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func documentBrowserContextMenu<T0>(_ p0: T0? = nil) -> Self { self }
    public func draggable<T0>(_ p0: T0? = nil) -> Self { self }
    public func draggable<T0, T1>(_ p0: T0? = nil, preview p1: T1? = nil) -> Self { self }
    public func drawingGroup<T0, T1>(opaque p0: T0? = nil, colorMode p1: T1? = nil) -> Self { self }
    public func dropDestination<T0, T1, T2>(`for` p0: T0? = nil, action p1: T1? = nil, isTargeted p2: T2? = nil) -> Self { self }
    public func dropDestination<T0, T1, T2>(`for` p0: T0? = nil, isEnabled p1: T1? = nil, action p2: T2? = nil) -> Self { self }
    public func dynamicTypeSize<T0>(_ p0: T0? = nil) -> Self { self }
    public func edgesIgnoringSafeArea<T0>(_ p0: T0? = nil) -> Self { self }
    public func environment<T0>(_ p0: T0? = nil) -> Self { self }
    public func environment<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func environmentObject<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogBrowserOptions<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogConfirmationLabel<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogCustomizationID<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogDefaultDirectory<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogImportsUnresolvedAliases<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogMessage<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileDialogURLEnabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4>(isPresented p0: T0? = nil, document p1: T1? = nil, contentType p2: T2? = nil, defaultFilename p3: T3? = nil, onCompletion p4: T4? = nil) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4, T5>(isPresented p0: T0? = nil, document p1: T1? = nil, contentTypes p2: T2? = nil, defaultFilename p3: T3? = nil, onCompletion p4: T4? = nil, onCancellation p5: T5? = nil) -> Self { self }
    public func fileExporter<T0, T1, T2, T3>(isPresented p0: T0? = nil, documents p1: T1? = nil, contentType p2: T2? = nil, onCompletion p3: T3? = nil) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4>(isPresented p0: T0? = nil, documents p1: T1? = nil, contentTypes p2: T2? = nil, onCompletion p3: T3? = nil, onCancellation p4: T4? = nil) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4, T5>(isPresented p0: T0? = nil, item p1: T1? = nil, contentTypes p2: T2? = nil, defaultFilename p3: T3? = nil, onCompletion p4: T4? = nil, onCancellation p5: T5? = nil) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4>(isPresented p0: T0? = nil, items p1: T1? = nil, contentTypes p2: T2? = nil, onCompletion p3: T3? = nil, onCancellation p4: T4? = nil) -> Self { self }
    public func fileExporterFilenameLabel<T0>(_ p0: T0? = nil) -> Self { self }
    public func fileImporter<T0, T1, T2, T3>(isPresented p0: T0? = nil, allowedContentTypes p1: T1? = nil, allowsMultipleSelection p2: T2? = nil, onCompletion p3: T3? = nil) -> Self { self }
    public func fileImporter<T0, T1, T2, T3, T4>(isPresented p0: T0? = nil, allowedContentTypes p1: T1? = nil, allowsMultipleSelection p2: T2? = nil, onCompletion p3: T3? = nil, onCancellation p4: T4? = nil) -> Self { self }
    public func fileImporter<T0, T1, T2>(isPresented p0: T0? = nil, allowedContentTypes p1: T1? = nil, onCompletion p2: T2? = nil) -> Self { self }
    public func fileMover<T0, T1, T2>(isPresented p0: T0? = nil, file p1: T1? = nil, onCompletion p2: T2? = nil) -> Self { self }
    public func fileMover<T0, T1, T2, T3>(isPresented p0: T0? = nil, file p1: T1? = nil, onCompletion p2: T2? = nil, onCancellation p3: T3? = nil) -> Self { self }
    public func fileMover<T0, T1, T2>(isPresented p0: T0? = nil, files p1: T1? = nil, onCompletion p2: T2? = nil) -> Self { self }
    public func fileMover<T0, T1, T2, T3>(isPresented p0: T0? = nil, files p1: T1? = nil, onCompletion p2: T2? = nil, onCancellation p3: T3? = nil) -> Self { self }
    public func findDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func findNavigator<T0>(isPresented p0: T0? = nil) -> Self { self }
    public func fixedSize() -> Self { self }
    public func fixedSize<T0, T1>(horizontal p0: T0? = nil, vertical p1: T1? = nil) -> Self { self }
    public func flipsForRightToLeftLayoutDirection<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusEffectDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusable<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusable<T0, T1>(_ p0: T0? = nil, interactions p1: T1? = nil) -> Self { self }
    public func focused<T0>(_ p0: T0? = nil) -> Self { self }
    public func focused<T0, T1>(_ p0: T0? = nil, equals p1: T1? = nil) -> Self { self }
    public func focusedObject<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusedSceneObject<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusedSceneValue<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusedSceneValue<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func focusedValue<T0>(_ p0: T0? = nil) -> Self { self }
    public func focusedValue<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func font<T0>(_ p0: T0? = nil) -> Self { self }
    public func fontDesign<T0>(_ p0: T0? = nil) -> Self { self }
    public func fontWeight<T0>(_ p0: T0? = nil) -> Self { self }
    public func fontWidth<T0>(_ p0: T0? = nil) -> Self { self }
    public func foregroundColor<T0>(_ p0: T0? = nil) -> Self { self }
    public func foregroundStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func foregroundStyle<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func foregroundStyle<T0, T1, T2>(_ p0: T0? = nil, _ p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func formStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func frame() -> Self { self }
    public func frame<T0, T1, T2, T3, T4, T5, T6>(minWidth p0: T0? = nil, idealWidth p1: T1? = nil, maxWidth p2: T2? = nil, minHeight p3: T3? = nil, idealHeight p4: T4? = nil, maxHeight p5: T5? = nil, alignment p6: T6? = nil) -> Self { self }
    public func frame<T0, T1, T2>(width p0: T0? = nil, height p1: T1? = nil, alignment p2: T2? = nil) -> Self { self }
    public func fullScreenCover<T0, T1, T2>(isPresented p0: T0? = nil, onDismiss p1: T1? = nil, content p2: T2? = nil) -> Self { self }
    public func fullScreenCover<T0, T1, T2>(item p0: T0? = nil, onDismiss p1: T1? = nil, content p2: T2? = nil) -> Self { self }
    public func gaugeStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func geometryGroup() -> Self { self }
    public func gesture<T0>(_ p0: T0? = nil) -> Self { self }
    public func gesture<T0, T1>(_ p0: T0? = nil, including p1: T1? = nil) -> Self { self }
    public func gesture<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func gesture<T0, T1, T2>(_ p0: T0? = nil, name p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func glassEffect<T0, T1>(_ p0: T0? = nil, `in` p1: T1? = nil) -> Self { self }
    public func glassEffectID<T0, T1>(_ p0: T0? = nil, `in` p1: T1? = nil) -> Self { self }
    public func glassEffectTransition<T0>(_ p0: T0? = nil) -> Self { self }
    public func glassEffectUnion<T0, T1>(id p0: T0? = nil, namespace p1: T1? = nil) -> Self { self }
    public func grayscale<T0>(_ p0: T0? = nil) -> Self { self }
    public func gridCellAnchor<T0>(_ p0: T0? = nil) -> Self { self }
    public func gridCellColumns<T0>(_ p0: T0? = nil) -> Self { self }
    public func gridCellUnsizedAxes<T0>(_ p0: T0? = nil) -> Self { self }
    public func gridColumnAlignment<T0>(_ p0: T0? = nil) -> Self { self }
    public func groupBoxStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func handGestureShortcut<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func handlesExternalEvents<T0, T1>(preferring p0: T0? = nil, allowing p1: T1? = nil) -> Self { self }
    public func headerProminence<T0>(_ p0: T0? = nil) -> Self { self }
    public func help<T0>(_ p0: T0? = nil) -> Self { self }
    public func hidden() -> Self { self }
    public func highPriorityGesture<T0, T1>(_ p0: T0? = nil, including p1: T1? = nil) -> Self { self }
    public func highPriorityGesture<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func highPriorityGesture<T0, T1, T2>(_ p0: T0? = nil, name p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func hoverEffect<T0>(_ p0: T0? = nil) -> Self { self }
    public func hoverEffect<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func hoverEffectDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func hueRotation<T0>(_ p0: T0? = nil) -> Self { self }
    public func id<T0>(_ p0: T0? = nil) -> Self { self }
    public func ignoresSafeArea<T0, T1>(_ p0: T0? = nil, edges p1: T1? = nil) -> Self { self }
    public func imageScale<T0>(_ p0: T0? = nil) -> Self { self }
    public func indexViewStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func inspector<T0, T1>(isPresented p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func inspectorColumnWidth<T0>(_ p0: T0? = nil) -> Self { self }
    public func inspectorColumnWidth<T0, T1, T2>(min p0: T0? = nil, ideal p1: T1? = nil, max p2: T2? = nil) -> Self { self }
    public func interactionActivityTrackingTag<T0>(_ p0: T0? = nil) -> Self { self }
    public func interactiveDismissDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func invalidatableContent<T0>(_ p0: T0? = nil) -> Self { self }
    public func italic<T0>(_ p0: T0? = nil) -> Self { self }
    public func itemProvider<T0>(_ p0: T0? = nil) -> Self { self }
    public func kerning<T0>(_ p0: T0? = nil) -> Self { self }
    public func keyboardShortcut<T0>(_ p0: T0? = nil) -> Self { self }
    public func keyboardShortcut<T0, T1>(_ p0: T0? = nil, modifiers p1: T1? = nil) -> Self { self }
    public func keyboardShortcut<T0, T1, T2>(_ p0: T0? = nil, modifiers p1: T1? = nil, localization p2: T2? = nil) -> Self { self }
    public func keyboardType<T0>(_ p0: T0? = nil) -> Self { self }
    public func keyframeAnimator<T0, T1, T2, T3>(initialValue p0: T0? = nil, repeating p1: T1? = nil, content p2: T2? = nil, keyframes p3: T3? = nil) -> Self { self }
    public func keyframeAnimator<T0, T1, T2, T3>(initialValue p0: T0? = nil, trigger p1: T1? = nil, content p2: T2? = nil, keyframes p3: T3? = nil) -> Self { self }
    public func labelIconToTitleSpacing<T0>(_ p0: T0? = nil) -> Self { self }
    public func labelReservedIconWidth<T0>(_ p0: T0? = nil) -> Self { self }
    public func labelStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func labeledContentStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func labelsHidden() -> Self { self }
    public func labelsVisibility<T0>(_ p0: T0? = nil) -> Self { self }
    public func layerEffect<T0, T1, T2>(_ p0: T0? = nil, maxSampleOffset p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func layoutDirectionBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func layoutPriority<T0>(_ p0: T0? = nil) -> Self { self }
    public func layoutValue<T0, T1>(key p0: T0? = nil, value p1: T1? = nil) -> Self { self }
    public func lineHeight<T0>(_ p0: T0? = nil) -> Self { self }
    public func lineLimit<T0>(_ p0: T0? = nil) -> Self { self }
    public func lineLimit<T0, T1>(_ p0: T0? = nil, reservesSpace p1: T1? = nil) -> Self { self }
    public func lineSpacing<T0>(_ p0: T0? = nil) -> Self { self }
    public func listItemTint<T0>(_ p0: T0? = nil) -> Self { self }
    public func listRowBackground<T0>(_ p0: T0? = nil) -> Self { self }
    public func listRowInsets<T0>(_ p0: T0? = nil) -> Self { self }
    public func listRowInsets<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func listRowSeparator<T0, T1>(_ p0: T0? = nil, edges p1: T1? = nil) -> Self { self }
    public func listRowSeparatorTint<T0, T1>(_ p0: T0? = nil, edges p1: T1? = nil) -> Self { self }
    public func listRowSpacing<T0>(_ p0: T0? = nil) -> Self { self }
    public func listSectionIndexVisibility<T0>(_ p0: T0? = nil) -> Self { self }
    public func listSectionMargins<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func listSectionSeparator<T0, T1>(_ p0: T0? = nil, edges p1: T1? = nil) -> Self { self }
    public func listSectionSeparatorTint<T0, T1>(_ p0: T0? = nil, edges p1: T1? = nil) -> Self { self }
    public func listSectionSpacing<T0>(_ p0: T0? = nil) -> Self { self }
    public func listStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func luminanceToAlpha() -> Self { self }
    public func mask<T0>(_ p0: T0? = nil) -> Self { self }
    public func mask<T0, T1>(alignment p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func matchedGeometryEffect<T0, T1, T2, T3, T4>(id p0: T0? = nil, `in` p1: T1? = nil, properties p2: T2? = nil, anchor p3: T3? = nil, isSource p4: T4? = nil) -> Self { self }
    public func matchedTransitionSource<T0, T1>(id p0: T0? = nil, `in` p1: T1? = nil) -> Self { self }
    public func matchedTransitionSource<T0, T1, T2>(id p0: T0? = nil, `in` p1: T1? = nil, configuration p2: T2? = nil) -> Self { self }
    public func materialActiveAppearance<T0>(_ p0: T0? = nil) -> Self { self }
    public func menuActionDismissBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func menuIndicator<T0>(_ p0: T0? = nil) -> Self { self }
    public func menuOrder<T0>(_ p0: T0? = nil) -> Self { self }
    public func menuStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func minimumScaleFactor<T0>(_ p0: T0? = nil) -> Self { self }
    public func modifier<T0>(_ p0: T0? = nil) -> Self { self }
    public func monospaced<T0>(_ p0: T0? = nil) -> Self { self }
    public func monospacedDigit() -> Self { self }
    public func moveDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func multilineTextAlignment<T0>(_ p0: T0? = nil) -> Self { self }
    public func multilineTextAlignment<T0>(strategy p0: T0? = nil) -> Self { self }
    public func navigationBarBackButtonHidden<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationBarHidden<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationBarItems<T0>(leading p0: T0? = nil) -> Self { self }
    public func navigationBarItems<T0, T1>(leading p0: T0? = nil, trailing p1: T1? = nil) -> Self { self }
    public func navigationBarItems<T0>(trailing p0: T0? = nil) -> Self { self }
    public func navigationBarTitle<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationBarTitle<T0, T1>(_ p0: T0? = nil, displayMode p1: T1? = nil) -> Self { self }
    public func navigationBarTitleDisplayMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationDestination<T0, T1>(`for` p0: T0? = nil, destination p1: T1? = nil) -> Self { self }
    public func navigationDestination<T0, T1>(isPresented p0: T0? = nil, destination p1: T1? = nil) -> Self { self }
    public func navigationDestination<T0, T1>(item p0: T0? = nil, destination p1: T1? = nil) -> Self { self }
    public func navigationDocument<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationDocument<T0, T1>(_ p0: T0? = nil, preview p1: T1? = nil) -> Self { self }
    public func navigationLinkIndicatorVisibility<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationSplitViewColumnWidth<T0, T1, T2>(min p0: T0? = nil, ideal p1: T1? = nil, max p2: T2? = nil) -> Self { self }
    public func navigationSplitViewStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationSubtitle<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationTitle<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationTransition<T0>(_ p0: T0? = nil) -> Self { self }
    public func navigationViewStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func offset<T0>(_ p0: T0? = nil) -> Self { self }
    public func offset<T0, T1>(x p0: T0? = nil, y p1: T1? = nil) -> Self { self }
    public func onAppIntentExecution<T0, T1>(_ p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func onAppear<T0>(perform p0: T0? = nil) -> Self { self }
    public func onChange<T0, T1, T2>(of p0: T0? = nil, initial p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func onChange<T0, T1>(of p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func onContinueUserActivity<T0, T1>(_ p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func onContinuousHover<T0, T1>(coordinateSpace p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func onDisappear<T0>(perform p0: T0? = nil) -> Self { self }
    public func onDrag<T0>(_ p0: T0? = nil) -> Self { self }
    public func onDrag<T0, T1>(_ p0: T0? = nil, preview p1: T1? = nil) -> Self { self }
    public func onDrop<T0, T1>(of p0: T0? = nil, delegate p1: T1? = nil) -> Self { self }
    public func onDrop<T0, T1, T2>(of p0: T0? = nil, isTargeted p1: T1? = nil, perform p2: T2? = nil) -> Self { self }
    public func onGeometryChange<T0, T1, T2>(`for` p0: T0? = nil, of p1: T1? = nil, action p2: T2? = nil) -> Self { self }
    public func onHover<T0>(perform p0: T0? = nil) -> Self { self }
    public func onInteractiveResizeChange<T0>(_ p0: T0? = nil) -> Self { self }
    public func onKeyPress<T0, T1>(_ p0: T0? = nil, action p1: T1? = nil) -> Self { self }
    public func onKeyPress<T0, T1, T2>(_ p0: T0? = nil, phases p1: T1? = nil, action p2: T2? = nil) -> Self { self }
    public func onKeyPress<T0, T1, T2>(characters p0: T0? = nil, phases p1: T1? = nil, action p2: T2? = nil) -> Self { self }
    public func onKeyPress<T0, T1, T2>(keys p0: T0? = nil, phases p1: T1? = nil, action p2: T2? = nil) -> Self { self }
    public func onKeyPress<T0, T1>(phases p0: T0? = nil, action p1: T1? = nil) -> Self { self }
    public func onLongPressGesture<T0, T1, T2, T3>(minimumDuration p0: T0? = nil, maximumDistance p1: T1? = nil, perform p2: T2? = nil, onPressingChanged p3: T3? = nil) -> Self { self }
    public func onLongPressGesture<T0, T1, T2, T3>(minimumDuration p0: T0? = nil, maximumDistance p1: T1? = nil, pressing p2: T2? = nil, perform p3: T3? = nil) -> Self { self }
    public func onLongPressGesture<T0, T1, T2>(minimumDuration p0: T0? = nil, perform p1: T1? = nil, onPressingChanged p2: T2? = nil) -> Self { self }
    public func onLongPressGesture<T0, T1, T2>(minimumDuration p0: T0? = nil, pressing p1: T1? = nil, perform p2: T2? = nil) -> Self { self }
    public func onOpenURL<T0>(perform p0: T0? = nil) -> Self { self }
    public func onOpenURL<T0>(prefersInApp p0: T0? = nil) -> Self { self }
    public func onPencilDoubleTap<T0>(perform p0: T0? = nil) -> Self { self }
    public func onPencilSqueeze<T0>(perform p0: T0? = nil) -> Self { self }
    public func onPreferenceChange<T0, T1>(_ p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func onReceive<T0, T1>(_ p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func onScrollGeometryChange<T0, T1, T2>(`for` p0: T0? = nil, of p1: T1? = nil, action p2: T2? = nil) -> Self { self }
    public func onScrollPhaseChange<T0>(_ p0: T0? = nil) -> Self { self }
    public func onScrollTargetVisibilityChange<T0, T1, T2>(idType p0: T0? = nil, threshold p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func onScrollVisibilityChange<T0, T1>(threshold p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func onSubmit<T0, T1>(of p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func onTapGesture<T0, T1, T2>(count p0: T0? = nil, coordinateSpace p1: T1? = nil, perform p2: T2? = nil) -> Self { self }
    public func onTapGesture<T0, T1>(count p0: T0? = nil, perform p1: T1? = nil) -> Self { self }
    public func opacity<T0>(_ p0: T0? = nil) -> Self { self }
    public func overlay<T0, T1>(_ p0: T0? = nil, alignment p1: T1? = nil) -> Self { self }
    public func overlay<T0, T1>(_ p0: T0? = nil, ignoresSafeAreaEdges p1: T1? = nil) -> Self { self }
    public func overlay<T0, T1, T2>(_ p0: T0? = nil, `in` p1: T1? = nil, fillStyle p2: T2? = nil) -> Self { self }
    public func overlay<T0, T1>(alignment p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func overlayPreferenceValue<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func overlayPreferenceValue<T0, T1, T2>(_ p0: T0? = nil, alignment p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func padding<T0>(_ p0: T0? = nil) -> Self { self }
    public func padding<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func paletteSelectionEffect<T0>(_ p0: T0? = nil) -> Self { self }
    public func persistentSystemOverlays<T0>(_ p0: T0? = nil) -> Self { self }
    public func phaseAnimator<T0, T1, T2>(_ p0: T0? = nil, content p1: T1? = nil, animation p2: T2? = nil) -> Self { self }
    public func phaseAnimator<T0, T1, T2, T3>(_ p0: T0? = nil, trigger p1: T1? = nil, content p2: T2? = nil, animation p3: T3? = nil) -> Self { self }
    public func pickerStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func popover<T0, T1, T2, T3>(isPresented p0: T0? = nil, attachmentAnchor p1: T1? = nil, arrowEdge p2: T2? = nil, content p3: T3? = nil) -> Self { self }
    public func popover<T0, T1, T2, T3>(item p0: T0? = nil, attachmentAnchor p1: T1? = nil, arrowEdge p2: T2? = nil, content p3: T3? = nil) -> Self { self }
    public func position<T0>(_ p0: T0? = nil) -> Self { self }
    public func position<T0, T1>(x p0: T0? = nil, y p1: T1? = nil) -> Self { self }
    public func preference<T0, T1>(key p0: T0? = nil, value p1: T1? = nil) -> Self { self }
    public func preferredColorScheme<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationBackground<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationBackground<T0, T1>(alignment p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func presentationBackgroundInteraction<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationCompactAdaptation<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationCompactAdaptation<T0, T1>(horizontal p0: T0? = nil, vertical p1: T1? = nil) -> Self { self }
    public func presentationContentInteraction<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationCornerRadius<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationDetents<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationDetents<T0, T1>(_ p0: T0? = nil, selection p1: T1? = nil) -> Self { self }
    public func presentationDragIndicator<T0>(_ p0: T0? = nil) -> Self { self }
    public func presentationSizing<T0>(_ p0: T0? = nil) -> Self { self }
    public func previewContext<T0>(_ p0: T0? = nil) -> Self { self }
    public func previewDevice<T0>(_ p0: T0? = nil) -> Self { self }
    public func previewDisplayName<T0>(_ p0: T0? = nil) -> Self { self }
    public func previewInterfaceOrientation<T0>(_ p0: T0? = nil) -> Self { self }
    public func previewLayout<T0>(_ p0: T0? = nil) -> Self { self }
    public func privacySensitive<T0>(_ p0: T0? = nil) -> Self { self }
    public func progressViewStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func projectionEffect<T0>(_ p0: T0? = nil) -> Self { self }
    public func redacted<T0>(reason p0: T0? = nil) -> Self { self }
    public func refreshable<T0>(action p0: T0? = nil) -> Self { self }
    public func renameAction<T0>(_ p0: T0? = nil) -> Self { self }
    public func replaceDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func rotation3DEffect<T0, T1, T2, T3, T4>(_ p0: T0? = nil, axis p1: T1? = nil, anchor p2: T2? = nil, anchorZ p3: T3? = nil, perspective p4: T4? = nil) -> Self { self }
    public func rotationEffect<T0, T1>(_ p0: T0? = nil, anchor p1: T1? = nil) -> Self { self }
    public func safeAreaBar<T0, T1, T2, T3>(edge p0: T0? = nil, alignment p1: T1? = nil, spacing p2: T2? = nil, content p3: T3? = nil) -> Self { self }
    public func safeAreaInset<T0, T1, T2, T3>(edge p0: T0? = nil, alignment p1: T1? = nil, spacing p2: T2? = nil, content p3: T3? = nil) -> Self { self }
    public func safeAreaPadding<T0>(_ p0: T0? = nil) -> Self { self }
    public func safeAreaPadding<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func saturation<T0>(_ p0: T0? = nil) -> Self { self }
    public func scaleEffect<T0, T1>(_ p0: T0? = nil, anchor p1: T1? = nil) -> Self { self }
    public func scaleEffect<T0, T1, T2>(x p0: T0? = nil, y p1: T1? = nil, anchor p2: T2? = nil) -> Self { self }
    public func scaledToFill() -> Self { self }
    public func scaledToFit() -> Self { self }
    public func scenePadding<T0>(_ p0: T0? = nil) -> Self { self }
    public func scenePadding<T0, T1>(_ p0: T0? = nil, edges p1: T1? = nil) -> Self { self }
    public func scrollBounceBehavior<T0, T1>(_ p0: T0? = nil, axes p1: T1? = nil) -> Self { self }
    public func scrollClipDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func scrollContentBackground<T0>(_ p0: T0? = nil) -> Self { self }
    public func scrollDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func scrollDismissesKeyboard<T0>(_ p0: T0? = nil) -> Self { self }
    public func scrollEdgeEffectHidden<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func scrollEdgeEffectStyle<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func scrollIndicators<T0, T1>(_ p0: T0? = nil, axes p1: T1? = nil) -> Self { self }
    public func scrollIndicatorsFlash<T0>(onAppear p0: T0? = nil) -> Self { self }
    public func scrollIndicatorsFlash<T0>(trigger p0: T0? = nil) -> Self { self }
    public func scrollInputBehavior<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func scrollPosition<T0, T1>(_ p0: T0? = nil, anchor p1: T1? = nil) -> Self { self }
    public func scrollPosition<T0, T1>(id p0: T0? = nil, anchor p1: T1? = nil) -> Self { self }
    public func scrollTargetBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func scrollTargetLayout<T0>(isEnabled p0: T0? = nil) -> Self { self }
    public func scrollTransition<T0, T1, T2>(_ p0: T0? = nil, axis p1: T1? = nil, transition p2: T2? = nil) -> Self { self }
    public func scrollTransition<T0, T1, T2, T3>(topLeading p0: T0? = nil, bottomTrailing p1: T1? = nil, axis p2: T2? = nil, transition p3: T3? = nil) -> Self { self }
    public func searchCompletion<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchDictationBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchFocused<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchFocused<T0, T1>(_ p0: T0? = nil, equals p1: T1? = nil) -> Self { self }
    public func searchPresentationToolbarBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchScopes<T0, T1, T2>(_ p0: T0? = nil, activation p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func searchScopes<T0, T1>(_ p0: T0? = nil, scopes p1: T1? = nil) -> Self { self }
    public func searchSelection<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchSuggestions<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchSuggestions<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func searchToolbarBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5>(text p0: T0? = nil, editableTokens p1: T1? = nil, isPresented p2: T2? = nil, placement p3: T3? = nil, prompt p4: T4? = nil, token p5: T5? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4>(text p0: T0? = nil, editableTokens p1: T1? = nil, placement p2: T2? = nil, prompt p3: T3? = nil, token p4: T4? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3>(text p0: T0? = nil, isPresented p1: T1? = nil, placement p2: T2? = nil, prompt p3: T3? = nil) -> Self { self }
    public func searchable<T0, T1, T2>(text p0: T0? = nil, placement p1: T1? = nil, prompt p2: T2? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3>(text p0: T0? = nil, placement p1: T1? = nil, prompt p2: T2? = nil, suggestions p3: T3? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5>(text p0: T0? = nil, tokens p1: T1? = nil, isPresented p2: T2? = nil, placement p3: T3? = nil, prompt p4: T4? = nil, token p5: T5? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4>(text p0: T0? = nil, tokens p1: T1? = nil, placement p2: T2? = nil, prompt p3: T3? = nil, token p4: T4? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5, T6>(text p0: T0? = nil, tokens p1: T1? = nil, suggestedTokens p2: T2? = nil, isPresented p3: T3? = nil, placement p4: T4? = nil, prompt p5: T5? = nil, token p6: T6? = nil) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5>(text p0: T0? = nil, tokens p1: T1? = nil, suggestedTokens p2: T2? = nil, placement p3: T3? = nil, prompt p4: T4? = nil, token p5: T5? = nil) -> Self { self }
    public func sectionActions<T0>(content p0: T0? = nil) -> Self { self }
    public func sectionIndexLabel<T0>(_ p0: T0? = nil) -> Self { self }
    public func selectionDisabled<T0>(_ p0: T0? = nil) -> Self { self }
    public func sensoryFeedback<T0, T1>(_ p0: T0? = nil, trigger p1: T1? = nil) -> Self { self }
    public func sensoryFeedback<T0, T1, T2>(_ p0: T0? = nil, trigger p1: T1? = nil, condition p2: T2? = nil) -> Self { self }
    public func sensoryFeedback<T0, T1>(trigger p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func shadow<T0, T1, T2, T3>(color p0: T0? = nil, radius p1: T1? = nil, x p2: T2? = nil, y p3: T3? = nil) -> Self { self }
    public func sheet<T0, T1, T2>(isPresented p0: T0? = nil, onDismiss p1: T1? = nil, content p2: T2? = nil) -> Self { self }
    public func sheet<T0, T1, T2>(item p0: T0? = nil, onDismiss p1: T1? = nil, content p2: T2? = nil) -> Self { self }
    public func shortcutsLinkStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func simultaneousGesture<T0, T1>(_ p0: T0? = nil, including p1: T1? = nil) -> Self { self }
    public func simultaneousGesture<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func simultaneousGesture<T0, T1, T2>(_ p0: T0? = nil, name p1: T1? = nil, isEnabled p2: T2? = nil) -> Self { self }
    public func siriTipViewStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func sliderThumbVisibility<T0>(_ p0: T0? = nil) -> Self { self }
    public func speechAdjustedPitch<T0>(_ p0: T0? = nil) -> Self { self }
    public func speechAlwaysIncludesPunctuation<T0>(_ p0: T0? = nil) -> Self { self }
    public func speechAnnouncementsQueued<T0>(_ p0: T0? = nil) -> Self { self }
    public func speechSpellsOutCharacters<T0>(_ p0: T0? = nil) -> Self { self }
    public func springLoadingBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func statusBar<T0>(hidden p0: T0? = nil) -> Self { self }
    public func statusBarHidden<T0>(_ p0: T0? = nil) -> Self { self }
    public func strikethrough<T0, T1, T2>(_ p0: T0? = nil, pattern p1: T1? = nil, color p2: T2? = nil) -> Self { self }
    public func submitLabel<T0>(_ p0: T0? = nil) -> Self { self }
    public func submitScope<T0>(_ p0: T0? = nil) -> Self { self }
    public func swipeActions<T0, T1, T2>(edge p0: T0? = nil, allowsFullSwipe p1: T1? = nil, content p2: T2? = nil) -> Self { self }
    public func symbolColorRenderingMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func symbolEffect<T0, T1, T2>(_ p0: T0? = nil, options p1: T1? = nil, isActive p2: T2? = nil) -> Self { self }
    public func symbolEffect<T0, T1, T2>(_ p0: T0? = nil, options p1: T1? = nil, value p2: T2? = nil) -> Self { self }
    public func symbolEffectsRemoved<T0>(_ p0: T0? = nil) -> Self { self }
    public func symbolRenderingMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func symbolVariableValueMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func symbolVariant<T0>(_ p0: T0? = nil) -> Self { self }
    public func tabBarMinimizeBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func tabItem<T0>(_ p0: T0? = nil) -> Self { self }
    public func tabViewBottomAccessory<T0>(content p0: T0? = nil) -> Self { self }
    public func tabViewCustomization<T0>(_ p0: T0? = nil) -> Self { self }
    public func tabViewSearchActivation<T0>(_ p0: T0? = nil) -> Self { self }
    public func tabViewSidebarBottomBar<T0>(content p0: T0? = nil) -> Self { self }
    public func tabViewSidebarFooter<T0>(content p0: T0? = nil) -> Self { self }
    public func tabViewSidebarHeader<T0>(content p0: T0? = nil) -> Self { self }
    public func tabViewStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func tableColumnHeaders<T0>(_ p0: T0? = nil) -> Self { self }
    public func tableStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func tag<T0, T1>(_ p0: T0? = nil, includeOptional p1: T1? = nil) -> Self { self }
    public func task<T0, T1, T2, T3, T4, T5, T6>(id p0: T0? = nil, name p1: T1? = nil, executorPreference p2: T2? = nil, priority p3: T3? = nil, file p4: T4? = nil, line p5: T5? = nil, _ p6: T6? = nil) -> Self { self }
    public func task<T0, T1, T2>(id p0: T0? = nil, priority p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func task<T0, T1>(priority p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func textCase<T0>(_ p0: T0? = nil) -> Self { self }
    public func textContentType<T0>(_ p0: T0? = nil) -> Self { self }
    public func textEditorStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func textFieldStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func textInputAutocapitalization<T0>(_ p0: T0? = nil) -> Self { self }
    public func textInputFormattingControlVisibility<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func textRenderer<T0>(_ p0: T0? = nil) -> Self { self }
    public func textScale<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func textSelection<T0>(_ p0: T0? = nil) -> Self { self }
    public func textSelectionAffinity<T0>(_ p0: T0? = nil) -> Self { self }
    public func tint<T0>(_ p0: T0? = nil) -> Self { self }
    public func toggleStyle<T0>(_ p0: T0? = nil) -> Self { self }
    public func toolbar<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func toolbar<T0>(content p0: T0? = nil) -> Self { self }
    public func toolbar<T0, T1>(id p0: T0? = nil, content p1: T1? = nil) -> Self { self }
    public func toolbar<T0>(removing p0: T0? = nil) -> Self { self }
    public func toolbarBackground<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func toolbarBackgroundVisibility<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func toolbarColorScheme<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func toolbarForegroundStyle<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func toolbarRole<T0>(_ p0: T0? = nil) -> Self { self }
    public func toolbarTitleDisplayMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func toolbarTitleMenu<T0>(content p0: T0? = nil) -> Self { self }
    public func toolbarVisibility<T0, T1>(_ p0: T0? = nil, `for` p1: T1? = nil) -> Self { self }
    public func tracking<T0>(_ p0: T0? = nil) -> Self { self }
    public func transaction<T0>(_ p0: T0? = nil) -> Self { self }
    public func transaction<T0, T1>(_ p0: T0? = nil, body p1: T1? = nil) -> Self { self }
    public func transaction<T0, T1>(value p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func transformAnchorPreference<T0, T1, T2>(key p0: T0? = nil, value p1: T1? = nil, transform p2: T2? = nil) -> Self { self }
    public func transformEffect<T0>(_ p0: T0? = nil) -> Self { self }
    public func transformEnvironment<T0, T1>(_ p0: T0? = nil, transform p1: T1? = nil) -> Self { self }
    public func transformPreference<T0, T1>(_ p0: T0? = nil, _ p1: T1? = nil) -> Self { self }
    public func transition<T0>(_ p0: T0? = nil) -> Self { self }
    public func truncationMode<T0>(_ p0: T0? = nil) -> Self { self }
    public func typeSelectEquivalent<T0>(_ p0: T0? = nil) -> Self { self }
    public func typesettingLanguage<T0, T1>(_ p0: T0? = nil, isEnabled p1: T1? = nil) -> Self { self }
    public func underline<T0, T1, T2>(_ p0: T0? = nil, pattern p1: T1? = nil, color p2: T2? = nil) -> Self { self }
    public func unredacted() -> Self { self }
    public func userActivity<T0, T1, T2>(_ p0: T0? = nil, element p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func userActivity<T0, T1, T2>(_ p0: T0? = nil, isActive p1: T1? = nil, _ p2: T2? = nil) -> Self { self }
    public func visualEffect<T0>(_ p0: T0? = nil) -> Self { self }
    public func windowToolbarFullScreenVisibility<T0>(_ p0: T0? = nil) -> Self { self }
    public func writingDirection<T0>(strategy p0: T0? = nil) -> Self { self }
    public func writingToolsAffordanceVisibility<T0>(_ p0: T0? = nil) -> Self { self }
    public func writingToolsBehavior<T0>(_ p0: T0? = nil) -> Self { self }
    public func zIndex<T0>(_ p0: T0? = nil) -> Self { self }
}
#endif

