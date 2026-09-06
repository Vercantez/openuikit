import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Security)
import Security
#endif

/// Linux identity wrapper returned by `View.certificateSheet`.
/// `body` is the unmodified content. Darwin would present a certificate
/// sheet when `trust` is non-nil; Linux never presents and never writes
/// the binding back to `nil`. Not part of Apple's public census.
public struct SecurityUICertificateSheetView<Content: View>: View {
    public let content: Content
    public let title: String?
    public let message: String?
    public let help: URL?
    let trustBinding: Binding<SecTrust?>
    let linuxDidPresent: Bool

    public var body: Content { content }

    public var linuxHasTrust: Bool { trustBinding.wrappedValue != nil }
}

extension View {
    /// Displays a certificate sheet using the provided certificate trust.
    ///
    /// Darwin (from the pinned symbol-graph doc comment):
    /// - `trust`: binding to a `SecTrust` created with
    ///   `SecTrustCreateWithCertificates`; non-nil determines whether to
    ///   present the sheet.
    /// - `title` / `message` / `help`: optional chrome. Nil uses Apple
    ///   defaults, which are unobserved here and stored as nil.
    ///
    /// Linux applies an identity wrapper, does not present, does not
    /// evaluate the trust, and does not mutate the binding.
    @MainActor
    @preconcurrency
    public func certificateSheet(
        trust: Binding<SecTrust?>,
        title: String? = nil,
        message: String? = nil,
        help: URL? = nil
    ) -> SecurityUICertificateSheetView<Self> {
        SecurityUICertificateSheetView(
            content: self,
            title: title,
            message: message,
            help: help,
            trustBinding: trust,
            linuxDidPresent: false
        )
    }
}
