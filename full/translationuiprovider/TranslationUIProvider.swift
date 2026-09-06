/// Portable Linux starting point for Apple's public `TranslationUIProvider` module.
///
/// Context value types (`inputText`, `allowsReplacement`) and the documented
/// `finish(translation:)` replacement rule are real and process-local. Linux
/// has no Translation UI extension host, XPC session, or system translation
/// sheet: `expandSheet()` records the request and never presents UI,
/// `finish(translation:)` never closes an Apple sheet, and
/// `TranslationUIProviderHostControl.presentTranslationProviderUI()` always
/// throws `TranslationUIProviderUnavailable.linuxHost`.
///
/// Apple annotates extension types `@MainActor @preconcurrency`. The isolated
/// Linux host has no SwiftUI/ExtensionKit run loop, so Linux types are usable
/// from synchronous tests. TBD-only SPI (`TranslationProviderContextImp`,
/// `TranslationProviderSceneID`, `TranslationProviderRemoteUIExtensionPointIdentifier`,
/// `translate(text:replacementAllowed:)`) is not published; it is not in the
/// 16-ID public surface.

import Foundation
import Observation

// MARK: - Fail-closed host errors

/// Linux-only result when a host asks to present Apple Translation UI.
/// Not an Apple NSError domain or extension error code.
public enum TranslationUIProviderUnavailable: Error, Equatable, Hashable, Sendable {
    case linuxHost(operation: String)
}

extension TranslationUIProviderUnavailable: CustomNSError {
    public static var errorDomain: String { "TranslationUIProvider.Linux" }

    public var errorCode: Int {
        switch self {
        case .linuxHost: return 1
        }
    }
}

/// Process-local record of a `finish(translation:)` call.
/// Not an Apple XPC payload.
public struct TranslationUIProviderHostFinishRecord: Equatable, Sendable {
    /// The argument the extension passed to `finish(translation:)`.
    public let submittedTranslation: AttributedString?
    /// Replacement text after applying the documented ignore/no-replacement
    /// rule. `nil` means no replacement takes place.
    public let appliedReplacement: AttributedString?
}

/// Linux host-test control. Not part of Apple's public TranslationUIProvider
/// surface.
@_spi(OpenUIKitHost)
public enum TranslationUIProviderHostControl {
    /// Always throws. Linux never presents a Translation UI provider sheet.
    public static func presentTranslationProviderUI() throws {
        throw TranslationUIProviderUnavailable.linuxHost(
            operation: "presentTranslationProviderUI"
        )
    }
}

// MARK: - TranslationUIProviderContext

/// An object that internalizes the XPC communication between the host process
/// and the 3rd party extension implementation.
///
/// Information provided to the extension is via the observable properties
/// `inputText` and `allowsReplacement`. The public graph does not include the
/// doc-comment `isPopoverPresentation` property or `cancel()`.
///
/// The extension calls back to the host using `finish(translation:)` and
/// optionally `expandSheet()`. Darwin is `@MainActor` and XPC-backed. Linux
/// omits `@MainActor` so the sealed runner can construct conforming types.
public protocol TranslationUIProviderContext: Observable {
    /// The source text to translate.
    var inputText: AttributedString? { get }

    /// If the source text is replaceable. The provider should clearly indicate
    /// on their control when text will be replaced.
    var allowsReplacement: Bool { get }

    /// Completes the translation after which the sheet will be closed.
    ///
    /// - Parameter translation: The optional translation result.
    ///   If `nil`, and the source text allows replacement, no replacement
    ///   will take place. If non-`nil`, and the source text does not allow
    ///   replacement, the parameter will be ignored. Providers should attempt
    ///   to preserve any attributes of the source text, but this is not a
    ///   requirement.
    ///
    /// Linux records the documented replacement outcome and never closes a
    /// sheet.
    func finish(translation: AttributedString?)

    /// Requests that the sheet expand.
    ///
    /// Linux records the request and never expands UI.
    func expandSheet()
}

/// Process-local translation-provider context. Not Apple's XPC-backed
/// `TranslationProviderContextImp`.
///
/// Defaults are fail-closed and unobserved on Darwin: `inputText` is `nil`
/// and `allowsReplacement` is `false` until a host injects a request.
public final class TranslationUIProviderHostContext: TranslationUIProviderContext, @unchecked Sendable {
    private let lock = NSLock()
    private var inputTextStorage: AttributedString?
    private var allowsReplacementStorage: Bool
    private var finishRecordStorage: TranslationUIProviderHostFinishRecord?
    private var expandSheetRequestCountStorage = 0

    public init(
        inputText: AttributedString? = nil,
        allowsReplacement: Bool = false
    ) {
        self.inputTextStorage = inputText
        self.allowsReplacementStorage = allowsReplacement
    }

    public var inputText: AttributedString? {
        lock.lock()
        defer { lock.unlock() }
        return inputTextStorage
    }

    public var allowsReplacement: Bool {
        lock.lock()
        defer { lock.unlock() }
        return allowsReplacementStorage
    }

    public func finish(translation: AttributedString?) {
        lock.lock()
        defer { lock.unlock() }
        let applied: AttributedString?
        if allowsReplacementStorage, let translation {
            applied = translation
        } else {
            applied = nil
        }
        finishRecordStorage = TranslationUIProviderHostFinishRecord(
            submittedTranslation: translation,
            appliedReplacement: applied
        )
    }

    public func expandSheet() {
        lock.lock()
        expandSheetRequestCountStorage += 1
        lock.unlock()
    }

    /// Injects source text the way Apple's internal `translate(text:replacementAllowed:)`
    /// would over XPC. Linux only mutates process-local storage.
    @_spi(OpenUIKitHost)
    public func hostProvideText(_ text: AttributedString?, replacementAllowed: Bool) {
        lock.lock()
        inputTextStorage = text
        allowsReplacementStorage = replacementAllowed
        lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public var hostFinishRecord: TranslationUIProviderHostFinishRecord? {
        lock.lock()
        defer { lock.unlock() }
        return finishRecordStorage
    }

    @_spi(OpenUIKitHost)
    public var hostIsFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finishRecordStorage != nil
    }

    @_spi(OpenUIKitHost)
    public var hostExpandSheetRequestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return expandSheetRequestCountStorage
    }

    /// Always `false`. Linux never presents or expands a translation sheet.
    @_spi(OpenUIKitHost)
    public var hostDidPresentExpandedSheet: Bool { false }
}
