import Foundation

extension View {
    @MainActor @preconcurrency func backgroundExtensionEffect() -> some View { EmptyView() }
    @MainActor @preconcurrency func backgroundExtensionEffect(isEnabled: Bool) -> some View { EmptyView() }
    @MainActor @preconcurrency func documentBrowserContextMenu(@ViewBuilder _ menu: @escaping ([URL]?) -> some View) -> some View { EmptyView() }
    @MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View { EmptyView() }
    @MainActor @preconcurrency func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View { EmptyView() }
    @MainActor @preconcurrency func navigationLinkIndicatorVisibility(_ visibility: Visibility) -> some View { EmptyView() }
    @MainActor @preconcurrency func onOpenURL(prefersInApp: Bool) -> some View { EmptyView() }
    @MainActor @preconcurrency func scrollInputBehavior(_ behavior: ScrollInputBehavior, for input: ScrollInputKind) -> some View { EmptyView() }
    @MainActor @preconcurrency func writingToolsAffordanceVisibility(_ visibility: Visibility) -> some View { EmptyView() }
    @MainActor @preconcurrency func writingToolsBehavior(_ behavior: WritingToolsBehavior) -> some View { EmptyView() }
    @preconcurrency nonisolated func alignmentGuide(_ g: HorizontalAlignment, computeValue: @escaping (ViewDimensions) -> CGFloat) -> some View { EmptyView() }
    @preconcurrency nonisolated func alignmentGuide(_ g: VerticalAlignment, computeValue: @escaping (ViewDimensions) -> CGFloat) -> some View { EmptyView() }
    @preconcurrency nonisolated func onGeometryChange<T>(for type: T.Type, of transform: @escaping (GeometryProxy) -> T, action: @escaping (T) -> Void) -> some View where T : Equatable, T : Sendable { EmptyView() }
    @preconcurrency nonisolated func onGeometryChange<T>(for type: T.Type, of transform: @escaping (GeometryProxy) -> T, action: @escaping (T, T) -> Void) -> some View where T : Equatable, T : Sendable { EmptyView() }
    @preconcurrency nonisolated func refundRequestSheet(for transactionID: Transaction.ID, isPresented: Binding<Bool>, onDismiss: (@MainActor (Result<Transaction.RefundRequestStatus, Transaction.RefundRequestError>) -> ())? = nil) -> some View { EmptyView() }
    nonisolated func accentColor(_ accentColor: Color?) -> some View { EmptyView() }
    nonisolated func accessibility(activationPoint: CGPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(activationPoint: UnitPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(addTraits traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(hidden: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(hint: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(identifier: String) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(inputLabels: [Text]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(label: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(removeTraits traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(selectionIdentifier: AnyHashable) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(sortPriority: Double) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibility(value: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAction(_ actionKind: AccessibilityActionKind = .default, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAction(named name: Text, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAction(named nameKey: LocalizedStringKey, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAction(named nameResource: LocalizedStringResource, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAction<Label>(action: @escaping () -> Void, @ViewBuilder label: () -> Label) -> some View where Label : View { EmptyView() }
    nonisolated func accessibilityAction<S>(named name: S, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityActions<Content>(@ViewBuilder _ content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func accessibilityActions<Content>(category: AccessibilityActionCategory, @ViewBuilder _ content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func accessibilityActivationPoint(_ activationPoint: CGPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityActivationPoint(_ activationPoint: CGPoint, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityActivationPoint(_ activationPoint: UnitPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityActivationPoint(_ activationPoint: UnitPoint, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAddTraits(_ traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityAdjustableAction(_ handler: @escaping (AccessibilityAdjustmentDirection) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityChartDescriptor<R>(_ representable: R) -> some View where R : AXChartDescriptorRepresentable { EmptyView() }
    nonisolated func accessibilityChildren<V>(@ViewBuilder children: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func accessibilityCustomContent(_ key: AccessibilityCustomContentKey, _ value: Text?, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ key: AccessibilityCustomContentKey, _ valueKey: LocalizedStringKey, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ key: AccessibilityCustomContentKey, _ valueResource: LocalizedStringResource, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ label: LocalizedStringResource, _ value: Text, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ label: LocalizedStringResource, _ valueResource: LocalizedStringResource, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ label: Text, _ value: Text, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ labelKey: LocalizedStringKey, _ value: Text, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent(_ labelKey: LocalizedStringKey, _ valueKey: LocalizedStringKey, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent<L, V>(_ label: L, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where L : StringProtocol, V : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent<V>(_ key: AccessibilityCustomContentKey, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where V : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent<V>(_ label: LocalizedStringResource, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where V : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityCustomContent<V>(_ labelKey: LocalizedStringKey, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where V : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDefaultFocus<Value>(_ binding: AccessibilityFocusState<Value>.Binding, _ value: Value) -> some View where Value : Hashable { EmptyView() }
    nonisolated func accessibilityDirectTouch(_ isDirectTouchArea: Bool = true, options: AccessibilityDirectTouchOptions = []) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint<S>(_ point: UnitPoint, description: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDragPoint<S>(_ point: UnitPoint, description: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint<S>(_ point: UnitPoint, description: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityDropPoint<S>(_ point: UnitPoint, description: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityElement(children: AccessibilityChildBehavior = .ignore) -> some View { EmptyView() }
    nonisolated func accessibilityFocused(_ condition: AccessibilityFocusState<Bool>.Binding) -> some View { EmptyView() }
    nonisolated func accessibilityFocused<Value>(_ binding: AccessibilityFocusState<Value>.Binding, equals value: Value) -> some View where Value : Hashable { EmptyView() }
    nonisolated func accessibilityHeading(_ level: AccessibilityHeadingLevel) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHidden(_ hidden: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHidden(_ hidden: Bool, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint(_ hint: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint(_ hint: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint(_ hint: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint(_ hint: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint(_ hintKey: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint(_ hintKey: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint<S>(_ hint: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityHint<S>(_ hint: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityIdentifier(_ identifier: String) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityIdentifier(_ identifier: String, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityIgnoresInvertColors(_ active: Bool = true) -> some View { EmptyView() }
    nonisolated func accessibilityInputLabels(_ inputLabelKeys: [LocalizedStringKey]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityInputLabels(_ inputLabelKeys: [LocalizedStringKey], isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityInputLabels(_ inputLabels: [Text]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityInputLabels(_ inputLabels: [Text], isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityInputLabels<S>(_ inputLabels: [S]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityInputLabels<S>(_ inputLabels: [S], isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel(_ label: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel(_ label: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel(_ label: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel(_ label: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel(_ labelKey: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel(_ labelKey: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel<S>(_ label: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel<S>(_ label: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityLabel<V>(@ViewBuilder content: (PlaceholderContentView<Self>) -> V) -> some View where V : View { EmptyView() }
    nonisolated func accessibilityLabeledPair<ID>(role: AccessibilityLabeledPairRole, id: ID, in namespace: Namespace.ID) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityLinkedGroup<ID>(id: ID, in namespace: Namespace.ID) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityRemoveTraits(_ traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityRepresentation<V>(@ViewBuilder representation: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func accessibilityRespondsToUserInteraction(_ respondsToUserInteraction: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityRespondsToUserInteraction(_ respondsToUserInteraction: Bool, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityRotor(_ label: LocalizedStringResource, textRanges: [Range<String.Index>]) -> some View { EmptyView() }
    nonisolated func accessibilityRotor(_ label: Text, textRanges: [Range<String.Index>]) -> some View { EmptyView() }
    nonisolated func accessibilityRotor(_ labelKey: LocalizedStringKey, textRanges: [Range<String.Index>]) -> some View { EmptyView() }
    nonisolated func accessibilityRotor(_ systemRotor: AccessibilitySystemRotor, textRanges: [Range<String.Index>]) -> some View { EmptyView() }
    nonisolated func accessibilityRotor<Content>(_ label: LocalizedStringResource, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { EmptyView() }
    nonisolated func accessibilityRotor<Content>(_ label: Text, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { EmptyView() }
    nonisolated func accessibilityRotor<Content>(_ labelKey: LocalizedStringKey, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { EmptyView() }
    nonisolated func accessibilityRotor<Content>(_ systemRotor: AccessibilitySystemRotor, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel, ID>(_ rotorLabel: Text, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel, ID>(_ rotorLabelKey: LocalizedStringKey, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel, ID>(_ rotorLabelResource: LocalizedStringResource, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel, ID>(_ systemRotor: AccessibilitySystemRotor, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel>(_ rotorLabel: Text, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel>(_ rotorLabelKey: LocalizedStringKey, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel>(_ rotorLabelResource: LocalizedStringResource, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { EmptyView() }
    nonisolated func accessibilityRotor<EntryModel>(_ systemRotor: AccessibilitySystemRotor, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { EmptyView() }
    nonisolated func accessibilityRotor<L, Content>(_ label: L, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where L : StringProtocol, Content : AccessibilityRotorContent { EmptyView() }
    nonisolated func accessibilityRotor<L, EntryModel, ID>(_ rotorLabel: L, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where L : StringProtocol, ID : Hashable { EmptyView() }
    nonisolated func accessibilityRotor<L, EntryModel>(_ rotorLabel: L, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where L : StringProtocol, EntryModel : Identifiable { EmptyView() }
    nonisolated func accessibilityRotor<L>(_ label: L, textRanges: [Range<String.Index>]) -> some View where L : StringProtocol { EmptyView() }
    nonisolated func accessibilityRotorEntry<ID>(id: ID, in namespace: Namespace.ID) -> some View where ID : Hashable { EmptyView() }
    nonisolated func accessibilityScrollAction(_ handler: @escaping (Edge) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityScrollStatus(_ status: LocalizedStringResource, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityScrollStatus(_ status: Text, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityScrollStatus(_ status: some StringProtocol, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityScrollStatus(_ statusKey: LocalizedStringKey, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityShowsLargeContentViewer() -> some View { EmptyView() }
    nonisolated func accessibilityShowsLargeContentViewer<V>(@ViewBuilder _ largeContentView: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func accessibilitySortPriority(_ sortPriority: Double) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityTextContentType(_ value: AccessibilityTextContentType) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue(_ valueDescription: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue(_ valueDescription: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue(_ valueKey: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue(_ valueKey: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue(_ valueResource: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue(_ valueResource: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue<S>(_ value: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityValue<S>(_ value: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { fatalError("StoreKit Linux lookalike") }
    nonisolated func accessibilityZoomAction(_ handler: @escaping (AccessibilityZoomGestureAction) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { fatalError("StoreKit Linux lookalike") }
    nonisolated func actionSheet(isPresented: Binding<Bool>, content: () -> ActionSheet) -> some View { EmptyView() }
    nonisolated func actionSheet<T>(item: Binding<T?>, content: (T) -> ActionSheet) -> some View where T : Identifiable { EmptyView() }
    nonisolated func alert(isPresented: Binding<Bool>, content: () -> Alert) -> some View { EmptyView() }
    nonisolated func alert<A, M, T>(_ title: Text, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func alert<A, M, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func alert<A, M, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func alert<A, M>(_ title: Text, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func alert<A, M>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func alert<A, M>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func alert<A, T>(_ title: Text, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { EmptyView() }
    nonisolated func alert<A, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { EmptyView() }
    nonisolated func alert<A, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { EmptyView() }
    nonisolated func alert<A>(_ title: Text, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where A : View { EmptyView() }
    nonisolated func alert<A>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where A : View { EmptyView() }
    nonisolated func alert<A>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where A : View { EmptyView() }
    nonisolated func alert<E, A, M>(isPresented: Binding<Bool>, error: E?, @ViewBuilder actions: (E) -> A, @ViewBuilder message: (E) -> M) -> some View where E : LocalizedError, A : View, M : View { EmptyView() }
    nonisolated func alert<E, A>(isPresented: Binding<Bool>, error: E?, @ViewBuilder actions: () -> A) -> some View where E : LocalizedError, A : View { EmptyView() }
    nonisolated func alert<Item>(item: Binding<Item?>, content: (Item) -> Alert) -> some View where Item : Identifiable { EmptyView() }
    nonisolated func alert<S, A, M, T>(_ title: S, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where S : StringProtocol, A : View, M : View { EmptyView() }
    nonisolated func alert<S, A, M>(_ title: S, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where S : StringProtocol, A : View, M : View { EmptyView() }
    nonisolated func alert<S, A, T>(_ title: S, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where S : StringProtocol, A : View { EmptyView() }
    nonisolated func alert<S, A>(_ title: S, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where S : StringProtocol, A : View { EmptyView() }
    nonisolated func allowedDynamicRange(_ range: Image.DynamicRange?) -> some View { EmptyView() }
    nonisolated func allowsHitTesting(_ enabled: Bool) -> some View { EmptyView() }
    nonisolated func allowsTightening(_ flag: Bool) -> some View { EmptyView() }
    nonisolated func allowsWindowActivationEvents() -> some View { EmptyView() }
    nonisolated func allowsWindowActivationEvents(_ value: Bool?) -> some View { EmptyView() }
    nonisolated func anchorPreference<A, K>(key _: K.Type = K.self, value: Anchor<A>.Source, transform: @escaping (Anchor<A>) -> K.Value) -> some View where K : PreferenceKey { EmptyView() }
    nonisolated func animation(_ animation: Animation?) -> some View { EmptyView() }
    nonisolated func animation<V>(_ animation: Animation?, @ViewBuilder body: (PlaceholderContentView<Self>) -> V) -> some View where V : View { EmptyView() }
    nonisolated func animation<V>(_ animation: Animation?, value: V) -> some View where V : Equatable { EmptyView() }
    nonisolated func appStoreMerchandising(isPresented: Binding<Bool>, kind: AppStoreMerchandisingKind, onDismiss: ((Result<AppStoreMerchandisingKind.PresentationResult, any Error>) async -> ())? = nil) -> some View { EmptyView() }
    nonisolated func appStoreOverlay(isPresented: Binding<Bool>, configuration: @escaping () -> SKOverlay.Configuration) -> some View { EmptyView() }
    nonisolated func aspectRatio(_ aspectRatio: CGFloat? = nil, contentMode: ContentMode) -> some View { EmptyView() }
    nonisolated func aspectRatio(_ aspectRatio: CGSize, contentMode: ContentMode) -> some View { EmptyView() }
    nonisolated func assistiveAccessNavigationIcon(_ icon: Image) -> some View { EmptyView() }
    nonisolated func assistiveAccessNavigationIcon(systemImage: String) -> some View { EmptyView() }
    nonisolated func attributedTextFormattingDefinition<D>(_ definition: D) -> some View where D : AttributedTextFormattingDefinition { EmptyView() }
    nonisolated func attributedTextFormattingDefinition<S>(_ path: KeyPath<AttributeScopes, S.Type>) -> some View where S : AttributeScope { EmptyView() }
    nonisolated func attributedTextFormattingDefinition<S>(_ scope: S.Type) -> some View where S : AttributeScope { EmptyView() }
    nonisolated func autocapitalization(_ style: UITextAutocapitalizationType) -> some View { EmptyView() }
    nonisolated func autocorrectionDisabled(_ disable: Bool = true) -> some View { EmptyView() }
    nonisolated func background(ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View { EmptyView() }
    nonisolated func background<Background>(_ background: Background, alignment: Alignment = .center) -> some View where Background : View { EmptyView() }
    nonisolated func background<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S : ShapeStyle, T : InsettableShape { EmptyView() }
    nonisolated func background<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S : ShapeStyle, T : Shape { EmptyView() }
    nonisolated func background<S>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func background<S>(in shape: S, fillStyle: FillStyle = FillStyle()) -> some View where S : InsettableShape { EmptyView() }
    nonisolated func background<S>(in shape: S, fillStyle: FillStyle = FillStyle()) -> some View where S : Shape { EmptyView() }
    nonisolated func background<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func backgroundPreferenceValue<K, V>(_ key: K.Type, alignment: Alignment = .center, @ViewBuilder _ transform: @escaping (K.Value) -> V) -> some View where K : PreferenceKey, V : View { EmptyView() }
    nonisolated func backgroundPreferenceValue<Key, T>(_ key: Key.Type = Key.self, @ViewBuilder _ transform: @escaping (Key.Value) -> T) -> some View where Key : PreferenceKey, T : View { EmptyView() }
    nonisolated func backgroundStyle<S>(_ style: S) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func badge(_ count: Int) -> some View { EmptyView() }
    nonisolated func badge(_ key: LocalizedStringKey?) -> some View { EmptyView() }
    nonisolated func badge(_ label: Text?) -> some View { EmptyView() }
    nonisolated func badge(_ resource: LocalizedStringResource?) -> some View { EmptyView() }
    nonisolated func badge<S>(_ label: S?) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func badgeProminence(_ prominence: BadgeProminence) -> some View { EmptyView() }
    nonisolated func baselineOffset(_ baselineOffset: CGFloat) -> some View { EmptyView() }
    nonisolated func blendMode(_ blendMode: BlendMode) -> some View { EmptyView() }
    nonisolated func blur(radius: CGFloat, opaque: Bool = false) -> some View { EmptyView() }
    nonisolated func bold(_ isActive: Bool = true) -> some View { EmptyView() }
    nonisolated func border<S>(_ content: S, width: CGFloat = 1) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func brightness(_ amount: Double) -> some View { EmptyView() }
    nonisolated func buttonBorderShape(_ shape: ButtonBorderShape) -> some View { EmptyView() }
    nonisolated func buttonRepeatBehavior(_ behavior: ButtonRepeatBehavior) -> some View { EmptyView() }
    nonisolated func buttonSizing(_ sizing: ButtonSizing) -> some View { EmptyView() }
    nonisolated func buttonStyle<S>(_ style: S) -> some View where S : ButtonStyle { EmptyView() }
    nonisolated func buttonStyle<S>(_ style: S) -> some View where S : PrimitiveButtonStyle { EmptyView() }
    nonisolated func clipShape<S>(_ shape: S, style: FillStyle = FillStyle()) -> some View where S : Shape { EmptyView() }
    nonisolated func clipped(antialiased: Bool = false) -> some View { EmptyView() }
    nonisolated func colorEffect(_ shader: Shader, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func colorInvert() -> some View { EmptyView() }
    nonisolated func colorMultiply(_ color: Color) -> some View { EmptyView() }
    nonisolated func colorScheme(_ colorScheme: ColorScheme) -> some View { EmptyView() }
    nonisolated func compositingGroup() -> some View { EmptyView() }
    nonisolated func confirmationDialog<A, M, T>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<A, M, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<A, M, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<A, M>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<A, M>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<A, M>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<A, T>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { EmptyView() }
    nonisolated func confirmationDialog<A, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { EmptyView() }
    nonisolated func confirmationDialog<A, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { EmptyView() }
    nonisolated func confirmationDialog<A>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where A : View { EmptyView() }
    nonisolated func confirmationDialog<A>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where A : View { EmptyView() }
    nonisolated func confirmationDialog<A>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where A : View { EmptyView() }
    nonisolated func confirmationDialog<S, A, M, T>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where S : StringProtocol, A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<S, A, M>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where S : StringProtocol, A : View, M : View { EmptyView() }
    nonisolated func confirmationDialog<S, A, T>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where S : StringProtocol, A : View { EmptyView() }
    nonisolated func confirmationDialog<S, A>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where S : StringProtocol, A : View { EmptyView() }
    nonisolated func containerBackground<S>(_ style: S, for container: ContainerBackgroundPlacement) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func containerBackground<V>(for container: ContainerBackgroundPlacement, alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func containerCornerOffset(_ edges: Edge.Set, sizeToFit: Bool = false) -> some View { EmptyView() }
    nonisolated func containerRelativeFrame(_ axes: Axis.Set, alignment: Alignment = .center) -> some View { EmptyView() }
    nonisolated func containerRelativeFrame(_ axes: Axis.Set, alignment: Alignment = .center, _ length: @escaping (CGFloat, Axis) -> CGFloat) -> some View { EmptyView() }
    nonisolated func containerRelativeFrame(_ axes: Axis.Set, count: Int, span: Int = 1, spacing: CGFloat, alignment: Alignment = .center) -> some View { EmptyView() }
    nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View { EmptyView() }
    nonisolated func containerShape<T>(_ shape: T) -> some View where T : InsettableShape { EmptyView() }
    nonisolated func containerValue<V>(_ keyPath: WritableKeyPath<ContainerValues, V>, _ value: V) -> some View { EmptyView() }
    nonisolated func contentMargins(_ edges: Edge.Set = .all, _ insets: EdgeInsets, for placement: ContentMarginPlacement = .automatic) -> some View { EmptyView() }
    nonisolated func contentMargins(_ edges: Edge.Set = .all, _ length: CGFloat?, for placement: ContentMarginPlacement = .automatic) -> some View { EmptyView() }
    nonisolated func contentMargins(_ length: CGFloat, for placement: ContentMarginPlacement = .automatic) -> some View { EmptyView() }
    nonisolated func contentShape<S>(_ kind: ContentShapeKinds, _ shape: S, eoFill: Bool = false) -> some View where S : Shape { EmptyView() }
    nonisolated func contentShape<S>(_ shape: S, eoFill: Bool = false) -> some View where S : Shape { EmptyView() }
    nonisolated func contentToolbar<Content>(for placement: ContentToolbarPlacement, @ToolbarContentBuilder content: () -> Content) -> some View where Content : ToolbarContent { EmptyView() }
    nonisolated func contentToolbar<Content>(for placement: ContentToolbarPlacement, @ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func contentTransition(_ transition: ContentTransition) -> some View { EmptyView() }
    nonisolated func contextMenu<I, M>(forSelectionType itemType: I.Type = I.self, @ViewBuilder menu: @escaping (Set<I>) -> M, primaryAction: ((Set<I>) -> Void)? = nil) -> some View where I : Hashable, M : View { EmptyView() }
    nonisolated func contextMenu<M, P>(@ViewBuilder menuItems: () -> M, @ViewBuilder preview: () -> P) -> some View where M : View, P : View { EmptyView() }
    nonisolated func contextMenu<MenuItems>(@ViewBuilder menuItems: () -> MenuItems) -> some View where MenuItems : View { EmptyView() }
    nonisolated func contextMenu<MenuItems>(_ contextMenu: ContextMenu<MenuItems>?) -> some View where MenuItems : View { EmptyView() }
    nonisolated func contrast(_ amount: Double) -> some View { EmptyView() }
    nonisolated func controlGroupStyle<S>(_ style: S) -> some View where S : ControlGroupStyle { EmptyView() }
    nonisolated func controlSize(_ controlSize: ControlSize) -> some View { EmptyView() }
    nonisolated func controlSize<T>(_ range: T) -> some View where T : RangeExpression, T.Bound == ControlSize { EmptyView() }
    nonisolated func coordinateSpace(_ name: NamedCoordinateSpace) -> some View { EmptyView() }
    nonisolated func coordinateSpace<T>(name: T) -> some View where T : Hashable { EmptyView() }
    nonisolated func cornerRadius(_ radius: CGFloat, antialiased: Bool = true) -> some View { EmptyView() }
    nonisolated func currentEntitlementTask(for productID: String, priority: TaskPriority = .medium, action: @escaping (EntitlementTaskState<VerificationResult<Transaction>?>) async -> ()) -> some View { EmptyView() }
    nonisolated func datePickerStyle<S>(_ style: S) -> some View where S : DatePickerStyle { EmptyView() }
    nonisolated func defaultAdaptableTabBarPlacement(_ defaultPlacement: AdaptableTabBarPlacement = .automatic) -> some View { EmptyView() }
    nonisolated func defaultAppStorage(_ store: UserDefaults) -> some View { EmptyView() }
    nonisolated func defaultFocus<V>(_ binding: FocusState<V>.Binding, _ value: V, priority: DefaultFocusEvaluationPriority = .automatic) -> some View where V : Hashable { EmptyView() }
    nonisolated func defaultHoverEffect(_ effect: HoverEffect?) -> some View { EmptyView() }
    nonisolated func defaultHoverEffect(_ effect: some CustomHoverEffect) -> some View { EmptyView() }
    nonisolated func defaultScrollAnchor(_ anchor: UnitPoint?) -> some View { EmptyView() }
    nonisolated func defaultScrollAnchor(_ anchor: UnitPoint?, for role: ScrollAnchorRole) -> some View { EmptyView() }
    nonisolated func defersSystemGestures(on edges: Edge.Set) -> some View { EmptyView() }
    nonisolated func deleteDisabled(_ isDisabled: Bool) -> some View { EmptyView() }
    nonisolated func dialogIcon(_ icon: Image?) -> some View { EmptyView() }
    nonisolated func dialogSuppressionToggle(_ label: Text, isSuppressed: Binding<Bool>) -> some View { EmptyView() }
    nonisolated func dialogSuppressionToggle(_ titleKey: LocalizedStringKey, isSuppressed: Binding<Bool>) -> some View { EmptyView() }
    nonisolated func dialogSuppressionToggle(_ titleResource: LocalizedStringResource, isSuppressed: Binding<Bool>) -> some View { EmptyView() }
    nonisolated func dialogSuppressionToggle(isSuppressed: Binding<Bool>) -> some View { EmptyView() }
    nonisolated func dialogSuppressionToggle<S>(_ title: S, isSuppressed: Binding<Bool>) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func disableAutocorrection(_ disable: Bool?) -> some View { EmptyView() }
    nonisolated func disabled(_ disabled: Bool) -> some View { EmptyView() }
    nonisolated func disclosureGroupStyle<S>(_ style: S) -> some View where S : DisclosureGroupStyle { EmptyView() }
    nonisolated func distortionEffect(_ shader: Shader, maxSampleOffset: CGSize, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func draggable<T>(_ payload: @autoclosure @escaping () -> T) -> some View where T : Transferable { EmptyView() }
    nonisolated func draggable<V, T>(_ payload: @autoclosure @escaping () -> T, @ViewBuilder preview: () -> V) -> some View where V : View, T : Transferable { EmptyView() }
    nonisolated func drawingGroup(opaque: Bool = false, colorMode: ColorRenderingMode = .nonLinear) -> some View { EmptyView() }
    nonisolated func dropDestination<T>(for payloadType: T.Type = T.self, action: @escaping ([T], CGPoint) -> Bool, isTargeted: @escaping (Bool) -> Void = { _ in }) -> some View where T : Transferable { EmptyView() }
    nonisolated func dropDestination<T>(for type: T.Type = T.self, isEnabled: Bool = true, action: @escaping ([T], DropSession) -> Void) -> some View where T : Transferable { EmptyView() }
    nonisolated func dynamicTypeSize(_ size: DynamicTypeSize) -> some View { EmptyView() }
    nonisolated func dynamicTypeSize<T>(_ range: T) -> some View where T : RangeExpression, T.Bound == DynamicTypeSize { EmptyView() }
    nonisolated func edgesIgnoringSafeArea(_ edges: Edge.Set) -> some View { EmptyView() }
    nonisolated func environment<T>(_ object: T?) -> some View where T : AnyObject, T : Observable { EmptyView() }
    nonisolated func environment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, _ value: V) -> some View { EmptyView() }
    nonisolated func environmentObject<T>(_ object: T) -> some View where T : ObservableObject { EmptyView() }
    nonisolated func fileDialogBrowserOptions(_ options: FileDialogBrowserOptions) -> some View { EmptyView() }
    nonisolated func fileDialogConfirmationLabel(_ label: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func fileDialogConfirmationLabel(_ label: Text?) -> some View { EmptyView() }
    nonisolated func fileDialogConfirmationLabel(_ labelKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func fileDialogConfirmationLabel<S>(_ label: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func fileDialogCustomizationID(_ id: String) -> some View { EmptyView() }
    nonisolated func fileDialogDefaultDirectory(_ defaultDirectory: URL?) -> some View { EmptyView() }
    nonisolated func fileDialogImportsUnresolvedAliases(_ imports: Bool) -> some View { EmptyView() }
    nonisolated func fileDialogMessage(_ message: Text?) -> some View { EmptyView() }
    nonisolated func fileDialogMessage(_ messageKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func fileDialogMessage(_ messageResource: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func fileDialogMessage<S>(_ message: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func fileDialogURLEnabled(_ predicate: Predicate<URL>) -> some View { EmptyView() }
    nonisolated func fileExporter<C, T>(isPresented: Binding<Bool>, items: C, contentTypes: [UTType] = [], onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void = { }) -> some View where C : Collection, T : Transferable, T == C.Element { EmptyView() }
    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentType: UTType, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View where C : Collection, C.Element : FileDocument { EmptyView() }
    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentType: UTType, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View where C : Collection, C.Element : ReferenceFileDocument { EmptyView() }
    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentTypes: [UTType] = [], onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where C : Collection, C.Element : FileDocument { EmptyView() }
    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentTypes: [UTType] = [], onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where C : Collection, C.Element : ReferenceFileDocument { EmptyView() }
    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentType: UTType, defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View where D : FileDocument { EmptyView() }
    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentType: UTType, defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View where D : ReferenceFileDocument { EmptyView() }
    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where D : FileDocument { EmptyView() }
    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where D : ReferenceFileDocument { EmptyView() }
    nonisolated func fileExporter<T>(isPresented: Binding<Bool>, item: T?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = { }) -> some View where T : Transferable { EmptyView() }
    nonisolated func fileExporterFilenameLabel(_ label: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func fileExporterFilenameLabel(_ label: Text?) -> some View { EmptyView() }
    nonisolated func fileExporterFilenameLabel(_ labelKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func fileExporterFilenameLabel<S>(_ label: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], allowsMultipleSelection: Bool, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View { EmptyView() }
    nonisolated func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], allowsMultipleSelection: Bool, onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View { EmptyView() }
    nonisolated func fileMover(isPresented: Binding<Bool>, file: URL?, onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View { EmptyView() }
    nonisolated func fileMover(isPresented: Binding<Bool>, file: URL?, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func fileMover<C>(isPresented: Binding<Bool>, files: C, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View where C : Collection, C.Element == URL { EmptyView() }
    nonisolated func fileMover<C>(isPresented: Binding<Bool>, files: C, onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void) -> some View where C : Collection, C.Element == URL { EmptyView() }
    nonisolated func findDisabled(_ isDisabled: Bool = true) -> some View { EmptyView() }
    nonisolated func findNavigator(isPresented: Binding<Bool>) -> some View { EmptyView() }
    nonisolated func fixedSize() -> some View { EmptyView() }
    nonisolated func fixedSize(horizontal: Bool, vertical: Bool) -> some View { EmptyView() }
    nonisolated func flipsForRightToLeftLayoutDirection(_ enabled: Bool) -> some View { EmptyView() }
    nonisolated func focusEffectDisabled(_ disabled: Bool = true) -> some View { EmptyView() }
    nonisolated func focusable(_ isFocusable: Bool = true) -> some View { EmptyView() }
    nonisolated func focusable(_ isFocusable: Bool = true, interactions: FocusInteractions) -> some View { EmptyView() }
    nonisolated func focused(_ condition: FocusState<Bool>.Binding) -> some View { EmptyView() }
    nonisolated func focused<Value>(_ binding: FocusState<Value>.Binding, equals value: Value) -> some View where Value : Hashable { EmptyView() }
    nonisolated func focusedObject<T>(_ object: T) -> some View where T : ObservableObject { EmptyView() }
    nonisolated func focusedObject<T>(_ object: T?) -> some View where T : ObservableObject { EmptyView() }
    nonisolated func focusedSceneObject<T>(_ object: T) -> some View where T : ObservableObject { EmptyView() }
    nonisolated func focusedSceneObject<T>(_ object: T?) -> some View where T : ObservableObject { EmptyView() }
    nonisolated func focusedSceneValue<T>(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T) -> some View { EmptyView() }
    nonisolated func focusedSceneValue<T>(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T?) -> some View { EmptyView() }
    nonisolated func focusedSceneValue<T>(_ object: T?) -> some View where T : AnyObject, T : Observable { EmptyView() }
    nonisolated func focusedValue<T>(_ object: T?) -> some View where T : AnyObject, T : Observable { EmptyView() }
    nonisolated func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value) -> some View { EmptyView() }
    nonisolated func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value?) -> some View { EmptyView() }
    nonisolated func font(_ font: Font?) -> some View { EmptyView() }
    nonisolated func fontDesign(_ design: Font.Design?) -> some View { EmptyView() }
    nonisolated func fontWeight(_ weight: Font.Weight?) -> some View { EmptyView() }
    nonisolated func fontWidth(_ width: Font.Width?) -> some View { EmptyView() }
    nonisolated func foregroundColor(_ color: Color?) -> some View { EmptyView() }
    nonisolated func foregroundStyle<S1, S2, S3>(_ primary: S1, _ secondary: S2, _ tertiary: S3) -> some View where S1 : ShapeStyle, S2 : ShapeStyle, S3 : ShapeStyle { EmptyView() }
    nonisolated func foregroundStyle<S1, S2>(_ primary: S1, _ secondary: S2) -> some View where S1 : ShapeStyle, S2 : ShapeStyle { EmptyView() }
    nonisolated func foregroundStyle<S>(_ style: S) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func formStyle<S>(_ style: S) -> some View where S : FormStyle { EmptyView() }
    nonisolated func frame() -> some View { EmptyView() }
    nonisolated func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View { EmptyView() }
    nonisolated func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View { EmptyView() }
    nonisolated func fullScreenCover<Content>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func fullScreenCover<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View { EmptyView() }
    nonisolated func gaugeStyle<S>(_ style: S) -> some View where S : GaugeStyle { EmptyView() }
    nonisolated func geometryGroup() -> some View { EmptyView() }
    nonisolated func gesture(_ representable: some UIGestureRecognizerRepresentable) -> some View { EmptyView() }
    nonisolated func gesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { EmptyView() }
    nonisolated func gesture<T>(_ gesture: T, isEnabled: Bool) -> some View where T : Gesture { EmptyView() }
    nonisolated func gesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { EmptyView() }
    nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View { EmptyView() }
    nonisolated func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View { EmptyView() }
    nonisolated func grayscale(_ amount: Double) -> some View { EmptyView() }
    nonisolated func gridCellAnchor(_ anchor: UnitPoint) -> some View { EmptyView() }
    nonisolated func gridCellColumns(_ count: Int) -> some View { EmptyView() }
    nonisolated func gridCellUnsizedAxes(_ axes: Axis.Set) -> some View { EmptyView() }
    nonisolated func gridColumnAlignment(_ guide: HorizontalAlignment) -> some View { EmptyView() }
    nonisolated func groupBoxStyle<S>(_ style: S) -> some View where S : GroupBoxStyle { EmptyView() }
    nonisolated func handGestureShortcut(_ shortcut: HandGestureShortcut, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func handlesExternalEvents(preferring: Set<String>, allowing: Set<String>) -> some View { EmptyView() }
    nonisolated func headerProminence(_ prominence: Prominence) -> some View { EmptyView() }
    nonisolated func help(_ text: Text) -> some View { EmptyView() }
    nonisolated func help(_ textKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func help(_ textKey: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func help<S>(_ text: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func hidden() -> some View { EmptyView() }
    nonisolated func highPriorityGesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { EmptyView() }
    nonisolated func highPriorityGesture<T>(_ gesture: T, isEnabled: Bool) -> some View where T : Gesture { EmptyView() }
    nonisolated func highPriorityGesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { EmptyView() }
    nonisolated func hoverEffect(_ effect: HoverEffect = .automatic) -> some View { EmptyView() }
    nonisolated func hoverEffect(_ effect: HoverEffect = .automatic, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func hoverEffectDisabled(_ disabled: Bool = true) -> some View { EmptyView() }
    nonisolated func hueRotation(_ angle: Angle) -> some View { EmptyView() }
    nonisolated func id<ID>(_ id: ID) -> some View where ID : Hashable { EmptyView() }
    nonisolated func ignoresSafeArea(_ regions: SafeAreaRegions = .all, edges: Edge.Set = .all) -> some View { EmptyView() }
    nonisolated func imageScale(_ scale: Image.Scale) -> some View { EmptyView() }
    nonisolated func inAppPurchaseOptions(_ options: ((Product) async -> Set<Product.PurchaseOption>)?) -> some View { EmptyView() }
    nonisolated func indexViewStyle<S>(_ style: S) -> some View where S : IndexViewStyle { EmptyView() }
    nonisolated func inspector<V>(isPresented: Binding<Bool>, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func inspectorColumnWidth(_ width: CGFloat) -> some View { EmptyView() }
    nonisolated func inspectorColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> some View { EmptyView() }
    nonisolated func interactionActivityTrackingTag(_ tag: String) -> some View { EmptyView() }
    nonisolated func interactiveDismissDisabled(_ isDisabled: Bool = true) -> some View { EmptyView() }
    nonisolated func invalidatableContent(_ invalidatable: Bool = true) -> some View { EmptyView() }
    nonisolated func italic(_ isActive: Bool = true) -> some View { EmptyView() }
    nonisolated func itemProvider(_ action: Optional<() -> NSItemProvider?>) -> some View { EmptyView() }
    nonisolated func kerning(_ kerning: CGFloat) -> some View { EmptyView() }
    nonisolated func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command) -> some View { EmptyView() }
    nonisolated func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command, localization: KeyboardShortcut.Localization) -> some View { EmptyView() }
    nonisolated func keyboardShortcut(_ shortcut: KeyboardShortcut) -> some View { EmptyView() }
    nonisolated func keyboardShortcut(_ shortcut: KeyboardShortcut?) -> some View { EmptyView() }
    nonisolated func keyboardType(_ type: UIKeyboardType) -> some View { EmptyView() }
    nonisolated func keyframeAnimator<Value>(initialValue: Value, repeating: Bool = true, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Value) -> some View, @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes) -> some View { EmptyView() }
    nonisolated func keyframeAnimator<Value>(initialValue: Value, trigger: some Equatable, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Value) -> some View, @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes) -> some View { EmptyView() }
    nonisolated func labelIconToTitleSpacing(_ value: CGFloat) -> some View { EmptyView() }
    nonisolated func labelReservedIconWidth(_ value: CGFloat) -> some View { EmptyView() }
    nonisolated func labelStyle<S>(_ style: S) -> some View where S : LabelStyle { EmptyView() }
    nonisolated func labeledContentStyle<S>(_ style: S) -> some View where S : LabeledContentStyle { EmptyView() }
    nonisolated func labelsHidden() -> some View { EmptyView() }
    nonisolated func labelsVisibility(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func layerEffect(_ shader: Shader, maxSampleOffset: CGSize, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func layoutDirectionBehavior(_ behavior: LayoutDirectionBehavior) -> some View { EmptyView() }
    nonisolated func layoutPriority(_ value: Double) -> some View { EmptyView() }
    nonisolated func layoutValue<K>(key: K.Type, value: K.Value) -> some View where K : LayoutValueKey { EmptyView() }
    nonisolated func lineHeight(_ lineHeight: AttributedString.LineHeight?) -> some View { EmptyView() }
    nonisolated func lineLimit(_ limit: ClosedRange<Int>) -> some View { EmptyView() }
    nonisolated func lineLimit(_ limit: Int, reservesSpace: Bool) -> some View { EmptyView() }
    nonisolated func lineLimit(_ limit: PartialRangeFrom<Int>) -> some View { EmptyView() }
    nonisolated func lineLimit(_ limit: PartialRangeThrough<Int>) -> some View { EmptyView() }
    nonisolated func lineLimit(_ number: Int?) -> some View { EmptyView() }
    nonisolated func lineSpacing(_ lineSpacing: CGFloat) -> some View { EmptyView() }
    nonisolated func listItemTint(_ tint: Color?) -> some View { EmptyView() }
    nonisolated func listItemTint(_ tint: ListItemTint?) -> some View { EmptyView() }
    nonisolated func listRowBackground<V>(_ view: V?) -> some View where V : View { EmptyView() }
    nonisolated func listRowInsets(_ edges: Edge.Set = .all, _ length: CGFloat?) -> some View { EmptyView() }
    nonisolated func listRowInsets(_ insets: EdgeInsets?) -> some View { EmptyView() }
    nonisolated func listRowSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View { EmptyView() }
    nonisolated func listRowSeparatorTint(_ color: Color?, edges: VerticalEdge.Set = .all) -> some View { EmptyView() }
    nonisolated func listRowSpacing(_ spacing: CGFloat?) -> some View { EmptyView() }
    nonisolated func listSectionIndexVisibility(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func listSectionMargins(_ edges: Edge.Set = .all, _ length: CGFloat?) -> some View { EmptyView() }
    nonisolated func listSectionSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View { EmptyView() }
    nonisolated func listSectionSeparatorTint(_ color: Color?, edges: VerticalEdge.Set = .all) -> some View { EmptyView() }
    nonisolated func listSectionSpacing(_ spacing: CGFloat) -> some View { EmptyView() }
    nonisolated func listSectionSpacing(_ spacing: ListSectionSpacing) -> some View { EmptyView() }
    nonisolated func listStyle<S>(_ style: S) -> some View where S : ListStyle { EmptyView() }
    nonisolated func luminanceToAlpha() -> some View { EmptyView() }
    nonisolated func manageSubscriptionsSheet(isPresented: Binding<Bool>) -> some View { EmptyView() }
    nonisolated func manageSubscriptionsSheet(isPresented: Binding<Bool>, subscriptionGroupID: String) -> some View { EmptyView() }
    nonisolated func mask<Mask>(_ mask: Mask) -> some View where Mask : View { EmptyView() }
    nonisolated func mask<Mask>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> Mask) -> some View where Mask : View { EmptyView() }
    nonisolated func matchedGeometryEffect<ID>(id: ID, in namespace: Namespace.ID, properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center, isSource: Bool = true) -> some View where ID : Hashable { EmptyView() }
    nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View { EmptyView() }
    nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID, configuration: (EmptyMatchedTransitionSourceConfiguration) -> some MatchedTransitionSourceConfiguration) -> some View { EmptyView() }
    nonisolated func materialActiveAppearance(_ appearance: MaterialActiveAppearance) -> some View { EmptyView() }
    nonisolated func menuActionDismissBehavior(_ behavior: MenuActionDismissBehavior) -> some View { EmptyView() }
    nonisolated func menuIndicator(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func menuOrder(_ order: MenuOrder) -> some View { EmptyView() }
    nonisolated func menuStyle<S>(_ style: S) -> some View where S : MenuStyle { EmptyView() }
    nonisolated func minimumScaleFactor(_ factor: CGFloat) -> some View { EmptyView() }
    nonisolated func modifier<T>(_ modifier: T) -> ModifiedContent<Self, T> { fatalError("StoreKit Linux lookalike") }
    nonisolated func monospaced(_ isActive: Bool = true) -> some View { EmptyView() }
    nonisolated func monospacedDigit() -> some View { EmptyView() }
    nonisolated func moveDisabled(_ isDisabled: Bool) -> some View { EmptyView() }
    nonisolated func multilineTextAlignment(_ alignment: TextAlignment) -> some View { EmptyView() }
    nonisolated func multilineTextAlignment(strategy: Text.AlignmentStrategy) -> some View { EmptyView() }
    nonisolated func navigationBarBackButtonHidden(_ hidesBackButton: Bool = true) -> some View { EmptyView() }
    nonisolated func navigationBarHidden(_ hidden: Bool) -> some View { EmptyView() }
    nonisolated func navigationBarItems<L, T>(leading: L, trailing: T) -> some View where L : View, T : View { EmptyView() }
    nonisolated func navigationBarItems<L>(leading: L) -> some View where L : View { EmptyView() }
    nonisolated func navigationBarItems<T>(trailing: T) -> some View where T : View { EmptyView() }
    nonisolated func navigationBarTitle(_ title: Text) -> some View { EmptyView() }
    nonisolated func navigationBarTitle(_ title: Text, displayMode: NavigationBarItem.TitleDisplayMode) -> some View { EmptyView() }
    nonisolated func navigationBarTitle(_ titleKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func navigationBarTitle(_ titleKey: LocalizedStringKey, displayMode: NavigationBarItem.TitleDisplayMode) -> some View { EmptyView() }
    nonisolated func navigationBarTitle<S>(_ title: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func navigationBarTitle<S>(_ title: S, displayMode: NavigationBarItem.TitleDisplayMode) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func navigationBarTitleDisplayMode(_ displayMode: NavigationBarItem.TitleDisplayMode) -> some View { EmptyView() }
    nonisolated func navigationDestination<D, C>(for data: D.Type, @ViewBuilder destination: @escaping (D) -> C) -> some View where D : Hashable, C : View { EmptyView() }
    nonisolated func navigationDestination<D, C>(item: Binding<Optional<D>>, @ViewBuilder destination: @escaping (D) -> C) -> some View where D : Hashable, C : View { EmptyView() }
    nonisolated func navigationDestination<V>(isPresented: Binding<Bool>, @ViewBuilder destination: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func navigationDocument(_ url: URL) -> some View { EmptyView() }
    nonisolated func navigationDocument<D, I1, I2>(_ document: D, preview: SharePreview<I1, I2>) -> some View where D : Transferable, I1 : Transferable, I2 : Transferable { EmptyView() }
    nonisolated func navigationDocument<D, I>(_ document: D, preview: SharePreview<I, Never>) -> some View where D : Transferable, I : Transferable { EmptyView() }
    nonisolated func navigationDocument<D, I>(_ document: D, preview: SharePreview<Never, I>) -> some View where D : Transferable, I : Transferable { EmptyView() }
    nonisolated func navigationDocument<D>(_ document: D) -> some View where D : Transferable { EmptyView() }
    nonisolated func navigationDocument<D>(_ document: D, preview: SharePreview<Never, Never>) -> some View where D : Transferable { EmptyView() }
    nonisolated func navigationSplitViewColumnWidth(_ width: CGFloat) -> some View { EmptyView() }
    nonisolated func navigationSplitViewColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> some View { EmptyView() }
    nonisolated func navigationSplitViewStyle<S>(_ style: S) -> some View where S : NavigationSplitViewStyle { EmptyView() }
    nonisolated func navigationSubtitle(_ subtitle: Text) -> some View { EmptyView() }
    nonisolated func navigationSubtitle(_ subtitleKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func navigationSubtitle(_ subtitleKey: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func navigationSubtitle<S>(_ subtitle: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func navigationTitle(_ title: Binding<String>) -> some View { EmptyView() }
    nonisolated func navigationTitle(_ title: Text) -> some View { EmptyView() }
    nonisolated func navigationTitle(_ titleKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func navigationTitle(_ titleResource: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func navigationTitle<S>(_ title: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func navigationTitle<V>(@ViewBuilder _ title: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func navigationTransition(_ style: some NavigationTransition) -> some View { EmptyView() }
    nonisolated func navigationViewStyle<S>(_ style: S) -> some View where S : NavigationViewStyle { EmptyView() }
    nonisolated func offerCodeRedemption(isPresented: Binding<Bool>, onCompletion: @escaping @MainActor (Result<Void, any Error>) -> Void = { _ in }) -> some View { EmptyView() }
    nonisolated func offset(_ offset: CGSize) -> some View { EmptyView() }
    nonisolated func offset(x: CGFloat = 0, y: CGFloat = 0) -> some View { EmptyView() }
    nonisolated func onAppear(perform action: (() -> Void)? = nil) -> some View { EmptyView() }
    nonisolated func onChange<V>(of value: V, initial: Bool = false, _ action: @escaping () -> Void) -> some View where V : Equatable { EmptyView() }
    nonisolated func onChange<V>(of value: V, initial: Bool = false, _ action: @escaping (V, V) -> Void) -> some View where V : Equatable { EmptyView() }
    nonisolated func onChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V : Equatable { EmptyView() }
    nonisolated func onContinueUserActivity(_ activityType: String, perform action: @escaping (NSUserActivity) -> ()) -> some View { EmptyView() }
    nonisolated func onContinuousHover(coordinateSpace: CoordinateSpace = .local, perform action: @escaping (HoverPhase) -> Void) -> some View { EmptyView() }
    nonisolated func onDisappear(perform action: (() -> Void)? = nil) -> some View { EmptyView() }
    nonisolated func onDrag(_ data: @escaping () -> NSItemProvider) -> some View { EmptyView() }
    nonisolated func onDrag<V>(_ data: @escaping () -> NSItemProvider, @ViewBuilder preview: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func onDrop(of supportedContentTypes: [UTType], delegate: any DropDelegate) -> some View { EmptyView() }
    nonisolated func onDrop(of supportedContentTypes: [UTType], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider]) -> Bool) -> some View { EmptyView() }
    nonisolated func onDrop(of supportedContentTypes: [UTType], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider], CGPoint) -> Bool) -> some View { EmptyView() }
    nonisolated func onDrop(of supportedTypes: [String], delegate: any DropDelegate) -> some View { EmptyView() }
    nonisolated func onDrop(of supportedTypes: [String], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider]) -> Bool) -> some View { EmptyView() }
    nonisolated func onDrop(of supportedTypes: [String], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider], CGPoint) -> Bool) -> some View { EmptyView() }
    nonisolated func onHover(perform action: @escaping (Bool) -> Void) -> some View { EmptyView() }
    nonisolated func onInAppPurchaseCompletion(perform action: ((Product, Result<Product.PurchaseResult, any Error>) async -> ())?) -> some View { EmptyView() }
    nonisolated func onInAppPurchaseStart(perform action: ((Product) async -> ())?) -> some View { EmptyView() }
    nonisolated func onInteractiveResizeChange(_ action: @escaping (Bool) -> Void) -> some View { EmptyView() }
    nonisolated func onKeyPress(_ key: KeyEquivalent, action: @escaping () -> KeyPress.Result) -> some View { EmptyView() }
    nonisolated func onKeyPress(_ key: KeyEquivalent, phases: KeyPress.Phases, action: @escaping (KeyPress) -> KeyPress.Result) -> some View { EmptyView() }
    nonisolated func onKeyPress(characters: CharacterSet, phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result) -> some View { EmptyView() }
    nonisolated func onKeyPress(keys: Set<KeyEquivalent>, phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result) -> some View { EmptyView() }
    nonisolated func onKeyPress(phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result) -> some View { EmptyView() }
    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10, perform action: @escaping () -> Void, onPressingChanged: ((Bool) -> Void)? = nil) -> some View { EmptyView() }
    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10, pressing: ((Bool) -> Void)? = nil, perform action: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, perform action: @escaping () -> Void, onPressingChanged: ((Bool) -> Void)? = nil) -> some View { EmptyView() }
    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, pressing: ((Bool) -> Void)? = nil, perform action: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func onOpenURL(perform action: @escaping (URL) -> ()) -> some View { EmptyView() }
    nonisolated func onPencilDoubleTap(perform action: @escaping (PencilDoubleTapGestureValue) -> Void) -> some View { EmptyView() }
    nonisolated func onPencilSqueeze(perform action: @escaping (PencilSqueezeGesturePhase) -> Void) -> some View { EmptyView() }
    nonisolated func onPreferenceChange<K>(_ key: K.Type = K.self, perform action: @escaping (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable { EmptyView() }
    nonisolated func onReceive<P>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P : Publisher, P.Failure == Never { EmptyView() }
    nonisolated func onScrollGeometryChange<T>(for type: T.Type, of transform: @escaping (ScrollGeometry) -> T, action: @escaping (T, T) -> Void) -> some View where T : Equatable { EmptyView() }
    nonisolated func onScrollPhaseChange(_ action: @escaping (ScrollPhase, ScrollPhase) -> Void) -> some View { EmptyView() }
    nonisolated func onScrollPhaseChange(_ action: @escaping (ScrollPhase, ScrollPhase, ScrollPhaseChangeContext) -> Void) -> some View { EmptyView() }
    nonisolated func onScrollTargetVisibilityChange<ID>(idType: ID.Type, threshold: Double = 0.5, _ action: @escaping ([ID]) -> Void) -> some View where ID : Hashable { EmptyView() }
    nonisolated func onScrollVisibilityChange(threshold: Double = 0.5, _ action: @escaping (Bool) -> Void) -> some View { EmptyView() }
    nonisolated func onSubmit(of triggers: SubmitTriggers = .text, _ action: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func onTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, perform action: @escaping (CGPoint) -> Void) -> some View { EmptyView() }
    nonisolated func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func opacity(_ opacity: Double) -> some View { EmptyView() }
    nonisolated func overlay<Overlay>(_ overlay: Overlay, alignment: Alignment = .center) -> some View where Overlay : View { EmptyView() }
    nonisolated func overlay<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S : ShapeStyle, T : Shape { EmptyView() }
    nonisolated func overlay<S>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func overlay<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func overlayPreferenceValue<K, V>(_ key: K.Type, alignment: Alignment = .center, @ViewBuilder _ transform: @escaping (K.Value) -> V) -> some View where K : PreferenceKey, V : View { EmptyView() }
    nonisolated func overlayPreferenceValue<Key, T>(_ key: Key.Type = Key.self, @ViewBuilder _ transform: @escaping (Key.Value) -> T) -> some View where Key : PreferenceKey, T : View { EmptyView() }
    nonisolated func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { EmptyView() }
    nonisolated func padding(_ insets: EdgeInsets) -> some View { EmptyView() }
    nonisolated func padding(_ length: CGFloat) -> some View { EmptyView() }
    nonisolated func paletteSelectionEffect(_ effect: PaletteSelectionEffect) -> some View { EmptyView() }
    nonisolated func persistentSystemOverlays(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func phaseAnimator<Phase>(_ phases: some Sequence, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Phase) -> some View, animation: @escaping (Phase) -> Animation? = { _ in .default }) -> some View where Phase : Equatable { EmptyView() }
    nonisolated func phaseAnimator<Phase>(_ phases: some Sequence, trigger: some Equatable, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Phase) -> some View, animation: @escaping (Phase) -> Animation? = { _ in .default }) -> some View where Phase : Equatable { EmptyView() }
    nonisolated func pickerStyle<S>(_ style: S) -> some View where S : PickerStyle { EmptyView() }
    nonisolated func popover<Content>(isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func popover<Item, Content>(item: Binding<Item?>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View { EmptyView() }
    nonisolated func position(_ position: CGPoint) -> some View { EmptyView() }
    nonisolated func position(x: CGFloat = 0, y: CGFloat = 0) -> some View { EmptyView() }
    nonisolated func preference<K>(key: K.Type = K.self, value: K.Value) -> some View where K : PreferenceKey { EmptyView() }
    nonisolated func preferredColorScheme(_ colorScheme: ColorScheme?) -> some View { EmptyView() }
    nonisolated func preferredSubscriptionOffer(_ offer: @escaping (Product, Product.SubscriptionInfo, [Product.SubscriptionOffer]) -> Product.SubscriptionOffer?) -> some View { EmptyView() }
    nonisolated func presentationBackground<S>(_ style: S) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func presentationBackground<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View { EmptyView() }
    nonisolated func presentationCompactAdaptation(_ adaptation: PresentationAdaptation) -> some View { EmptyView() }
    nonisolated func presentationCompactAdaptation(horizontal horizontalAdaptation: PresentationAdaptation, vertical verticalAdaptation: PresentationAdaptation) -> some View { EmptyView() }
    nonisolated func presentationContentInteraction(_ behavior: PresentationContentInteraction) -> some View { EmptyView() }
    nonisolated func presentationCornerRadius(_ cornerRadius: CGFloat?) -> some View { EmptyView() }
    nonisolated func presentationDetents(_ detents: Set<PresentationDetent>) -> some View { EmptyView() }
    nonisolated func presentationDetents(_ detents: Set<PresentationDetent>, selection: Binding<PresentationDetent>) -> some View { EmptyView() }
    nonisolated func presentationDragIndicator(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func presentationSizing(_ sizing: some PresentationSizing) -> some View { EmptyView() }
    nonisolated func previewContext<C>(_ value: C) -> some View where C : PreviewContext { EmptyView() }
    nonisolated func previewDevice(_ value: PreviewDevice?) -> some View { EmptyView() }
    nonisolated func previewDisplayName(_ value: String?) -> some View { EmptyView() }
    nonisolated func previewInterfaceOrientation(_ value: InterfaceOrientation) -> some View { EmptyView() }
    nonisolated func previewLayout(_ value: PreviewLayout) -> some View { EmptyView() }
    nonisolated func privacySensitive(_ sensitive: Bool = true) -> some View { EmptyView() }
    nonisolated func productDescription(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func productIconBorder() -> some View { EmptyView() }
    nonisolated func productViewStyle(_ style: some ProductViewStyle) -> some View { EmptyView() }
    nonisolated func progressViewStyle<S>(_ style: S) -> some View where S : ProgressViewStyle { EmptyView() }
    nonisolated func projectionEffect(_ transform: ProjectionTransform) -> some View { EmptyView() }
    nonisolated func redacted(reason: RedactionReasons) -> some View { EmptyView() }
    nonisolated func refreshable(action: @escaping () async -> Void) -> some View { EmptyView() }
    nonisolated func renameAction(_ action: @escaping () -> Void) -> some View { EmptyView() }
    nonisolated func renameAction(_ isFocused: FocusState<Bool>.Binding) -> some View { EmptyView() }
    nonisolated func replaceDisabled(_ isDisabled: Bool = true) -> some View { EmptyView() }
    nonisolated func rotation3DEffect(_ angle: Angle, axis: (x: CGFloat, y: CGFloat, z: CGFloat), anchor: UnitPoint = .center, anchorZ: CGFloat = 0, perspective: CGFloat = 1) -> some View { EmptyView() }
    nonisolated func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View { EmptyView() }
    nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> some View) -> some View { EmptyView() }
    nonisolated func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> some View) -> some View { EmptyView() }
    nonisolated func safeAreaInset<V>(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func safeAreaInset<V>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { EmptyView() }
    nonisolated func safeAreaPadding(_ insets: EdgeInsets) -> some View { EmptyView() }
    nonisolated func safeAreaPadding(_ length: CGFloat) -> some View { EmptyView() }
    nonisolated func saturation(_ amount: Double) -> some View { EmptyView() }
    nonisolated func scaleEffect(_ s: CGFloat, anchor: UnitPoint = .center) -> some View { EmptyView() }
    nonisolated func scaleEffect(_ scale: CGSize, anchor: UnitPoint = .center) -> some View { EmptyView() }
    nonisolated func scaleEffect(x: CGFloat = 1.0, y: CGFloat = 1.0, anchor: UnitPoint = .center) -> some View { EmptyView() }
    nonisolated func scaledToFill() -> some View { EmptyView() }
    nonisolated func scaledToFit() -> some View { EmptyView() }
    nonisolated func scenePadding(_ edges: Edge.Set = .all) -> some View { EmptyView() }
    nonisolated func scenePadding(_ padding: ScenePadding, edges: Edge.Set = .all) -> some View { EmptyView() }
    nonisolated func scrollBounceBehavior(_ behavior: ScrollBounceBehavior, axes: Axis.Set = [.vertical]) -> some View { EmptyView() }
    nonisolated func scrollClipDisabled(_ disabled: Bool = true) -> some View { EmptyView() }
    nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func scrollDisabled(_ disabled: Bool) -> some View { EmptyView() }
    nonisolated func scrollDismissesKeyboard(_ mode: ScrollDismissesKeyboardMode) -> some View { EmptyView() }
    nonisolated func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View { EmptyView() }
    nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View { EmptyView() }
    nonisolated func scrollIndicators(_ visibility: ScrollIndicatorVisibility, axes: Axis.Set = [.vertical, .horizontal]) -> some View { EmptyView() }
    nonisolated func scrollIndicatorsFlash(onAppear: Bool) -> some View { EmptyView() }
    nonisolated func scrollIndicatorsFlash(trigger value: some Equatable) -> some View { EmptyView() }
    nonisolated func scrollPosition(_ position: Binding<ScrollPosition>, anchor: UnitPoint? = nil) -> some View { EmptyView() }
    nonisolated func scrollPosition(id: Binding<(some Hashable)?>, anchor: UnitPoint? = nil) -> some View { EmptyView() }
    nonisolated func scrollTargetBehavior(_ behavior: some ScrollTargetBehavior) -> some View { EmptyView() }
    nonisolated func scrollTargetLayout(isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func scrollTransition(_ configuration: ScrollTransitionConfiguration = .interactive, axis: Axis? = nil, transition: @escaping (EmptyVisualEffect, ScrollTransitionPhase) -> some VisualEffect) -> some View { EmptyView() }
    nonisolated func scrollTransition(topLeading: ScrollTransitionConfiguration, bottomTrailing: ScrollTransitionConfiguration, axis: Axis? = nil, transition: @escaping (EmptyVisualEffect, ScrollTransitionPhase) -> some VisualEffect) -> some View { EmptyView() }
    nonisolated func searchCompletion(_ completion: String) -> some View { EmptyView() }
    nonisolated func searchCompletion<T>(_ token: T) -> some View where T : Identifiable { EmptyView() }
    nonisolated func searchDictationBehavior(_ dictationBehavior: TextInputDictationBehavior) -> some View { EmptyView() }
    nonisolated func searchFocused(_ binding: FocusState<Bool>.Binding) -> some View { EmptyView() }
    nonisolated func searchFocused<V>(_ binding: FocusState<V>.Binding, equals value: V) -> some View where V : Hashable { EmptyView() }
    nonisolated func searchPresentationToolbarBehavior(_ behavior: SearchPresentationToolbarBehavior) -> some View { EmptyView() }
    nonisolated func searchScopes<V, S>(_ scope: Binding<V>, @ViewBuilder scopes: () -> S) -> some View where V : Hashable, S : View { EmptyView() }
    nonisolated func searchScopes<V, S>(_ scope: Binding<V>, activation: SearchScopeActivation, @ViewBuilder _ scopes: () -> S) -> some View where V : Hashable, S : View { EmptyView() }
    nonisolated func searchSelection(_ selection: Binding<TextSelection?>) -> some View { EmptyView() }
    nonisolated func searchSuggestions(_ visibility: Visibility, for placements: SearchSuggestionsPlacement.Set) -> some View { EmptyView() }
    nonisolated func searchSuggestions<S>(@ViewBuilder _ suggestions: () -> S) -> some View where S : View { EmptyView() }
    nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View { EmptyView() }
    nonisolated func searchable(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func searchable(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func searchable(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil) -> some View { EmptyView() }
    nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil) -> some View { EmptyView() }
    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: some StringProtocol, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: some StringProtocol, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { EmptyView() }
    nonisolated func searchable<S>(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func searchable<S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder suggestions: () -> S) -> some View where S : View { EmptyView() }
    nonisolated func searchable<S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func searchable<S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder suggestions: () -> S) -> some View where S : View { EmptyView() }
    nonisolated func searchable<V, S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder suggestions: () -> V) -> some View where V : View, S : StringProtocol { EmptyView() }
    nonisolated func sectionActions<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func sectionIndexLabel(_ label: Text?) -> some View { EmptyView() }
    nonisolated func sectionIndexLabel<S>(_ label: S?) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func selectionDisabled(_ isDisabled: Bool = true) -> some View { EmptyView() }
    nonisolated func sensoryFeedback<T>(_ feedback: SensoryFeedback, trigger: T) -> some View where T : Equatable { EmptyView() }
    nonisolated func sensoryFeedback<T>(_ feedback: SensoryFeedback, trigger: T, condition: @escaping (T, T) -> Bool) -> some View where T : Equatable { EmptyView() }
    nonisolated func sensoryFeedback<T>(trigger: T, _ feedback: @escaping () -> SensoryFeedback?) -> some View where T : Equatable { EmptyView() }
    nonisolated func sensoryFeedback<T>(trigger: T, _ feedback: @escaping (T, T) -> SensoryFeedback?) -> some View where T : Equatable { EmptyView() }
    nonisolated func shadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View { EmptyView() }
    nonisolated func sheet<Content>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func sheet<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View { EmptyView() }
    nonisolated func simultaneousGesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { EmptyView() }
    nonisolated func simultaneousGesture<T>(_ gesture: T, isEnabled: Bool) -> some View where T : Gesture { EmptyView() }
    nonisolated func simultaneousGesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { EmptyView() }
    nonisolated func sliderThumbVisibility(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func speechAdjustedPitch(_ value: Double) -> some View { EmptyView() }
    nonisolated func speechAlwaysIncludesPunctuation(_ value: Bool = true) -> some View { EmptyView() }
    nonisolated func speechAnnouncementsQueued(_ value: Bool = true) -> some View { EmptyView() }
    nonisolated func speechSpellsOutCharacters(_ value: Bool = true) -> some View { EmptyView() }
    nonisolated func springLoadingBehavior(_ behavior: SpringLoadingBehavior) -> some View { EmptyView() }
    nonisolated func statusBar(hidden: Bool) -> some View { EmptyView() }
    nonisolated func statusBarHidden(_ hidden: Bool = true) -> some View { EmptyView() }
    nonisolated func storeButton(_ visibility: Visibility, for buttonKinds: StoreButtonKind...) -> some View { EmptyView() }
    nonisolated func storeProductTask(for id: Product.ID, priority: TaskPriority = .medium, action: @escaping (Product.TaskState) async -> ()) -> some View { EmptyView() }
    nonisolated func storeProductsTask(for ids: some Collection<String> & Equatable & Sendable, priority: TaskPriority = .medium, action: @escaping (Product.CollectionTaskState) async -> ()) -> some View { EmptyView() }
    nonisolated func strikethrough(_ isActive: Bool = true, pattern: Text.LineStyle.Pattern = .solid, color: Color? = nil) -> some View { EmptyView() }
    nonisolated func submitLabel(_ submitLabel: SubmitLabel) -> some View { EmptyView() }
    nonisolated func submitScope(_ isBlocking: Bool = true) -> some View { EmptyView() }
    nonisolated func subscriptionIntroductoryOffer(applyOffer: @escaping (Product, Product.SubscriptionInfo) -> Bool, compactJWS: @escaping (Product, Product.SubscriptionInfo) async throws -> String) -> some View { EmptyView() }
    nonisolated func subscriptionOfferViewButtonVisibility(_ visibility: Visibility, for buttonKinds: SubscriptionOfferViewButtonKind...) -> some View { EmptyView() }
    nonisolated func subscriptionOfferViewDetailAction(_ action: (() -> ())?) -> some View { EmptyView() }
    nonisolated func subscriptionOfferViewStyle(_ style: some SubscriptionOfferViewStyle) -> some View { EmptyView() }
    nonisolated func subscriptionPromotionalOffer(offer: @escaping (Product, Product.SubscriptionInfo) -> Product.SubscriptionOffer?, compactJWS: @escaping (Product, Product.SubscriptionInfo, Product.SubscriptionOffer) async throws -> String) -> some View { EmptyView() }
    nonisolated func subscriptionPromotionalOffer(offer: @escaping (Product, Product.SubscriptionInfo) -> Product.SubscriptionOffer?, signature: @escaping (Product, Product.SubscriptionInfo, Product.SubscriptionOffer) async throws -> Product.SubscriptionOffer.Signature) -> some View { EmptyView() }
    nonisolated func subscriptionStatusTask(for groupID: String, priority: TaskPriority = .medium, action: @escaping (EntitlementTaskState<[Product.SubscriptionInfo.Status]>) async -> ()) -> some View { EmptyView() }
    nonisolated func subscriptionStoreButtonLabel(_ label: SubscriptionStoreButtonLabel) -> some View { EmptyView() }
    nonisolated func subscriptionStoreControlBackground(_ backgroundStyle: SubscriptionStoreControlBackground) -> some View { EmptyView() }
    nonisolated func subscriptionStoreControlBackground(_ backgroundStyle: some ShapeStyle) -> some View { EmptyView() }
    nonisolated func subscriptionStoreControlIcon(@ViewBuilder icon: @escaping (Product, Product.SubscriptionInfo) -> some View) -> some View { EmptyView() }
    nonisolated func subscriptionStoreControlStyle(_ style: some SubscriptionStoreControlStyle) -> some View { EmptyView() }
    nonisolated func subscriptionStoreControlStyle<S>(_ style: S, placement: S.Placement) -> some View where S : SubscriptionStoreControlStyle { EmptyView() }
    nonisolated func subscriptionStoreOptionGroupStyle(_ style: some SubscriptionOptionGroupStyle) -> some View { EmptyView() }
    nonisolated func subscriptionStorePickerItemBackground(_ backgroundStyle: some ShapeStyle) -> some View { EmptyView() }
    nonisolated func subscriptionStorePickerItemBackground(_ backgroundStyle: some ShapeStyle, in shape: some Shape) -> some View { EmptyView() }
    nonisolated func subscriptionStorePolicyDestination(for button: SubscriptionStorePolicyKind, @ViewBuilder destination: () -> some View) -> some View { EmptyView() }
    nonisolated func subscriptionStorePolicyDestination(url: URL, for button: SubscriptionStorePolicyKind) -> some View { EmptyView() }
    nonisolated func subscriptionStorePolicyForegroundStyle(_ primary: some ShapeStyle, _ secondary: some ShapeStyle) -> some View { EmptyView() }
    nonisolated func subscriptionStorePolicyForegroundStyle(_ style: some ShapeStyle) -> some View { EmptyView() }
    nonisolated func subscriptionStoreSignInAction(_ action: (() -> ())?) -> some View { EmptyView() }
    nonisolated func swipeActions<T>(edge: HorizontalEdge = .trailing, allowsFullSwipe: Bool = true, @ViewBuilder content: () -> T) -> some View where T : View { EmptyView() }
    nonisolated func symbolColorRenderingMode(_ mode: SymbolColorRenderingMode?) -> some View { EmptyView() }
    nonisolated func symbolEffect<T, U>(_ effect: T, options: SymbolEffectOptions = .default, value: U) -> some View where T : DiscreteSymbolEffect, T : SymbolEffect, U : Equatable { EmptyView() }
    nonisolated func symbolEffect<T>(_ effect: T, options: SymbolEffectOptions = .default, isActive: Bool = true) -> some View where T : IndefiniteSymbolEffect, T : SymbolEffect { EmptyView() }
    nonisolated func symbolEffectsRemoved(_ isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func symbolRenderingMode(_ mode: SymbolRenderingMode?) -> some View { EmptyView() }
    nonisolated func symbolVariableValueMode(_ mode: SymbolVariableValueMode?) -> some View { EmptyView() }
    nonisolated func symbolVariant(_ variant: SymbolVariants) -> some View { EmptyView() }
    nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View { EmptyView() }
    nonisolated func tabItem<V>(@ViewBuilder _ label: () -> V) -> some View where V : View { EmptyView() }
    nonisolated func tabViewBottomAccessory<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func tabViewCustomization(_ customization: Binding<TabViewCustomization>?) -> some View { EmptyView() }
    nonisolated func tabViewSearchActivation(_ activation: TabSearchActivation) -> some View { EmptyView() }
    nonisolated func tabViewSidebarBottomBar<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func tabViewSidebarFooter<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func tabViewSidebarHeader<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func tabViewStyle<S>(_ style: S) -> some View where S : TabViewStyle { EmptyView() }
    nonisolated func tableColumnHeaders(_ visibility: Visibility) -> some View { EmptyView() }
    nonisolated func tableStyle<S>(_ style: S) -> some View where S : TableStyle { EmptyView() }
    nonisolated func tag<V>(_ tag: V, includeOptional: Bool = true) -> some View where V : Hashable { EmptyView() }
    nonisolated func task(priority: TaskPriority = .userInitiated, _ action: @escaping () async -> Void) -> some View { EmptyView() }
    nonisolated func task<T>(id value: T, priority: TaskPriority = .userInitiated, _ action: @escaping () async -> Void) -> some View where T : Equatable { EmptyView() }
    nonisolated func task<T>(id: T, name: String? = nil, executorPreference taskExecutor: any TaskExecutor, priority: TaskPriority = .userInitiated, file: String = #fileID, line: Int = #line, _ action: sending @escaping @isolated(any) () async -> Void) -> some View where T : Equatable { EmptyView() }
    nonisolated func textCase(_ textCase: Text.Case?) -> some View { EmptyView() }
    nonisolated func textContentType(_ textContentType: UITextContentType?) -> some View { EmptyView() }
    nonisolated func textEditorStyle(_ style: some TextEditorStyle) -> some View { EmptyView() }
    nonisolated func textFieldStyle<S>(_ style: S) -> some View where S : TextFieldStyle { EmptyView() }
    nonisolated func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization?) -> some View { EmptyView() }
    nonisolated func textInputFormattingControlVisibility(_ visibility: Visibility, for placement: TextInputFormattingControlPlacement.Set) -> some View { EmptyView() }
    nonisolated func textRenderer<T>(_ renderer: T) -> some View where T : TextRenderer { EmptyView() }
    nonisolated func textScale(_ scale: Text.Scale, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func textSelection<S>(_ selectability: S) -> some View where S : TextSelectability { EmptyView() }
    nonisolated func textSelectionAffinity(_ affinity: TextSelectionAffinity) -> some View { EmptyView() }
    nonisolated func tint(_ tint: Color?) -> some View { EmptyView() }
    nonisolated func toggleStyle<S>(_ style: S) -> some View where S : ToggleStyle { EmptyView() }
    nonisolated func toolbar(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { EmptyView() }
    nonisolated func toolbar(removing defaultItemKind: ToolbarDefaultItemKind?) -> some View { EmptyView() }
    nonisolated func toolbar<Content>(@ToolbarContentBuilder content: () -> Content) -> some View where Content : ToolbarContent { EmptyView() }
    nonisolated func toolbar<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { EmptyView() }
    nonisolated func toolbar<Content>(id: String, @ToolbarContentBuilder content: () -> Content) -> some View where Content : CustomizableToolbarContent { EmptyView() }
    nonisolated func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { EmptyView() }
    nonisolated func toolbarBackground<S>(_ style: S, for bars: ToolbarPlacement...) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { EmptyView() }
    nonisolated func toolbarColorScheme(_ colorScheme: ColorScheme?, for bars: ToolbarPlacement...) -> some View { EmptyView() }
    nonisolated func toolbarForegroundStyle<S>(_ style: S, for bars: ToolbarPlacement...) -> some View where S : ShapeStyle { EmptyView() }
    nonisolated func toolbarRole(_ role: ToolbarRole) -> some View { EmptyView() }
    nonisolated func toolbarTitleDisplayMode(_ mode: ToolbarTitleDisplayMode) -> some View { EmptyView() }
    nonisolated func toolbarTitleMenu<C>(@ViewBuilder content: () -> C) -> some View where C : View { EmptyView() }
    nonisolated func toolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { EmptyView() }
    nonisolated func tracking(_ tracking: CGFloat) -> some View { EmptyView() }
    nonisolated func transformAnchorPreference<A, K>(key _: K.Type = K.self, value: Anchor<A>.Source, transform: @escaping (inout K.Value, Anchor<A>) -> Void) -> some View where K : PreferenceKey { EmptyView() }
    nonisolated func transformEffect(_ transform: CGAffineTransform) -> some View { EmptyView() }
    nonisolated func transformEnvironment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, transform: @escaping (inout V) -> Void) -> some View { EmptyView() }
    nonisolated func transformPreference<K>(_ key: K.Type = K.self, _ callback: @escaping (inout K.Value) -> Void) -> some View where K : PreferenceKey { EmptyView() }
    nonisolated func transition(_ t: AnyTransition) -> some View { EmptyView() }
    nonisolated func transition<T>(_ transition: T) -> some View where T : Transition { EmptyView() }
    nonisolated func truncationMode(_ mode: Text.TruncationMode) -> some View { EmptyView() }
    nonisolated func typeSelectEquivalent(_ stringKey: LocalizedStringKey) -> some View { EmptyView() }
    nonisolated func typeSelectEquivalent(_ stringResource: LocalizedStringResource) -> some View { EmptyView() }
    nonisolated func typeSelectEquivalent(_ text: Text?) -> some View { EmptyView() }
    nonisolated func typeSelectEquivalent<S>(_ string: S) -> some View where S : StringProtocol { EmptyView() }
    nonisolated func typesettingLanguage(_ language: Locale.Language, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func typesettingLanguage(_ language: TypesettingLanguage, isEnabled: Bool = true) -> some View { EmptyView() }
    nonisolated func underline(_ isActive: Bool = true, pattern: Text.LineStyle.Pattern = .solid, color: Color? = nil) -> some View { EmptyView() }
    nonisolated func unredacted() -> some View { EmptyView() }
    nonisolated func userActivity(_ activityType: String, isActive: Bool = true, _ update: @escaping (NSUserActivity) -> ()) -> some View { EmptyView() }
    nonisolated func userActivity<P>(_ activityType: String, element: P?, _ update: @escaping (P, NSUserActivity) -> ()) -> some View { EmptyView() }
    nonisolated func visualEffect(_ effect: @escaping (EmptyVisualEffect, GeometryProxy) -> some VisualEffect) -> some View { EmptyView() }
    nonisolated func windowToolbarFullScreenVisibility(_ visibility: WindowToolbarFullScreenVisibility) -> some View { EmptyView() }
    nonisolated func writingDirection(strategy: Text.WritingDirectionStrategy) -> some View { EmptyView() }
    nonisolated func zIndex(_ value: Double) -> some View { EmptyView() }
}

