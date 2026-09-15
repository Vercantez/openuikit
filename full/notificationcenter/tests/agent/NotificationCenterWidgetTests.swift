import Foundation
@_spi(OpenUIKitHost) import NotificationCenter

private final class NCWave4DefaultWidget: NSObject, NCWidgetProviding {}

private final class NCWave4RecordingWidget: NSObject, NCWidgetProviding {
    var lastMode: NCWidgetDisplayMode?
    var lastWidth: CGFloat?
    var lastHeight: CGFloat?
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
        lastWidth = maxSize.width
        lastHeight = maxSize.height
    }
}

func testNCWidgetProvidingDefaults() {
    let widget: any NCWidgetProviding = NCWave4DefaultWidget()
    var defaultResult: NCUpdateResult?
    widget.widgetPerformUpdate { defaultResult = $0 }
    precondition(defaultResult == .noData)
    widget.widgetActiveDisplayModeDidChange(
        .compact,
        withMaximumSize: CGSize(width: 100, height: 50)
    )

    let recording = NCWave4RecordingWidget()
    let asProvided: any NCWidgetProviding = recording
    var recorded: NCUpdateResult?
    asProvided.widgetPerformUpdate { recorded = $0 }
    precondition(recorded == .newData)
    recording.widgetActiveDisplayModeDidChange(
        .expanded,
        withMaximumSize: CGSize(width: 320, height: 200)
    )
    precondition(recording.lastMode == .expanded)
    precondition(recording.lastWidth == 320)
    precondition(recording.lastHeight == 200)
    recording.updateResult = .failed
    var failed: NCUpdateResult?
    recording.widgetPerformUpdate { failed = $0 }
    precondition(failed == .failed)
}

func testNCWidgetControllerHasContent() {
    let controller = NCWidgetController.widgetController()
    controller.resetPortableContentFlags()
    precondition(NCWidgetController.systemWidgetHostAvailable == false)
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.nc-wave4"
        ) == nil
    )
    controller.setHasContent(
        true,
        forWidgetWithBundleIdentifier: "org.openuikit.nc-wave4"
    )
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.nc-wave4"
        ) == true
    )
    let other = NCWidgetController()
    other.setHasContent(
        false,
        forWidgetWithBundleIdentifier: "org.openuikit.nc-wave4"
    )
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.nc-wave4"
        ) == false
    )
    controller.resetPortableContentFlags()
    precondition(
        controller.portableHasContent(
            forWidgetWithBundleIdentifier: "org.openuikit.nc-wave4"
        ) == nil
    )
}
