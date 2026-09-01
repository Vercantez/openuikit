// Recorded host-facing modifiers for `ContactAccessButton`.
//
// These names match the SwiftUI `View` members synthesized onto Apple's
// `ContactAccessButton`. Linux has no SwiftUI runtime, so each method stores
// configuration for a host renderer and returns `Self`. Closures are accepted
// for source compatibility and are not invoked; there is no view lifecycle.

extension ContactAccessButton {
    public enum RecordedModifier: Equatable, Sendable {
    case navigationSplitViewColumnWidth(min: CGFloat?, ideal: CGFloat, max: CGFloat?)
    case navigationSplitViewColumnWidthWidth(CGFloat)
    case brightness(Double)
    case saturation(Double)
    case unredacted
    case colorInvert
    case onDisappear
    case refreshable
    case scaledToFit
    case cornerRadius(CGFloat, antialiased: Bool)
    case labelsHidden
    case onTapGesture(count: Int)
    case renameAction
    case scaledToFill
    case geometryGroup
    case layoutPriority(Double)
    case listRowSpacing(CGFloat?)
    case scrollDisabled(Bool)
    case gridCellColumns(Int)
    case monospacedDigit
    case safeAreaPadding(CGFloat)
    case statusBarHidden(Bool)
    case allowsHitTesting(Bool)
    case allowsTightening(Bool)
    case compositingGroup
    case luminanceToAlpha
    case privacySensitive(Bool)
    case searchCompletion(String)
    case listSectionSpacing(CGFloat)
    case minimumScaleFactor(CGFloat)
    case previewDisplayName(String?)
    case scrollClipDisabled(Bool)
    case focusEffectDisabled(Bool)
    case hoverEffectDisabled(Bool)
    case navigationBarHidden(Bool)
    case speechAdjustedPitch(Double)
    case inspectorColumnWidth(min: CGFloat?, ideal: CGFloat, max: CGFloat?)
    case inspectorColumnWidthWidth(CGFloat)
    case invalidatableContent(Bool)
    case disableAutocorrection(Bool?)
    case autocorrectionDisabled(Bool)
    case labelReservedIconWidth(CGFloat)
    case labelIconToTitleSpacing(CGFloat)
    case onScrollVisibilityChange(threshold: Double)
    case backgroundExtensionEffect
    case fileDialogCustomizationID(String)
    case onInteractiveResizeChange
    case speechAnnouncementsQueued(Bool)
    case speechSpellsOutCharacters(Bool)
    case allowsWindowActivationEventsNil
    case allowsWindowActivationEvents(Bool?)
    case interactionActivityTrackingTag(String)
    case speechAlwaysIncludesPunctuation(Bool)
    case accessibilityIgnoresInvertColors(Bool)
    case fileDialogImportsUnresolvedAliases(Bool)
    case flipsForRightToLeftLayoutDirection(Bool)
    case accessibilityShowsLargeContentViewer
    case blur(radius: CGFloat, opaque: Bool)
    case badge(Int)
    case frame
    case hidden
    case offset(x: CGFloat, y: CGFloat)
    case zIndex(Double)
    case clipped(antialiased: Bool)
    case kerning(CGFloat)
    case onHover
    case opacity(Double)
    case padding(CGFloat)
    case contrast(Double)
    case disabled(Bool)
    case onAppear
    case position(x: CGFloat, y: CGFloat)
    case tracking(CGFloat)
    case fixedSize(horizontal: Bool, vertical: Bool)
    case fixedSizeBoth
    case grayscale(Double)
    case lineLimit(Int?)
    case statusBar(hidden: Bool)
    case contactAccessPickerPresented(Bool)
    }
}

extension ContactAccessButton {
    func recording(_ modifier: RecordedModifier) -> ContactAccessButton {
        var copy = self
        copy.recordedModifiers.append(modifier)
        return copy
    }

    public func navigationSplitViewColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> ContactAccessButton {
        return recording(.navigationSplitViewColumnWidth(min: min, ideal: ideal, max: max))
    }

    public func navigationSplitViewColumnWidth(_ width: CGFloat) -> ContactAccessButton {
        return recording(.navigationSplitViewColumnWidthWidth(width))
    }

    public func brightness(_ amount: Double) -> ContactAccessButton {
        return recording(.brightness(amount))
    }

    public func saturation(_ amount: Double) -> ContactAccessButton {
        return recording(.saturation(amount))
    }

    public func unredacted() -> ContactAccessButton {
        return recording(.unredacted)
    }

    public func colorInvert() -> ContactAccessButton {
        return recording(.colorInvert)
    }

    public func onDisappear(perform action: (() -> Void)? = nil) -> ContactAccessButton {
        _ = action as Any
        return recording(.onDisappear)
    }

    public func refreshable(action: @escaping () async -> Void) -> ContactAccessButton {
        _ = action as Any
        return recording(.refreshable)
    }

    public func scaledToFit() -> ContactAccessButton {
        return recording(.scaledToFit)
    }

    public func cornerRadius(_ radius: CGFloat, antialiased: Bool = true) -> ContactAccessButton {
        return recording(.cornerRadius(radius, antialiased: antialiased))
    }

    public func labelsHidden() -> ContactAccessButton {
        return recording(.labelsHidden)
    }

    public func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> ContactAccessButton {
        _ = action as Any
        return recording(.onTapGesture(count: count))
    }

    public func renameAction(_ action: @escaping () -> Void) -> ContactAccessButton {
        _ = action as Any
        return recording(.renameAction)
    }

    public func scaledToFill() -> ContactAccessButton {
        return recording(.scaledToFill)
    }

    public func geometryGroup() -> ContactAccessButton {
        return recording(.geometryGroup)
    }

    public func layoutPriority(_ value: Double) -> ContactAccessButton {
        return recording(.layoutPriority(value))
    }

    public func listRowSpacing(_ spacing: CGFloat?) -> ContactAccessButton {
        return recording(.listRowSpacing(spacing))
    }

    public func scrollDisabled(_ disabled: Bool) -> ContactAccessButton {
        return recording(.scrollDisabled(disabled))
    }

    public func gridCellColumns(_ count: Int) -> ContactAccessButton {
        return recording(.gridCellColumns(count))
    }

    public func monospacedDigit() -> ContactAccessButton {
        return recording(.monospacedDigit)
    }

    public func safeAreaPadding(_ length: CGFloat) -> ContactAccessButton {
        return recording(.safeAreaPadding(length))
    }

    public func statusBarHidden(_ hidden: Bool = true) -> ContactAccessButton {
        return recording(.statusBarHidden(hidden))
    }

    public func allowsHitTesting(_ enabled: Bool) -> ContactAccessButton {
        return recording(.allowsHitTesting(enabled))
    }

    public func allowsTightening(_ flag: Bool) -> ContactAccessButton {
        return recording(.allowsTightening(flag))
    }

    public func compositingGroup() -> ContactAccessButton {
        return recording(.compositingGroup)
    }

    public func luminanceToAlpha() -> ContactAccessButton {
        return recording(.luminanceToAlpha)
    }

    public func privacySensitive(_ sensitive: Bool = true) -> ContactAccessButton {
        return recording(.privacySensitive(sensitive))
    }

    public func searchCompletion(_ completion: String) -> ContactAccessButton {
        return recording(.searchCompletion(completion))
    }

    public func listSectionSpacing(_ spacing: CGFloat) -> ContactAccessButton {
        return recording(.listSectionSpacing(spacing))
    }

    public func minimumScaleFactor(_ factor: CGFloat) -> ContactAccessButton {
        return recording(.minimumScaleFactor(factor))
    }

    public func previewDisplayName(_ value: String?) -> ContactAccessButton {
        return recording(.previewDisplayName(value))
    }

    public func scrollClipDisabled(_ disabled: Bool = true) -> ContactAccessButton {
        return recording(.scrollClipDisabled(disabled))
    }

    public func focusEffectDisabled(_ disabled: Bool = true) -> ContactAccessButton {
        return recording(.focusEffectDisabled(disabled))
    }

    public func hoverEffectDisabled(_ disabled: Bool = true) -> ContactAccessButton {
        return recording(.hoverEffectDisabled(disabled))
    }

    public func navigationBarHidden(_ hidden: Bool) -> ContactAccessButton {
        return recording(.navigationBarHidden(hidden))
    }

    public func speechAdjustedPitch(_ value: Double) -> ContactAccessButton {
        return recording(.speechAdjustedPitch(value))
    }

    public func inspectorColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> ContactAccessButton {
        return recording(.inspectorColumnWidth(min: min, ideal: ideal, max: max))
    }

    public func inspectorColumnWidth(_ width: CGFloat) -> ContactAccessButton {
        return recording(.inspectorColumnWidthWidth(width))
    }

    public func invalidatableContent(_ invalidatable: Bool = true) -> ContactAccessButton {
        return recording(.invalidatableContent(invalidatable))
    }

    public func disableAutocorrection(_ disable: Bool?) -> ContactAccessButton {
        return recording(.disableAutocorrection(disable))
    }

    public func autocorrectionDisabled(_ disable: Bool = true) -> ContactAccessButton {
        return recording(.autocorrectionDisabled(disable))
    }

    public func labelReservedIconWidth(_ value: CGFloat) -> ContactAccessButton {
        return recording(.labelReservedIconWidth(value))
    }

    public func labelIconToTitleSpacing(_ value: CGFloat) -> ContactAccessButton {
        return recording(.labelIconToTitleSpacing(value))
    }

    public func onScrollVisibilityChange(threshold: Double = 0.5, _ action: @escaping (Bool) -> Void) -> ContactAccessButton {
        _ = action as Any
        return recording(.onScrollVisibilityChange(threshold: threshold))
    }

    public func backgroundExtensionEffect() -> ContactAccessButton {
        return recording(.backgroundExtensionEffect)
    }

    public func fileDialogCustomizationID(_ id: String) -> ContactAccessButton {
        return recording(.fileDialogCustomizationID(id))
    }

    public func onInteractiveResizeChange(_ action: @escaping (Bool) -> Void) -> ContactAccessButton {
        _ = action as Any
        return recording(.onInteractiveResizeChange)
    }

    public func speechAnnouncementsQueued(_ value: Bool = true) -> ContactAccessButton {
        return recording(.speechAnnouncementsQueued(value))
    }

    public func speechSpellsOutCharacters(_ value: Bool = true) -> ContactAccessButton {
        return recording(.speechSpellsOutCharacters(value))
    }

    public func allowsWindowActivationEvents() -> ContactAccessButton {
        return recording(.allowsWindowActivationEventsNil)
    }

    public func allowsWindowActivationEvents(_ value: Bool?) -> ContactAccessButton {
        return recording(.allowsWindowActivationEvents(value))
    }

    public func interactionActivityTrackingTag(_ tag: String) -> ContactAccessButton {
        return recording(.interactionActivityTrackingTag(tag))
    }

    public func speechAlwaysIncludesPunctuation(_ value: Bool = true) -> ContactAccessButton {
        return recording(.speechAlwaysIncludesPunctuation(value))
    }

    public func accessibilityIgnoresInvertColors(_ active: Bool = true) -> ContactAccessButton {
        return recording(.accessibilityIgnoresInvertColors(active))
    }

    public func fileDialogImportsUnresolvedAliases(_ imports: Bool) -> ContactAccessButton {
        return recording(.fileDialogImportsUnresolvedAliases(imports))
    }

    public func flipsForRightToLeftLayoutDirection(_ enabled: Bool) -> ContactAccessButton {
        return recording(.flipsForRightToLeftLayoutDirection(enabled))
    }

    public func accessibilityShowsLargeContentViewer() -> ContactAccessButton {
        return recording(.accessibilityShowsLargeContentViewer)
    }

    public func blur(radius: CGFloat, opaque: Bool = false) -> ContactAccessButton {
        return recording(.blur(radius: radius, opaque: opaque))
    }

    public func badge(_ count: Int) -> ContactAccessButton {
        return recording(.badge(count))
    }

    public func frame() -> ContactAccessButton {
        return recording(.frame)
    }

    public func hidden() -> ContactAccessButton {
        return recording(.hidden)
    }

    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> ContactAccessButton {
        return recording(.offset(x: x, y: y))
    }

    public func zIndex(_ value: Double) -> ContactAccessButton {
        return recording(.zIndex(value))
    }

    public func clipped(antialiased: Bool = false) -> ContactAccessButton {
        return recording(.clipped(antialiased: antialiased))
    }

    public func kerning(_ kerning: CGFloat) -> ContactAccessButton {
        return recording(.kerning(kerning))
    }

    public func onHover(perform action: @escaping (Bool) -> Void) -> ContactAccessButton {
        _ = action as Any
        return recording(.onHover)
    }

    public func opacity(_ opacity: Double) -> ContactAccessButton {
        return recording(.opacity(opacity))
    }

    public func padding(_ length: CGFloat) -> ContactAccessButton {
        return recording(.padding(length))
    }

    public func contrast(_ amount: Double) -> ContactAccessButton {
        return recording(.contrast(amount))
    }

    public func disabled(_ disabled: Bool) -> ContactAccessButton {
        return recording(.disabled(disabled))
    }

    public func onAppear(perform action: (() -> Void)? = nil) -> ContactAccessButton {
        _ = action as Any
        return recording(.onAppear)
    }

    public func position(x: CGFloat = 0, y: CGFloat = 0) -> ContactAccessButton {
        return recording(.position(x: x, y: y))
    }

    public func tracking(_ tracking: CGFloat) -> ContactAccessButton {
        return recording(.tracking(tracking))
    }

    public func fixedSize(horizontal: Bool, vertical: Bool) -> ContactAccessButton {
        return recording(.fixedSize(horizontal: horizontal, vertical: vertical))
    }

    public func fixedSize() -> ContactAccessButton {
        return recording(.fixedSizeBoth)
    }

    public func grayscale(_ amount: Double) -> ContactAccessButton {
        return recording(.grayscale(amount))
    }

    public func lineLimit(_ number: Int?) -> ContactAccessButton {
        return recording(.lineLimit(number))
    }

    public func statusBar(hidden: Bool) -> ContactAccessButton {
        return recording(.statusBar(hidden: hidden))
    }

}
