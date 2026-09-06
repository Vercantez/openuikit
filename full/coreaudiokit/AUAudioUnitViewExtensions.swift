import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Per-instance selected view configuration. Isolated Linux has no AU custom
/// view process, so `select(_:)` only records the host request.
enum AUAudioUnitViewSelection {
    private static var selectedByUnit: [ObjectIdentifier: AUAudioUnitViewConfiguration] = [:]

    static func store(_ unit: AUAudioUnit, _ configuration: AUAudioUnitViewConfiguration) {
        selectedByUnit[ObjectIdentifier(unit)] = configuration
    }

    static func selected(for unit: AUAudioUnit) -> AUAudioUnitViewConfiguration? {
        selectedByUnit[ObjectIdentifier(unit)]
    }
}

extension AUAudioUnit {
    /// Darwin loads an Audio Unit custom view and delivers a controller.
    /// Linux has no AU view service: the handler runs synchronously with `nil`.
    /// Callback queue on Apple is unobserved (oracle).
    public func requestViewController(
        completionHandler: @escaping (UIViewController?) -> Void
    ) {
        completionHandler(nil)
    }

    /// Darwin chooses among the unit's supported sizes. Linux records the
    /// request and does not present chrome.
    public func select(_ viewConfiguration: AUAudioUnitViewConfiguration) {
        AUAudioUnitViewSelection.store(self, viewConfiguration)
    }

    /// Darwin returns indexes into `availableViewConfigurations` that the unit
    /// can host. Linux has no custom view, so the result is always empty.
    public func supportedViewConfigurations(
        _ availableViewConfigurations: [AUAudioUnitViewConfiguration]
    ) -> IndexSet {
        _ = availableViewConfigurations
        return IndexSet()
    }
}
