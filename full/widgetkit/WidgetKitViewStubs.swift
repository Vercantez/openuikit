#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Inert Linux-host View members. Apple SwiftUI supplies these when the
/// real module is imported; the isolated host has no SwiftUI, so WidgetKit
/// types that conform to View expose the method names from the canonical
/// synthesized surface as no-op lookalikes.
enum _WidgetKitViewStubsMarker {}

#if !canImport(SwiftUI)
extension View {
    public func onAppIntentExecution<T0, T1>(_ p0: T0, perform: T1) -> Self { self }
    public func siriTipViewStyle<T0>(_ p0: T0) -> Self { self }
    public func shortcutsLinkStyle<T0>(_ p0: T0) -> Self { self }
    public func accessibilityAction<T0, T1>(named: T0, intent: T1) -> Self { self }
    public func accessibilityAction<T0, T1>(intent: T0, label: T1) -> Self { self }
    public func accessibilityAction<T0, T1>(_ p0: T0, intent: T1) -> Self { self }
    public func controlWidgetActionHint<T0>(_ p0: T0) -> Self { self }
    public func controlWidgetStatus<T0>(_ p0: T0) -> Self { self }
    public func widgetLabel<T0: StringProtocol>(label: T0) -> Self { self }
    public func dynamicIsland<T0>(verticalPlacement: T0) -> Self { self }
    public func widgetAccentable<T0>(_ p0: T0) -> Self { self }
    public func widgetCurvesContent<T0>(_ p0: T0) -> Self { self }
    public func activityBackgroundTint<T0>(_ p0: T0) -> Self { self }
    public func activitySystemActionForegroundColor<T0>(_ p0: T0) -> Self { self }
    public func widgetURL<T0>(_ p0: T0) -> Self { self }
    public func navigationViewStyle<T0>(_ p0: T0) -> Self { self }
    public func navigationSplitViewColumnWidth<T0, T1, T2>(min: T0, ideal: T1, max: T2) -> Self { self }
    public func navigationSplitViewColumnWidth<T0>(_ p0: T0) -> Self { self }
    public func navigationSplitViewStyle<T0>(_ p0: T0) -> Self { self }
    public func tabViewCustomization<T0>(_ p0: T0) -> Self { self }
    public func tabViewSidebarFooter<T0>(content: T0) -> Self { self }
    public func tabViewSidebarHeader<T0>(content: T0) -> Self { self }
    public func tabViewBottomAccessory<T0>(content: T0) -> Self { self }
    public func tabViewSearchActivation<T0>(_ p0: T0) -> Self { self }
    public func tabViewSidebarBottomBar<T0>(content: T0) -> Self { self }
    public func tabViewStyle<T0>(_ p0: T0) -> Self { self }
    public func indexViewStyle<T0>(_ p0: T0) -> Self { self }
    public func progressViewStyle<T0>(_ p0: T0) -> Self { self }
    public func background<T0>(ignoresSafeAreaEdges: T0) -> Self { self }
    public func background<T0, T1>(`in`: T0, fillStyle: T1) -> Self { self }
    public func background<T0, T1>(alignment: T0, content: T1) -> Self { self }
    public func background<T0, T1>(_ p0: T0, ignoresSafeAreaEdges: T1) -> Self { self }
    public func background<T0, T1, T2>(_ p0: T0, `in`: T1, fillStyle: T2) -> Self { self }
    public func background<T0, T1>(_ p0: T0, alignment: T1) -> Self { self }
    public func brightness<T0>(_ p0: T0) -> Self { self }
    public func dialogIcon<T0>(_ p0: T0) -> Self { self }
    public func fontDesign<T0>(_ p0: T0) -> Self { self }
    public func fontWeight<T0>(_ p0: T0) -> Self { self }
    public func gaugeStyle<T0>(_ p0: T0) -> Self { self }
    public func imageScale<T0>(_ p0: T0) -> Self { self }
    public func labelStyle<T0>(_ p0: T0) -> Self { self }
    public func lineHeight<T0>(_ p0: T0) -> Self { self }
    public func monospaced<T0>(_ p0: T0) -> Self { self }
    public func onKeyPress<T0, T1, T2>(characters: T0, phases: T1, action: T2) -> Self { self }
    public func onKeyPress<T0, T1, T2>(keys: T0, phases: T1, action: T2) -> Self { self }
    public func onKeyPress<T0, T1>(phases: T0, action: T1) -> Self { self }
    public func onKeyPress<T0, T1>(_ p0: T0, action: T1) -> Self { self }
    public func onKeyPress<T0, T1, T2>(_ p0: T0, phases: T1, action: T2) -> Self { self }
    public func preference<T0, T1>(key: T0, value: T1) -> Self { self }
    public func saturation<T0>(_ p0: T0) -> Self { self }
    public func searchable<T0, T1, T2, T3>(text: T0, isPresented: T1, placement: T2, prompt: T3) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5>(text: T0, editableTokens: T1, isPresented: T2, placement: T3, prompt: T4, token: T5) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4>(text: T0, editableTokens: T1, placement: T2, prompt: T3, token: T4) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5>(text: T0, tokens: T1, isPresented: T2, placement: T3, prompt: T4, token: T5) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5, T6>(text: T0, tokens: T1, suggestedTokens: T2, isPresented: T3, placement: T4, prompt: T5, token: T6) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4, T5>(text: T0, tokens: T1, suggestedTokens: T2, placement: T3, prompt: T4, token: T5) -> Self { self }
    public func searchable<T0, T1, T2, T3, T4>(text: T0, tokens: T1, placement: T2, prompt: T3, token: T4) -> Self { self }
    public func searchable<T0, T1, T2, T3>(text: T0, placement: T1, prompt: T2, suggestions: T3) -> Self { self }
    public func searchable<T0, T1, T2>(text: T0, placement: T1, prompt: T2) -> Self { self }
    public func tableStyle<T0>(_ p0: T0) -> Self { self }
    public func transition<T0>(_ p0: T0) -> Self { self }
    public func unredacted() -> Self { self }
    public func accentColor<T0>(_ p0: T0) -> Self { self }
    public func actionSheet<T0, T1>(isPresented: T0, content: T1) -> Self { self }
    public func actionSheet<T0, T1>(item: T0, content: T1) -> Self { self }
    public func aspectRatio<T0, T1>(_ p0: T0, contentMode: T1) -> Self { self }
    public func buttonStyle<T0>(_ p0: T0) -> Self { self }
    public func colorEffect<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func colorInvert() -> Self { self }
    public func colorScheme<T0>(_ p0: T0) -> Self { self }
    public func contextMenu<T0, T1, T2>(forSelectionType: T0, menu: T1, primaryAction: T2) -> Self { self }
    public func contextMenu<T0, T1>(menuItems: T0, preview: T1) -> Self { self }
    public func contextMenu<T0>(menuItems: T0) -> Self { self }
    public func contextMenu<T0>(_ p0: T0) -> Self { self }
    public func controlSize<T0>(_ p0: T0) -> Self { self }
    public func environment<T0>(_ p0: T0) -> Self { self }
    public func environment<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func glassEffect<T0, T1>(_ p0: T0, `in`: T1) -> Self { self }
    public func hoverEffect<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func hoverEffect<T0>(_ p0: T0) -> Self { self }
    public func hueRotation<T0>(_ p0: T0) -> Self { self }
    public func layerEffect<T0, T1, T2>(_ p0: T0, maxSampleOffset: T1, isEnabled: T2) -> Self { self }
    public func layoutValue<T0, T1>(key: T0, value: T1) -> Self { self }
    public func lineSpacing<T0>(_ p0: T0) -> Self { self }
    public func onDisappear<T0>(perform: T0) -> Self { self }
    public func pickerStyle<T0>(_ p0: T0) -> Self { self }
    public func refreshable<T0>(action: T0) -> Self { self }
    public func safeAreaBar<T0, T1, T2, T3>(edge: T0, alignment: T1, spacing: T2, content: T3) -> Self { self }
    public func scaleEffect<T0, T1, T2>(x: T0, y: T1, anchor: T2) -> Self { self }
    public func scaleEffect<T0, T1>(_ p0: T0, anchor: T1) -> Self { self }
    public func scaledToFit() -> Self { self }
    public func submitLabel<T0>(_ p0: T0) -> Self { self }
    public func submitScope<T0>(_ p0: T0) -> Self { self }
    public func toggleStyle<T0>(_ p0: T0) -> Self { self }
    public func toolbarRole<T0>(_ p0: T0) -> Self { self }
    public func transaction<T0, T1>(value: T0, _ p1: T1) -> Self { self }
    public func transaction<T0, T1>(_ p0: T0, body: T1) -> Self { self }
    public func transaction<T0>(_ p0: T0) -> Self { self }
    public func buttonSizing<T0>(_ p0: T0) -> Self { self }
    public func contentShape<T0, T1>(_ p0: T0, eoFill: T1) -> Self { self }
    public func contentShape<T0, T1, T2>(_ p0: T0, _ p1: T1, eoFill: T2) -> Self { self }
    public func cornerRadius<T0, T1>(_ p0: T0, antialiased: T1) -> Self { self }
    public func defaultFocus<T0, T1, T2>(_ p0: T0, _ p1: T1, priority: T2) -> Self { self }
    public func drawingGroup<T0, T1>(opaque: T0, colorMode: T1) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4, T5>(isPresented: T0, item: T1, contentTypes: T2, defaultFilename: T3, onCompletion: T4, onCancellation: T5) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4>(isPresented: T0, items: T1, contentTypes: T2, onCompletion: T3, onCancellation: T4) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4>(isPresented: T0, document: T1, contentType: T2, defaultFilename: T3, onCompletion: T4) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4, T5>(isPresented: T0, document: T1, contentTypes: T2, defaultFilename: T3, onCompletion: T4, onCancellation: T5) -> Self { self }
    public func fileExporter<T0, T1, T2, T3>(isPresented: T0, documents: T1, contentType: T2, onCompletion: T3) -> Self { self }
    public func fileExporter<T0, T1, T2, T3, T4>(isPresented: T0, documents: T1, contentTypes: T2, onCompletion: T3, onCancellation: T4) -> Self { self }
    public func fileImporter<T0, T1, T2>(isPresented: T0, allowedContentTypes: T1, onCompletion: T2) -> Self { self }
    public func fileImporter<T0, T1, T2, T3, T4>(isPresented: T0, allowedContentTypes: T1, allowsMultipleSelection: T2, onCompletion: T3, onCancellation: T4) -> Self { self }
    public func fileImporter<T0, T1, T2, T3>(isPresented: T0, allowedContentTypes: T1, allowsMultipleSelection: T2, onCompletion: T3) -> Self { self }
    public func findDisabled<T0>(_ p0: T0) -> Self { self }
    public func focusedValue<T0>(_ p0: T0) -> Self { self }
    public func focusedValue<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func itemProvider<T0>(_ p0: T0) -> Self { self }
    public func keyboardType<T0>(_ p0: T0) -> Self { self }
    public func labelsHidden() -> Self { self }
    public func listItemTint<T0>(_ p0: T0) -> Self { self }
    public func moveDisabled<T0>(_ p0: T0) -> Self { self }
    public func onTapGesture<T0, T1, T2>(count: T0, coordinateSpace: T1, perform: T2) -> Self { self }
    public func onTapGesture<T0, T1>(count: T0, perform: T1) -> Self { self }
    public func renameAction<T0>(_ p0: T0) -> Self { self }
    public func scaledToFill() -> Self { self }
    public func scenePadding<T0, T1>(_ p0: T0, edges: T1) -> Self { self }
    public func scenePadding<T0>(_ p0: T0) -> Self { self }
    public func searchScopes<T0, T1, T2>(_ p0: T0, activation: T1, _ p2: T2) -> Self { self }
    public func searchScopes<T0, T1>(_ p0: T0, scopes: T1) -> Self { self }
    public func swipeActions<T0, T1, T2>(edge: T0, allowsFullSwipe: T1, content: T2) -> Self { self }
    public func symbolEffect<T0, T1, T2>(_ p0: T0, options: T1, value: T2) -> Self { self }
    public func symbolEffect<T0, T1, T2>(_ p0: T0, options: T1, isActive: T2) -> Self { self }
    public func textRenderer<T0>(_ p0: T0) -> Self { self }
    public func userActivity<T0, T1, T2>(_ p0: T0, element: T1, _ p2: T2) -> Self { self }
    public func userActivity<T0, T1, T2>(_ p0: T0, isActive: T1, _ p2: T2) -> Self { self }
    public func visualEffect<T0>(_ p0: T0) -> Self { self }
    public func accessibility<T0>(identifier: T0) -> Self { self }
    public func accessibility<T0>(inputLabels: T0) -> Self { self }
    public func accessibility<T0>(removeTraits: T0) -> Self { self }
    public func accessibility<T0>(sortPriority: T0) -> Self { self }
    public func accessibility<T0>(activationPoint: T0) -> Self { self }
    public func accessibility<T0>(selectionIdentifier: T0) -> Self { self }
    public func accessibility<T0>(hint: T0) -> Self { self }
    public func accessibility<T0>(label: T0) -> Self { self }
    public func accessibility<T0>(value: T0) -> Self { self }
    public func accessibility<T0>(hidden: T0) -> Self { self }
    public func accessibility<T0>(addTraits: T0) -> Self { self }
    public func colorMultiply<T0>(_ p0: T0) -> Self { self }
    public func findNavigator<T0>(isPresented: T0) -> Self { self }
    public func focusedObject<T0>(_ p0: T0) -> Self { self }
    public func geometryGroup() -> Self { self }
    public func glassEffectID<T0, T1>(_ p0: T0, `in`: T1) -> Self { self }
    public func groupBoxStyle<T0>(_ p0: T0) -> Self { self }
    public func listRowInsets<T0>(_ p0: T0) -> Self { self }
    public func listRowInsets<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func menuIndicator<T0>(_ p0: T0) -> Self { self }
    public func phaseAnimator<T0, T1, T2>(_ p0: T0, content: T1, animation: T2) -> Self { self }
    public func phaseAnimator<T0, T1, T2, T3>(_ p0: T0, trigger: T1, content: T2, animation: T3) -> Self { self }
    public func previewDevice<T0>(_ p0: T0) -> Self { self }
    public func previewLayout<T0>(_ p0: T0) -> Self { self }
    public func safeAreaInset<T0, T1, T2, T3>(edge: T0, alignment: T1, spacing: T2, content: T3) -> Self { self }
    public func searchFocused<T0, T1>(_ p0: T0, equals: T1) -> Self { self }
    public func searchFocused<T0>(_ p0: T0) -> Self { self }
    public func strikethrough<T0, T1, T2>(_ p0: T0, pattern: T1, color: T2) -> Self { self }
    public func symbolVariant<T0>(_ p0: T0) -> Self { self }
    public func textSelection<T0>(_ p0: T0) -> Self { self }
    public func alignmentGuide<T0, T1>(_ p0: T0, computeValue: T1) -> Self { self }
    public func baselineOffset<T0>(_ p0: T0) -> Self { self }
    public func containerShape<T0>(_ p0: T0) -> Self { self }
    public func containerValue<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func contentMargins<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func contentMargins<T0, T1, T2>(_ p0: T0, _ p1: T1, `for`: T2) -> Self { self }
    public func contentToolbar<T0, T1>(`for`: T0, content: T1) -> Self { self }
    public func deleteDisabled<T0>(_ p0: T0) -> Self { self }
    public func gridCellAnchor<T0>(_ p0: T0) -> Self { self }
    public func layoutPriority<T0>(_ p0: T0) -> Self { self }
    public func listRowSpacing<T0>(_ p0: T0) -> Self { self }
    public func previewContext<T0>(_ p0: T0) -> Self { self }
    public func rotationEffect<T0, T1>(_ p0: T0, anchor: T1) -> Self { self }
    public func scrollDisabled<T0>(_ p0: T0) -> Self { self }
    public func scrollPosition<T0, T1>(id: T0, anchor: T1) -> Self { self }
    public func scrollPosition<T0, T1>(_ p0: T0, anchor: T1) -> Self { self }
    public func sectionActions<T0>(content: T0) -> Self { self }
    public func textFieldStyle<T0>(_ p0: T0) -> Self { self }
    public func truncationMode<T0>(_ p0: T0) -> Self { self }
    public func backgroundStyle<T0>(_ p0: T0) -> Self { self }
    public func badgeProminence<T0>(_ p0: T0) -> Self { self }
    public func coordinateSpace<T0>(name: T0) -> Self { self }
    public func coordinateSpace<T0>(_ p0: T0) -> Self { self }
    public func datePickerStyle<T0>(_ p0: T0) -> Self { self }
    public func dropDestination<T0, T1, T2>(`for`: T0, action: T1, isTargeted: T2) -> Self { self }
    public func dropDestination<T0, T1, T2>(`for`: T0, isEnabled: T1, action: T2) -> Self { self }
    public func dynamicTypeSize<T0>(_ p0: T0) -> Self { self }
    public func foregroundColor<T0>(_ p0: T0) -> Self { self }
    public func foregroundStyle<T0>(_ p0: T0) -> Self { self }
    public func foregroundStyle<T0, T1, T2>(_ p0: T0, _ p1: T1, _ p2: T2) -> Self { self }
    public func foregroundStyle<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func fullScreenCover<T0, T1, T2>(isPresented: T0, onDismiss: T1, content: T2) -> Self { self }
    public func fullScreenCover<T0, T1, T2>(item: T0, onDismiss: T1, content: T2) -> Self { self }
    public func gridCellColumns<T0>(_ p0: T0) -> Self { self }
    public func ignoresSafeArea<T0, T1>(_ p0: T0, edges: T1) -> Self { self }
    public func monospacedDigit() -> Self { self }
    public func navigationTitle<T0>(_ p0: T0) -> Self { self }
    public func onPencilSqueeze<T0>(perform: T0) -> Self { self }
    public func replaceDisabled<T0>(_ p0: T0) -> Self { self }
    public func safeAreaPadding<T0>(_ p0: T0) -> Self { self }
    public func safeAreaPadding<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func searchSelection<T0>(_ p0: T0) -> Self { self }
    public func sensoryFeedback<T0, T1>(trigger: T0, _ p1: T1) -> Self { self }
    public func sensoryFeedback<T0, T1, T2>(_ p0: T0, trigger: T1, condition: T2) -> Self { self }
    public func sensoryFeedback<T0, T1>(_ p0: T0, trigger: T1) -> Self { self }
    public func statusBarHidden<T0>(_ p0: T0) -> Self { self }
    public func textContentType<T0>(_ p0: T0) -> Self { self }
    public func textEditorStyle<T0>(_ p0: T0) -> Self { self }
    public func transformEffect<T0>(_ p0: T0) -> Self { self }
    public func allowsHitTesting<T0>(_ p0: T0) -> Self { self }
    public func allowsTightening<T0>(_ p0: T0) -> Self { self }
    public func anchorPreference<T0, T1, T2>(key: T0, value: T1, transform: T2) -> Self { self }
    public func compositingGroup() -> Self { self }
    public func distortionEffect<T0, T1, T2>(_ p0: T0, maxSampleOffset: T1, isEnabled: T2) -> Self { self }
    public func glassEffectUnion<T0, T1>(id: T0, namespace: T1) -> Self { self }
    public func headerProminence<T0>(_ p0: T0) -> Self { self }
    public func keyboardShortcut<T0, T1, T2>(_ p0: T0, modifiers: T1, localization: T2) -> Self { self }
    public func keyboardShortcut<T0, T1>(_ p0: T0, modifiers: T1) -> Self { self }
    public func keyboardShortcut<T0>(_ p0: T0) -> Self { self }
    public func keyframeAnimator<T0, T1, T2, T3>(initialValue: T0, trigger: T1, content: T2, keyframes: T3) -> Self { self }
    public func keyframeAnimator<T0, T1, T2, T3>(initialValue: T0, repeating: T1, content: T2, keyframes: T3) -> Self { self }
    public func labelsVisibility<T0>(_ p0: T0) -> Self { self }
    public func listRowSeparator<T0, T1>(_ p0: T0, edges: T1) -> Self { self }
    public func luminanceToAlpha() -> Self { self }
    public func onGeometryChange<T0, T1, T2>(`for`: T0, of: T1, action: T2) -> Self { self }
    public func privacySensitive<T0>(_ p0: T0) -> Self { self }
    public func projectionEffect<T0>(_ p0: T0) -> Self { self }
    public func rotation3DEffect<T0, T1, T2, T3, T4>(_ p0: T0, axis: T1, anchor: T2, anchorZ: T3, perspective: T4) -> Self { self }
    public func scrollIndicators<T0, T1>(_ p0: T0, axes: T1) -> Self { self }
    public func scrollTransition<T0, T1, T2, T3>(topLeading: T0, bottomTrailing: T1, axis: T2, transition: T3) -> Self { self }
    public func scrollTransition<T0, T1, T2>(_ p0: T0, axis: T1, transition: T2) -> Self { self }
    public func searchCompletion<T0>(_ p0: T0) -> Self { self }
    public func toolbarTitleMenu<T0>(content: T0) -> Self { self }
    public func writingDirection<T0>(strategy: T0) -> Self { self }
    public func accessibilityHint<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityHint<T0>(_ p0: T0) -> Self { self }
    public func buttonBorderShape<T0>(_ p0: T0) -> Self { self }
    public func contentTransition<T0>(_ p0: T0) -> Self { self }
    public func controlGroupStyle<T0>(_ p0: T0) -> Self { self }
    public func defaultAppStorage<T0>(_ p0: T0) -> Self { self }
    public func environmentObject<T0>(_ p0: T0) -> Self { self }
    public func fileDialogMessage<T0>(_ p0: T0) -> Self { self }
    public func focusedSceneValue<T0>(_ p0: T0) -> Self { self }
    public func focusedSceneValue<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func listRowBackground<T0>(_ p0: T0) -> Self { self }
    public func onContinuousHover<T0, T1>(coordinateSpace: T0, perform: T1) -> Self { self }
    public func onPencilDoubleTap<T0>(perform: T0) -> Self { self }
    public func searchSuggestions<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func searchSuggestions<T0>(_ p0: T0) -> Self { self }
    public func sectionIndexLabel<T0>(_ p0: T0) -> Self { self }
    public func selectionDisabled<T0>(_ p0: T0) -> Self { self }
    public func toolbarBackground<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func toolbarVisibility<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func accessibilityLabel<T0>(content: T0) -> Self { self }
    public func accessibilityLabel<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityLabel<T0>(_ p0: T0) -> Self { self }
    public func accessibilityRotor<T0, T1>(_ p0: T0, textRanges: T1) -> Self { self }
    public func accessibilityRotor<T0, T1, T2>(_ p0: T0, entries: T1, entryLabel: T2) -> Self { self }
    public func accessibilityRotor<T0, T1, T2, T3>(_ p0: T0, entries: T1, entryID: T2, entryLabel: T3) -> Self { self }
    public func accessibilityRotor<T0, T1>(_ p0: T0, entries: T1) -> Self { self }
    public func accessibilityValue<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityValue<T0>(_ p0: T0) -> Self { self }
    public func autocapitalization<T0>(_ p0: T0) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3, T4, T5>(_ p0: T0, isPresented: T1, titleVisibility: T2, presenting: T3, actions: T4, message: T5) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3, T4>(_ p0: T0, isPresented: T1, titleVisibility: T2, presenting: T3, actions: T4) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3, T4>(_ p0: T0, isPresented: T1, titleVisibility: T2, actions: T3, message: T4) -> Self { self }
    public func confirmationDialog<T0, T1, T2, T3>(_ p0: T0, isPresented: T1, titleVisibility: T2, actions: T3) -> Self { self }
    public func defaultHoverEffect<T0>(_ p0: T0) -> Self { self }
    public func focusedSceneObject<T0>(_ p0: T0) -> Self { self }
    public func listSectionMargins<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func listSectionSpacing<T0>(_ p0: T0) -> Self { self }
    public func minimumScaleFactor<T0>(_ p0: T0) -> Self { self }
    public func navigationBarItems<T0, T1>(leading: T0, trailing: T1) -> Self { self }
    public func navigationBarItems<T0>(leading: T0) -> Self { self }
    public func navigationBarItems<T0>(trailing: T0) -> Self { self }
    public func navigationBarTitle<T0, T1>(_ p0: T0, displayMode: T1) -> Self { self }
    public func navigationBarTitle<T0>(_ p0: T0) -> Self { self }
    public func navigationDocument<T0, T1>(_ p0: T0, preview: T1) -> Self { self }
    public func navigationDocument<T0>(_ p0: T0) -> Self { self }
    public func navigationSubtitle<T0>(_ p0: T0) -> Self { self }
    public func onLongPressGesture<T0, T1, T2, T3>(minimumDuration: T0, maximumDistance: T1, perform: T2, onPressingChanged: T3) -> Self { self }
    public func onLongPressGesture<T0, T1, T2, T3>(minimumDuration: T0, maximumDistance: T1, pressing: T2, perform: T3) -> Self { self }
    public func onLongPressGesture<T0, T1, T2>(minimumDuration: T0, perform: T1, onPressingChanged: T2) -> Self { self }
    public func onLongPressGesture<T0, T1, T2>(minimumDuration: T0, pressing: T1, perform: T2) -> Self { self }
    public func onPreferenceChange<T0, T1>(_ p0: T0, perform: T1) -> Self { self }
    public func presentationSizing<T0>(_ p0: T0) -> Self { self }
    public func previewDisplayName<T0>(_ p0: T0) -> Self { self }
    public func scrollClipDisabled<T0>(_ p0: T0) -> Self { self }
    public func scrollTargetLayout<T0>(isEnabled: T0) -> Self { self }
    public func tableColumnHeaders<T0>(_ p0: T0) -> Self { self }
    public func toolbarColorScheme<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func accessibilityAction<T0, T1>(named: T0, _ p1: T1) -> Self { self }
    public func accessibilityAction<T0, T1>(action: T0, label: T1) -> Self { self }
    public func accessibilityAction<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func accessibilityHidden<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityHidden<T0>(_ p0: T0) -> Self { self }
    public func allowedDynamicRange<T0>(_ p0: T0) -> Self { self }
    public func containerBackground<T0, T1, T2>(`for`: T0, alignment: T1, content: T2) -> Self { self }
    public func containerBackground<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func defaultScrollAnchor<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func defaultScrollAnchor<T0>(_ p0: T0) -> Self { self }
    public func focusEffectDisabled<T0>(_ p0: T0) -> Self { self }
    public func gridCellUnsizedAxes<T0>(_ p0: T0) -> Self { self }
    public func gridColumnAlignment<T0>(_ p0: T0) -> Self { self }
    public func handGestureShortcut<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func highPriorityGesture<T0, T1, T2>(_ p0: T0, name: T1, isEnabled: T2) -> Self { self }
    public func highPriorityGesture<T0, T1>(_ p0: T0, including: T1) -> Self { self }
    public func highPriorityGesture<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func hoverEffectDisabled<T0>(_ p0: T0) -> Self { self }
    public func labeledContentStyle<T0>(_ p0: T0) -> Self { self }
    public func navigationBarHidden<T0>(_ p0: T0) -> Self { self }
    public func onScrollPhaseChange<T0>(_ p0: T0) -> Self { self }
    public func presentationDetents<T0, T1>(_ p0: T0, selection: T1) -> Self { self }
    public func presentationDetents<T0>(_ p0: T0) -> Self { self }
    public func scrollInputBehavior<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func simultaneousGesture<T0, T1, T2>(_ p0: T0, name: T1, isEnabled: T2) -> Self { self }
    public func simultaneousGesture<T0, T1>(_ p0: T0, including: T1) -> Self { self }
    public func simultaneousGesture<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func speechAdjustedPitch<T0>(_ p0: T0) -> Self { self }
    public func symbolRenderingMode<T0>(_ p0: T0) -> Self { self }
    public func transformPreference<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func typesettingLanguage<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityActions<T0, T1>(category: T0, _ p1: T1) -> Self { self }
    public func accessibilityActions<T0>(_ p0: T0) -> Self { self }
    public func accessibilityElement<T0>(children: T0) -> Self { self }
    public func accessibilityFocused<T0, T1>(_ p0: T0, equals: T1) -> Self { self }
    public func accessibilityFocused<T0>(_ p0: T0) -> Self { self }
    public func accessibilityHeading<T0>(_ p0: T0) -> Self { self }
    public func buttonRepeatBehavior<T0>(_ p0: T0) -> Self { self }
    public func defersSystemGestures<T0>(on: T0) -> Self { self }
    public func disclosureGroupStyle<T0>(_ p0: T0) -> Self { self }
    public func fileDialogURLEnabled<T0>(_ p0: T0) -> Self { self }
    public func inspectorColumnWidth<T0, T1, T2>(min: T0, ideal: T1, max: T2) -> Self { self }
    public func inspectorColumnWidth<T0>(_ p0: T0) -> Self { self }
    public func invalidatableContent<T0>(_ p0: T0) -> Self { self }
    public func listRowSeparatorTint<T0, T1>(_ p0: T0, edges: T1) -> Self { self }
    public func listSectionSeparator<T0, T1>(_ p0: T0, edges: T1) -> Self { self }
    public func navigationTransition<T0>(_ p0: T0) -> Self { self }
    public func preferredColorScheme<T0>(_ p0: T0) -> Self { self }
    public func scrollBounceBehavior<T0, T1>(_ p0: T0, axes: T1) -> Self { self }
    public func scrollTargetBehavior<T0>(_ p0: T0) -> Self { self }
    public func symbolEffectsRemoved<T0>(_ p0: T0) -> Self { self }
    public func transformEnvironment<T0, T1>(_ p0: T0, transform: T1) -> Self { self }
    public func typeSelectEquivalent<T0>(_ p0: T0) -> Self { self }
    public func writingToolsBehavior<T0>(_ p0: T0) -> Self { self }
    public func accessibilityChildren<T0>(children: T0) -> Self { self }
    public func containerCornerOffset<T0, T1>(_ p0: T0, sizeToFit: T1) -> Self { self }
    public func disableAutocorrection<T0>(_ p0: T0) -> Self { self }
    public func edgesIgnoringSafeArea<T0>(_ p0: T0) -> Self { self }
    public func glassEffectTransition<T0>(_ p0: T0) -> Self { self }
    public func handlesExternalEvents<T0, T1>(preferring: T0, allowing: T1) -> Self { self }
    public func matchedGeometryEffect<T0, T1, T2, T3, T4>(id: T0, `in`: T1, properties: T2, anchor: T3, isSource: T4) -> Self { self }
    public func navigationDestination<T0, T1>(isPresented: T0, destination: T1) -> Self { self }
    public func navigationDestination<T0, T1>(`for`: T0, destination: T1) -> Self { self }
    public func navigationDestination<T0, T1>(item: T0, destination: T1) -> Self { self }
    public func scrollEdgeEffectStyle<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func scrollIndicatorsFlash<T0>(trigger: T0) -> Self { self }
    public func scrollIndicatorsFlash<T0>(onAppear: T0) -> Self { self }
    public func searchToolbarBehavior<T0>(_ p0: T0) -> Self { self }
    public func sliderThumbVisibility<T0>(_ p0: T0) -> Self { self }
    public func springLoadingBehavior<T0>(_ p0: T0) -> Self { self }
    public func textSelectionAffinity<T0>(_ p0: T0) -> Self { self }
    public func accessibilityAddTraits<T0>(_ p0: T0) -> Self { self }
    public func accessibilityDragPoint<T0, T1, T2>(_ p0: T0, description: T1, isEnabled: T2) -> Self { self }
    public func accessibilityDragPoint<T0, T1>(_ p0: T0, description: T1) -> Self { self }
    public func accessibilityDropPoint<T0, T1, T2>(_ p0: T0, description: T1, isEnabled: T2) -> Self { self }
    public func accessibilityDropPoint<T0, T1>(_ p0: T0, description: T1) -> Self { self }
    public func autocorrectionDisabled<T0>(_ p0: T0) -> Self { self }
    public func containerRelativeFrame<T0, T1, T2, T3, T4>(_ p0: T0, count: T1, span: T2, spacing: T3, alignment: T4) -> Self { self }
    public func containerRelativeFrame<T0, T1>(_ p0: T0, alignment: T1) -> Self { self }
    public func containerRelativeFrame<T0, T1, T2>(_ p0: T0, alignment: T1, _ p2: T2) -> Self { self }
    public func labelReservedIconWidth<T0>(_ p0: T0) -> Self { self }
    public func multilineTextAlignment<T0>(strategy: T0) -> Self { self }
    public func multilineTextAlignment<T0>(_ p0: T0) -> Self { self }
    public func onContinueUserActivity<T0, T1>(_ p0: T0, perform: T1) -> Self { self }
    public func onScrollGeometryChange<T0, T1, T2>(`for`: T0, of: T1, action: T2) -> Self { self }
    public func overlayPreferenceValue<T0, T1, T2>(_ p0: T0, alignment: T1, _ p2: T2) -> Self { self }
    public func overlayPreferenceValue<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func paletteSelectionEffect<T0>(_ p0: T0) -> Self { self }
    public func presentationBackground<T0, T1>(alignment: T0, content: T1) -> Self { self }
    public func presentationBackground<T0>(_ p0: T0) -> Self { self }
    public func scrollEdgeEffectHidden<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func tabBarMinimizeBehavior<T0>(_ p0: T0) -> Self { self }
    public func toolbarForegroundStyle<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func accessibilityIdentifier<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityIdentifier<T0>(_ p0: T0) -> Self { self }
    public func accessibilityRotorEntry<T0, T1>(id: T0, `in`: T1) -> Self { self }
    public func accessibilityZoomAction<T0>(_ p0: T0) -> Self { self }
    public func dialogSuppressionToggle<T0>(isSuppressed: T0) -> Self { self }
    public func dialogSuppressionToggle<T0, T1>(_ p0: T0, isSuppressed: T1) -> Self { self }
    public func labelIconToTitleSpacing<T0>(_ p0: T0) -> Self { self }
    public func layoutDirectionBehavior<T0>(_ p0: T0) -> Self { self }
    public func matchedTransitionSource<T0, T1, T2>(id: T0, `in`: T1, configuration: T2) -> Self { self }
    public func matchedTransitionSource<T0, T1>(id: T0, `in`: T1) -> Self { self }
    public func scrollContentBackground<T0>(_ p0: T0) -> Self { self }
    public func scrollDismissesKeyboard<T0>(_ p0: T0) -> Self { self }
    public func searchDictationBehavior<T0>(_ p0: T0) -> Self { self }
    public func symbolVariableValueMode<T0>(_ p0: T0) -> Self { self }
    public func toolbarTitleDisplayMode<T0>(_ p0: T0) -> Self { self }
    public func accessibilityDirectTouch<T0, T1>(_ p0: T0, options: T1) -> Self { self }
    public func accessibilityInputLabels<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityInputLabels<T0>(_ p0: T0) -> Self { self }
    public func accessibilityLabeledPair<T0, T1, T2>(role: T0, id: T1, `in`: T2) -> Self { self }
    public func accessibilityLinkedGroup<T0, T1>(id: T0, `in`: T1) -> Self { self }
    public func fileDialogBrowserOptions<T0>(_ p0: T0) -> Self { self }
    public func listSectionSeparatorTint<T0, T1>(_ p0: T0, edges: T1) -> Self { self }
    public func materialActiveAppearance<T0>(_ p0: T0) -> Self { self }
    public func onScrollVisibilityChange<T0, T1>(threshold: T0, _ p1: T1) -> Self { self }
    public func persistentSystemOverlays<T0>(_ p0: T0) -> Self { self }
    public func presentationCornerRadius<T0>(_ p0: T0) -> Self { self }
    public func symbolColorRenderingMode<T0>(_ p0: T0) -> Self { self }
    public func accessibilityDefaultFocus<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func accessibilityRemoveTraits<T0>(_ p0: T0) -> Self { self }
    public func accessibilityScrollAction<T0>(_ p0: T0) -> Self { self }
    public func accessibilityScrollStatus<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilitySortPriority<T0>(_ p0: T0) -> Self { self }
    public func backgroundExtensionEffect<T0>(isEnabled: T0) -> Self { self }
    public func backgroundExtensionEffect() -> Self { self }
    public func backgroundPreferenceValue<T0, T1, T2>(_ p0: T0, alignment: T1, _ p2: T2) -> Self { self }
    public func backgroundPreferenceValue<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func fileDialogCustomizationID<T0>(_ p0: T0) -> Self { self }
    public func fileExporterFilenameLabel<T0>(_ p0: T0) -> Self { self }
    public func menuActionDismissBehavior<T0>(_ p0: T0) -> Self { self }
    public func onInteractiveResizeChange<T0>(_ p0: T0) -> Self { self }
    public func presentationDragIndicator<T0>(_ p0: T0) -> Self { self }
    public func speechAnnouncementsQueued<T0>(_ p0: T0) -> Self { self }
    public func speechSpellsOutCharacters<T0>(_ p0: T0) -> Self { self }
    public func transformAnchorPreference<T0, T1, T2>(key: T0, value: T1, transform: T2) -> Self { self }
    public func accessibilityCustomContent<T0, T1, T2>(_ p0: T0, _ p1: T1, importance: T2) -> Self { self }
    public func documentBrowserContextMenu<T0>(_ p0: T0) -> Self { self }
    public func fileDialogDefaultDirectory<T0>(_ p0: T0) -> Self { self }
    public func interactiveDismissDisabled<T0>(_ p0: T0) -> Self { self }
    public func listSectionIndexVisibility<T0>(_ p0: T0) -> Self { self }
    public func accessibilityRepresentation<T0>(representation: T0) -> Self { self }
    public func fileDialogConfirmationLabel<T0>(_ p0: T0) -> Self { self }
    public func previewInterfaceOrientation<T0>(_ p0: T0) -> Self { self }
    public func textInputAutocapitalization<T0>(_ p0: T0) -> Self { self }
    public func toolbarBackgroundVisibility<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func accessibilityActivationPoint<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityActivationPoint<T0>(_ p0: T0) -> Self { self }
    public func accessibilityChartDescriptor<T0>(_ p0: T0) -> Self { self }
    public func accessibilityTextContentType<T0>(_ p0: T0) -> Self { self }
    public func allowsWindowActivationEvents() -> Self { self }
    public func allowsWindowActivationEvents<T0>(_ p0: T0) -> Self { self }
    public func accessibilityAdjustableAction<T0>(_ p0: T0) -> Self { self }
    public func assistiveAccessNavigationIcon<T0>(systemImage: T0) -> Self { self }
    public func assistiveAccessNavigationIcon<T0>(_ p0: T0) -> Self { self }
    public func navigationBarBackButtonHidden<T0>(_ p0: T0) -> Self { self }
    public func navigationBarTitleDisplayMode<T0>(_ p0: T0) -> Self { self }
    public func presentationCompactAdaptation<T0, T1>(horizontal: T0, vertical: T1) -> Self { self }
    public func presentationCompactAdaptation<T0>(_ p0: T0) -> Self { self }
    public func id<T0>(_ p0: T0) -> Self { self }
    public func interactionActivityTrackingTag<T0>(_ p0: T0) -> Self { self }
    public func onScrollTargetVisibilityChange<T0, T1, T2>(idType: T0, threshold: T1, _ p2: T2) -> Self { self }
    public func presentationContentInteraction<T0>(_ p0: T0) -> Self { self }
    public func defaultAdaptableTabBarPlacement<T0>(_ p0: T0) -> Self { self }
    public func speechAlwaysIncludesPunctuation<T0>(_ p0: T0) -> Self { self }
    public func accessibilityIgnoresInvertColors<T0>(_ p0: T0) -> Self { self }
    public func writingToolsAffordanceVisibility<T0>(_ p0: T0) -> Self { self }
    public func navigationLinkIndicatorVisibility<T0>(_ p0: T0) -> Self { self }
    public func presentationBackgroundInteraction<T0>(_ p0: T0) -> Self { self }
    public func searchPresentationToolbarBehavior<T0>(_ p0: T0) -> Self { self }
    public func windowToolbarFullScreenVisibility<T0>(_ p0: T0) -> Self { self }
    public func attributedTextFormattingDefinition<T0>(_ p0: T0) -> Self { self }
    public func fileDialogImportsUnresolvedAliases<T0>(_ p0: T0) -> Self { self }
    public func flipsForRightToLeftLayoutDirection<T0>(_ p0: T0) -> Self { self }
    public func accessibilityShowsLargeContentViewer() -> Self { self }
    public func accessibilityShowsLargeContentViewer<T0>(_ p0: T0) -> Self { self }
    public func textInputFormattingControlVisibility<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func accessibilityRespondsToUserInteraction<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func accessibilityRespondsToUserInteraction<T0>(_ p0: T0) -> Self { self }
    public func tag<T0, T1>(_ p0: T0, includeOptional: T1) -> Self { self }
    public func blur<T0, T1>(radius: T0, opaque: T1) -> Self { self }
    public func bold<T0>(_ p0: T0) -> Self { self }
    public func font<T0>(_ p0: T0) -> Self { self }
    public func help<T0>(_ p0: T0) -> Self { self }
    public func mask<T0, T1>(alignment: T0, _ p1: T1) -> Self { self }
    public func mask<T0>(_ p0: T0) -> Self { self }
    public func task<T0, T1, T2, T3, T4, T5, T6>(id: T0, name: T1, executorPreference: T2, priority: T3, file: T4, line: T5, _ p6: T6) -> Self { self }
    public func task<T0, T1, T2>(id: T0, priority: T1, _ p2: T2) -> Self { self }
    public func task<T0, T1>(priority: T0, _ p1: T1) -> Self { self }
    public func tint<T0>(_ p0: T0) -> Self { self }
    public func alert<T0, T1, T2, T3>(isPresented: T0, error: T1, actions: T2, message: T3) -> Self { self }
    public func alert<T0, T1, T2>(isPresented: T0, error: T1, actions: T2) -> Self { self }
    public func alert<T0, T1>(isPresented: T0, content: T1) -> Self { self }
    public func alert<T0, T1>(item: T0, content: T1) -> Self { self }
    public func alert<T0, T1, T2, T3, T4>(_ p0: T0, isPresented: T1, presenting: T2, actions: T3, message: T4) -> Self { self }
    public func alert<T0, T1, T2, T3>(_ p0: T0, isPresented: T1, presenting: T2, actions: T3) -> Self { self }
    public func alert<T0, T1, T2, T3>(_ p0: T0, isPresented: T1, actions: T2, message: T3) -> Self { self }
    public func alert<T0, T1, T2>(_ p0: T0, isPresented: T1, actions: T2) -> Self { self }
    public func badge<T0>(_ p0: T0) -> Self { self }
    public func frame<T0, T1, T2>(width: T0, height: T1, alignment: T2) -> Self { self }
    public func frame<T0, T1, T2, T3, T4, T5, T6>(minWidth: T0, idealWidth: T1, maxWidth: T2, minHeight: T3, idealHeight: T4, maxHeight: T5, alignment: T6) -> Self { self }
    public func frame() -> Self { self }
    public func sheet<T0, T1, T2>(isPresented: T0, onDismiss: T1, content: T2) -> Self { self }
    public func sheet<T0, T1, T2>(item: T0, onDismiss: T1, content: T2) -> Self { self }
    public func border<T0, T1>(_ p0: T0, width: T1) -> Self { self }
    public func hidden() -> Self { self }
    public func italic<T0>(_ p0: T0) -> Self { self }
    public func offset<T0, T1>(x: T0, y: T1) -> Self { self }
    public func offset<T0>(_ p0: T0) -> Self { self }
    public func onDrag<T0, T1>(_ p0: T0, preview: T1) -> Self { self }
    public func onDrag<T0>(_ p0: T0) -> Self { self }
    public func onDrop<T0, T1, T2>(of: T0, isTargeted: T1, perform: T2) -> Self { self }
    public func onDrop<T0, T1>(of: T0, delegate: T1) -> Self { self }
    public func shadow<T0, T1, T2, T3>(color: T0, radius: T1, x: T2, y: T3) -> Self { self }
    public func zIndex<T0>(_ p0: T0) -> Self { self }
    public func clipped<T0>(antialiased: T0) -> Self { self }
    public func focused<T0, T1>(_ p0: T0, equals: T1) -> Self { self }
    public func focused<T0>(_ p0: T0) -> Self { self }
    public func gesture<T0, T1, T2>(_ p0: T0, name: T1, isEnabled: T2) -> Self { self }
    public func gesture<T0, T1>(_ p0: T0, including: T1) -> Self { self }
    public func gesture<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func gesture<T0>(_ p0: T0) -> Self { self }
    public func kerning<T0>(_ p0: T0) -> Self { self }
    public func onHover<T0>(perform: T0) -> Self { self }
    public func opacity<T0>(_ p0: T0) -> Self { self }
    public func overlay<T0, T1>(alignment: T0, content: T1) -> Self { self }
    public func overlay<T0, T1>(_ p0: T0, ignoresSafeAreaEdges: T1) -> Self { self }
    public func overlay<T0, T1, T2>(_ p0: T0, `in`: T1, fillStyle: T2) -> Self { self }
    public func overlay<T0, T1>(_ p0: T0, alignment: T1) -> Self { self }
    public func padding<T0>(_ p0: T0) -> Self { self }
    public func padding<T0, T1>(_ p0: T0, _ p1: T1) -> Self { self }
    public func popover<T0, T1, T2, T3>(isPresented: T0, attachmentAnchor: T1, arrowEdge: T2, content: T3) -> Self { self }
    public func popover<T0, T1, T2, T3>(item: T0, attachmentAnchor: T1, arrowEdge: T2, content: T3) -> Self { self }
    public func tabItem<T0>(_ p0: T0) -> Self { self }
    public func toolbar<T0, T1>(id: T0, content: T1) -> Self { self }
    public func toolbar<T0>(content: T0) -> Self { self }
    public func toolbar<T0>(removing: T0) -> Self { self }
    public func toolbar<T0, T1>(_ p0: T0, `for`: T1) -> Self { self }
    public func contrast<T0>(_ p0: T0) -> Self { self }
    public func disabled<T0>(_ p0: T0) -> Self { self }
    public func modifier<T0>(_ p0: T0) -> Self { self }
    public func onAppear<T0>(perform: T0) -> Self { self }
    public func onChange<T0, T1, T2>(of: T0, initial: T1, _ p2: T2) -> Self { self }
    public func onChange<T0, T1>(of: T0, perform: T1) -> Self { self }
    public func onSubmit<T0, T1>(of: T0, _ p1: T1) -> Self { self }
    public func position<T0, T1>(x: T0, y: T1) -> Self { self }
    public func position<T0>(_ p0: T0) -> Self { self }
    public func redacted<T0>(reason: T0) -> Self { self }
    public func textCase<T0>(_ p0: T0) -> Self { self }
    public func tracking<T0>(_ p0: T0) -> Self { self }
    public func animation<T0, T1>(_ p0: T0, body: T1) -> Self { self }
    public func animation<T0, T1>(_ p0: T0, value: T1) -> Self { self }
    public func animation<T0>(_ p0: T0) -> Self { self }
    public func blendMode<T0>(_ p0: T0) -> Self { self }
    public func clipShape<T0, T1>(_ p0: T0, style: T1) -> Self { self }
    public func draggable<T0, T1>(_ p0: T0, preview: T1) -> Self { self }
    public func draggable<T0>(_ p0: T0) -> Self { self }
    public func fileMover<T0, T1, T2, T3>(isPresented: T0, file: T1, onCompletion: T2, onCancellation: T3) -> Self { self }
    public func fileMover<T0, T1, T2>(isPresented: T0, file: T1, onCompletion: T2) -> Self { self }
    public func fileMover<T0, T1, T2, T3>(isPresented: T0, files: T1, onCompletion: T2, onCancellation: T3) -> Self { self }
    public func fileMover<T0, T1, T2>(isPresented: T0, files: T1, onCompletion: T2) -> Self { self }
    public func fixedSize<T0, T1>(horizontal: T0, vertical: T1) -> Self { self }
    public func fixedSize() -> Self { self }
    public func focusable<T0, T1>(_ p0: T0, interactions: T1) -> Self { self }
    public func focusable<T0>(_ p0: T0) -> Self { self }
    public func fontWidth<T0>(_ p0: T0) -> Self { self }
    public func formStyle<T0>(_ p0: T0) -> Self { self }
    public func grayscale<T0>(_ p0: T0) -> Self { self }
    public func inspector<T0, T1>(isPresented: T0, content: T1) -> Self { self }
    public func lineLimit<T0, T1>(_ p0: T0, reservesSpace: T1) -> Self { self }
    public func lineLimit<T0>(_ p0: T0) -> Self { self }
    public func listStyle<T0>(_ p0: T0) -> Self { self }
    public func menuOrder<T0>(_ p0: T0) -> Self { self }
    public func menuStyle<T0>(_ p0: T0) -> Self { self }
    public func onOpenURL<T0>(prefersInApp: T0) -> Self { self }
    public func onOpenURL<T0>(perform: T0) -> Self { self }
    public func onReceive<T0, T1>(_ p0: T0, perform: T1) -> Self { self }
    public func statusBar<T0>(hidden: T0) -> Self { self }
    public func textScale<T0, T1>(_ p0: T0, isEnabled: T1) -> Self { self }
    public func underline<T0, T1, T2>(_ p0: T0, pattern: T1, color: T2) -> Self { self }
}
#endif
