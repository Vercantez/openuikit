import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Contact access button. On Darwin this is a SwiftUI `View` that can present
/// a limited-access grant sheet. Isolated Linux keeps the Foundation-typed
/// stored configuration, conforms to the local `View` lookalike, and never
/// presents a grant sheet. `approvalCallback` is not invoked unless the host
/// SPI explicitly delivers the fail-closed empty identifier list.
@MainActor
@preconcurrency
public struct ContactAccessButton: @MainActor View {
    public var queryString: String
    public var ignoredEmails: Set<String>?
    public var ignoredPhoneNumbers: Set<String>?
    public var approvalCallback: (([String]) -> Void)?

    public var linuxCaption: Caption
    public var linuxStyle: Style
    var linuxModifiers: [String]

    public var body: some View {
        EmptyView()
    }

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
    /// because the Darwin overlay returns `some View`.
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

    /// Fail-closed limited-access picker. If `isPresented` is true, it is set
    /// back to false and `completionHandler` receives `[]`. No grant sheet.
    @discardableResult
    public func contactAccessPicker(
        isPresented: Binding<Bool>,
        completionHandler: @escaping ([String]) -> Void = { _ in }
    ) -> ContactAccessButton {
        if isPresented.wrappedValue {
            isPresented.wrappedValue = false
            completionHandler([])
        }
        return applyingLinuxModifier("contactAccessPicker(isPresented:completionHandler:)")
    }

    public enum Caption: String, Hashable, Sendable {
        case defaultText
        case email
        case phone
    }

    public struct Style: Equatable, Hashable, Sendable {
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
}

extension View {
    /// ContactsUI overlay on `View`. Isolated Linux returns `Self` without
    /// presenting a grant sheet. If `isPresented` is true, it is cleared and
    /// `completionHandler` receives `[]`.
    @MainActor
    @discardableResult
    public func contactAccessPicker(
        isPresented: Binding<Bool>,
        completionHandler: @escaping ([String]) -> Void = { _ in }
    ) -> Self {
        if isPresented.wrappedValue {
            isPresented.wrappedValue = false
            completionHandler([])
        }
        return self
    }

    @MainActor
    @discardableResult
    public func contactAccessButtonStyle(_ style: ContactAccessButton.Style) -> Self {
        _ = style
        return self
    }

    @MainActor
    @discardableResult
    public func contactAccessButtonCaption(_ caption: ContactAccessButton.Caption) -> Self {
        _ = caption
        return self
    }
}
