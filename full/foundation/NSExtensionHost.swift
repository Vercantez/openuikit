// Canonical Foundation app-extension request values for Linux-hosted Mach-O
// guests.
//
// Apple normally supplies these declarations through Foundation while an
// extension daemon injects NSExtensionContext's input and terminal request
// channel.  The portable platform has no such daemon.  It nevertheless owns
// the real Foundation nominal identities so framework categories in
// NotificationCenter and UserNotificationsUI extend one shared context.  Host
// operations fail closed: URL opens report false and completion work is
// reported expired rather than pretending an Apple host accepted it.

#if FOUNDATION_EXTENSION_HOST
import Foundation
#else
import FoundationEssentials
import ObjectiveC
import OpenUIKit
#endif
import Synchronization

// MARK: - Exported extension constants

public let NSExtensionItemsAndErrorsKey = "NSExtensionItemsAndErrorsKey"

public let NSExtensionItemAttributedTitleKey =
    "NSExtensionItemAttributedTitleKey"
public let NSExtensionItemAttributedContentTextKey =
    "NSExtensionItemAttributedContentTextKey"
public let NSExtensionItemAttachmentsKey = "NSExtensionItemAttachmentsKey"

public let NSExtensionJavaScriptPreprocessingResultsKey =
    "NSExtensionJavaScriptPreprocessingResultsKey"
public let NSExtensionJavaScriptFinalizeArgumentKey =
    "NSExtensionJavaScriptFinalizeArgumentKey"
public let NSItemProviderPreferredImageSizeKey =
    "NSItemProviderPreferredImageSizeKey"

#if !FOUNDATION_EXTENSION_HOST
public extension Notification.Name {
    static let NSExtensionHostWillEnterForeground = Notification.Name(
        "NSExtensionHostWillEnterForegroundNotification"
    )
    static let NSExtensionHostDidEnterBackground = Notification.Name(
        "NSExtensionHostDidEnterBackgroundNotification"
    )
    static let NSExtensionHostWillResignActive = Notification.Name(
        "NSExtensionHostWillResignActiveNotification"
    )
    static let NSExtensionHostDidBecomeActive = Notification.Name(
        "NSExtensionHostDidBecomeActiveNotification"
    )
}
#endif

// MARK: - Bounded secure-coding transport

private struct _ExtensionItemSnapshot: @unchecked Sendable {
    var attributedTitle: NSAttributedString?
    var attributedContentText: NSAttributedString?
    var attachments: [NSItemProvider]?
    var userInfo: [AnyHashable: Any]?
}

private struct _ItemProviderSnapshot: @unchecked Sendable {
#if FOUNDATION_EXTENSION_HOST
    var registeredTypeIdentifiers: [String]
    var suggestedName: String?
    var item: (any NSSecureCoding)?
#else
    var provider: OpenUIKit.NSItemProvider
#endif
}

#if !FOUNDATION_EXTENSION_HOST
/// OpenUIKit's Foundation-hidden NSCoder is deliberately a nominal boundary,
/// not a keyed archiver.  Until NSKeyedArchiver joins the guest facade, keep a
/// small process-local transport so NSSecureCoding participants can still
/// round-trip through the canonical coder identity.  Missing or evicted
/// snapshots decode as nil; no malformed archive is accepted as success.
private enum _ExtensionArchiveTransport {
    private struct State: @unchecked Sendable {
        var itemSnapshots: [ObjectIdentifier: _ExtensionItemSnapshot] = [:]
        var providerSnapshots: [ObjectIdentifier: _ItemProviderSnapshot] = [:]
        var order: [ObjectIdentifier] = []
    }

    private static let capacity = 64
    private static let state = Mutex(State())

    static func store(
        _ snapshot: _ExtensionItemSnapshot,
        for coder: NSCoder
    ) {
        let identifier = ObjectIdentifier(coder)
        state.withLock { state in
            state.itemSnapshots[identifier] = snapshot
            touch(identifier, state: &state)
        }
    }

    static func store(
        _ snapshot: _ItemProviderSnapshot,
        for coder: NSCoder
    ) {
        let identifier = ObjectIdentifier(coder)
        state.withLock { state in
            state.providerSnapshots[identifier] = snapshot
            touch(identifier, state: &state)
        }
    }

    static func item(for coder: NSCoder) -> _ExtensionItemSnapshot? {
        state.withLock { $0.itemSnapshots[ObjectIdentifier(coder)] }
    }

    static func provider(for coder: NSCoder) -> _ItemProviderSnapshot? {
        state.withLock { $0.providerSnapshots[ObjectIdentifier(coder)] }
    }

    private static func touch(
        _ identifier: ObjectIdentifier,
        state: inout State
    ) {
        state.order.removeAll { $0 == identifier }
        state.order.append(identifier)
        while state.order.count > capacity {
            let evicted = state.order.removeFirst()
            state.itemSnapshots.removeValue(forKey: evicted)
            state.providerSnapshots.removeValue(forKey: evicted)
        }
    }
}
#endif

// MARK: - Item provider identity used by extension items

#if FOUNDATION_EXTENSION_HOST
/// The bounded item-provider identity required by `NSExtensionItem`.
///
/// In-process item retention, identifier ordering, copying, and secure metadata
/// coding are real.  UTI conformance, coercion, file coordination, and XPC
/// loading remain separate NSItemProvider work and are not fabricated here.
open class NSItemProvider: NSObject, NSCopying, NSSecureCoding {
    private struct State: @unchecked Sendable {
        var registeredTypeIdentifiers: [String]
        var suggestedName: String?
        var item: (any NSSecureCoding)?
    }

    private let state: Mutex<State>

    open class var supportsSecureCoding: Bool { true }

    public override init() {
        state = Mutex(
            State(
                registeredTypeIdentifiers: [],
                suggestedName: nil,
                item: nil
            )
        )
        super.init()
    }

    public init(
        item: (any NSSecureCoding)?,
        typeIdentifier: String?
    ) {
        state = Mutex(
            State(
                registeredTypeIdentifiers: typeIdentifier.map { [$0] } ?? [],
                suggestedName: nil,
                item: item
            )
        )
        super.init()
    }

    private init(snapshot: _ItemProviderSnapshot) {
        state = Mutex(
            State(
                registeredTypeIdentifiers: snapshot.registeredTypeIdentifiers,
                suggestedName: snapshot.suggestedName,
                item: snapshot.item
            )
        )
        super.init()
    }

    public required init?(coder: NSCoder) {
#if FOUNDATION_EXTENSION_HOST
        guard coder.allowsKeyedCoding else { return nil }
        let identifiers = coder.decodeObject(
            of: [NSArray.self, NSString.self],
            forKey: "NSExtensionItemProviderTypeIdentifiers"
        ) as? [String]
        let suggestedName = coder.decodeObject(
            of: NSString.self,
            forKey: "NSExtensionItemProviderSuggestedName"
        ) as String?
        state = Mutex(
            State(
                registeredTypeIdentifiers: identifiers ?? [],
                suggestedName: suggestedName,
                item: nil
            )
        )
#else
        guard let snapshot = _ExtensionArchiveTransport.provider(for: coder)
        else { return nil }
        state = Mutex(
            State(
                registeredTypeIdentifiers: snapshot.registeredTypeIdentifiers,
                suggestedName: snapshot.suggestedName,
                item: snapshot.item
            )
        )
#endif
        super.init()
    }

    open var registeredTypeIdentifiers: [String] {
        state.withLock { $0.registeredTypeIdentifiers }
    }

    open var suggestedName: String? {
        get { state.withLock { $0.suggestedName } }
        set { state.withLock { $0.suggestedName = newValue } }
    }

    open func hasItemConformingToTypeIdentifier(
        _ typeIdentifier: String
    ) -> Bool {
        // Exact identity is honest without a UniformTypeIdentifiers graph.
        // Broader UTI conformance must wait for that canonical dependency.
        state.withLock { $0.registeredTypeIdentifiers.contains(typeIdentifier) }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSItemProvider(snapshot: snapshot())
    }

    open override func copy() -> Any { copy(with: nil) }

    open func encode(with coder: NSCoder) {
        let snapshot = snapshot()
#if FOUNDATION_EXTENSION_HOST
        guard coder.allowsKeyedCoding else { return }
        coder.encode(
            snapshot.registeredTypeIdentifiers,
            forKey: "NSExtensionItemProviderTypeIdentifiers"
        )
        coder.encode(
            snapshot.suggestedName,
            forKey: "NSExtensionItemProviderSuggestedName"
        )
#else
        _ExtensionArchiveTransport.store(snapshot, for: coder)
#endif
    }

    private func snapshot() -> _ItemProviderSnapshot {
        state.withLock { state in
            _ItemProviderSnapshot(
                registeredTypeIdentifiers: state.registeredTypeIdentifiers,
                suggestedName: state.suggestedName,
                item: state.item
            )
        }
    }
}

#else
/// Guest Foundation's extension-host provider is a storage-preserving subclass
/// bridge to the Foundation-hidden OpenUIKit provider. Unlike an alias with a
/// retroactive conformance, this can implement NSSecureCoding's required coder
/// initializer on an open class. UIDragItem consumes this SAME object, while
/// NSExtensionItem keeps its existing Foundation attachment/coding contract.
///
/// MEASURED verify88, x86 rungs b/c: two unrelated provider classes rejected
/// URLBar.swift:1137. Apple Foundation's contentsOf oracle returned non-nil for
/// https, existing file, missing .txt, directory; the inherited failable
/// initializer now preserves these URL payloads instead of returning nil.
open class NSItemProvider: OpenUIKit.NSItemProvider, NSCopying, NSSecureCoding,
    @unchecked Sendable {
    // Representations are immutable after initialization. Keep the original
    // extension-host synchronization for its one mutable metadata property.
    private let name = Mutex<String?>(nil)
    open override var suggestedName: String? {
        get { name.withLock { $0 } }
        set { name.withLock { $0 = newValue } }
    }
    open class var supportsSecureCoding: Bool { true }

    public override init() { super.init() }

    public override init(item: Any?, typeIdentifier: String?) {
        super.init(item: item, typeIdentifier: typeIdentifier)
    }

    public override init(_openUIKitCopying provider: OpenUIKit.NSItemProvider) {
        super.init(_openUIKitCopying: provider)
        suggestedName = provider.suggestedName
    }

    public required init?(coder: NSCoder) {
        guard let snapshot = _ExtensionArchiveTransport.provider(for: coder)
        else { return nil }
        super.init(_openUIKitCopying: snapshot.provider)
        suggestedName = snapshot.provider.suggestedName
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        NSItemProvider(_openUIKitCopying: self)
    }

    open override func copy() -> Any { copy(with: nil) }

    open func encode(with coder: NSCoder) {
        _ExtensionArchiveTransport.store(
            _ItemProviderSnapshot(provider: OpenUIKit.NSItemProvider(
                _openUIKitCopying: self)), for: coder)
    }
}
#endif

// MARK: - Extension item

open class NSExtensionItem: NSObject, NSCopying, NSSecureCoding {
    private struct State: @unchecked Sendable {
        var attributedTitle: NSAttributedString?
        var attributedContentText: NSAttributedString?
        var attachments: [NSItemProvider]?
        var userInfo: [AnyHashable: Any]?
    }

    private let state: Mutex<State>

    open class var supportsSecureCoding: Bool { true }

    public override init() {
        state = Mutex(
            State(
                attributedTitle: nil,
                attributedContentText: nil,
                attachments: nil,
                userInfo: [:]
            )
        )
        super.init()
    }

    private init(snapshot: _ExtensionItemSnapshot) {
        state = Mutex(
            State(
                attributedTitle: snapshot.attributedTitle,
                attributedContentText: snapshot.attributedContentText,
                attachments: snapshot.attachments,
                userInfo: snapshot.userInfo
            )
        )
        super.init()
    }

    public required init?(coder: NSCoder) {
#if FOUNDATION_EXTENSION_HOST
        guard coder.allowsKeyedCoding else { return nil }
        let title = coder.decodeObject(
            of: NSAttributedString.self,
            forKey: "NSExtensionItemAttributedTitleKey"
        )
        let content = coder.decodeObject(
            of: NSAttributedString.self,
            forKey: "NSExtensionItemAttributedContentTextKey"
        )
        let attachments = coder.decodeObject(
            of: [NSArray.self, NSItemProvider.self],
            forKey: "NSExtensionItemAttachmentsKey"
        ) as? [NSItemProvider]
        let allowedUserInfoClasses: [AnyClass] = [
            NSDictionary.self,
            NSArray.self,
            NSString.self,
            NSNumber.self,
            NSData.self,
            NSDate.self,
            NSURL.self,
            NSAttributedString.self,
            NSItemProvider.self,
        ]
        let userInfo = coder.decodeObject(
            of: allowedUserInfoClasses,
            forKey: "NSExtensionItemUserInfoKey"
        ) as? [AnyHashable: Any]
        state = Mutex(
            State(
                attributedTitle: title,
                attributedContentText: content,
                attachments: attachments,
                userInfo: userInfo
            )
        )
#else
        guard let snapshot = _ExtensionArchiveTransport.item(for: coder)
        else { return nil }
        state = Mutex(
            State(
                attributedTitle: snapshot.attributedTitle,
                attributedContentText: snapshot.attributedContentText,
                attachments: snapshot.attachments,
                userInfo: snapshot.userInfo
            )
        )
#endif
        super.init()
    }

    open var attributedTitle: NSAttributedString? {
        get { state.withLock { $0.attributedTitle } }
        set {
            let copied = newValue.map {
                NSAttributedString(attributedString: $0)
            }
            state.withLock { state in
                state.attributedTitle = copied
                setReflectedValue(
                    copied,
                    forKey: NSExtensionItemAttributedTitleKey,
                    state: &state
                )
            }
        }
    }

    open var attributedContentText: NSAttributedString? {
        get { state.withLock { $0.attributedContentText } }
        set {
            let copied = newValue.map {
                NSAttributedString(attributedString: $0)
            }
            state.withLock { state in
                state.attributedContentText = copied
                setReflectedValue(
                    copied,
                    forKey: NSExtensionItemAttributedContentTextKey,
                    state: &state
                )
            }
        }
    }

    open var attachments: [NSItemProvider]? {
        get { state.withLock { $0.attachments } }
        set {
            let copied = newValue.map(Array.init)
            state.withLock { state in
                state.attachments = copied
                setReflectedValue(
                    copied,
                    forKey: NSExtensionItemAttachmentsKey,
                    state: &state
                )
            }
        }
    }

    open var userInfo: [AnyHashable: Any]? {
        get { state.withLock { $0.userInfo } }
        set {
            // Dictionary assignment preserves Foundation's copy-on-set value
            // semantics without attempting to clone arbitrary payload values.
            var copied: [AnyHashable: Any]? = newValue
            let title = (copied?[NSExtensionItemAttributedTitleKey]
                as? NSAttributedString).map {
                    NSAttributedString(attributedString: $0)
                }
            let content = (copied?[NSExtensionItemAttributedContentTextKey]
                as? NSAttributedString).map {
                    NSAttributedString(attributedString: $0)
                }
            let attachments = (copied?[NSExtensionItemAttachmentsKey]
                as? [NSItemProvider]).map(Array.init)
            if title != nil {
                copied?[NSExtensionItemAttributedTitleKey] = title
            }
            if content != nil {
                copied?[NSExtensionItemAttributedContentTextKey] = content
            }
            if attachments != nil {
                copied?[NSExtensionItemAttachmentsKey] = attachments
            }
            state.withLock { state in
                state.userInfo = copied
                state.attributedTitle = title
                state.attributedContentText = content
                state.attachments = attachments
            }
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let source = snapshot()
        let title = source.attributedTitle.map {
            NSAttributedString(attributedString: $0)
        }
        let content = source.attributedContentText.map {
            NSAttributedString(attributedString: $0)
        }
        let providers = source.attachments?.map {
            $0.copy(with: zone) as! NSItemProvider
        }
        var info = source.userInfo
        if info != nil {
            info?[NSExtensionItemAttributedTitleKey] = title
            info?[NSExtensionItemAttributedContentTextKey] = content
            info?[NSExtensionItemAttachmentsKey] = providers
            if title == nil {
                info?.removeValue(forKey: NSExtensionItemAttributedTitleKey)
            }
            if content == nil {
                info?.removeValue(
                    forKey: NSExtensionItemAttributedContentTextKey
                )
            }
            if providers == nil {
                info?.removeValue(forKey: NSExtensionItemAttachmentsKey)
            }
        }
        return NSExtensionItem(
            snapshot: _ExtensionItemSnapshot(
                attributedTitle: title,
                attributedContentText: content,
                attachments: providers,
                userInfo: info
            )
        )
    }

    open override func copy() -> Any { copy(with: nil) }

    open func encode(with coder: NSCoder) {
        let snapshot = snapshot()
#if FOUNDATION_EXTENSION_HOST
        guard coder.allowsKeyedCoding else { return }
        coder.encode(
            snapshot.attributedTitle,
            forKey: "NSExtensionItemAttributedTitleKey"
        )
        coder.encode(
            snapshot.attributedContentText,
            forKey: "NSExtensionItemAttributedContentTextKey"
        )
        coder.encode(
            snapshot.attachments,
            forKey: "NSExtensionItemAttachmentsKey"
        )
        coder.encode(
            snapshot.userInfo,
            forKey: "NSExtensionItemUserInfoKey"
        )
#else
        // A decoded object must not share mutable attachment/provider state
        // with the encoded root merely because the bounded transport is
        // in-process.
        let archivedTitle = snapshot.attributedTitle.map {
            NSAttributedString(attributedString: $0)
        }
        let archivedContent = snapshot.attributedContentText.map {
            NSAttributedString(attributedString: $0)
        }
        let archivedAttachments = snapshot.attachments?.map {
            $0.copy(with: nil) as! NSItemProvider
        }
        var archivedUserInfo = snapshot.userInfo
        if archivedUserInfo != nil {
            archivedUserInfo?[NSExtensionItemAttributedTitleKey] =
                archivedTitle
            archivedUserInfo?[NSExtensionItemAttributedContentTextKey] =
                archivedContent
            archivedUserInfo?[NSExtensionItemAttachmentsKey] =
                archivedAttachments
        }
        let archived = _ExtensionItemSnapshot(
            attributedTitle: archivedTitle,
            attributedContentText: archivedContent,
            attachments: archivedAttachments,
            userInfo: archivedUserInfo
        )
        _ExtensionArchiveTransport.store(archived, for: coder)
#endif
    }

    private func snapshot() -> _ExtensionItemSnapshot {
        state.withLock { state in
            _ExtensionItemSnapshot(
                attributedTitle: state.attributedTitle,
                attributedContentText: state.attributedContentText,
                attachments: state.attachments,
                userInfo: state.userInfo
            )
        }
    }

    private func setReflectedValue(
        _ value: Any?,
        forKey key: String,
        state: inout State
    ) {
        if state.userInfo == nil {
            state.userInfo = [:]
        }
        if let value {
            state.userInfo?[key] = value
        } else {
            state.userInfo?.removeValue(forKey: key)
        }
    }
}

// MARK: - Extension request context

@_spi(OpenUIKitHost)
public enum NSExtensionContextHostDisposition: Equatable, Sendable {
    case active
    case completionUnavailable(returnedItemCount: Int?)
    case cancelled(errorType: String, description: String)
}

open class NSExtensionContext: NSObject {
    private struct State: @unchecked Sendable {
        var inputItems: [Any]
        var disposition: NSExtensionContextHostDisposition
        var rejectedOpenRequestCount: Int
    }

    private let state: Mutex<State>

    public override init() {
        state = Mutex(
            State(
                inputItems: [],
                disposition: .active,
                rejectedOpenRequestCount: 0
            )
        )
        super.init()
    }

    @_spi(OpenUIKitHost)
    public init(inputItems: [Any]) {
        state = Mutex(
            State(
                inputItems: Array(inputItems),
                disposition: .active,
                rejectedOpenRequestCount: 0
            )
        )
        super.init()
    }

    open var inputItems: [Any] {
        state.withLock { $0.inputItems }
    }

    open func completeRequest(
        returningItems items: [Any]?,
        completionHandler: (@Sendable (Bool) -> Void)? = nil
    ) {
        state.withLock { state in
            if state.disposition == .active {
                state.disposition = .completionUnavailable(
                    returnedItemCount: items?.count
                )
            }
        }
        // `expired == true` is the only honest callback without an extension
        // host: no background work budget was granted and no OS completion is
        // claimed. Invoke outside the lock so client reentry cannot deadlock.
        completionHandler?(true)
    }

    open func cancelRequest(withError error: any Error) {
        state.withLock { state in
            guard state.disposition == .active else { return }
            state.disposition = .cancelled(
                errorType: String(reflecting: type(of: error)),
                description: String(describing: error)
            )
        }
    }

    open func open(
        _ URL: URL,
        completionHandler: (@Sendable (Bool) -> Void)? = nil
    ) {
        _ = URL
        recordRejectedOpen()
        completionHandler?(false)
    }

    open func open(_ URL: URL) async -> Bool {
        _ = URL
        recordRejectedOpen()
        return false
    }

    @_spi(OpenUIKitHost)
    public var portableHostDisposition: NSExtensionContextHostDisposition {
        state.withLock { $0.disposition }
    }

    @_spi(OpenUIKitHost)
    public var portableRejectedOpenRequestCount: Int {
        state.withLock { $0.rejectedOpenRequestCount }
    }

    private func recordRejectedOpen() {
        state.withLock { state in
            if state.rejectedOpenRequestCount < Int.max {
                state.rejectedOpenRequestCount += 1
            }
        }
    }
}

public protocol NSExtensionRequestHandling: NSObjectProtocol {
    func beginRequest(with context: NSExtensionContext)
}
