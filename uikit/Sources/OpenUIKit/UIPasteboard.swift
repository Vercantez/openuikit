// UIPasteboard — process-local clipboard state for portable hosts.
// Owner: app-compat cluster (#94).
//
// There is no system pasteboard for a Mach-O guest running on Linux to ask.
// The useful and honest portable behavior is therefore process-local: every
// handle for a named pasteboard shares one locked item store, while `.general`
// lives for the process. A host can bridge this store to its desktop clipboard
// later without changing app source.
//
// The direct-access behavior is measured by PasteboardProbe on real iOS 26.1
// (`scripts/pasteboard_probe_sim.sh`): each setter replaces all old items and
// increments `changeCount` once; plural getters are empty arrays rather than
// nil on an empty board; URL writes are readable as strings; and absolute
// URL-shaped strings are readable as URLs. Images and colors are independent
// representations and clear the string/URL representation when assigned.
// The same oracle covers typed-Data decoding, automatic-type normalization,
// nil-versus-empty item queries, replacement semantics for first-item setters,
// and named/general removal. A removed named handle is empty until a later
// mutation reattaches that shared handle state to its name.
//
// UIKit explicitly imports UIPasteboard as Sendable, not MainActor-isolated.
// Focus also reads `.general.string` on a background Dispatch queue. The
// opaque CPortableIO mutex is used instead of Foundation.NSLock so this exact
// implementation remains safe in the Foundation-free Mach-O build.
// Notification constants are provided for source compatibility, but this
// process-local backend does not post them yet: OpenUIKit's shared
// NotificationCenter is not currently safe to call from these background
// setters.
// Foundation builds round-trip supplied Data and encode image objects, but do
// not reproduce UIKit's opaque keyed-archive bytes for URL or color objects.
// Representation recognition covers the measured concrete text/image/URL/
// color identifiers; it is not a general Uniform Type Identifier conformance
// engine (for example, UTF-16 text conversion is not implemented).

import CPortableIO

#if canImport(Foundation)
import struct Foundation.Data
import struct Foundation.URL
#endif

private final class UIPasteboardMutex: @unchecked Sendable {
    private let raw: UnsafeMutableRawPointer

    init() {
        guard let raw = cpio_mutex_create() else {
            fatalError("OpenUIKit could not allocate a pasteboard mutex")
        }
        self.raw = raw
    }

    deinit { cpio_mutex_destroy(raw) }

    func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
        cpio_mutex_lock(raw)
        defer { cpio_mutex_unlock(raw) }
        return try body()
    }
}

private final class UIPasteboardStorage: @unchecked Sendable {
    let lock = UIPasteboardMutex()
    var items: [[String: Any]] = []
    var changeCount = 0
    var isPersistent = false
}

private final class UIPasteboardRegistry: @unchecked Sendable {
    static let shared = UIPasteboardRegistry()

    private let lock = UIPasteboardMutex()
    private var stores: [UIPasteboard.Name: UIPasteboardStorage] = [:]
    private var nextUniqueID = 0

    func storage(named name: UIPasteboard.Name, create: Bool) -> UIPasteboardStorage? {
        lock.withLock {
            if let existing = stores[name] { return existing }
            guard create else { return nil }
            let storage = UIPasteboardStorage()
            stores[name] = storage
            return storage
        }
    }

    func read<Result>(named name: UIPasteboard.Name,
                      fallback: UIPasteboardStorage,
                      _ body: (UIPasteboardStorage) -> Result) -> Result {
        lock.withLock {
            let current = stores[name] ?? fallback
            return current.lock.withLock { body(current) }
        }
    }

    func mutate<Result>(named name: UIPasteboard.Name,
                        fallback: UIPasteboardStorage,
                        _ body: (UIPasteboardStorage) -> Result) -> Result {
        lock.withLock {
            let current: UIPasteboardStorage
            if let existing = stores[name] {
                current = existing
            } else {
                stores[name] = fallback
                current = fallback
            }
            return current.lock.withLock { body(current) }
        }
    }

    func unique() -> (UIPasteboard.Name, UIPasteboardStorage) {
        lock.withLock {
            var name: UIPasteboard.Name
            repeat {
                nextUniqueID += 1
                name = UIPasteboard.Name("OpenUIKit.unique.\(nextUniqueID)")
            } while stores[name] != nil
            let storage = UIPasteboardStorage()
            stores[name] = storage
            return (name, storage)
        }
    }

    func remove(_ name: UIPasteboard.Name) {
        var retiredItems: [[String: Any]] = []
        lock.withLock {
            let removed = name == .general
                ? stores[name] : stores.removeValue(forKey: name)
            guard let removed else { return }
            removed.lock.withLock {
                retiredItems = removed.items
                removed.items = []
                removed.isPersistent = false
                // UIKit's count is an external pasteboard generation and can
                // move non-monotonically across named removal. This local
                // generation records that observable state changed.
                removed.changeCount += 1
            }
        }
        withExtendedLifetime(retiredItems) {}
    }
}

/// A process-local implementation of UIKit's pasteboard item model.
open class UIPasteboard: @unchecked Sendable {
    public struct Name: Hashable, RawRepresentable, Sendable,
                        ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        public static let general = Name("com.apple.UIKit.pboard.general")
    }

    public struct OptionsKey: Hashable, RawRepresentable, Sendable,
                              ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }

        public static let expirationDate =
            OptionsKey(rawValue: "expirationDate")
        public static let localOnly =
            OptionsKey(rawValue: "localOnly")
    }

    private enum ItemType {
        static let text = "public.utf8-plain-text"
        static let abstractText = "public.text"
        static let plainText = "public.plain-text"
        static let url = "public.url"
        static let image = "com.apple.uikit.image"
        static let color = "com.apple.uikit.color"
    }

    private static let generalPasteboard: UIPasteboard = {
        let storage = UIPasteboardRegistry.shared.storage(named: .general, create: true)!
        return UIPasteboard(name: .general, storage: storage)
    }()

    public class var general: UIPasteboard { generalPasteboard }

    public let name: Name
    private let storage: UIPasteboardStorage

    private init(name: Name, storage: UIPasteboardStorage) {
        self.name = name
        self.storage = storage
    }

    public convenience init?(name pasteboardName: Name, create: Bool) {
        guard let storage = UIPasteboardRegistry.shared.storage(
            named: pasteboardName, create: create
        ) else { return nil }
        self.init(name: pasteboardName, storage: storage)
    }

    public class func withUniqueName() -> UIPasteboard {
        let (name, storage) = UIPasteboardRegistry.shared.unique()
        return UIPasteboard(name: name, storage: storage)
    }

    public class func remove(withName pasteboardName: Name) {
        UIPasteboardRegistry.shared.remove(pasteboardName)
    }

    open var isPersistent: Bool {
        read { $0.isPersistent }
    }

    open func setPersistent(_ persistent: Bool) {
        mutate { $0.isPersistent = persistent }
    }

    open var changeCount: Int {
        read { $0.changeCount }
    }

    // MARK: - Item model

    open var items: [[String: Any]] {
        get { read { $0.items } }
        set { replaceItems(newValue) }
    }

    open var numberOfItems: Int {
        read { $0.items.count }
    }

    open var types: [String] {
        // UIKit applies an internal representation-preference order. The
        // process-local backend promises deterministic lexical order instead.
        read { $0.items.first?.keys.sorted() ?? [] }
    }

    open func contains(pasteboardTypes: [String]) -> Bool {
        read { storage in
            guard let first = storage.items.first else { return false }
            return pasteboardTypes.contains { first[$0] != nil }
        }
    }

    open func value(forPasteboardType pasteboardType: String) -> Any? {
        read { $0.items.first?[pasteboardType] }
    }

    open func setValue(_ value: Any, forPasteboardType pasteboardType: String) {
        replaceItems([[pasteboardType: value]])
    }

    open func addItems(_ newItems: [[String: Any]]) {
        let normalized = newItems.map(Self.normalizedItem)
        mutate { storage in
            storage.items.append(contentsOf: normalized)
            storage.changeCount += 1
        }
    }

    /// `localOnly` is inherent to a process-local pasteboard. Expiration is
    /// accepted for source compatibility but cannot use a wall clock without
    /// violating OpenUIKit's deterministic-runtime rule.
    open func setItems(_ newItems: [[String: Any]],
                       options: [OptionsKey: Any] = [:]) {
        _ = options
        replaceItems(newItems)
    }

    open func types(forItemSet itemSet: IndexSet?) -> [[String]]? {
        read { storage in
            guard !storage.items.isEmpty else { return nil }
            return selectedIndexes(itemSet, count: storage.items.count).map {
                storage.items[$0].keys.sorted()
            }
        }
    }

    open func contains(pasteboardTypes: [String], inItemSet itemSet: IndexSet?) -> Bool {
        read { storage in
            selectedIndexes(itemSet, count: storage.items.count).contains { index in
                pasteboardTypes.contains { storage.items[index][$0] != nil }
            }
        }
    }

    open func itemSet(withPasteboardTypes pasteboardTypes: [String]) -> IndexSet? {
        read { storage in
            var result = IndexSet()
            for (index, item) in storage.items.enumerated()
            where pasteboardTypes.contains(where: { item[$0] != nil }) {
                result.insert(index)
            }
            return result
        }
    }

    open func values(forPasteboardType pasteboardType: String,
                     inItemSet itemSet: IndexSet?) -> [Any]? {
        read { storage in
            guard !storage.items.isEmpty else { return nil }
            return selectedIndexes(itemSet, count: storage.items.count).compactMap {
                storage.items[$0][pasteboardType]
            }
        }
    }

#if canImport(Foundation)
    open func data(forPasteboardType pasteboardType: String) -> Data? {
        guard let value = value(forPasteboardType: pasteboardType) else { return nil }
        return Self.dataValue(value, pasteboardType: pasteboardType)
    }

    open func setData(_ data: Data, forPasteboardType pasteboardType: String) {
        setValue(data, forPasteboardType: pasteboardType)
    }

    open func data(forPasteboardType pasteboardType: String,
                   inItemSet itemSet: IndexSet?) -> [Data]? {
        guard let values = values(forPasteboardType: pasteboardType,
                                  inItemSet: itemSet) else { return nil }
        let result = values.compactMap {
            Self.dataValue($0, pasteboardType: pasteboardType)
        }
        return result
    }
#endif

    // MARK: - Direct access

    open var string: String? {
        get { strings?.first }
        set { strings = newValue.map { [$0] } ?? [] }
    }

    open var strings: [String]? {
        get {
            read { storage in
                storage.items.compactMap(Self.stringValue)
            }
        }
        set {
            replaceItems((newValue ?? []).map(Self.textItem))
        }
    }

#if canImport(Foundation)
    open var url: URL? {
        get { urls?.first }
        set { urls = newValue.map { [$0] } ?? [] }
    }

    open var urls: [URL]? {
        get {
            read { storage in
                storage.items.compactMap(Self.urlValue)
            }
        }
        set {
            replaceItems((newValue ?? []).map(Self.urlItem))
        }
    }
#endif

    open var image: UIImage? {
        get { images?.first }
        set { images = newValue.map { [$0] } ?? [] }
    }

    open var images: [UIImage]? {
        get {
            read { storage in
                storage.items.compactMap(Self.imageValue)
            }
        }
        set {
            replaceItems((newValue ?? []).map(Self.imageItem))
        }
    }

    open var color: UIColor? {
        get { colors?.first }
        set { colors = newValue.map { [$0] } ?? [] }
    }

    open var colors: [UIColor]? {
        get {
            read { storage in
                storage.items.compactMap(Self.colorValue)
            }
        }
        set {
            replaceItems((newValue ?? []).map { [ItemType.color: $0] })
        }
    }

    open var hasStrings: Bool {
        hasItem(withAnyType: [ItemType.text, ItemType.abstractText,
                              ItemType.plainText, ItemType.url])
    }

#if canImport(Foundation)
    open var hasURLs: Bool { hasItem(withAnyType: [ItemType.url]) }
#endif

    open var hasImages: Bool {
        hasItem(withAnyType: [ItemType.image, "public.png", "public.jpeg",
                              "com.compuserve.gif"])
    }
    open var hasColors: Bool { hasItem(withAnyType: [ItemType.color]) }

    // MARK: - UIKit constants

    public static let changedNotification =
        Notification.Name("UIPasteboardChangedNotification")
    public static let changedTypesAddedUserInfoKey = "UIPasteboardChangedTypesAddedKey"
    public static let changedTypesRemovedUserInfoKey = "UIPasteboardChangedTypesRemovedKey"
    public static let removedNotification =
        Notification.Name("UIPasteboardRemovedNotification")

    public class var typeListString: [String] { [ItemType.text, ItemType.abstractText] }
    public class var typeListURL: [String] { [ItemType.url] }
    public class var typeListImage: [String] {
        ["public.png", "public.jpeg", "com.compuserve.gif", ItemType.image]
    }
    public class var typeListColor: [String] { [ItemType.color] }
    public static let typeAutomatic = "com.apple.uikit.type-automatic"

    // MARK: - Helpers

    private func read<Result>(_ body: (UIPasteboardStorage) -> Result) -> Result {
        UIPasteboardRegistry.shared.read(named: name, fallback: storage, body)
    }

    private func mutate<Result>(_ body: (UIPasteboardStorage) -> Result) -> Result {
        UIPasteboardRegistry.shared.mutate(named: name, fallback: storage, body)
    }

    private func hasItem(withAnyType types: [String]) -> Bool {
        read { storage in
            storage.items.contains { item in
                types.contains { item[$0] != nil }
            }
        }
    }

    private func replaceItems(_ newItems: [[String: Any]]) {
        let normalized = newItems.map(Self.normalizedItem)
        var retiredItems: [[String: Any]] = []
        mutate { storage in
            retiredItems = storage.items
            storage.items = normalized
            storage.changeCount += 1
        }
        // Releasing an arbitrary `Any` value can run its deinitializer. Keep
        // old values alive until after the nonrecursive storage mutex unlocks
        // so a deinitializer may safely call back into this pasteboard.
        withExtendedLifetime(retiredItems) {}
    }

    private func selectedIndexes(_ itemSet: IndexSet?, count: Int) -> [Int] {
        guard let itemSet else { return Array(0..<count) }
        return itemSet.filter { $0 >= 0 && $0 < count }
    }

    private static func stringValue(in item: [String: Any]) -> String? {
        let textTypes = [ItemType.text, ItemType.abstractText, ItemType.plainText]
        for type in textTypes {
            if let value = item[type] as? String { return value }
        }
#if canImport(Foundation)
        for type in textTypes {
            if let value = item[type] as? Data,
               let text = String(data: value, encoding: .utf8) { return text }
        }
        if let value = item[ItemType.url] as? URL { return value.absoluteString }
#endif
        return nil
    }

#if canImport(Foundation)
    private static func dataValue(_ value: Any, pasteboardType: String) -> Data? {
        if let data = value as? Data {
            return pasteboardType == ItemType.image ? nil : data
        }
        if let bytes = value as? [UInt8] {
            return pasteboardType == ItemType.image ? nil : Data(bytes)
        }
        guard let image = value as? UIImage else { return nil }
        if pasteboardType == "public.jpeg" {
            return image.jpegData(compressionQuality: 1).map { Data($0) }
        }
        if pasteboardType == "public.png" || pasteboardType == ItemType.image {
            return image.pngData().map { Data($0) }
        }
        return nil
    }

    private static func textItem(_ text: String) -> [String: Any] {
        var item: [String: Any] = [ItemType.text: text]
        if let value = URL(string: text), value.scheme != nil {
            item[ItemType.url] = value
        }
        return item
    }

    private static func urlItem(_ url: URL) -> [String: Any] {
        [ItemType.url: url, ItemType.text: url.absoluteString]
    }

    private static func urlValue(in item: [String: Any]) -> URL? {
        if let value = item[ItemType.url] as? URL { return value }
        guard let text = stringValue(in: item),
              let value = URL(string: text), value.scheme != nil else { return nil }
        return value
    }
#else
    private static func textItem(_ text: String) -> [String: Any] {
        [ItemType.text: text]
    }
#endif

    private static func imageValue(in item: [String: Any]) -> UIImage? {
        let encodedTypes = ["public.png", "public.jpeg", "com.compuserve.gif"]
        if let value = item[ItemType.image] as? UIImage { return value }
        for key in encodedTypes {
            if let value = item[key] as? UIImage { return value }
#if canImport(Foundation)
            if let value = item[key] as? Data,
               let image = UIImage(data: Array(value)) { return image }
#endif
        }
        return nil
    }

    private static func colorValue(in item: [String: Any]) -> UIColor? {
        item[ItemType.color] as? UIColor
    }

    private static func imageItem(_ image: UIImage) -> [String: Any] {
        [ItemType.image: image, "public.jpeg": image, "public.png": image]
    }

    private static func normalizedItem(_ item: [String: Any]) -> [String: Any] {
        guard let automatic = item[typeAutomatic] else { return item }
        var result = item
        result.removeValue(forKey: typeAutomatic)

        if let text = automatic as? String {
            result.merge(textItem(text)) { _, normalized in normalized }
            return result
        }
#if canImport(Foundation)
        if let url = automatic as? URL {
            result.merge(urlItem(url)) { _, normalized in normalized }
            return result
        }
#endif
        if let image = automatic as? UIImage {
            result.merge(imageItem(image)) { _, normalized in normalized }
            return result
        }
        if let color = automatic as? UIColor {
            result[ItemType.color] = color
            return result
        }

        result[typeAutomatic] = automatic
        return result
    }
}
