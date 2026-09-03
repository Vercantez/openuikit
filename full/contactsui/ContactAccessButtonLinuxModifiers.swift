#if !canImport(SwiftUI)
import Foundation

// Isolated Linux fluent no-ops on ContactAccessButton. These are not
// SwiftUI.View protocol extensions: they return ContactAccessButton, record
// a host tag, and invent no layout, accessibility, or presentation behavior.
// When SwiftUI is imported, this file is compiled out so Darwin-shaped
// View modifiers can come from the real module.

@MainActor
extension ContactAccessButton {
    /// Linux-local fluent no-op. Darwin `ContactAccessButton.frame()` is a SwiftUI.View modifier.
    @discardableResult
    public func frame() -> ContactAccessButton {
        return applyingLinuxModifier("frame()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.hidden()` is a SwiftUI.View modifier.
    @discardableResult
    public func hidden() -> ContactAccessButton {
        return applyingLinuxModifier("hidden()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.fixedSize()` is a SwiftUI.View modifier.
    @discardableResult
    public func fixedSize() -> ContactAccessButton {
        return applyingLinuxModifier("fixedSize()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.unredacted()` is a SwiftUI.View modifier.
    @discardableResult
    public func unredacted() -> ContactAccessButton {
        return applyingLinuxModifier("unredacted()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.colorInvert()` is a SwiftUI.View modifier.
    @discardableResult
    public func colorInvert() -> ContactAccessButton {
        return applyingLinuxModifier("colorInvert()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.scaledToFit()` is a SwiftUI.View modifier.
    @discardableResult
    public func scaledToFit() -> ContactAccessButton {
        return applyingLinuxModifier("scaledToFit()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.labelsHidden()` is a SwiftUI.View modifier.
    @discardableResult
    public func labelsHidden() -> ContactAccessButton {
        return applyingLinuxModifier("labelsHidden()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.scaledToFill()` is a SwiftUI.View modifier.
    @discardableResult
    public func scaledToFill() -> ContactAccessButton {
        return applyingLinuxModifier("scaledToFill()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.geometryGroup()` is a SwiftUI.View modifier.
    @discardableResult
    public func geometryGroup() -> ContactAccessButton {
        return applyingLinuxModifier("geometryGroup()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.monospacedDigit()` is a SwiftUI.View modifier.
    @discardableResult
    public func monospacedDigit() -> ContactAccessButton {
        return applyingLinuxModifier("monospacedDigit()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.compositingGroup()` is a SwiftUI.View modifier.
    @discardableResult
    public func compositingGroup() -> ContactAccessButton {
        return applyingLinuxModifier("compositingGroup()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.luminanceToAlpha()` is a SwiftUI.View modifier.
    @discardableResult
    public func luminanceToAlpha() -> ContactAccessButton {
        return applyingLinuxModifier("luminanceToAlpha()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.allowsWindowActivationEvents()` is a SwiftUI.View modifier.
    @discardableResult
    public func allowsWindowActivationEvents() -> ContactAccessButton {
        return applyingLinuxModifier("allowsWindowActivationEvents()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.accessibilityShowsLargeContentViewer()` is a SwiftUI.View modifier.
    @discardableResult
    public func accessibilityShowsLargeContentViewer() -> ContactAccessButton {
        return applyingLinuxModifier("accessibilityShowsLargeContentViewer()")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.badge(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func badge(_ count: Int) -> ContactAccessButton {
        _ = count
        return applyingLinuxModifier("badge(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.statusBar(hidden:)` is a SwiftUI.View modifier.
    @discardableResult
    public func statusBar(hidden: Bool) -> ContactAccessButton {
        _ = hidden
        return applyingLinuxModifier("statusBar(hidden:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.zIndex(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func zIndex(_ value: Double) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("zIndex(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.lineLimit(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func lineLimit(_ number: Int?) -> ContactAccessButton {
        _ = number
        return applyingLinuxModifier("lineLimit(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.contrast(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func contrast(_ amount: Double) -> ContactAccessButton {
        _ = amount
        return applyingLinuxModifier("contrast(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.disabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func disabled(_ disabled: Bool) -> ContactAccessButton {
        _ = disabled
        return applyingLinuxModifier("disabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.opacity(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func opacity(_ opacity: Double) -> ContactAccessButton {
        _ = opacity
        return applyingLinuxModifier("opacity(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.padding(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func padding(_ length: CGFloat) -> ContactAccessButton {
        _ = length
        return applyingLinuxModifier("padding(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.grayscale(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func grayscale(_ amount: Double) -> ContactAccessButton {
        _ = amount
        return applyingLinuxModifier("grayscale(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.kerning(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func kerning(_ kerning: CGFloat) -> ContactAccessButton {
        _ = kerning
        return applyingLinuxModifier("kerning(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.brightness(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func brightness(_ amount: Double) -> ContactAccessButton {
        _ = amount
        return applyingLinuxModifier("brightness(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.saturation(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func saturation(_ amount: Double) -> ContactAccessButton {
        _ = amount
        return applyingLinuxModifier("saturation(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.bold(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func bold(_ isActive: Bool = true) -> ContactAccessButton {
        _ = isActive
        return applyingLinuxModifier("bold(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.gridCellColumns(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func gridCellColumns(_ count: Int) -> ContactAccessButton {
        _ = count
        return applyingLinuxModifier("gridCellColumns(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.tracking(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func tracking(_ tracking: CGFloat) -> ContactAccessButton {
        _ = tracking
        return applyingLinuxModifier("tracking(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.allowsTightening(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func allowsTightening(_ flag: Bool) -> ContactAccessButton {
        _ = flag
        return applyingLinuxModifier("allowsTightening(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.navigationDocument(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func navigationDocument(_ url: URL) -> ContactAccessButton {
        _ = url
        return applyingLinuxModifier("navigationDocument(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.italic(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func italic(_ isActive: Bool = true) -> ContactAccessButton {
        _ = isActive
        return applyingLinuxModifier("italic(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.layoutPriority(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func layoutPriority(_ value: Double) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("layoutPriority(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.moveDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func moveDisabled(_ isDisabled: Bool) -> ContactAccessButton {
        _ = isDisabled
        return applyingLinuxModifier("moveDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.scrollDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func scrollDisabled(_ disabled: Bool) -> ContactAccessButton {
        _ = disabled
        return applyingLinuxModifier("scrollDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.allowsHitTesting(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func allowsHitTesting(_ enabled: Bool) -> ContactAccessButton {
        _ = enabled
        return applyingLinuxModifier("allowsHitTesting(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.clipped(antialiased:)` is a SwiftUI.View modifier.
    @discardableResult
    public func clipped(antialiased: Bool = false) -> ContactAccessButton {
        _ = antialiased
        return applyingLinuxModifier("clipped(antialiased:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.deleteDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func deleteDisabled(_ isDisabled: Bool) -> ContactAccessButton {
        _ = isDisabled
        return applyingLinuxModifier("deleteDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.safeAreaPadding(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func safeAreaPadding(_ length: CGFloat) -> ContactAccessButton {
        _ = length
        return applyingLinuxModifier("safeAreaPadding(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.lineSpacing(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func lineSpacing(_ lineSpacing: CGFloat) -> ContactAccessButton {
        _ = lineSpacing
        return applyingLinuxModifier("lineSpacing(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.listRowSpacing(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func listRowSpacing(_ spacing: CGFloat?) -> ContactAccessButton {
        _ = spacing
        return applyingLinuxModifier("listRowSpacing(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.monospaced(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func monospaced(_ isActive: Bool = true) -> ContactAccessButton {
        _ = isActive
        return applyingLinuxModifier("monospaced(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.navigationBarHidden(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func navigationBarHidden(_ hidden: Bool) -> ContactAccessButton {
        _ = hidden
        return applyingLinuxModifier("navigationBarHidden(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.lineLimit(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func lineLimit(_ limit: ClosedRange<Int>) -> ContactAccessButton {
        _ = limit
        return applyingLinuxModifier("lineLimit(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.previewDisplayName(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func previewDisplayName(_ value: String?) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("previewDisplayName(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.speechAdjustedPitch(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func speechAdjustedPitch(_ value: Double) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("speechAdjustedPitch(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.focusable(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func focusable(_ isFocusable: Bool = true) -> ContactAccessButton {
        _ = isFocusable
        return applyingLinuxModifier("focusable(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.minimumScaleFactor(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func minimumScaleFactor(_ factor: CGFloat) -> ContactAccessButton {
        _ = factor
        return applyingLinuxModifier("minimumScaleFactor(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.scrollIndicatorsFlash(onAppear:)` is a SwiftUI.View modifier.
    @discardableResult
    public func scrollIndicatorsFlash(onAppear: Bool) -> ContactAccessButton {
        _ = onAppear
        return applyingLinuxModifier("scrollIndicatorsFlash(onAppear:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.inspectorColumnWidth(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func inspectorColumnWidth(_ width: CGFloat) -> ContactAccessButton {
        _ = width
        return applyingLinuxModifier("inspectorColumnWidth(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.listSectionSpacing(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func listSectionSpacing(_ spacing: CGFloat) -> ContactAccessButton {
        _ = spacing
        return applyingLinuxModifier("listSectionSpacing(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.searchCompletion(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func searchCompletion(_ completion: String) -> ContactAccessButton {
        _ = completion
        return applyingLinuxModifier("searchCompletion(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.statusBarHidden(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func statusBarHidden(_ hidden: Bool = true) -> ContactAccessButton {
        _ = hidden
        return applyingLinuxModifier("statusBarHidden(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.submitScope(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func submitScope(_ isBlocking: Bool = true) -> ContactAccessButton {
        _ = isBlocking
        return applyingLinuxModifier("submitScope(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.disableAutocorrection(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func disableAutocorrection(_ disable: Bool?) -> ContactAccessButton {
        _ = disable
        return applyingLinuxModifier("disableAutocorrection(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.fileDialogCustomizationID(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func fileDialogCustomizationID(_ id: String) -> ContactAccessButton {
        _ = id
        return applyingLinuxModifier("fileDialogCustomizationID(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.findDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func findDisabled(_ isDisabled: Bool = true) -> ContactAccessButton {
        _ = isDisabled
        return applyingLinuxModifier("findDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.defaultAppStorage(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func defaultAppStorage(_ store: UserDefaults) -> ContactAccessButton {
        _ = store
        return applyingLinuxModifier("defaultAppStorage(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.labelReservedIconWidth(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func labelReservedIconWidth(_ value: CGFloat) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("labelReservedIconWidth(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.baselineOffset(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func baselineOffset(_ baselineOffset: CGFloat) -> ContactAccessButton {
        _ = baselineOffset
        return applyingLinuxModifier("baselineOffset(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.labelIconToTitleSpacing(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func labelIconToTitleSpacing(_ value: CGFloat) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("labelIconToTitleSpacing(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.privacySensitive(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func privacySensitive(_ sensitive: Bool = true) -> ContactAccessButton {
        _ = sensitive
        return applyingLinuxModifier("privacySensitive(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.replaceDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func replaceDisabled(_ isDisabled: Bool = true) -> ContactAccessButton {
        _ = isDisabled
        return applyingLinuxModifier("replaceDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.scrollTargetLayout(isEnabled:)` is a SwiftUI.View modifier.
    @discardableResult
    public func scrollTargetLayout(isEnabled: Bool = true) -> ContactAccessButton {
        _ = isEnabled
        return applyingLinuxModifier("scrollTargetLayout(isEnabled:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.scrollClipDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func scrollClipDisabled(_ disabled: Bool = true) -> ContactAccessButton {
        _ = disabled
        return applyingLinuxModifier("scrollClipDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.allowsWindowActivationEvents(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func allowsWindowActivationEvents(_ value: Bool?) -> ContactAccessButton {
        _ = value
        return applyingLinuxModifier("allowsWindowActivationEvents(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.focusEffectDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func focusEffectDisabled(_ disabled: Bool = true) -> ContactAccessButton {
        _ = disabled
        return applyingLinuxModifier("focusEffectDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.hoverEffectDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func hoverEffectDisabled(_ disabled: Bool = true) -> ContactAccessButton {
        _ = disabled
        return applyingLinuxModifier("hoverEffectDisabled(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.renameAction(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func renameAction(_ action: @escaping () -> Void) -> ContactAccessButton {
        _ = action
        return applyingLinuxModifier("renameAction(_:)")
    }

    /// Linux-local fluent no-op. Darwin `ContactAccessButton.selectionDisabled(_:)` is a SwiftUI.View modifier.
    @discardableResult
    public func selectionDisabled(_ isDisabled: Bool = true) -> ContactAccessButton {
        _ = isDisabled
        return applyingLinuxModifier("selectionDisabled(_:)")
    }
}
#endif
