import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

#if !canImport(SwiftUI)
/// Token recorded by `ContactAccessButton.Style` when SwiftUI is absent.
/// This is not SwiftUI.Color and performs no catalog lookup.
public struct Color: Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
#endif

/// Fail-closed Limited Contacts Access control. Query strings and ignore lists
/// are preserved for a host renderer. Approval never invents Apple-granted
/// identifiers; a host may forward identifiers it already had authority to share.
@MainActor
public struct ContactAccessButton {
    public let queryString: String
    public let ignoredEmails: Set<String>?
    public let ignoredPhoneNumbers: Set<String>?
    public let approvalCallback: (([String]) -> Void)?

    public var style: Style
    public var caption: Caption
    public internal(set) var recordedModifiers: [RecordedModifier]

    public typealias Body = ContactAccessUnavailableView

    public var body: ContactAccessUnavailableView {
        ContactAccessUnavailableView()
    }

    public init(
        queryString query: String,
        ignoredEmails: Set<String>? = nil,
        ignoredPhoneNumbers: Set<String>? = nil,
        approvalCallback: (([String]) -> Void)? = nil
    ) {
        queryString = query
        self.ignoredEmails = ignoredEmails
        self.ignoredPhoneNumbers = ignoredPhoneNumbers
        self.approvalCallback = approvalCallback
        style = .automatic
        caption = .defaultText
        recordedModifiers = []
    }

    public func contactAccessButtonStyle(_ style: Style) -> ContactAccessButton {
        var copy = self
        copy.style = style
        return copy
    }

    public func contactAccessButtonCaption(_ caption: Caption) -> ContactAccessButton {
        var copy = self
        copy.caption = caption
        return copy
    }

    /// Source-compatible Limited Access picker hook. The completion always
    /// receives an empty array unless the host later calls
    /// `reportApproval(newlyGrantedIdentifiers:)`.
    public func contactAccessPicker(
        isPresented: Bool,
        completionHandler: @escaping ([String]) -> Void = { _ in }
    ) -> ContactAccessButton {
        var copy = self
        copy.recordedModifiers.append(.contactAccessPickerPresented(isPresented))
        _ = completionHandler as Any
        return copy
    }

    /// Host-facing approval finish. Identifiers must come from the host; this
    /// method never consults Apple Limited Contacts Access. Passing `[]`
    /// matches the documented empty result when authorization is not Limited.
    public func reportApproval(newlyGrantedIdentifiers identifiers: [String] = []) {
        approvalCallback?(identifiers)
    }

    public struct Style: Equatable, Sendable {
        public var imageTrailingEdgePadding: CGFloat?
        public var imageWidth: CGFloat?
        public var imageColor: Color?

        public static let automatic = Style()

        public init(
            imageTrailingEdgePadding: CGFloat? = nil,
            imageWidth: CGFloat? = nil,
            imageColor: Color? = nil
        ) {
            self.imageTrailingEdgePadding = imageTrailingEdgePadding
            self.imageWidth = imageWidth
            self.imageColor = imageColor
        }
    }

    public enum Caption: String, Equatable, Hashable, Sendable {
        case defaultText
        case email
        case phone
    }
}

/// Placeholder body. There is no Apple Limited Access UI on this host.
public struct ContactAccessUnavailableView: Equatable, Sendable {
    public let reason = "Apple Limited Contacts Access UI is unavailable"

    public init() {}
}
