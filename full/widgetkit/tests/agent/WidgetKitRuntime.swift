@_spi(OpenUIKitHost) import WidgetKit
import Foundation

/// Schema-v1-style local runtime probe. The sealed schema-v2 gate compiles
/// `*Tests.swift` plus generated load-smoke instead of this file.
func widgetKitRuntimeProbe() {
    precondition(WidgetFamily.systemSmall.rawValue == 0)
    precondition(TimelineReloadPolicy.atEnd != TimelineReloadPolicy.never)
    let center = WidgetCenter()
    center.reloadAllTimelines()
    let drained = center.drainReloadRequests()
    precondition(drained.count == 1)
    _ = AccessoryWidgetBackground()
    _ = ControlCenter.shared
}
