// NSItemProvider — in-process representations for share / pasteboard / drop.
//
// Darwin Foundation already vends the type; this file adds UIImage/UIColor
// load/register helpers (those classes are OpenUIKit's, not NSObject, so
// they cannot conform to Foundation.NSItemProviderWriting). Linux corelibs
// has no NSItemProvider, so the class lives here.
//
// MEASURED ValuesProbe, iPhone SE 3rd gen / iOS 26.1
// (`OpenUIKit-2x-uikit-tail-values`):
//   String  registeredTypeIdentifiers = public.utf8-plain-text
//   URL     = public.url
//   UIImage = com.apple.uikit.image, public.heic, public.png, public.jpeg
//   UIColor = com.apple.uikit.color
//   loadObject / loadDataRepresentation complete on a background queue
//   named com.apple.Foundation.NSItemProvider-callback-queue (not main).
//   suggestedName round-trips. canLoadObject is true only for a class
//   whose readable identifiers intersect the registered list.

#if canImport(Foundation)
import Foundation
#endif

#if os(Linux)

public enum NSItemProviderRepresentationVisibility: Int, Sendable {
    case all = 0
    case team = 1
    case group = 2
    case ownProcess = 3
}

public struct NSItemProviderFileOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let openInPlace = NSItemProviderFileOptions(rawValue: 1)
}

public let NSItemProviderPreferredImageSizeKey =
    "NSItemProviderPreferredImageSizeKey"
public let NSItemProviderErrorDomain = "NSItemProviderErrorDomain"

public enum NSItemProviderErrorCode: Int, Sendable {
    case unknown = -1
    case itemUnavailable = -1000
    case unexpectedValueClass = -1100
    case unavailableCoercion = -1200
}

public protocol NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] { get }
    func loadData(withTypeIdentifier typeIdentifier: String,
                  forItemProviderCompletionHandler completionHandler:
                    @escaping (Data?, Error?) -> Void) -> Progress?
}

public protocol NSItemProviderReading {
    static var readableTypeIdentifiersForItemProvider: [String] { get }
    static func object(withItemProviderData data: Data,
                       typeIdentifier: String) throws -> Self
}

public typealias NSItemProviderCompletionHandler = (Any?, Error?) -> Void

open class NSItemProvider: NSObject, @unchecked Sendable {
    private struct Representation {
        var typeIdentifier: String
        var visibility: NSItemProviderRepresentationVisibility
        var loadData: (@escaping (Data?, Error?) -> Void) -> Progress?
        var object: Any?
    }

    private let lock = NSLock()
    private var representations: [Representation] = []
    open var suggestedName: String?

    public override init() { super.init() }

    public convenience init(object: any NSItemProviderWriting) {
        self.init()
        registerObject(object, visibility: .all)
    }

    public convenience init(item: Any?, typeIdentifier: String?) {
        self.init()
        if let typeIdentifier, let item {
            registerItem(item, typeIdentifier: typeIdentifier)
        }
    }

    /// Gestures-dnd census spelling (`init(contentsOf:)`). Darwin Foundation
    /// already vends this; Linux stores the file URL as `public.file-url`.
    public convenience init(contentsOf fileURL: URL) {
        self.init(item: fileURL, typeIdentifier: "public.file-url")
        suggestedName = fileURL.lastPathComponent
    }

    open var registeredTypeIdentifiers: [String] {
        lock.lock()
        defer { lock.unlock() }
        return representations.map(\.typeIdentifier)
    }

    open func registeredTypeIdentifiers(
        withFileOptions fileOptions: NSItemProviderFileOptions
    ) -> [String] {
        _ = fileOptions
        return registeredTypeIdentifiers
    }

    open func hasItemConformingToTypeIdentifier(_ typeIdentifier: String) -> Bool {
        registeredTypeIdentifiers.contains { $0 == typeIdentifier }
    }

    open func hasRepresentationConforming(
        toTypeIdentifier typeIdentifier: String,
        fileOptions: NSItemProviderFileOptions
    ) -> Bool {
        _ = fileOptions
        return hasItemConformingToTypeIdentifier(typeIdentifier)
    }

    open func registerDataRepresentation(
        forTypeIdentifier typeIdentifier: String,
        visibility: NSItemProviderRepresentationVisibility,
        loadHandler: @escaping (@escaping (Data?, Error?) -> Void) -> Progress?
    ) {
        lock.lock()
        defer { lock.unlock() }
        if representations.contains(where: { $0.typeIdentifier == typeIdentifier }) {
            return
        }
        representations.append(Representation(
            typeIdentifier: typeIdentifier,
            visibility: visibility,
            loadData: loadHandler,
            object: nil
        ))
    }

    open func registerObject(_ object: any NSItemProviderWriting,
                             visibility: NSItemProviderRepresentationVisibility) {
        for identifier in type(of: object).writableTypeIdentifiersForItemProvider {
            lock.lock()
            let already = representations.contains { $0.typeIdentifier == identifier }
            lock.unlock()
            guard !already else { continue }
            registerDataRepresentation(
                forTypeIdentifier: identifier, visibility: visibility
            ) { completion in
                object.loadData(withTypeIdentifier: identifier,
                                forItemProviderCompletionHandler: completion)
            }
            lock.lock()
            if let last = representations.indices.last {
                representations[last].object = object
            }
            lock.unlock()
        }
    }

    private func registerItem(_ item: Any, typeIdentifier: String) {
        if let writer = item as? any NSItemProviderWriting {
            registerObject(writer, visibility: .all)
            return
        }
        registerDataRepresentation(
            forTypeIdentifier: typeIdentifier, visibility: .all
        ) { completion in
            if let data = item as? Data {
                completion(data, nil)
            } else if let text = item as? String {
                completion(Data(text.utf8), nil)
            } else {
                completion(nil, NSItemProvider._unavailable)
            }
            return Progress(totalUnitCount: 1)
        }
        lock.lock()
        if let last = representations.indices.last {
            representations[last].object = item
        }
        lock.unlock()
    }

    open func canLoadObject<T: NSItemProviderReading>(ofClass aClass: T.Type) -> Bool {
        let readable = aClass.readableTypeIdentifiersForItemProvider
        return registeredTypeIdentifiers.contains { id in
            readable.contains { $0 == id }
        }
    }

    @discardableResult
    open func loadDataRepresentation(
        forTypeIdentifier typeIdentifier: String,
        completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress {
        lock.lock()
        let match = representations.first { $0.typeIdentifier == typeIdentifier }
        lock.unlock()
        let progress = Progress(totalUnitCount: 1)
        NSItemProvider.callbackQueue.async {
            guard let match else {
                completionHandler(nil, NSItemProvider._unavailable)
                progress.completedUnitCount = 1
                return
            }
            _ = match.loadData { data, error in
                completionHandler(data, error)
                progress.completedUnitCount = 1
            }
        }
        return progress
    }

    @discardableResult
    open func loadObject<T: NSItemProviderReading>(
        ofClass aClass: T.Type,
        completionHandler: @escaping (T?, Error?) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        let readable = aClass.readableTypeIdentifiersForItemProvider
        lock.lock()
        let match = representations.first { rep in
            readable.contains { $0 == rep.typeIdentifier }
        }
        lock.unlock()
        NSItemProvider.callbackQueue.async {
            guard let match else {
                completionHandler(nil, NSItemProvider._unexpectedClass)
                progress.completedUnitCount = 1
                return
            }
            if let object = match.object as? T {
                completionHandler(object, nil)
                progress.completedUnitCount = 1
                return
            }
            _ = match.loadData { data, error in
                guard let data else {
                    completionHandler(nil, error)
                    progress.completedUnitCount = 1
                    return
                }
                do {
                    let object = try aClass.object(withItemProviderData: data,
                                                   typeIdentifier: match.typeIdentifier)
                    completionHandler(object, nil)
                } catch {
                    completionHandler(nil, error)
                }
                progress.completedUnitCount = 1
            }
        }
        return progress
    }

    @discardableResult
    open func loadItem(forTypeIdentifier typeIdentifier: String,
                       options: [AnyHashable: Any]? = nil,
                       completionHandler: NSItemProviderCompletionHandler? = nil)
        -> Progress {
        _ = options
        return loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
            completionHandler?(data, error)
        }
    }

    /// MEASURED ValuesProbe: completions run off the main thread on
    /// `com.apple.Foundation.NSItemProvider-callback-queue`.
    static let callbackQueue = DispatchQueue(
        label: "com.apple.Foundation.NSItemProvider-callback-queue"
    )

    static var _unavailable: NSError {
        NSError(domain: NSItemProviderErrorDomain,
                code: NSItemProviderErrorCode.itemUnavailable.rawValue)
    }

    static var _unexpectedClass: NSError {
        NSError(domain: NSItemProviderErrorDomain,
                code: NSItemProviderErrorCode.unexpectedValueClass.rawValue)
    }

    /// Process-local drag (`UIDragDrop.swift`) needs a typed in-process
    /// getter. Darwin Foundation does not expose one (tests set
    /// `UIDragItem.localObject`). MEASURED GestureProbe, iPhone SE 2x /
    /// iOS 26.1: drag items carry the provider plus optional localObject.
    func _canLoad(_ type: Any.Type) -> Bool {
        if type == String.self {
            return hasItemConformingToTypeIdentifier("public.utf8-plain-text")
                || hasItemConformingToTypeIdentifier("public.text")
                || hasItemConformingToTypeIdentifier("public.plain-text")
        }
        if type == URL.self {
            return hasItemConformingToTypeIdentifier("public.url")
                || hasItemConformingToTypeIdentifier("public.file-url")
        }
        if type == Data.self {
            return hasItemConformingToTypeIdentifier("public.data")
        }
        lock.lock()
        defer { lock.unlock() }
        return representations.contains { $0.object != nil }
    }

    func _load<T>(_ type: T.Type) -> T? {
        _ = type
        lock.lock()
        defer { lock.unlock() }
        for rep in representations {
            if let obj = rep.object as? T { return obj }
        }
        return nil
    }
}

extension String: NSItemProviderWriting, NSItemProviderReading {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        ["public.utf8-plain-text"]
    }
    public static var readableTypeIdentifiersForItemProvider: [String] {
        ["public.utf8-plain-text", "public.text", "public.plain-text"]
    }
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        _ = typeIdentifier
        completionHandler(Data(utf8), nil)
        return nil
    }
    public static func object(withItemProviderData data: Data,
                              typeIdentifier: String) throws -> String {
        _ = typeIdentifier
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension URL: NSItemProviderWriting, NSItemProviderReading {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        ["public.url"]
    }
    public static var readableTypeIdentifiersForItemProvider: [String] {
        ["public.url"]
    }
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        _ = typeIdentifier
        completionHandler(Data(absoluteString.utf8), nil)
        return nil
    }
    public static func object(withItemProviderData data: Data,
                              typeIdentifier: String) throws -> URL {
        _ = typeIdentifier
        let text = String(data: data, encoding: .utf8) ?? ""
        if let url = URL(string: text) { return url }
        throw NSError(domain: NSItemProviderErrorDomain,
                      code: NSItemProviderErrorCode.unavailableCoercion.rawValue)
    }
}

extension Data: NSItemProviderWriting, NSItemProviderReading {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        ["public.data"]
    }
    public static var readableTypeIdentifiersForItemProvider: [String] {
        ["public.data"]
    }
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        _ = typeIdentifier
        completionHandler(self, nil)
        return nil
    }
    public static func object(withItemProviderData data: Data,
                              typeIdentifier: String) throws -> Data {
        _ = typeIdentifier
        return data
    }
}

#endif

#if canImport(Foundation)
extension UIImage {
    static let _itemProviderTypeIdentifiers = [
        "com.apple.uikit.image", "public.heic", "public.png", "public.jpeg",
    ]

    func _itemProviderData(for typeIdentifier: String) -> Data? {
        if typeIdentifier == "public.jpeg" {
            return jpegData(compressionQuality: 1).map { Data($0) }
        }
        return pngData().map { Data($0) }
    }
}

extension UIColor {
    static let _itemProviderTypeIdentifiers = ["com.apple.uikit.color"]

    func _itemProviderData() -> Data {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        _ = getRed(&r, green: &g, blue: &b, alpha: &a)
        let text = "\(Double(r)),\(Double(g)),\(Double(b)),\(Double(a))"
        return Data(text.utf8)
    }

    static func _fromItemProviderData(_ data: Data) -> UIColor? {
        let text = String(data: data, encoding: .utf8) ?? ""
        let parts = text.split(separator: Character(","))
        guard parts.count == 4,
              let r = Double(parts[0]),
              let g = Double(parts[1]),
              let b = Double(parts[2]),
              let a = Double(parts[3]) else { return nil }
        return UIColor(red: CGFloat(r), green: CGFloat(g),
                       blue: CGFloat(b), alpha: CGFloat(a))
    }
}
#endif

#if os(Linux)
extension UIImage: NSItemProviderWriting, NSItemProviderReading {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        _itemProviderTypeIdentifiers
    }
    public static var readableTypeIdentifiersForItemProvider: [String] {
        _itemProviderTypeIdentifiers
    }
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        completionHandler(_itemProviderData(for: typeIdentifier), nil)
        return nil
    }
    public static func object(withItemProviderData data: Data,
                              typeIdentifier: String) throws -> Self {
        _ = typeIdentifier
        if let image = UIImage(data: Array(data)) as? Self { return image }
        throw NSError(domain: NSItemProviderErrorDomain,
                      code: NSItemProviderErrorCode.unavailableCoercion.rawValue)
    }
}

extension UIColor: NSItemProviderWriting, NSItemProviderReading {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        _itemProviderTypeIdentifiers
    }
    public static var readableTypeIdentifiersForItemProvider: [String] {
        _itemProviderTypeIdentifiers
    }
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        _ = typeIdentifier
        completionHandler(_itemProviderData(), nil)
        return nil
    }
    public static func object(withItemProviderData data: Data,
                              typeIdentifier: String) throws -> Self {
        _ = typeIdentifier
        if let color = _fromItemProviderData(data) as? Self { return color }
        throw NSError(domain: NSItemProviderErrorDomain,
                      code: NSItemProviderErrorCode.unavailableCoercion.rawValue)
    }
}
#endif

#if canImport(Foundation) && !os(Linux)
extension NSItemProvider {
    public convenience init(object image: UIImage) {
        self.init()
        _openUIKit_register(image: image)
    }

    public convenience init(object color: UIColor) {
        self.init()
        _openUIKit_register(color: color)
    }

    public func registerObject(_ image: UIImage,
                               visibility: NSItemProviderRepresentationVisibility) {
        _ = visibility
        _openUIKit_register(image: image)
    }

    public func registerObject(_ color: UIColor,
                               visibility: NSItemProviderRepresentationVisibility) {
        _ = visibility
        _openUIKit_register(color: color)
    }

    public func canLoadObject(ofClass aClass: UIImage.Type) -> Bool {
        _ = aClass
        return _openUIKit_hasAny(UIImage._itemProviderTypeIdentifiers)
    }

    public func canLoadObject(ofClass aClass: UIColor.Type) -> Bool {
        _ = aClass
        return _openUIKit_hasAny(UIColor._itemProviderTypeIdentifiers)
    }

    @discardableResult
    public func loadObject(
        ofClass aClass: UIImage.Type,
        completionHandler: @escaping (UIImage?, Error?) -> Void
    ) -> Progress {
        _ = aClass
        return _openUIKit_loadImage(completionHandler)
    }

    @discardableResult
    public func loadObject(
        ofClass aClass: UIColor.Type,
        completionHandler: @escaping (UIColor?, Error?) -> Void
    ) -> Progress {
        _ = aClass
        return _openUIKit_loadColor(completionHandler)
    }

    private func _openUIKit_hasAny(_ identifiers: [String]) -> Bool {
        registeredTypeIdentifiers.contains { id in
            identifiers.contains { $0 == id }
        }
    }

    private func _openUIKit_register(image: UIImage) {
        for identifier in UIImage._itemProviderTypeIdentifiers {
            registerDataRepresentation(forTypeIdentifier: identifier,
                                       visibility: .all) { completion in
                completion(image._itemProviderData(for: identifier), nil)
                return nil
            }
        }
    }

    private func _openUIKit_register(color: UIColor) {
        registerDataRepresentation(forTypeIdentifier: "com.apple.uikit.color",
                                   visibility: .all) { completion in
            completion(color._itemProviderData(), nil)
            return nil
        }
    }

    private func _openUIKit_loadImage(
        _ completion: @escaping (UIImage?, Error?) -> Void
    ) -> Progress {
        let identifiers = UIImage._itemProviderTypeIdentifiers
        let match = registeredTypeIdentifiers.first { id in
            identifiers.contains { $0 == id }
        } ?? "public.png"
        return loadDataRepresentation(forTypeIdentifier: match) { data, error in
            guard let data else {
                completion(nil, error)
                return
            }
            completion(UIImage(data: Array(data)), error)
        }
    }

    private func _openUIKit_loadColor(
        _ completion: @escaping (UIColor?, Error?) -> Void
    ) -> Progress {
        return loadDataRepresentation(forTypeIdentifier: "com.apple.uikit.color") { data, error in
            guard let data else {
                completion(nil, error)
                return
            }
            completion(UIColor._fromItemProviderData(data), error)
        }
    }
}
#endif
