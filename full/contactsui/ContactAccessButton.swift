#if canImport(SwiftUI)
import SwiftUI

/// Fail-closed Limited Contacts Access control. Compiled only when SwiftUI is
/// importable so `ContactAccessButton` is a real `SwiftUI.View`. Query strings
/// and ignore lists are preserved. The body never presents Apple Limited Access
/// UI and never invents granted identifiers.
@MainActor
@preconcurrency
public struct ContactAccessButton: View {
    public let queryString: String
    public let ignoredEmails: Set<String>?
    public let ignoredPhoneNumbers: Set<String>?
    public let approvalCallback: (([String]) -> Void)?

    public var style: Style
    public var caption: Caption

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
    }

    public var body: some View {
        EmptyView()
    }

    @_spi(OpenUIKitHost)
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

extension View {
    @MainActor
    @preconcurrency
    public func contactAccessButtonStyle(
        _ style: ContactAccessButton.Style
    ) -> some View {
        _ = style
        return self
    }

    @MainActor
    @preconcurrency
    public func contactAccessButtonCaption(
        _ caption: ContactAccessButton.Caption
    ) -> some View {
        _ = caption
        return self
    }

    @MainActor
    @preconcurrency
    public func contactAccessPicker(
        isPresented: Binding<Bool>,
        completionHandler: @escaping ([String]) -> Void = { _ in }
    ) -> some View {
        _ = isPresented
        _ = completionHandler
        return self
    }
}

extension ContactAccessButton {
    @MainActor
    @preconcurrency
    public func contactAccessButtonStyle(_ style: Style) -> some View {
        var copy = self
        copy.style = style
        return copy
    }

    @MainActor
    @preconcurrency
    public func contactAccessButtonCaption(_ caption: Caption) -> some View {
        var copy = self
        copy.caption = caption
        return copy
    }

    @MainActor
    @preconcurrency
    public func contactAccessPicker(
        isPresented: Binding<Bool>,
        completionHandler: @escaping ([String]) -> Void = { _ in }
    ) -> some View {
        _ = isPresented
        _ = completionHandler
        return self
    }
}
#endif
