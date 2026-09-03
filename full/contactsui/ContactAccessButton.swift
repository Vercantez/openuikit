import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Contact access button. On Darwin this is a SwiftUI `View`. Isolated Linux
/// keeps the Foundation-typed stored configuration and never presents a
/// contact-grant sheet. `approvalCallback` is not invoked unless the host SPI
/// explicitly delivers the fail-closed empty identifier list.
@MainActor
@preconcurrency
public struct ContactAccessButton {
    public var queryString: String
    public var ignoredEmails: Set<String>?
    public var ignoredPhoneNumbers: Set<String>?
    public var approvalCallback: (([String]) -> Void)?

    public var linuxCaption: Caption
    public var linuxStyle: Style
    var linuxModifiers: [String]

    @MainActor
    @preconcurrency
    public init(
        queryString query: String,
        ignoredEmails: Set<String>? = nil,
        ignoredPhoneNumbers: Set<String>? = nil,
        approvalCallback: (([String]) -> Void)? = nil
    ) {
        self.queryString = query
        self.ignoredEmails = ignoredEmails
        self.ignoredPhoneNumbers = ignoredPhoneNumbers
        self.approvalCallback = approvalCallback
        self.linuxCaption = .defaultText
        self.linuxStyle = .automatic
        self.linuxModifiers = []
    }

    func applyingLinuxModifier(_ tag: String) -> ContactAccessButton {
        var copy = self
        copy.linuxModifiers.append(tag)
        return copy
    }

    func invokeFailClosedApproval() -> [String] {
        let granted: [String] = []
        approvalCallback?(granted)
        return granted
    }

    /// ContactsUI-authored caption modifier. Returns `Self` on isolated Linux
    /// because `SwiftUI.View` is not imported. The Darwin overlay returns
    /// `some View`.
    @discardableResult
    public func contactAccessButtonCaption(_ caption: Caption) -> ContactAccessButton {
        var copy = self
        copy.linuxCaption = caption
        copy.linuxModifiers.append("contactAccessButtonCaption(_:)")
        return copy
    }

    /// ContactsUI-authored style modifier. Returns `Self` on isolated Linux.
    @discardableResult
    public func contactAccessButtonStyle(_ style: Style) -> ContactAccessButton {
        var copy = self
        copy.linuxStyle = style
        copy.linuxModifiers.append("contactAccessButtonStyle(_:)")
        return copy
    }

    public enum Caption: String, Hashable, Sendable {
        case defaultText
        case email
        case phone
    }

    public struct Style: Equatable, Hashable, Sendable {
        public var imageTrailingEdgePadding: CGFloat?
        public var imageWidth: CGFloat?

        public static let automatic = Style()

        public init(
            imageTrailingEdgePadding: CGFloat? = nil,
            imageWidth: CGFloat? = nil
        ) {
            self.imageTrailingEdgePadding = imageTrailingEdgePadding
            self.imageWidth = imageWidth
        }

        #if canImport(SwiftUI)
        public var imageColor: Color?

        public init(
            imageTrailingEdgePadding: CGFloat? = nil,
            imageWidth: CGFloat? = nil,
            imageColor: Color? = nil
        ) {
            self.imageTrailingEdgePadding = imageTrailingEdgePadding
            self.imageWidth = imageWidth
            self.imageColor = imageColor
        }
        #endif
    }
}

#if canImport(SwiftUI)
extension ContactAccessButton: View {
    public var body: some View {
        EmptyView()
    }
}
#endif
