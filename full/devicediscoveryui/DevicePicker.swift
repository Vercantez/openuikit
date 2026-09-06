import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Network)
import Network
#endif

/// SwiftUI control that lets the user pick a local device on Darwin.
///
/// Symmetric to `DevicePairingView`: when picking is unsupported, Darwin
/// shows `fallback`. Linux `DDDevicePickerViewController.isSupported` is
/// `false`, so `body` is the stored fallback. `onSelect` is retained and is
/// never invoked from public APIs (no fabricated peer).
///
/// https://developer.apple.com/documentation/devicediscoveryui/devicepicker
public struct DevicePicker<Label: View, Fallback: View>: View {
    public typealias Body = Fallback

    let linuxAccess: DDDevicePairingAccess
    let linuxLabel: Label
    let linuxFallback: Fallback
    let linuxHasParametersClosure: Bool
    private let onSelect: (Any) -> Void
    private let onSelectBox: Box

    private final class Box: @unchecked Sendable {
        var count = 0
    }

    /// Creates a device picker. Linux stores the closures and renders
    /// `fallback`. The `parameters` closure is retained and not used to
    /// start a browser.
    public init<Provider: BrowserProvider>(
        _ browserProvider: Provider,
        access: DDDevicePairingAccess = .default,
        onSelect: @escaping (Provider.Endpoint) -> Void,
        @ViewBuilder label: () -> Label,
        @ViewBuilder fallback: () -> Fallback,
        parameters: (() -> NWParameters)? = nil
    ) {
        _ = browserProvider
        self.linuxAccess = access
        self.linuxLabel = label()
        self.linuxFallback = fallback()
        self.linuxHasParametersClosure = parameters != nil
        self.onSelectBox = Box()
        self.onSelect = { value in
            if let endpoint = value as? Provider.Endpoint {
                onSelect(endpoint)
            }
        }
    }

    public var body: Fallback {
        linuxFallback
    }

    var linuxOnSelectCount: Int { onSelectBox.count }

    func linuxInvokeStoredOnSelect<Endpoint>(_ endpoint: Endpoint) {
        onSelectBox.count += 1
        onSelect(endpoint)
    }
}
