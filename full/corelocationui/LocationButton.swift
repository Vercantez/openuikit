import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// SwiftUI location button that grants one-time location authorization on Darwin.
/// Linux stores the title and action, renders `EmptyView`, and never produces a
/// location. The action is retained so host tests can prove `init` stored it;
/// `CoreLocationUIHostControl.activate` does not invoke it.
///
/// https://developer.apple.com/documentation/corelocationui/locationbutton
public struct LocationButton: View {
    public typealias Body = EmptyView

    /// Title catalog matching the five Darwin `LocationButton.Title` statics.
    /// Equality is the stored `CLLocationButtonLabel` (no `.none` on this type).
    public struct Title: Hashable, Sendable {
        public let label: CLLocationButtonLabel

        public static let currentLocation = Title(label: .currentLocation)
        public static let sendCurrentLocation = Title(label: .sendCurrentLocation)
        public static let sendMyCurrentLocation = Title(label: .sendMyCurrentLocation)
        public static let shareCurrentLocation = Title(label: .shareCurrentLocation)
        public static let shareMyCurrentLocation = Title(label: .shareMyCurrentLocation)
    }

    private let title: Title?
    private let action: () -> Void
    private let activationAttempts: Box

    private final class Box: @unchecked Sendable {
        var count = 0
    }

    /// Darwin default title is `.currentLocation`. Passing `nil` stores `nil`
    /// (Apple's nil-title rendering is unobserved).
    public init(_ title: Title? = .currentLocation, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.activationAttempts = Box()
    }

    public var body: EmptyView {
        EmptyView()
    }

    var linuxTitle: Title? { title }

    var linuxActivationAttempts: Int { activationAttempts.count }

    func linuxActivateFailClosed() -> Result<Void, CoreLocationUIUnavailable> {
        activationAttempts.count += 1
        return .failure(.linuxHost(operation: "LocationButton.oneTimeAuthorization"))
    }

    func linuxInvokeStoredAction() {
        action()
    }
}
