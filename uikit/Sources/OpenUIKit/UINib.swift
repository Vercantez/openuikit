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
// HOW OBJECTS ARE BUILT. Real UIKit decodes each archived object through
// `NSCoding`: `[[cls alloc] initWithCoder:nibDecoder]`. OpenUIKit does the
// same for every class it can find at run time (UINibCoder.swift): an app's
// custom view or controller is looked up by its archived name
// (`objc_lookUpClass` on an Objective-C runtime, `_typeByName` elsewhere) and
// built with its own `required init?(coder:)`, handed a `UINibCoder`
// positioned on its archived keys. The framework's `UIView.init?(coder:)` and
// `UIViewController.init?(coder:)` then decode the archived state, so the
// app's initializer body after `super.init(coder:)` sees it, exactly as on
// iOS (MEASURED, Tools/oracle2/nibruntimeprobe: a custom view's frame and
// background are already decoded when its `init(coder:)` returns).
//
// UIKit's own classes the archive names directly (`UILabel`, `UIView`, …)
// are built through a name -> factory registry (`UINibClassRegistry`) and the
// archived keys applied with a switch — the path the Pocket Casts fixture
// screens have been measured on since this file was written. An app can still
// register a factory for a custom class (the realapp harness does, for nibs
// compiled against a module it renames); a registration wins over run-time
// lookup. An archived key this file does not know is skipped —
// `UINib.unhandledKeys` records every one, so the gap is countable rather than
// silent.

#if canImport(ObjectiveC)
import ObjectiveC
#endif
#if canImport(Foundation)
import struct Foundation.Data
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

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

    /// True when an app registered a factory for `archivedName` (as opposed
    /// to a built-in UIKit class): an explicit registration beats run-time
    /// class lookup.
    static func isRegistered(_ archivedName: String) -> Bool {
        registered[demangleSwiftClassName(archivedName) ?? archivedName] != nil
    }

    /// Module renames for run-time lookup: `["Kiosk": "Eidolon"]` makes an
    /// archive compiled for the app's own module (`_TtC5Kiosk…`) resolve
    /// against the same source compiled under a different module name. Real
    /// UIKit has no such table because Xcode compiles the storyboard with the
    /// module the classes live in; a port that renames the module needs it.
    public static var moduleAliases: [String: String] = [:]

    /// `_TtC5Kiosk17AppViewController` -> ("Kiosk", ["AppViewController"]),
    /// following nested-class context letters (`C` class, `O` enum, `V`
    /// struct) the way Swift's legacy ObjC-name mangling writes them.
    static func legacyMangledComponents(_ mangled: String) -> (kinds: [Character], names: [String])? {
        guard mangled.hasPrefix("_Tt") else { return nil }
        let chars = Array(mangled.dropFirst(3))
        var kinds: [Character] = []
        var index = 0
        while index < chars.count, "COV".contains(chars[index]) {
            kinds.append(chars[index])
            index += 1
        }
        guard !kinds.isEmpty else { return nil }
        var names: [String] = []
        while index < chars.count {
            var digits = ""
            while index < chars.count, chars[index].isNumber {
                digits.append(chars[index])
                index += 1
            }
            guard let length = Int(digits), length > 0, index + length <= chars.count else { return nil }
            names.append(String(chars[index..<(index + length)]))
            index += length
        }
        // One module name plus one name per context letter.
        guard names.count == kinds.count + 1 else { return nil }
        return (kinds, names)
    }

    /// The archived name with its module replaced per `moduleAliases`, in
    /// legacy mangling (for `objc_lookUpClass`) — nil when nothing changes.
    static func aliasedLegacyName(_ archivedName: String) -> String? {
        guard let (kinds, names) = legacyMangledComponents(archivedName),
              let alias = moduleAliases[names[0]] else { return nil }
        var out = "_Tt" + String(kinds)
        for name in [alias] + names.dropFirst() { out += "\(name.utf8.count)\(name)" }
        return out
    }

    /// Swift's current mangling of the same nominal type, which the runtime's
    /// `_typeByName` accepts: `_TtC5Kiosk17AppViewController` ->
    /// `5Kiosk17AppViewControllerC`; a nested `_TtCO4main5Outer5Inner` ->
    /// `4main5OuterO5InnerC`. (MEASURED with swiftc 6.2.1: `_typeByName`
    /// returns nil for the legacy spelling and the type for this one.)
    static func currentMangledName(_ legacy: String) -> String? {
        guard let (kinds, names) = legacyMangledComponents(legacy) else { return nil }
        var out = "\(names[0].utf8.count)\(names[0])"
        // Legacy writes the context letters outermost-last; the current
        // mangling appends each context's letter after its name, innermost
        // last.
        for (offset, name) in names.dropFirst().enumerated() {
            out += "\(name.utf8.count)\(name)"
            out.append(kinds[kinds.count - 1 - offset])
        }
        return out
    }

    /// The class an archive names, found at run time the way UIKit's
    /// `NSClassFromString` finds it. Only for names the registry does not
    /// answer (UIKit's own classes stay on the registry path).
    static func runtimeClass(_ archivedName: String) -> AnyClass? {
        var candidates = [archivedName]
        if let aliased = aliasedLegacyName(archivedName) { candidates.append(aliased) }
        for name in candidates {
#if canImport(ObjectiveC)
            if let found = name.withCString({ objc_lookUpClass($0) }) { return found }
#endif
            if let current = currentMangledName(name),
               let type = _typeByName(current) as? AnyClass {
                return type
            }
        }
        return nil
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
        // iOS 7-10 top/bottom layout guides, archived as hidden views in
        // storyboards saved before safe areas (all of Eidolon's scenes).
        "_UILayoutGuide": { _UILayoutGuide() },
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
        /// UIKit's `UINib.OptionsKey.externalObjects`: a `[String: Any]`
        /// mapping each `UIProxyObject` identifier the archive names to the
        /// object that stands in for it. A storyboard hands its scene nibs
        /// `UIStoryboardPlaceholder` this way, and a storyboard controller
        /// hands its view nib the `UpstreamPlaceholder-N` table it archived.
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

    /// UIKit's `init(nibName:bundle:)`. The file is found on
    /// `OpenUIKitRuntime.nibSearchPaths` first — the same contract
    /// `OpenUIKitRuntime.imageSearchPaths` gives `UIImage(named:)`, so the
    /// library hardcodes no host paths — and then in the bundle's resource
    /// directory (the main bundle for nil), which is where Xcode puts it.
    public init(nibName name: String, bundle: Bundle?) {
        nibName = name
        archive = UINib.loadArchive(named: name, bundle: bundle)
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

    /// A nib read from an exact file path (a storyboard's scene archives).
    init(path: String) {
        nibName = path
        archive = ResourceIO.readFile(path).flatMap(NibArchive.parse)
    }

#if canImport(Foundation)
    /// UIKit's `init(data:bundle:)`.
    public convenience init(data: Data, bundle: Bundle?) {
        _ = bundle
        self.init(nibBytes: [UInt8](data), name: "<data>")
    }
#endif

    static func loadArchive(named name: String, bundle: Bundle? = nil) -> NibArchive? {
        let bare = name.hasSuffix(".nib") ? String(name.dropLast(4)) : name
        var directories = OpenUIKitRuntime.nibSearchPaths
        if let resources = _resourceDirectory(of: bundle) { directories.append(resources) }
        for directory in directories {
            // Xcode writes a nib either as a flat NIBArchive file or, for a
            // nib with device-specific variants, as a `.nib` directory whose
            // `runtime.nib` is the archive.
            for candidate in ["\(directory)/\(bare).nib", "\(directory)/\(bare)",
                              "\(directory)/\(bare).nib/runtime.nib"] {
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
    /// objects, with `owner` standing in for the File's Owner placeholder,
    /// `options[.externalObjects]` for the other placeholders, and every
    /// connection made.
    open func instantiate(withOwner owner: Any?,
                          options: [UINib.OptionsKey: Any]?) -> [Any] {
        guard let archive else {
            fatalError("UINib: no archive for '\(nibName)'; point "
                       + "OpenUIKitRuntime.nibSearchPaths at the directory holding "
                       + "\(nibName).nib")
        }
        var externals: [String: AnyObject] = [:]
        if let table = options?[.externalObjects] as? [String: Any] {
            for (key, value) in table { externals[key] = value as AnyObject }
        }
        return NibDecoder(archive: archive, owner: owner as AnyObject?,
                          externalObjects: externals).instantiate()
    }

    /// Default-argument form, as UIKit declares it.
    open func instantiate(withOwner owner: Any?) -> [Any] {
        instantiate(withOwner: owner, options: nil)
    }
}

extension Bundle {
    /// UIKit's `-[NSBundle loadNibNamed:owner:options:]`: the same load as
    /// `UINib(nibName:bundle:).instantiate(withOwner:options:)` (MEASURED
    /// identical top-level objects and owner outlets in the nibruntime2
    /// oracle), from this bundle.
    @MainActor
    public func loadNibNamed(_ name: String, owner: Any?,
                             options: [UINib.OptionsKey: Any]? = nil) -> [Any]? {
        UINib(nibName: name, bundle: self).instantiate(withOwner: owner, options: options)
    }
}

/// A bundle's resource directory as a path, without Foundation's `Bundle`
/// API surface differences between the package build and the guest shim.
@MainActor
func _resourceDirectory(of bundle: Bundle?) -> String? {
#if canImport(Foundation)
    return (bundle ?? Bundle.main).resourcePath
#elseif canImport(FoundationEssentials)
    return (bundle ?? Bundle.main).resourcePath
#else
    _ = bundle
    return nil
#endif
}

public extension OpenUIKitRuntime {
    /// Directories searched for `<name>.nib` by `UINib(nibName:bundle:)`, and
    /// for `<name>.storyboardc` by `UIStoryboard(name:bundle:)`, in order,
    /// before the bundle's own resources. EMPTY by default, exactly like
    /// `imageSearchPaths`: an app or host points this at its compiled nibs.
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
///
/// ORDER, MEASURED on iOS 26.1 (Tools/oracle2/nibruntimeprobe,
/// fixtures/nibruntime/oracle): every object is decoded first — top-level
/// objects in archive order, each one's `init(coder:)` decoding what it
/// references — then the archive's key-value pairs (user-defined runtime
/// attributes) are set, then the connections are made in archive order, and
/// finally `awakeFromNib` goes to every object in `UINibObjectsKey` order.
@MainActor
final class NibDecoder {
    let archive: NibArchive
    let owner: AnyObject?
    let externalObjects: [String: AnyObject]
    /// Memoized per index: an archived object is referenced by its parent, by
    /// the top-level list and by every constraint that names it.
    var built: [Int: AnyObject] = [:]
    var building: Set<Int> = []
    /// Every object the archive produced, in construction order — the
    /// awakeFromNib order when an archive has no `UINibObjectsKey`.
    var awakened: [AnyObject] = []
    /// Constraints wait for the whole hierarchy: activating one needs the
    /// common ancestor of its two items to exist.
    var deferredConstraints: [NSLayoutConstraint] = []
    /// Constraints whose constant is IB's symbolic standard spacing.
    var symbolicSpacings: [(NSLayoutConstraint, AnyObject, AnyObject?)] = []

    init(archive: NibArchive, owner: AnyObject?, externalObjects: [String: AnyObject] = [:]) {
        self.archive = archive
        self.owner = owner
        self.externalObjects = externalObjects
    }

    func instantiate() -> [Any] {
        // Object 0 is the archive root: a keyed NSObject naming the top-level
        // object list, the flat object list and the connection list.
        guard let root = archive.objects.first else { return [] }

        var topLevel: [Any] = []
        if case .reference(let index)? = root.first("UINibTopLevelObjectsKey") {
            for element in arrayElements(at: index) {
                // Placeholders (File's Owner, First Responder, external
                // objects) are proxies; UIKit does not return them.
                if isPlaceholder(element) { continue }
                topLevel.append(element)
            }
        }
        var objectOrder: [AnyObject]? = nil
        if case .reference(let index)? = root.first("UINibObjectsKey") {
            objectOrder = arrayElements(at: index)
        }

        if case .reference(let index)? = root.first("UINibKeyValuePairsKey") {
            for pair in arrayElements(at: index) {
                (pair as? NibKeyValuePair)?.apply()
            }
        }

        if case .reference(let index)? = root.first("UINibConnectionsKey") {
            for connection in arrayElements(at: index) {
                (connection as? NibConnecting)?.connect()
            }
        }

        resolveSymbolicSpacings()
        NSLayoutConstraint.activate(deferredConstraints)
        deferredConstraints = []

        var seen = Set<ObjectIdentifier>()
        for object in objectOrder ?? awakened {
            guard !isPlaceholder(object), seen.insert(ObjectIdentifier(object)).inserted else { continue }
            NibDecoder.sendAwakeFromNib(object)
        }
        return topLevel
    }

    func isPlaceholder(_ object: AnyObject) -> Bool {
        if object is NibProxyPlaceholder { return true }
        if let owner, object === owner { return true }
        for value in externalObjects.values where value === object { return true }
        return false
    }

    /// `awakeFromNib` is declared on NSObject on Apple platforms (AppKit's /
    /// UIKit's NSNibAwaking category) and on UIResponder in OpenUIKit
    /// everywhere; a custom archived NSObject gets it too (MEASURED:
    /// `Helper.awakeFromNib` fires for an IB "Object").
    static func sendAwakeFromNib(_ object: AnyObject) {
        if let responder = object as? UIResponder {
            responder.awakeFromNib()
            return
        }
#if canImport(AppKit)
        (object as? NSObject)?.awakeFromNib()
#elseif canImport(ObjectiveC)
        let selector = sel_registerName("awakeFromNib")
        if let nsobject = object as? NSObject, nsobject.responds(to: selector) {
            _ = nsobject.perform(selector)
        }
#endif
    }

    // MARK: Object graph

    /// Elements of an archived NSArray/NSMutableArray/NSSet, in order.
    func arrayElements(at index: Int) -> [AnyObject] {
        guard index >= 0, index < archive.objects.count else { return [] }
        var out: [AnyObject] = []
        for pair in archive.objects[index].values where pair.key == "UINibEncoderEmptyKey" {
            if case .reference(let child) = pair.value, let made = build(child) {
                out.append(made)
            }
        }
        return out
    }

    /// An archived NSDictionary: `UINibEncoderEmptyKey` entries alternate
    /// key, value (MEASURED on UIExternalObjectsTableForViewLoading and
    /// UIButtonStatefulContent).
    func dictionaryPairs(at index: Int) -> [(key: AnyObject, value: AnyObject)] {
        let flat = arrayElements(at: index)
        var out: [(key: AnyObject, value: AnyObject)] = []
        var i = 0
        while i + 1 < flat.count {
            out.append((flat[i], flat[i + 1]))
            i += 2
        }
        return out
    }

    func build(_ index: Int) -> AnyObject? {
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

    /// Register an object under construction (from inside its
    /// `init(coder:)`) so references back to it resolve.
    func register(_ object: AnyObject, at index: Int) {
        if built[index] == nil {
            built[index] = object
            awakened.append(object)
        }
    }

    func make(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        switch object.className {
        case "NSString", "NSMutableString":
            if case .bytes(let raw)? = object.first("NS.bytes") {
                return NibString(value: NibArchive.utf8String(raw))
            }
            return NibString(value: "")

        case "NSArray", "NSMutableArray", "NSSet", "NSMutableSet", "NSOrderedSet",
             "NSMutableOrderedSet":
            // Materialized on demand by `arrayElements`; the box exists so a
            // reference to the array resolves to something.
            return NibArrayBox(index: index)

        case "NSDictionary", "NSMutableDictionary":
            return NibDictionaryBox(index: index)

        case "NSData", "NSMutableData":
            if case .bytes(let raw)? = object.first("NS.bytes") { return NibDataBox(bytes: raw) }
            return NibDataBox(bytes: [])

        case "UINib":
            // A nib archived inside a nib: a storyboard table's prototype
            // cells (`UITableViewCellPrototypeNibs`), `archiveData` holding a
            // complete NIBArchive.
            guard let data = self.object(object.first("archiveData")) as? NibDataBox else {
                UINib.noteUnhandled("UINib:archiveData")
                return nil
            }
            return UINib(nibBytes: data.bytes, name: "<prototype>")

        case "UITabBarItem":
            let item = UITabBarItem(title: string(object.first("UITitle")),
                                    image: self.object(object.first("UIImage")) as? UIImage,
                                    tag: int(object.first("UITag")) ?? 0)
            if let enabled = bool(object.first("UIEnabled")) { item.isEnabled = enabled }
            return item

        case "NSNumber":
            for pair in object.values {
                switch pair.value {
                case .integer(let i): return NibNumberBox(value: Double(i), isInteger: true)
                case .number(let d): return NibNumberBox(value: d, isInteger: false)
                case .boolean(let b): return NibNumberBox(value: b ? 1 : 0, isInteger: true)
                default: continue
                }
            }
            return NibNumberBox(value: 0, isInteger: true)

        case "NSValue":
            return makeValue(object)

        case "NSAttributedString", "NSMutableAttributedString":
            // The characters only: attribute runs are not decoded yet.
            if object.first("NSAttributes") != nil {
                UINib.noteUnhandled("NSAttributedString.NSAttributes")
            }
            return NibString(value: string(object.first("NSString")) ?? "")

        case "UIProxyObject":
            let identifier = string(object.first("UIProxiedObjectIdentifier")) ?? ""
            if identifier == "IBFilesOwner", let owner { return owner }
            if let external = externalObjects[identifier] { return external }
            if identifier != "IBFirstResponder" && identifier != "IBFilesOwner" {
                UINib.noteUnhandled("external-object:\(identifier)")
            }
            return NibProxyPlaceholder(identifier: identifier)

        case "UIClassSwapper":
            return makeSwapped(object, index: index)

        case "UIRuntimeOutletConnection":
            return makeOutletConnection(object)

        case "UIRuntimeOutletCollectionConnection":
            return makeOutletCollectionConnection(object)

        case "UIRuntimeEventConnection":
            return makeEventConnection(object)

        case "UINibKeyValuePair":
            return makeKeyValuePair(object)

        case "NSLayoutConstraint", "_UILayoutSupportConstraint", "NSContentSizeLayoutConstraint":
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

        case "UIButtonContent":
            return makeButtonContent(object)

        case "UISegment":
            return NibSegmentBox(title: string(object.first("UISegmentInfo")))

        case "UINavigationItem":
            return makeNavigationItem(object, index: index)

        case "UIBarButtonItem":
            return makeBarButtonItem(object, index: index)

        case "UITapGestureRecognizer", "UILongPressGestureRecognizer", "UIPanGestureRecognizer",
             "UISwipeGestureRecognizer", "UIPinchGestureRecognizer",
             "UIRotationGestureRecognizer", "UIScreenEdgePanGestureRecognizer":
            return makeGestureRecognizer(object, index: index)

        case "UIStoryboardShowSegueTemplate", "UIStoryboardPushSegueTemplate",
             "UIStoryboardModalSegueTemplate", "UIStoryboardPresentationSegueTemplate",
             "UIStoryboardEmbedSegueTemplate", "UIStoryboardSegueTemplate",
             "UIStoryboardPopoverPresentationSegueTemplate",
             "UIStoryboardUnwindSegueTemplate":
            return makeSegueTemplate(object)

        case "_UITableViewCellSeparatorView":
            // The port's cell owns its own separator view and the table sets
            // the inset per style (UITableViewCell.swift); an archived one
            // would be a second, unmanaged separator. Dropped on purpose.
            return NibProxyPlaceholder(identifier: object.className)

        case "UILayoutGuide":
            return makeLayoutGuide(object)

        case "NSObject", "UITapRecognizer", "UIFontDescriptor",
             "NSMutableParagraphStyle", "NSParagraphStyle", "UIRuntimeAccessibilityConfiguration":
            // Archive bookkeeping or values read through their owner's keys
            // (a tap recognizer's `_imp`, a font's descriptor, the safe-area
            // guide's own record); never handed to app code on their own.
            return NibProxyPlaceholder(identifier: object.className)

        case "UICustomObject":
            // An IB "Object" with no custom class: a plain NSObject.
            let plain = NSObject()
            register(plain, at: index)
            return plain

        default:
            return makeClass(named: object.className, object: object, index: index)
        }
    }

    /// Build an instance of the archived class `name`: a registered factory
    /// or a built-in UIKit class through the registry; otherwise the class
    /// found at run time through its own `init(coder:)`.
    func makeClass(named name: String, object: NibArchive.Object, index: Int) -> AnyObject? {
        if let controller = NibDecoder.builtInControllers[name] {
            return makeWithCoder(controller, index: index)
        }
        if UINibClassRegistry.canMake(name) {
            guard let made = makeRegistered(name, object: object) else { return nil }
            built[index] = made
            awakened.append(made)
            apply(object, to: made)
            return made
        }
        if let cls = UINibClassRegistry.runtimeClass(name) {
            return makeRuntime(cls, name: name, index: index)
        }
        UINib.noteUnhandled("class:\(name)")
        return nil
    }

    /// A registry construction. A `UIButton` is built with its archived type
    /// (UIKit decodes `UIButtonType` inside `initWithCoder:`; the registry
    /// path constructs first, so the type has to be chosen here).
    func makeRegistered(_ name: String, object: NibArchive.Object) -> AnyObject? {
        // UIKit raw values: custom = 0, system = 1.
        if name == "UIButton", int(object.first("UIButtonType")) == 1 {
            return UIButton(type: .system)
        }
        // `style` is fixed at construction too: UIActivityIndicatorViewStyle
        // medium = 100, large = 101 (UIActivityIndicatorView.h).
        if name == "UIActivityIndicatorView", int(object.first("UIActivityIndicatorViewStyle-Modern")) == 101 {
            return UIActivityIndicatorView(style: .large)
        }
        return UINibClassRegistry.make(name)
    }

    /// UIKit's own controller classes, always built through
    /// `init(coder:)` so the archived controller state (nib name, navigation
    /// item, segue templates, children) is decoded the same way for a plain
    /// storyboard controller as for an app subclass.
    static let builtInControllers: [String: UIViewController.Type] = [
        "UIViewController": UIViewController.self,
        "UINavigationController": UINavigationController.self,
        "UITableViewController": UITableViewController.self,
        "UICollectionViewController": UICollectionViewController.self,
        "UITabBarController": UITabBarController.self,
        "UIPageViewController": UIPageViewController.self,
        "UISplitViewController": UISplitViewController.self,
    ]

    /// A run-time class: a view or controller through `init(coder:)`, any
    /// other NSObject through `init()` (MEASURED: an IB custom "Object" gets
    /// `init()`, never `init(coder:)` — `Helper.init()` in the oracle log).
    func makeRuntime(_ cls: AnyClass, name: String, index: Int) -> AnyObject? {
        if let viewType = cls as? UIView.Type {
            return makeWithCoder(viewType, index: index)
        }
        if let controllerType = cls as? UIViewController.Type {
            return makeWithCoder(controllerType, index: index)
        }
#if canImport(ObjectiveC)
        // `init()` is the Objective-C root initializer every NSObject
        // subclass answers; swift-corelibs' NSObject does not make it
        // `required`, so a native Linux build cannot call it through a
        // metatype.
        if let objectType = cls as? NSObject.Type {
            let made = objectType.init()
            register(made, at: index)
            return made
        }
#endif
        UINib.noteUnhandled("uninstantiable-class:\(name)")
        return nil
    }

    func makeWithCoder(_ type: UIView.Type, index: Int) -> AnyObject? {
        let coder = UINibCoder(decoder: self, index: index)
        guard let made = type.init(coder: coder) else { return nil }
        // A `required convenience init(coder:)` that delegates to a
        // programmatic initializer never reaches UIView.init(coder:), so
        // nothing archived was applied — and UIKit applies nothing either.
        register(made, at: index)
        return made
    }

    func makeWithCoder(_ type: UIViewController.Type, index: Int) -> AnyObject? {
        let coder = UINibCoder(decoder: self, index: index)
        guard let made = type.init(coder: coder) else { return nil }
        register(made, at: index)
        return made
    }

    /// `UIClassSwapper` is how Interface Builder archives "this is really a
    /// `ThemeableLabel`, decode it as a `UILabel`": the archived keys are the
    /// original class's, the instance is the custom class's. Falls back to
    /// `UIOriginalClassName` when the custom class cannot be found, which is
    /// what real UIKit does when `NSClassFromString` returns nil (it logs
    /// "Unknown class … in Interface Builder file").
    func makeSwapped(_ object: NibArchive.Object, index: Int) -> AnyObject? {
        let custom = string(object.first("UIClassName"))
        let original = string(object.first("UIOriginalClassName"))
        if let custom, custom != original {
            if UINibClassRegistry.isRegistered(custom) {
                return makeClass(named: custom, object: object, index: index)
            }
            if UINibClassRegistry.constructor(for: custom) == nil,
               NibDecoder.builtInControllers[custom] == nil,
               let cls = UINibClassRegistry.runtimeClass(custom) {
                return makeRuntime(cls, name: custom, index: index)
            }
            if UINibClassRegistry.canMake(custom) || NibDecoder.builtInControllers[custom] != nil {
                return makeClass(named: custom, object: object, index: index)
            }
            UINib.noteUnhandled("unregistered-class:\(custom)")
        }
        guard let original else {
            UINib.noteUnhandled("class:\(custom ?? "?")")
            return nil
        }
        if original == "UICustomObject" {
            let plain = NSObject()
            register(plain, at: index)
            return plain
        }
        return makeClass(named: original, object: object, index: index)
    }

    // MARK: Values

    func string(_ value: NibArchive.Value?) -> String? {
        guard case .reference(let i)? = value,
              let box = build(i) as? NibString else { return nil }
        return box.value
    }

    func cgFloat(_ value: NibArchive.Value?) -> CGFloat? {
        switch value {
        case .number(let d): return CGFloat(d)
        case .integer(let i): return CGFloat(i)
        default: return nil
        }
    }

    func int(_ value: NibArchive.Value?) -> Int? {
        switch value {
        case .integer(let i): return i
        case .number(let d): return Int(d)
        case .boolean(let b): return b ? 1 : 0
        default: return nil
        }
    }

    func bool(_ value: NibArchive.Value?) -> Bool? {
        switch value {
        case .boolean(let b): return b
        case .integer(let i): return i != 0
        default: return nil
        }
    }

    func object(_ value: NibArchive.Value?) -> AnyObject? {
        guard case .reference(let i)? = value else { return nil }
        return build(i)
    }

    /// An archived CGRect/CGPoint: a one-byte component-encoding tag then
    /// that many components. Tag 7 (f64) is what ibtool writes; tag 6 (f32)
    /// is accepted for completeness.
    func numbers(_ value: NibArchive.Value?, count: Int) -> [CGFloat]? {
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

    /// Every number in a string, in order: `"{750, 251}"`,
    /// `"{{16, 290}, {51, 31}}"`.
    static func numbersIn(_ text: String) -> [CGFloat] {
        var digits = ""
        var found: [CGFloat] = []
        for character in text {
            if character.isNumber || character == "." || (character == "-" && digits.isEmpty) {
                digits.append(character)
            } else if !digits.isEmpty {
                if let d = Double(digits) { found.append(CGFloat(d)) }
                digits = ""
            }
        }
        if !digits.isEmpty, let d = Double(digits) { found.append(CGFloat(d)) }
        return found
    }

    /// `"{750, 251}"` — the horizontal/vertical pair Interface Builder writes
    /// for hugging and compression-resistance priorities.
    func priorityPair(_ value: NibArchive.Value?) -> (CGFloat, CGFloat)? {
        guard let text = string(value) else { return nil }
        let found = NibDecoder.numbersIn(text)
        guard found.count >= 2 else { return nil }
        return (found[0], found[1])
    }

    /// `NSValue` as ibtool archives a rect (`NS.special` 3,
    /// `NS.rectval = "{{x, y}, {w, h}}"`) or point (1) / size (2).
    func makeValue(_ object: NibArchive.Object) -> AnyObject? {
        for key in ["NS.rectval", "NS.pointval", "NS.sizeval"] {
            if let text = string(object.first(key)) {
                return NibValueBox(key: key, numbers: NibDecoder.numbersIn(text))
            }
        }
        UINib.noteUnhandled("NSValue")
        return nil
    }

    func makeColor(_ object: NibArchive.Object) -> AnyObject? {
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
    static let archivedTextStyles: [String: UIFont.TextStyle] = [
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

    func makeFont(_ object: NibArchive.Object) -> AnyObject? {
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

    func makeConstraint(_ object: NibArchive.Object) -> AnyObject? {
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
        guard let first = item("NSFirstItem"), !(first is NibProxyPlaceholder) else {
            UINib.noteUnhandled("NSLayoutConstraint:NSFirstItem")
            return nil
        }
        var second = item("NSSecondItem")
        if second is NibProxyPlaceholder {
            UINib.noteUnhandled("NSLayoutConstraint:NSSecondItem")
            second = nil
        }
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: attribute("NSFirstAttributeV2", "NSFirstAttribute"),
            relatedBy: NSLayoutConstraint.Relation(
                rawValue: int(object.first("NSRelation")) ?? 0) ?? .equal,
            toItem: second,
            attribute: attribute("NSSecondAttributeV2", "NSSecondAttribute"),
            multiplier: cgFloat(object.first("NSMultiplier")) ?? 1,
            constant: constant)
        if let priority = cgFloat(object.first("NSPriority")) {
            constraint.priority = UILayoutPriority(Float(priority))
        }
        if let identifier = string(object.first("NSLayoutIdentifier")) {
            constraint.identifier = identifier
        }
        if let symbol = string(object.first("NSSymbolicConstant")) {
            if symbol == "NSSpace" {
                symbolicSpacings.append((constraint, first, second))
            } else {
                UINib.noteUnhandled("NSSymbolicConstant:\(symbol)")
            }
        }
        return constraint
    }

    /// Interface Builder's "Standard" spacing (`NSSymbolicConstant =
    /// NSSpace`, no numeric constant archived), resolved once the hierarchy
    /// exists. MEASURED on iOS 26.1 with Eidolon's archives
    /// (fixtures/nibruntime/oracle/eidolonnibs.json): a button's top to its
    /// superview's top resolves to 20 (Sb3-CP-VQj, Jj5-n3-bv0: y = 20), a
    /// button's leading to its sibling text view's trailing to 8
    /// (yff-WV-ozf: x = 781 = 773 + 8).
    func resolveSymbolicSpacings() {
        for (constraint, first, second) in symbolicSpacings {
            let a = first as? UIView, b = second as? UIView
            let toSuperview = (a != nil && a?.superview === b) || (b != nil && b?.superview === a)
            constraint.constant = toSuperview ? 20 : 8
        }
        symbolicSpacings = []
    }

    /// An archived layout guide. A view's safe-area guide is archived with
    /// identifier `UIViewSafeAreaLayoutGuide` and its owning view, and
    /// constraints to it must bind to that view's live guide.
    func makeLayoutGuide(_ object: NibArchive.Object) -> AnyObject? {
        let identifier = string(object.first("UILayoutGuideIdentifier")) ?? ""
        let owner = self.object(object.first("UILayoutGuideOwningView")) as? UIView
        switch (identifier, owner) {
        case ("UIViewSafeAreaLayoutGuide", let view?):
            return view.safeAreaLayoutGuide
        case ("UIViewLayoutMarginsGuide", let view?):
            return view.layoutMarginsGuide
        case ("", nil):
            // The unowned, unarchived guide ibtool writes beside a scene's
            // safe area; nothing refers to it.
            return NibProxyPlaceholder(identifier: "UILayoutGuide")
        default:
            UINib.noteUnhandled("UILayoutGuide:\(identifier)")
            return NibProxyPlaceholder(identifier: "UILayoutGuide")
        }
    }

    // MARK: Connections and key-value pairs

    func makeOutletConnection(_ object: NibArchive.Object) -> AnyObject? {
        guard let name = string(object.first("UILabel")),
              let source = self.object(object.first("UISource")) else { return nil }
        return NibConnection(name: name, source: source,
                             destination: self.object(object.first("UIDestination")))
    }

    func makeOutletCollectionConnection(_ object: NibArchive.Object) -> AnyObject? {
        guard let name = string(object.first("UILabel")),
              let source = self.object(object.first("UISource")),
              case .reference(let list)? = object.first("UIDestination") else { return nil }
        return NibCollectionConnection(
            name: name, source: source,
            destinations: arrayElements(at: list).filter { !($0 is NibProxyPlaceholder) },
            appends: bool(object.first("addsContentToExistingCollection")) ?? false)
    }

    func makeEventConnection(_ object: NibArchive.Object) -> AnyObject? {
        guard let name = string(object.first("UILabel")),
              let source = self.object(object.first("UISource")) else { return nil }
        let destination = self.object(object.first("UIDestination"))
        return NibEventConnection(
            selectorName: name, source: source,
            // The First Responder placeholder means "nil target": the
            // responder chain answers at send time.
            destination: destination is NibProxyPlaceholder ? nil : destination,
            eventMask: UInt(truncatingIfNeeded: int(object.first("UIEventMask")) ?? 0))
    }

    func makeKeyValuePair(_ object: NibArchive.Object) -> AnyObject? {
        guard let target = self.object(object.first("UIObject")),
              let keyPath = string(object.first("UIKeyPath")) else { return nil }
        return NibKeyValuePair(target: target, keyPath: keyPath,
                               value: self.object(object.first("UIValue")))
    }

    func makeButtonContent(_ object: NibArchive.Object) -> AnyObject? {
        let content = NibButtonContentBox()
        content.title = string(object.first("UITitle"))
        content.titleColor = self.object(object.first("UITitleColor")) as? UIColor
        content.shadowColor = self.object(object.first("UIShadowColor")) as? UIColor
        content.image = self.object(object.first("UIImage")) as? UIImage
        content.backgroundImage = self.object(object.first("UIBackgroundImage")) as? UIImage
        if object.first("UIAttributedTitle") != nil {
            content.title = content.title ?? string(object.first("UIAttributedTitle"))
        }
        return content
    }
}

// MARK: - Decoder-internal boxes

/// An archived NSString. Distinct from `String` so a reference to it can be
/// carried in the decoder's `AnyObject` memo.
final class NibString {
    let value: String
    init(value: String) { self.value = value }
}

/// An archived NSNumber.
final class NibNumberBox {
    let value: Double
    let isInteger: Bool
    init(value: Double, isInteger: Bool) {
        self.value = value
        self.isInteger = isInteger
    }
}

/// An archived NSValue (rect / point / size components).
final class NibValueBox {
    let key: String
    let numbers: [CGFloat]
    init(key: String, numbers: [CGFloat]) {
        self.key = key
        self.numbers = numbers
    }
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

/// A reference to an archived dictionary (`NibDecoder.dictionaryPairs`).
final class NibDictionaryBox {
    let index: Int
    init(index: Int) { self.index = index }
}

/// An archived NSData.
final class NibDataBox {
    let bytes: [UInt8]
    init(bytes: [UInt8]) { self.bytes = bytes }
}

/// One `UIButtonContent`: a button's per-state title / colours / images.
final class NibButtonContentBox {
    var title: String?
    var titleColor: UIColor?
    var shadowColor: UIColor?
    var image: UIImage?
    var backgroundImage: UIImage?
}

/// One archived `UISegment` (a segmented control's segment record).
final class NibSegmentBox {
    let title: String?
    init(title: String?) { self.title = title }
}

/// A placeholder for an archived object OpenUIKit deliberately does not build
/// (the First Responder proxy, the cell's own separator view, a missing
/// File's Owner, archive bookkeeping). Never returned to the caller.
final class NibProxyPlaceholder {
    let identifier: String
    init(identifier: String) { self.identifier = identifier }
}
