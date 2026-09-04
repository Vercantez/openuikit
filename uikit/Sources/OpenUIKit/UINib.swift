// UINib — Interface Builder archive loading. Owner: app-compat module.
//
// docs/REAL_APP_TEST.md blocker 13 ("xibs / storyboards", `@IBOutlet` 1,678
// uses / 323 files) was an explicit non-goal until this file. It is the
// reason every small Pocket Casts settings screen was out of reach: they all
// say
//
//     settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil),
//                            forCellReuseIdentifier: switchCellId)
//
// and the cell itself is a xib with `@IBOutlet` labels, switches and
// constraints.
//
// WHAT THIS READS is the compiled artefact, not the xib: `ibtool --compile`
// turns the XML into a **NIBArchive**, and that binary container is what
// ships in an app bundle. The format is not documented by Apple; the reader
// below was written against the bytes of the three nibs in
// fixtures/realapp/nibs (scripts/compile_realapp_nibs.sh), field by field
// against the xib XML they came from. Layout, measured on `SwitchCell.nib`
// (3,606 bytes, Xcode 26.1 ibtool):
//
//   0    "NIBArchive"                       10 bytes, no terminator
//   10   format version                     u32, 1
//   14   coder version                      u32, 10
//   18   object count / offset              u32, u32   (48 / 50)
//   26   key count / offset                 u32, u32   (79 / 217)
//   34   value count / offset               u32, u32   (256 / 1636)
//   42   class-name count / offset          u32, u32   (16 / 3341)
//
//   object:      varint classNameIndex, varint firstValueIndex, varint count
//   key:         varint byteCount, bytes (UTF-8, no terminator)
//   value:       varint keyIndex, u8 type, payload
//   class name:  varint byteCount, varint extraIntCount, extraIntCount * i32,
//                bytes
//
// The varint is little-endian 7-bit groups where the HIGH BIT MARKS THE LAST
// byte — the opposite convention from protobuf, and the one detail a reader
// written from memory gets wrong. Value types:
//
//   0 i8   1 i16   2 i32   3 i64   4 false   5 true   6 f32   7 f64
//   8 data (varint length + bytes)   9 nil   10 object reference (u32)
//
// MEASURED that 4 is false and 5 is true, not the other way round, from keys
// whose xib spelling is known: `SwitchCell.xib`'s content view says
// `multipleTouchEnabled="YES" clipsSubviews="YES"` and its image view says
// `userInteractionEnabled="NO" translatesAutoresizingMaskIntoConstraints="NO"`
// — all four encode as type 5, and `StorageAndDataUseViewController.xib`'s
// `clearsContextBeforeDrawing="NO"` encodes as type 4.
//
// A `CGRect`/`CGPoint` value (`UIBounds`, `UICenter`) is a type-8 blob whose
// first byte is the component encoding — 7 for f64, which is what ibtool
// writes — followed by that many components. `SwitchCell`'s label decodes to
// bounds (0, 0, 267, 64) and centre (181.5, 32), i.e. frame (48, 0, 267, 64),
// which is the `<rect>` in the xib.
//
// WHAT THIS DOES NOT DO is run `initWithCoder:`. Real UIKit decodes each
// archived object through `NSCoding`; OpenUIKit has no archiver, so the
// decoder below constructs the object through a name -> factory registry
// (`UINibClassRegistry`, the nib-side twin of the `SelectorDispatching`
// registry in UISelector.swift) and then applies the archived keys with a
// switch. Two consequences, both in docs/KNOWN_GAPS.md: a custom
// `init?(coder:)` in app code is not called, and an archived key this file
// does not know is skipped — `UINib.unhandledKeys` records every one, so the
// gap is countable rather than silent.

// MARK: - The archive

/// A parsed NIBArchive: the flat object/key/value tables, before anything is
/// turned into a UIKit object. Internal — the shape is an implementation
/// detail of a private Apple format, and only the decoder below reads it.
struct NibArchive {
    enum Value {
        case integer(Int)
        case boolean(Bool)
        case number(Double)
        case bytes([UInt8])
        case null
        case reference(Int)
    }

    struct Object {
        let className: String
        /// Keys repeat: an archived array is one object whose every element
        /// is stored under `UINibEncoderEmptyKey`, so this must stay ordered
        /// and cannot become a dictionary.
        let values: [(key: String, value: Value)]

        func first(_ key: String) -> Value? {
            for pair in values where pair.key == key { return pair.value }
            return nil
        }
    }

    let objects: [Object]

    /// Byte cursor over the archive. `failed` from any accessor means the
    /// file is truncated or not a NIBArchive; the parser fails closed rather
    /// than trapping on a bad index, because the input is an app resource.
    private struct Cursor {
        let bytes: [UInt8]
        var pos: Int
        var failed = false

        mutating func byte() -> UInt8 {
            guard pos < bytes.count else { failed = true; return 0 }
            let b = bytes[pos]
            pos += 1
            return b
        }

        mutating func u16() -> UInt16 {
            let lo = UInt16(byte()), hi = UInt16(byte())
            return lo | (hi << 8)
        }

        mutating func u32() -> UInt32 {
            var v: UInt32 = 0
            for i in 0..<4 { v |= UInt32(byte()) << (8 * UInt32(i)) }
            return v
        }

        mutating func u64() -> UInt64 {
            var v: UInt64 = 0
            for i in 0..<8 { v |= UInt64(byte()) << (8 * UInt64(i)) }
            return v
        }

        /// Little-endian 7-bit groups; the byte with the high bit SET is the
        /// last one (see the file header).
        mutating func varint() -> Int {
            var v = 0
            var shift = 0
            while !failed {
                let b = byte()
                v |= Int(b & 0x7F) << shift
                shift += 7
                if b & 0x80 != 0 { break }
                if shift > 56 { failed = true }
            }
            return v
        }

        mutating func data(_ count: Int) -> [UInt8] {
            guard count >= 0, pos + count <= bytes.count else {
                failed = true
                return []
            }
            let slice = Array(bytes[pos..<(pos + count)])
            pos += count
            return slice
        }

        mutating func string(_ count: Int) -> String {
            NibArchive.utf8String(data(count))
        }
    }

    /// UTF-8 bytes to String without Foundation. Archived keys and class
    /// names are ASCII; a label's text is not, so this goes through the
    /// Unicode decoder rather than byte-casting.
    static func utf8String(_ bytes: [UInt8]) -> String {
        var trimmed = bytes
        while let last = trimmed.last, last == 0 { trimmed.removeLast() }
        return String(decoding: trimmed, as: UTF8.self)
    }

    static func parse(_ bytes: [UInt8]) -> NibArchive? {
        // "NIBArchive"
        let magic: [UInt8] = [0x4E, 0x49, 0x42, 0x41, 0x72, 0x63, 0x68, 0x69, 0x76, 0x65]
        guard bytes.count > 50, Array(bytes[0..<10]) == magic else { return nil }

        var head = Cursor(bytes: bytes, pos: 10)
        let formatVersion = head.u32()
        _ = head.u32()                              // coder version (10)
        guard formatVersion == 1 else { return nil }
        let objectCount = Int(head.u32()), objectOffset = Int(head.u32())
        let keyCount = Int(head.u32()), keyOffset = Int(head.u32())
        let valueCount = Int(head.u32()), valueOffset = Int(head.u32())
        let classCount = Int(head.u32()), classOffset = Int(head.u32())
        guard !head.failed else { return nil }

        var classNames: [String] = []
        classNames.reserveCapacity(classCount)
        var c = Cursor(bytes: bytes, pos: classOffset)
        for _ in 0..<classCount {
            let length = c.varint()
            let extraCount = c.varint()
            // The extra i32s are ibtool's archived-ivar-count hints for
            // classes whose layout it knows; nothing here needs them.
            _ = c.data(4 * extraCount)
            classNames.append(c.string(length))
        }
        guard !c.failed else { return nil }

        var keys: [String] = []
        keys.reserveCapacity(keyCount)
        var k = Cursor(bytes: bytes, pos: keyOffset)
        for _ in 0..<keyCount {
            keys.append(k.string(k.varint()))
        }
        guard !k.failed else { return nil }

        var values: [(key: String, value: Value)] = []
        values.reserveCapacity(valueCount)
        var v = Cursor(bytes: bytes, pos: valueOffset)
        for _ in 0..<valueCount {
            let keyIndex = v.varint()
            let type = v.byte()
            let decoded: Value
            switch type {
            case 0: decoded = .integer(Int(Int8(bitPattern: v.byte())))
            case 1: decoded = .integer(Int(Int16(bitPattern: v.u16())))
            case 2: decoded = .integer(Int(Int32(bitPattern: v.u32())))
            case 3: decoded = .integer(Int(Int64(bitPattern: v.u64())))
            case 4: decoded = .boolean(false)
            case 5: decoded = .boolean(true)
            case 6: decoded = .number(Double(Float(bitPattern: v.u32())))
            case 7: decoded = .number(Double(bitPattern: v.u64()))
            case 8: decoded = .bytes(v.data(v.varint()))
            case 9: decoded = .null
            case 10: decoded = .reference(Int(v.u32()))
            default: return nil
            }
            guard keyIndex >= 0, keyIndex < keys.count else { return nil }
            values.append((keys[keyIndex], decoded))
        }
        guard !v.failed else { return nil }

        var objects: [Object] = []
        objects.reserveCapacity(objectCount)
        var o = Cursor(bytes: bytes, pos: objectOffset)
        for _ in 0..<objectCount {
            let classIndex = o.varint()
            let firstValue = o.varint()
            let count = o.varint()
            guard classIndex >= 0, classIndex < classNames.count,
                  firstValue >= 0, count >= 0,
                  firstValue + count <= values.count else { return nil }
            objects.append(Object(
                className: classNames[classIndex],
                values: Array(values[firstValue..<(firstValue + count)])))
        }
        guard !o.failed else { return nil }
        return NibArchive(objects: objects)
    }
}

// MARK: - The class registry

/// Name -> constructor for classes a nib names but the framework cannot see.
///
/// This is the nib-side twin of `SelectorDispatching` (UISelector.swift), and
/// it exists for the same reason: real UIKit calls `NSClassFromString`, which
/// needs an Objective-C runtime with every app class registered in it, and
/// OpenUIKit's portable builds have none. UIKit's own classes are
/// pre-registered below; an app (or a harness — see
/// Sources/RealAppProbe/NibClasses.swift) registers its own.
///
/// LOOKUP accepts either spelling a nib can carry: the Objective-C class name
/// (`UILabel`) or the mangled Swift name `ibtool` writes for a class with a
/// `customModule` (`_TtC8podcasts14ThemeableLabel`). The mangled form is
/// demangled and matched on the CLASS name alone, so a nib compiled against
/// the app's own module resolves against a harness that compiles the same
/// source under a different module name.
@preconcurrency @MainActor
public enum UINibClassRegistry {
    public typealias Constructor = @MainActor () -> AnyObject

    private static var registered: [String: Constructor] = [:]

    /// Register `name` (an unmangled class name) as constructible.
    public static func register(_ name: String, _ constructor: @escaping Constructor) {
        registered[name] = constructor
    }

    /// Construct the class a nib named, or nil if nothing answers to it.
    public static func make(_ archivedName: String) -> AnyObject? {
        constructor(for: archivedName)?()
    }

    /// True when `archivedName` resolves — `UIClassSwapper` asks before
    /// deciding whether to fall back to the archived original class.
    public static func canMake(_ archivedName: String) -> Bool {
        constructor(for: archivedName) != nil
    }

    static func constructor(for archivedName: String) -> Constructor? {
        let name = demangleSwiftClassName(archivedName) ?? archivedName
        if let found = registered[name] { return found }
        return builtIn[name]
    }

    /// `_TtC8podcasts14ThemeableLabel` -> `ThemeableLabel`.
    ///
    /// Swift's legacy class mangling, which is still what Interface Builder
    /// writes into a nib: `_TtC` then length-prefixed module and class names.
    /// A nested or generic class mangles differently and is not handled — such
    /// a nib simply fails to resolve and falls back to its archived UIKit
    /// original class, which is the honest outcome.
    static func demangleSwiftClassName(_ mangled: String) -> String? {
        guard mangled.hasPrefix("_TtC") else { return nil }
        let rest = Array(mangled.dropFirst(4))
        var last: String? = nil
        var index = 0
        while index < rest.count {
            var digits = ""
            while index < rest.count, rest[index].isNumber {
                digits.append(rest[index])
                index += 1
            }
            guard let length = Int(digits), length > 0,
                  index + length <= rest.count else { return last }
            last = String(rest[index..<(index + length)])
            index += length
        }
        return last
    }

    /// UIKit's own classes. A nib names these unmangled, so the archived
    /// name is the key.
    private static let builtIn: [String: Constructor] = [
        "UIView": { UIView() },
        "UILabel": { UILabel() },
        "UIImageView": { UIImageView() },
        "UIButton": { UIButton() },
        "UISwitch": { UISwitch() },
        "UISlider": { UISlider() },
        "UIStepper": { UIStepper() },
        "UIProgressView": { UIProgressView() },
        "UIActivityIndicatorView": { UIActivityIndicatorView() },
        "UISegmentedControl": { UISegmentedControl() },
        "UITextField": { UITextField() },
        "UITextView": { UITextView() },
        "UIStackView": { UIStackView() },
        "UIScrollView": { UIScrollView() },
        "UITableView": { UITableView() },
        "UITableViewCell": { UITableViewCell() },
        "UITableViewCellContentView": { UITableViewCellContentView() },
        "UICollectionViewCell": { UICollectionViewCell() },
        "UIViewController": { UIViewController() },
    ]
}

// MARK: - Outlets

/// A nib-loaded object that can receive its `@IBOutlet` assignments.
///
/// `@IBOutlet` means "@objc property, assigned by KVC", and neither half
/// exists in a portable build (docs/REAL_APP_TEST.md blocker 1). A class whose
/// outlets a nib fills therefore publishes them the way a target publishes its
/// actions: one line per outlet in a table the class owns. The framework's own
/// outlet names (`view`, `delegate`, `dataSource`) are handled by `UINib`
/// without any conformance.
@preconcurrency @MainActor
public protocol UINibOutletConnecting: AnyObject {
    /// Assign `object` to the outlet called `name`. Return false when the
    /// name is unknown, so `UINib` can record it in `unhandledKeys`.
    func setNibOutlet(_ object: AnyObject?, forName name: String) -> Bool
}

// MARK: - UINib

/// A loaded Interface Builder archive that can be instantiated repeatedly.
@preconcurrency @MainActor
open class UINib {
    /// Options accepted by `instantiate(withOwner:options:)`.
    public struct OptionsKey: Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        /// UIKit's `UINib.OptionsKey.externalObjects`. Accepted and ignored:
        /// no fixture nib uses external-object placeholders.
        public static let externalObjects = OptionsKey(rawValue: "UINibExternalObjects")
    }

    /// Archived keys, class names and outlet names no branch below claimed,
    /// in first-seen order, process-wide. This is the measurement that keeps
    /// the gap honest: docs/KNOWN_GAPS.md quotes it for the fixture nibs, and
    /// `openrender realapp` prints it.
    public nonisolated(unsafe) static var unhandledKeys: [String] = []

    static func noteUnhandled(_ what: String) {
        if !unhandledKeys.contains(what) { unhandledKeys.append(what) }
    }

    let archive: NibArchive?
    /// Retained for the diagnostic when a nib is missing.
    public let nibName: String

    /// UIKit's `init(nibName:bundle:)`. The bundle argument is retained for
    /// source compatibility; the file is found on
    /// `OpenUIKitRuntime.nibSearchPaths`, the same contract
    /// `OpenUIKitRuntime.imageSearchPaths` gives `UIImage(named:)` — the
    /// library hardcodes no host paths.
    public init(nibName name: String, bundle: Bundle?) {
        _ = bundle
        nibName = name
        archive = UINib.loadArchive(named: name)
    }

    /// UIKit's `UINib.nib(withNibName:bundle:)`.
    public static func nib(withNibName name: String, bundle: Bundle?) -> UINib {
        UINib(nibName: name, bundle: bundle)
    }

    /// Bytes-in initializer for tests and for hosts that read the archive
    /// themselves. (UIKit's equivalent takes `Data`; OpenUIKit's portable
    /// core has no Foundation, so it takes the bytes.)
    public init(nibBytes bytes: [UInt8], name: String) {
        nibName = name
        archive = NibArchive.parse(bytes)
    }

    static func loadArchive(named name: String) -> NibArchive? {
        let bare = name.hasSuffix(".nib") ? String(name.dropLast(4)) : name
        for directory in OpenUIKitRuntime.nibSearchPaths {
            for candidate in ["\(directory)/\(bare).nib", "\(directory)/\(bare)"] {
                if let bytes = ResourceIO.readFile(candidate),
                   let parsed = NibArchive.parse(bytes) {
                    return parsed
                }
            }
        }
        return nil
    }

    /// True when the archive was found and parsed.
    public var isLoaded: Bool { archive != nil }

    /// UIKit's `instantiate(withOwner:options:)`: the archive's top-level
    /// objects, with `owner` standing in for the File's Owner placeholder and
    /// every outlet connected.
    open func instantiate(withOwner owner: Any?,
                          options: [UINib.OptionsKey: Any]?) -> [Any] {
        _ = options
        guard let archive else {
            fatalError("UINib: no archive for '\(nibName)'; point "
                       + "OpenUIKitRuntime.nibSearchPaths at the directory holding "
                       + "\(nibName).nib")
        }
        return NibDecoder(archive: archive, owner: owner as AnyObject?).instantiate()
    }

    /// Default-argument form, as UIKit declares it.
    open func instantiate(withOwner owner: Any?) -> [Any] {
        instantiate(withOwner: owner, options: nil)
    }
}

public extension OpenUIKitRuntime {
    /// Directories searched for `<name>.nib` by `UINib(nibName:bundle:)`, in
    /// order. EMPTY by default, exactly like `imageSearchPaths`: an app or
    /// host points this at its compiled nibs.
    static var nibSearchPaths: [String] {
        get { _openUIKitNibSearchPaths }
        set { _openUIKitNibSearchPaths = newValue }
    }
}

/// Storage for `OpenUIKitRuntime.nibSearchPaths` (an `enum` extension cannot
/// declare stored state).
nonisolated(unsafe) var _openUIKitNibSearchPaths: [String] = []

// MARK: - The decoder

/// Turns one parsed archive into live objects. One instance per
/// `instantiate(withOwner:options:)` call, so a nib registered with a table
/// hands out a fresh hierarchy per dequeue, as UIKit's does.
@MainActor
final class NibDecoder {
    private let archive: NibArchive
    private let owner: AnyObject?
    /// Memoized per index: an archived object is referenced by its parent, by
    /// the top-level list and by every constraint that names it.
    private var built: [Int: AnyObject] = [:]
    private var building: Set<Int> = []
    /// Every view/controller the archive produced, for the awakeFromNib pass.
    private var awakened: [AnyObject] = []
    /// Constraints wait for the whole hierarchy: activating one needs the
    /// common ancestor of its two items to exist.
    private var deferredConstraints: [NSLayoutConstraint] = []

    init(archive: NibArchive, owner: AnyObject?) {
        self.archive = archive
        self.owner = owner
    }

    func instantiate() -> [Any] {
        // Object 0 is the archive root: a keyed NSObject naming the top-level
        // object list, the flat object list and the connection list.
        guard let root = archive.objects.first else { return [] }

        var topLevel: [Any] = []
        if case .reference(let index)? = root.first("UINibTopLevelObjectsKey") {
            for element in arrayElements(at: index) {
                // The two placeholders (File's Owner, First Responder) are
                // proxies; UIKit does not return them.
                if element is NibProxyPlaceholder { continue }
                topLevel.append(element)
            }
        }

        if case .reference(let index)? = root.first("UINibConnectionsKey") {
            for connection in arrayElements(at: index) {
                (connection as? NibConnection)?.connect()
            }
        }

        NSLayoutConstraint.activate(deferredConstraints)
        deferredConstraints = []

        for object in awakened { (object as? UIResponder)?.awakeFromNib() }
        return topLevel
    }

    // MARK: Object graph

    /// Elements of an archived NSArray/NSMutableArray, in order.
    private func arrayElements(at index: Int) -> [AnyObject] {
        guard index >= 0, index < archive.objects.count else { return [] }
        var out: [AnyObject] = []
        for pair in archive.objects[index].values where pair.key == "UINibEncoderEmptyKey" {
            if case .reference(let child) = pair.value, let made = build(child) {
                out.append(made)
            }
        }
        return out
    }

    private func build(_ index: Int) -> AnyObject? {
        if let existing = built[index] { return existing }
        guard index >= 0, index < archive.objects.count else { return nil }
        // A cycle (a constraint naming the view that owns it) resolves through
        // the memo; entering the same index twice would recurse forever.
        guard !building.contains(index) else { return nil }
        building.insert(index)
        defer { building.remove(index) }
        guard let made = make(archive.objects[index], index: index) else { return nil }
        built[index] = made
        return made
    }

    private func make(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        switch object.className {
        case "NSString":
            if case .bytes(let raw)? = object.first("NS.bytes") {
                return NibString(value: NibArchive.utf8String(raw))
            }
            return NibString(value: "")

        case "NSArray", "NSMutableArray", "NSSet", "NSMutableSet":
            // Materialized on demand by `arrayElements`; the box exists so a
            // reference to the array resolves to something.
            return NibArrayBox(index: index)

        case "UIProxyObject":
            let identifier = string(object.first("UIProxiedObjectIdentifier")) ?? ""
            if identifier == "IBFilesOwner", let owner { return owner }
            return NibProxyPlaceholder(identifier: identifier)

        case "UIClassSwapper":
            return makeSwapped(object, index: index)

        case "UIRuntimeOutletConnection":
            return makeOutletConnection(object)

        case "NSLayoutConstraint":
            return makeConstraint(object)

        case "UIColor":
            return makeColor(object)

        case "UIFont":
            return makeFont(object)

        case "UIImageNibPlaceholder", "UIImage":
            guard let name = string(object.first("UIResourceName")) else { return nil }
            if let image = UIImage(named: name) { return image }
            UINib.noteUnhandled("missing-image:\(name)")
            return nil

        case "_UITableViewCellSeparatorView":
            // The port's cell owns its own separator view and the table sets
            // the inset per style (UITableViewCell.swift); an archived one
            // would be a second, unmanaged separator. Dropped on purpose.
            return NibProxyPlaceholder(identifier: object.className)

        case "NSObject":
            return NibProxyPlaceholder(identifier: object.className)

        default:
            guard let made = UINibClassRegistry.make(object.className) else {
                UINib.noteUnhandled("class:\(object.className)")
                return nil
            }
            built[index] = made
            apply(object, to: made)
            return made
        }
    }

    /// `UIClassSwapper` is how Interface Builder archives "this is really a
    /// `ThemeableLabel`, decode it as a `UILabel`": the archived keys are the
    /// original class's, the instance is the custom class's. Falls back to
    /// `UIOriginalClassName` when the custom class is not registered, which is
    /// what real UIKit does when `NSClassFromString` returns nil.
    private func makeSwapped(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        let custom = string(object.first("UIClassName"))
        let original = string(object.first("UIOriginalClassName"))
        var made: AnyObject? = nil
        if let custom, UINibClassRegistry.canMake(custom) {
            made = UINibClassRegistry.make(custom)
        } else {
            if let custom { UINib.noteUnhandled("unregistered-class:\(custom)") }
            if let original { made = UINibClassRegistry.make(original) }
        }
        guard let made else {
            UINib.noteUnhandled("class:\(custom ?? original ?? "?")")
            return nil
        }
        built[index] = made
        apply(object, to: made)
        return made
    }

    private func makeOutletConnection(_ object: NibArchive.Object) -> AnyObject? {
        func reference(_ key: String) -> AnyObject? {
            guard case .reference(let i)? = object.first(key) else { return nil }
            return build(i)
        }
        guard let name = string(object.first("UILabel")),
              let source = reference("UISource") else { return nil }
        return NibConnection(name: name, source: source,
                             destination: reference("UIDestination"))
    }

    // MARK: Values

    private func string(_ value: NibArchive.Value?) -> String? {
        guard case .reference(let i)? = value,
              let box = build(i) as? NibString else { return nil }
        return box.value
    }

    private func cgFloat(_ value: NibArchive.Value?) -> CGFloat? {
        switch value {
        case .number(let d): return CGFloat(d)
        case .integer(let i): return CGFloat(i)
        default: return nil
        }
    }

    private func int(_ value: NibArchive.Value?) -> Int? {
        switch value {
        case .integer(let i): return i
        case .number(let d): return Int(d)
        case .boolean(let b): return b ? 1 : 0
        default: return nil
        }
    }

    private func bool(_ value: NibArchive.Value?) -> Bool? {
        switch value {
        case .boolean(let b): return b
        case .integer(let i): return i != 0
        default: return nil
        }
    }

    /// An archived CGRect/CGPoint: a one-byte component-encoding tag then
    /// that many components. Tag 7 (f64) is what ibtool writes; tag 6 (f32)
    /// is accepted for completeness.
    private func numbers(_ value: NibArchive.Value?, count: Int) -> [CGFloat]? {
        guard case .bytes(let raw)? = value, raw.count >= 1 else { return nil }
        let width = raw[0] == 7 ? 8 : (raw[0] == 6 ? 4 : 0)
        guard width > 0, raw.count >= 1 + width * count else { return nil }
        var out: [CGFloat] = []
        for i in 0..<count {
            var bits: UInt64 = 0
            for b in 0..<width {
                bits |= UInt64(raw[1 + i * width + b]) << (8 * UInt64(b))
            }
            out.append(width == 8
                       ? CGFloat(Double(bitPattern: bits))
                       : CGFloat(Float(bitPattern: UInt32(truncatingIfNeeded: bits))))
        }
        return out
    }

    /// `"{750, 251}"` — the horizontal/vertical pair Interface Builder writes
    /// for hugging and compression-resistance priorities.
    private func priorityPair(_ value: NibArchive.Value?) -> (CGFloat, CGFloat)? {
        guard let text = string(value) else { return nil }
        var digits = ""
        var found: [CGFloat] = []
        for character in text {
            if character.isNumber || character == "." {
                digits.append(character)
            } else if !digits.isEmpty {
                found.append(CGFloat(Double(digits) ?? 0))
                digits = ""
            }
        }
        if !digits.isEmpty { found.append(CGFloat(Double(digits) ?? 0)) }
        guard found.count >= 2 else { return nil }
        return (found[0], found[1])
    }

    private func makeColor(_ object: NibArchive.Object) -> AnyObject? {
        // A system colour is archived by name AND by the components it
        // resolved to in Interface Builder's light appearance. Prefer the
        // NAME: OpenUIKit's palette is measured per appearance
        // (SystemColors.swift), so taking the archived components would freeze
        // a semantic colour to light mode. IB writes the ObjC accessor
        // (`separatorColor`), the palette is keyed on the Swift property
        // (`separator`), hence the suffix strip.
        if let name = string(object.first("UISystemColorName")) {
            let stripped = name.hasSuffix("Color") && name != "tintColor"
                ? String(name.dropLast(5)) : name
            if SystemColors.isKnown(stripped) {
                return UIColor(semantic: stripped)
            }
            UINib.noteUnhandled("UISystemColorName:\(name)")
        }
        let alpha = cgFloat(object.first("UIAlpha-Double"))
            ?? cgFloat(object.first("UIAlpha")) ?? 1
        if let r = cgFloat(object.first("UIRed-Double")) ?? cgFloat(object.first("UIRed")),
           let g = cgFloat(object.first("UIGreen-Double")) ?? cgFloat(object.first("UIGreen")),
           let b = cgFloat(object.first("UIBlue-Double")) ?? cgFloat(object.first("UIBlue")) {
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        }
        if let white = cgFloat(object.first("UIWhite-Double"))
            ?? cgFloat(object.first("UIWhite")) {
            return UIColor(white: white, alpha: alpha)
        }
        UINib.noteUnhandled("UIColor:components")
        return nil
    }

    /// `UICTFontTextStyleCallout` -> `UIFont.TextStyle.callout`. UIKit's own
    /// raw values; `largeTitle` really is `Title0` and `subheadline` really is
    /// `Subhead`.
    private static let archivedTextStyles: [String: UIFont.TextStyle] = [
        "UICTFontTextStyleTitle0": .largeTitle,
        "UICTFontTextStyleTitle1": .title1,
        "UICTFontTextStyleTitle2": .title2,
        "UICTFontTextStyleTitle3": .title3,
        "UICTFontTextStyleHeadline": .headline,
        "UICTFontTextStyleSubhead": .subheadline,
        "UICTFontTextStyleBody": .body,
        "UICTFontTextStyleCallout": .callout,
        "UICTFontTextStyleFootnote": .footnote,
        "UICTFontTextStyleCaption1": .caption1,
        "UICTFontTextStyleCaption2": .caption2,
    ]

    private func makeFont(_ object: NibArchive.Object) -> AnyObject? {
        let size = cgFloat(object.first("NSSize"))
            ?? cgFloat(object.first("UIFontPointSize")) ?? 17
        // An IB text style means "the preferred font for this style", which is
        // what app code then re-derives with UIFontMetrics anyway.
        if let styleName = string(object.first("UIIBTextStyle")) {
            if let style = NibDecoder.archivedTextStyles[styleName] {
                return NibFontBox(font: UIFont.preferredFont(forTextStyle: style))
            }
            UINib.noteUnhandled("UIIBTextStyle:\(styleName)")
        }
        if let name = string(object.first("UIFontName")) {
            // `.SFUI-Regular` / `.SFUI-Semibold` are the system face; the
            // portable font engine spells it `systemFont(ofSize:weight:)`.
            let lower = name.lowercased()
            if lower.hasPrefix(".sfui") || lower.hasPrefix(".sfns")
                || lower.hasPrefix(".applesystemui") {
                // Substring test on the stdlib alone: `contains("semibold")`
                // is Foundation's StringProtocol overload on Darwin, but the
                // guest compiles against the port's Foundation and picked the
                // _StringProcessing generic instead, adding
                // libswift_StringProcessing.dylib to libOpenUIKit's load
                // list and failing the Focus widget gate on both authorities
                // (GATE_B_FAIL rc=2 "dylib loads changed", 54be0035).
                func has(_ needle: String) -> Bool {
                    var i = lower.startIndex
                    while i < lower.endIndex {
                        if lower[i...].hasPrefix(needle) { return true }
                        i = lower.index(after: i)
                    }
                    return false
                }
                let weight: UIFont.Weight =
                    has("semibold") ? .semibold
                    : (has("bold") ? .bold
                       : (has("medium") ? .medium : .regular))
                return NibFontBox(font: UIFont.systemFont(ofSize: size, weight: weight))
            }
            // A bundled custom face has no portable loader (the font engine
            // is fed explicit paths, OpenUIKitRuntime.fontPaths); recorded
            // rather than silently substituted.
            UINib.noteUnhandled("UIFontName:\(name)")
        }
        return NibFontBox(font: UIFont.systemFont(ofSize: size))
    }

    private func makeConstraint(_ object: NibArchive.Object) -> AnyObject? {
        func item(_ key: String) -> AnyObject? {
            guard case .reference(let i)? = object.first(key) else { return nil }
            return build(i)
        }
        func attribute(_ v2: String, _ v1: String) -> NSLayoutConstraint.Attribute {
            // V2 keeps the margin attributes (leadingMargin = 17); the legacy
            // key collapses them onto the plain edge, so V2 wins when present.
            for key in [v2, v1] {
                if let raw = int(object.first(key)),
                   let attribute = NSLayoutConstraint.Attribute(rawValue: raw) {
                    return attribute
                }
            }
            return .notAnAttribute
        }
        // IB archives a margin constraint TWICE: the modern form (V2 attribute
        // `leadingMargin`, constant 0) and a pre-iOS-8 fallback that spends the
        // old 8 pt default margin as a plain `leading` constant. So the
        // constant has to come from the same generation as the attribute, and
        // an absent `NSConstantV2` beside a V2 attribute means zero, not
        // "inherit `NSConstant`".
        //
        // MEASURED (SwitchCell.nib #28, `imageView.leading` ==
        // `contentView.{leadingMargin, V2} / {leading, legacy}`, NSConstant 8,
        // no NSConstantV2): the golden puts that image view at x = 20, which
        // is the content view's 20 pt leading margin plus nothing. Reading the
        // legacy pair put it at 16 and dragged every label in both nib cells
        // 4 pt left with it.
        let isV2 = object.first("NSFirstAttributeV2") != nil
            || object.first("NSSecondAttributeV2") != nil
        let constant = isV2
            ? cgFloat(object.first("NSConstantV2")) ?? 0
            : cgFloat(object.first("NSConstant")) ?? 0
        guard let first = item("NSFirstItem") else {
            UINib.noteUnhandled("NSLayoutConstraint:NSFirstItem")
            return nil
        }
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: attribute("NSFirstAttributeV2", "NSFirstAttribute"),
            relatedBy: NSLayoutConstraint.Relation(
                rawValue: int(object.first("NSRelation")) ?? 0) ?? .equal,
            toItem: item("NSSecondItem"),
            attribute: attribute("NSSecondAttributeV2", "NSSecondAttribute"),
            multiplier: cgFloat(object.first("NSMultiplier")) ?? 1,
            constant: constant)
        if let priority = cgFloat(object.first("NSPriority")) {
            constraint.priority = UILayoutPriority(Float(priority))
        }
        if let identifier = string(object.first("NSLayoutIdentifier")) {
            constraint.identifier = identifier
        }
        return constraint
    }

    // MARK: Applying archived keys

    private func apply(_ object: NibArchive.Object, to target: AnyObject) {
        if let view = target as? UIView {
            applyView(object, to: view)
            awakened.append(view)
        } else if let controller = target as? UIViewController {
            awakened.append(controller)
        }
    }

    /// UIKit's `UIViewContentMode` raw values (UIView.h), which the port's
    /// `UIViewContentMode` spells as cases without raw values.
    private static let archivedContentModes: [UIViewContentMode] = [
        .scaleToFill, .scaleAspectFit, .scaleAspectFill, .redraw, .center,
        .top, .bottom, .left, .right, .topLeft, .topRight, .bottomLeft,
        .bottomRight,
    ]
    /// `NSTextAlignment` raw values on iOS (left = 0, centre = 1, right = 2,
    /// justified = 3, natural = 4).
    private static let archivedAlignments: [NSTextAlignment] = [
        .left, .center, .right, .justified, .natural,
    ]
    /// `NSLineBreakMode` raw values.
    private static let archivedLineBreaks: [NSLineBreakMode] = [
        .byWordWrapping, .byCharWrapping, .byClipping,
        .byTruncatingHead, .byTruncatingTail, .byTruncatingMiddle,
    ]

    private func applyView(_ object: NibArchive.Object, to view: UIView) {
        // Bounds + centre, UIKit's archived spelling of `frame`. Applied
        // FIRST so a subview's autoresizing starts from the right size.
        if let bounds = numbers(object.first("UIBounds"), count: 4) {
            if let center = numbers(object.first("UICenter"), count: 2) {
                view.frame = CGRect(x: center[0] - bounds[2] / 2,
                                    y: center[1] - bounds[3] / 2,
                                    width: bounds[2], height: bounds[3])
            } else {
                view.frame = CGRect(x: 0, y: 0, width: bounds[2], height: bounds[3])
            }
        }

        // A UITableViewCell's `contentView` is `let` in the port (and is the
        // view its layoutSubviews positions), so the archived content view is
        // BOUND to the live one before anything else can construct a second
        // one: every constraint that names the archived index then resolves to
        // the view that is really in the hierarchy. UIKit reaches the same
        // shape through `-setContentView:` while decoding.
        var boundContentView = false
        if let cell = view as? UITableViewCell,
           case .reference(let contentIndex)? = object.first("UIContentView"),
           contentIndex >= 0, contentIndex < archive.objects.count {
            built[contentIndex] = cell.contentView
            applyView(archive.objects[contentIndex], to: cell.contentView)
            awakened.append(cell.contentView)
            // The nib's cell has no textLabel/imageView (`UITextLabel` and
            // `UIImageView` decode as nil); the port creates them eagerly in
            // `init(style:)`, so take them out of the hierarchy or they show
            // up as two extra views in every layout dump.
            cell.textLabel?.removeFromSuperview()
            cell.imageView?.removeFromSuperview()
            boundContentView = true
        }

        for pair in object.values {
            switch pair.key {
            case "UIBounds", "UICenter",
                 // Class-swap bookkeeping, read by `makeSwapped`.
                 "UIClassName", "UIOriginalClassName",
                 // Archived state the port models elsewhere, or that has no
                 // effect on a rendered frame. Listed so the silence is a
                 // decision rather than an omission.
                 "UIDeepDrawRect", "UIViewSemanticContentAttribute",
                 "UIViewLargeContentStoredProperties", "UISystemBackgroundView",
                 "UIContentConfigurationView", "UITextLabel", "UIDetailTextLabel",
                 "UIImageView", "UIPrefetchingEnabled", "UIFillerRowHeight",
                 "UIInsetsContentViewsToSafeArea",
                 "UIScrollViewIndicatorInsetAdjustmentBehavior",
                 "UIScrollViewContentInsetAdjustmentBehavior",
                 "UIShadowOffset", "UIHighlightedColor", "UIBaselineAdjustment",
                 "UIAutoresizeSubviews", "UISelectionStyle", "UIIndentationWidth",
                 "UIDisableUpdateTextColorOnTraitCollectionChange",
                 "UIStyle", "UISeparatorStyleIOS5AndLater", "UIBouncesZoom",
                 "UIMultipleTouchEnabled", "UIClearsContextBeforeDrawing",
                 "UISectionHeaderTopPadding",
                 "UIAdjustsFontSizeToFit", "UIEnabled":
                continue

            case "UIAutoresizingMask":
                if let raw = int(pair.value) {
                    view.autoresizingMask = UIView.AutoresizingMask(rawValue: UInt(raw))
                }
            case "UIClipsToBounds":
                if let flag = bool(pair.value) { view.clipsToBounds = flag }
            case "UIOpaque":
                if let flag = bool(pair.value) { view.isOpaque = flag }
            case "UIHidden":
                if let flag = bool(pair.value) { view.isHidden = flag }
            case "UIAlpha":
                if let alpha = cgFloat(pair.value) { view.alpha = alpha }
            case "UITag":
                if let tag = int(pair.value) { view.tag = tag }
            case "UIUserInteractionDisabled":
                if let flag = bool(pair.value) { view.isUserInteractionEnabled = !flag }
            case "UIBackgroundColor":
                if case .reference(let i) = pair.value {
                    view.backgroundColor = build(i) as? UIColor
                }
            case "UIViewDoesNotTranslateAutoresizingMaskIntoConstraints":
                if let flag = bool(pair.value) {
                    view.translatesAutoresizingMaskIntoConstraints = !flag
                }
            case "UIViewContentHuggingPriority":
                if let (h, v) = priorityPair(pair.value) {
                    view.setContentHuggingPriority(UILayoutPriority(Float(h)), for: .horizontal)
                    view.setContentHuggingPriority(UILayoutPriority(Float(v)), for: .vertical)
                }
            case "UIViewContentCompressionResistancePriority":
                if let (h, v) = priorityPair(pair.value) {
                    view.setContentCompressionResistancePriority(
                        UILayoutPriority(Float(h)), for: .horizontal)
                    view.setContentCompressionResistancePriority(
                        UILayoutPriority(Float(v)), for: .vertical)
                }
            case "UIViewAutolayoutConstraints":
                if case .reference(let i) = pair.value {
                    for element in arrayElements(at: i) {
                        if let constraint = element as? NSLayoutConstraint {
                            deferredConstraints.append(constraint)
                        }
                    }
                }
            case "UISubviews":
                guard !boundContentView, case .reference(let i) = pair.value else { continue }
                for element in arrayElements(at: i) {
                    if let sub = element as? UIView { view.addSubview(sub) }
                }
            case "UIContentView":
                continue
            case "UIContentMode":
                if let raw = int(pair.value),
                   raw >= 0, raw < NibDecoder.archivedContentModes.count {
                    view.contentMode = NibDecoder.archivedContentModes[raw]
                }
            default:
                applySpecific(pair, to: view)
            }
        }
    }

    /// Per-class archived keys.
    private func applySpecific(_ pair: (key: String, value: NibArchive.Value),
                               to view: UIView) {
        if let label = view as? UILabel {
            switch pair.key {
            case "UIText":
                if let text = string(pair.value) { label.text = text }
                return
            case "UIFont":
                if case .reference(let i) = pair.value,
                   let box = build(i) as? NibFontBox { label.font = box.font }
                return
            case "UITextColor":
                if case .reference(let i) = pair.value,
                   let color = build(i) as? UIColor { label.textColor = color }
                return
            case "UINumberOfLines":
                if let n = int(pair.value) { label.numberOfLines = n }
                return
            case "UITextAlignment":
                if let raw = int(pair.value),
                   raw >= 0, raw < NibDecoder.archivedAlignments.count {
                    label.textAlignment = NibDecoder.archivedAlignments[raw]
                }
                return
            case "UILineBreakMode":
                if let raw = int(pair.value),
                   raw >= 0, raw < NibDecoder.archivedLineBreaks.count {
                    label.lineBreakMode = NibDecoder.archivedLineBreaks[raw]
                }
                return
            case "UIAdjustsFontForContentSizeCategory":
                if let flag = bool(pair.value) {
                    label.adjustsFontForContentSizeCategory = flag
                }
                return
            default: break
            }
        }
        if let imageView = view as? UIImageView {
            if pair.key == "UIImage" {
                if case .reference(let i) = pair.value {
                    imageView.image = build(i) as? UIImage
                }
                return
            }
        }
        if let table = view as? UITableView {
            switch pair.key {
            case "UITableViewStyle":
                // UIKit's UITableViewStyle: plain = 0, grouped = 1,
                // insetGrouped = 2.
                if let raw = int(pair.value) {
                    let styles: [UITableView.Style] = [.plain, .grouped, .insetGrouped]
                    if raw >= 0, raw < styles.count { table._setArchivedStyle(styles[raw]) }
                }
                return
            case "UIRowHeight":
                if let h = cgFloat(pair.value) { table.rowHeight = h }
                return
            case "UIEstimatedRowHeight":
                if let h = cgFloat(pair.value) { table.estimatedRowHeight = h }
                return
            case "UIEstimatedSectionHeaderHeight":
                if let h = cgFloat(pair.value) { table.estimatedSectionHeaderHeight = h }
                return
            case "UIEstimatedSectionFooterHeight":
                if let h = cgFloat(pair.value) { table.estimatedSectionFooterHeight = h }
                return
            case "UISectionHeaderHeight":
                if let h = cgFloat(pair.value) { table.sectionHeaderHeight = h }
                return
            case "UISectionFooterHeight":
                if let h = cgFloat(pair.value) { table.sectionFooterHeight = h }
                return
            case "UISeparatorColor":
                if case .reference(let i) = pair.value {
                    table.separatorColor = (build(i) as? UIColor)
                }
                return
            case "UISeparatorInsetReference":
                // Present whenever IB has an opinion, and an opinion is
                // exactly what makes the inset explicit. The three fixture
                // nibs all archive a zero inset (no `UISeparatorInset` key),
                // so a non-zero one stays unhandled rather than guessed —
                // there is nothing to measure its encoding against.
                if let raw = int(pair.value),
                   let reference = UITableView.SeparatorInsetReference(rawValue: raw) {
                    table.separatorInsetReference = reference
                    table.separatorInset = .zero
                }
                return
            case "UISeparatorStyle":
                // UIKit: none = 0, singleLine = 1 (the etched styles are
                // deprecated aliases of singleLine).
                if let raw = int(pair.value) {
                    table.separatorStyle = raw == 0 ? .none : .singleLine
                }
                return
            default: break
            }
        }
        if let scroll = view as? UIScrollView {
            switch pair.key {
            case "UIAlwaysBounceVertical":
                if let flag = bool(pair.value) { scroll.alwaysBounceVertical = flag }
                return
            case "UIAlwaysBounceHorizontal":
                if let flag = bool(pair.value) { scroll.alwaysBounceHorizontal = flag }
                return
            case "UIShowsHorizontalScrollIndicator":
                if let flag = bool(pair.value) { scroll.showsHorizontalScrollIndicator = flag }
                return
            case "UIShowsVerticalScrollIndicator":
                if let flag = bool(pair.value) { scroll.showsVerticalScrollIndicator = flag }
                return
            case "UIDelaysContentTouches", "UICanCancelContentTouches":
                return
            default: break
            }
        }
        if let control = view as? UISwitch, pair.key == "UISwitchOn" {
            if let flag = bool(pair.value) { control.isOn = flag }
            return
        }
        UINib.noteUnhandled("\(type(of: view)).\(pair.key)")
    }
}

// MARK: - Decoder-internal boxes

/// An archived NSString. Distinct from `String` so a reference to it can be
/// carried in the decoder's `AnyObject` memo.
final class NibString {
    let value: String
    init(value: String) { self.value = value }
}

/// An archived UIFont. `UIFont` is a value type in the portable core (UIKit's
/// is a class), so it needs a box to live in the `AnyObject` memo.
final class NibFontBox {
    let font: UIFont
    init(font: UIFont) { self.font = font }
}

/// A reference to an archived array; the elements are materialized on demand
/// by `NibDecoder.arrayElements`.
final class NibArrayBox {
    let index: Int
    init(index: Int) { self.index = index }
}

/// A placeholder for an archived object OpenUIKit deliberately does not build
/// (the First Responder proxy, the cell's own separator view, a missing
/// File's Owner). Never returned to the caller.
final class NibProxyPlaceholder {
    let identifier: String
    init(identifier: String) { self.identifier = identifier }
}

/// One archived `UIRuntimeOutletConnection`.
@MainActor
final class NibConnection {
    let name: String
    let source: AnyObject
    let destination: AnyObject?

    init(name: String, source: AnyObject, destination: AnyObject?) {
        self.name = name
        self.source = source
        self.destination = destination
    }

    func connect() {
        let target = destination is NibProxyPlaceholder ? nil : destination
        // Framework-owned outlet names first: UIKit fills these through KVC
        // on its own classes, where no app-owned table exists to publish them.
        if let controller = source as? UIViewController, name == "view" {
            controller.view = target as? UIView
            return
        }
        if let table = source as? UITableView, name == "dataSource" {
            table.dataSource = target as? UITableViewDataSource
            return
        }
        // A table's `delegate` IS the inherited scroll-view delegate, as in
        // UIKit (UITableViewDelegate refines UIScrollViewDelegate).
        if let scroll = source as? UIScrollView, name == "delegate" {
            scroll.delegate = target as? UIScrollViewDelegate
            return
        }
        if let receiver = source as? UINibOutletConnecting,
           receiver.setNibOutlet(target, forName: name) {
            return
        }
        UINib.noteUnhandled("outlet:\(type(of: source)).\(name)")
    }
}
