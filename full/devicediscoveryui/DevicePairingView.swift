import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Network)
import Network
#endif

/// SwiftUI control that makes the device discoverable to local peers on Darwin.
///
/// Graph docs: the `label` describes requesting advertising when it is
/// supported; the `fallback` describes the alternative when advertising is
/// not supported. Linux `DDDevicePairingViewController.isSupported` is
/// `false`, so `body` is the stored fallback and never presents an advertiser.
///
/// https://developer.apple.com/documentation/devicediscoveryui/devicepairingview
public struct DevicePairingView<Label: View, Fallback: View>: View {
    public typealias Body = Fallback

    let linuxAccess: DDDevicePairingAccess
    let linuxLabel: Label
    let linuxFallback: Fallback
    private let listenerProvider: any ListenerProvider

    /// Creates a pairing view. Darwin shows an advertiser when the listener
    /// is supported; Linux always stores `label` / `fallback` and renders
    /// `fallback`.
    public init(
        _ listenerProvider: any ListenerProvider,
        access: DDDevicePairingAccess = .default,
        @ViewBuilder label: () -> Label,
        @ViewBuilder fallback: () -> Fallback
    ) {
        self.listenerProvider = listenerProvider
        self.linuxAccess = access
        self.linuxLabel = label()
        self.linuxFallback = fallback()
    }

    public var body: Fallback {
        _ = listenerProvider
        return linuxFallback
    }
}
