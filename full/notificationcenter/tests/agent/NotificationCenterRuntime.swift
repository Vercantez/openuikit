import Foundation
#if canImport(UIKit)
import UIKit
#endif
@_spi(OpenUIKitHost) import NotificationCenter

private final class DefaultWidget: NSObject, NCWidgetProviding {}

private final class RecordingWidget: NSObject, NCWidgetProviding {
    var lastMode: NCWidgetDisplayMode?
    var lastSize: CGSize?
    var updateResult: NCUpdateResult = .newData

    func widgetPerformUpdate(
        completionHandler: @escaping (NCUpdateResult) -> Void
    ) {
        completionHandler(updateResult)
    }

    func widgetActiveDisplayModeDidChange(
        _ activeDisplayMode: NCWidgetDisplayMode,
        withMaximumSize maxSize: CGSize
    ) {
        lastMode = activeDisplayMode
        lastSize = maxSize
    }

#if canImport(UIKit)
    func widgetMarginInsets(
        forProposedMarginInsets defaultMarginInsets: UIEdgeInsets
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: defaultMarginInsets.top + 1,
            left: defaultMarginInsets.left + 2,
            bottom: defaultMarginInsets.bottom + 3,
            right: defaultMarginInsets.right + 4
        )
    }
#endif
}

func exerciseUpdateResult() {
    precondition(NCUpdateResult.newData.rawValue == 0)
    precondition(NCUpdateResult.noData.rawValue == 1)
    precondition(NCUpdateResult.failed.rawValue == 2)
    precondition(NCUpdateResult(rawValue: 0) == .newData)
    precondition(NCUpdateResult(rawValue: 1) == .noData)
    precondition(NCUpdateResult(rawValue: 2) == .failed)
    precondition(NCUpdateResult(rawValue: 3) == nil)
    precondition(NCUpdateResult.newData != .failed)
    precondition(NCUpdateResult.noData == NCUpdateResult(rawValue: 1))
    precondition(NCUpdateResult.newData.hashValue == NCUpdateResult.newData.hashValue)
    var hasher = Hasher()
    NCUpdateResult.failed.hash(into: &hasher)
    _ = hasher.finalize()
    let asSet: Set<NCUpdateResult> = [.newData, .noData, .failed]
    precondition(asSet.count == 3)
}

func exerciseDisplayMode() {
    precondition(NCWidgetDisplayMode.compact.rawValue == 0)
    precondition(NCWidgetDisplayMode.expanded.rawValue == 1)
    precondition(NCWidgetDisplayMode(rawValue: 0) == .compact)
    precondition(NCWidgetDisplayMode(rawValue: 1) == .expanded)
    precondition(NCWidgetDisplayMode(rawValue: -1) == nil)
    precondition(NCWidgetDisplayMode.compact != .expanded)
    precondition(NCWidgetDisplayMode.compact.hashValue == NCWidgetDisplayMode.compact.hashValue)
    var hasher = Hasher()
    NCWidgetDisplayMode.expanded.hash(into: &hasher)
    _ = hasher.finalize()
    let asSet: Set<NCWidgetDisplayMode> = [.compact, .expanded]
    precondition(asSet.count == 2)
}

func exerciseWidgetProviding() async {
    let defaults = DefaultWidget()
    var defaultResult: NCUpdateResult?
    defaults.widgetPerformUpdate { defaultResult = $0 }
    precondition(defaultResult == .noData)
    defaults.widgetActiveDisplayModeDidChange(
        .expanded,
        withMaximumSize: CGSize(width: 10, height: 20)
    )

    let recording = RecordingWidget()
    var recorded: NCUpdateResult?
    recording.widgetPerformUpdate { recorded = $0 }
    precondition(recorded == .newData)
    recording.widgetActiveDisplayModeDidChange(
        .expanded,
        withMaximumSize: CGSize(width: 320, height: 200)
    )
    precondition(recording.lastMode == .expanded)
    precondition(recording.lastSize?.width == 320)
    precondition(recording.lastSize?.height == 200)

#if canImport(UIKit)
    let passed = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    let returned: UIKit.UIEdgeInsets = defaults.widgetMarginInsets(
        forProposedMarginInsets: passed
    )
    precondition(returned == passed)
    let adjusted: UIKit.UIEdgeInsets = recording.widgetMarginInsets(
        forProposedMarginInsets: UIEdgeInsets(top: 5, left: 6, bottom: 7, right: 8)
    )
    precondition(adjusted.top == 6)
    precondition(adjusted.left == 8)
    precondition(adjusted.bottom == 10)
    precondition(adjusted.right == 12)
#endif

    let asyncResult = await recording.widgetPerformUpdate()
    precondition(asyncResult == .newData)
    let asyncDefault = await defaults.widgetPerformUpdate()
    precondition(asyncDefault == .noData)
}

func exerciseWidgetController() {
    let controller = NCWidgetController.widgetController()
    controller.resetPortableContentFlags()
    precondition(NCWidgetController.systemWidgetHostAvailable == false)
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.widget"
        ) == nil
    )
    controller.setHasContent(
        true,
        forWidgetWithBundleIdentifier: "org.openuikit.widget"
    )
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.widget"
        ) == true
    )
    let other = NCWidgetController()
    other.setHasContent(
        false,
        forWidgetWithBundleIdentifier: "org.openuikit.widget"
    )
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.widget"
        ) == false
    )
    other.setHasContent(
        true,
        forWidgetWithBundleIdentifier: "org.openuikit.empty"
    )
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.empty"
        ) == true
    )
    controller.resetPortableContentFlags()
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.widget"
        ) == nil
    )
}

#if canImport(UIKit) && NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT
func exerciseExtensionContext() {
    let context: Foundation.NSExtensionContext = NSExtensionContext()
    precondition(context.widgetLargestAvailableDisplayMode == .compact)
    precondition(context.widgetActiveDisplayMode == .compact)
    precondition(context.widgetMaximumSize(for: .compact) == .zero)
    precondition(context.widgetMaximumSize(for: .expanded) == .zero)

    context.widgetLargestAvailableDisplayMode = .expanded
    precondition(context.widgetLargestAvailableDisplayMode == .expanded)
    precondition(context.widgetActiveDisplayMode == .compact)

    context.setPortableActiveDisplayMode(.expanded)
    precondition(context.widgetActiveDisplayMode == .expanded)

    let compactSize = CGSize(width: 320, height: 110)
    let expandedSize = CGSize(width: 320, height: 300)
    context.setPortableWidgetMaximumSize(compactSize, for: .compact)
    context.setPortableWidgetMaximumSize(expandedSize, for: .expanded)
    precondition(context.widgetMaximumSize(for: .compact) == compactSize)
    precondition(context.widgetMaximumSize(for: .expanded) == expandedSize)

    let other: Foundation.NSExtensionContext = NSExtensionContext()
    precondition(other.widgetLargestAvailableDisplayMode == .compact)
    precondition(other.widgetMaximumSize(for: .compact) == .zero)
}
#endif

#if canImport(UIKit)
func exerciseVibrancy() {
    let notification: UIKit.UIVibrancyEffect = .notificationCenter()
    let primary: UIKit.UIVibrancyEffect = .widgetPrimary()
    let secondary: UIKit.UIVibrancyEffect = .widgetSecondary()
    let styled: UIKit.UIVibrancyEffect = .widgetEffect(forVibrancyStyle: .label)
    let fill: UIKit.UIVibrancyEffect = .widgetEffect(forVibrancyStyle: .fill)
    precondition(notification !== primary)
    precondition(primary !== secondary)
    precondition(styled !== fill)
    precondition(UIVibrancyEffectStyle.label.rawValue == 0)
    precondition(UIVibrancyEffectStyle.separator.rawValue == 7)
}
#endif

exerciseUpdateResult()
exerciseDisplayMode()
await exerciseWidgetProviding()
exerciseWidgetController()
#if canImport(UIKit)
exerciseVibrancy()
#endif
#if canImport(UIKit) && NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT
exerciseExtensionContext()
#endif
print("NOTIFICATIONCENTER_AGENT_RUNTIME_OK")
#if !canImport(UIKit)
print("NOTIFICATIONCENTER_STANDALONE_DYLIB_ONLY")
#endif
