// CoreText font registration and UIFont(name:size:). Owner: text module.
//
// Real apps ship their own fonts and register them at run time
// (`CTFontManagerRegisterFontsForURL`), then ask for them by PostScript name
// (`UIFont(name:size:)`). Kickstarter's design system does exactly that with
// the Inter variable fonts in its bundle (KDS/Fonts/CustomFont.swift), and
// asserts when the lookup returns nil.
//
// MEASURED iPhone 16 / iOS 26.1 (Tools/oracle2/iososswallsprobe `ct.*`, with
// the app's own Inter-VariableFont.ttf and Inter-Italic-VariableFont.ttf):
//
//   * before registration every Inter name is nil;
//   * registering each file returns true; registering a file again returns
//     false with CTFontManagerError 105 (alreadyRegistered); a missing file
//     returns false with 101 (fileNotFound);
//   * after registration the family is "Inter" and its names are the
//     default instance's PostScript name ("Inter-Regular", "Inter-Italic")
//     plus one name per other named instance, `<default>_<subfamily>` with
//     spaces turned into hyphens ("Inter-Regular_SemiBold",
//     "Inter-Italic_Bold-Italic"); the family name alone resolves to the
//     upright default ("Inter" → "Inter-Regular"); "Inter-SemiBold" and
//     "Inter-Medium" stay nil;
//   * Inter-Regular 16 pt: ascender 15.5, descender −3.859375, leading 0,
//     lineHeight 19.359375, capHeight 11.640625, xHeight 8.6796875 — the
//     file's hhea / OS/2 values scaled by 16 / unitsPerEm; every named
//     instance reports the same vertical metrics.
//
// What OpenUIKit does with a registered face: metrics come from the file
// exactly as above; glyphs are drawn from the file at the named instance's
// fvar coordinates. Advances come from the file's DEFAULT instance and pair
// kerning (GPOS) is not applied — Apple's "Next" in Inter-Regular 16 is
// 35.025 pt and in Inter-Regular_SemiBold 36.05 pt; here both measure the
// default instance's advances. Recorded in docs/KNOWN_GAPS.md.
//
// System fonts by PostScript name ("Helvetica", …) are not available: the
// port ships no font files of its own, so `UIFont(name:size:)` answers only
// for registered fonts (Apple resolves "Helvetica" to Helvetica, measured in
// ios-oss-launch.md).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - SFNT reader (the few tables registration needs)

/// The name / metric / named-instance tables of one font file.
struct SFNTFaceInfo {
    struct Instance {
        var subfamily: String
        var postScriptName: String?
        var coordinates: [UInt32: Double]
    }
    var unitsPerEm: Double = 1000
    var ascender: Double = 0
    var descender: Double = 0
    var lineGap: Double = 0
    var capHeight: Double = 0
    var xHeight: Double = 0
    var familyName: String?
    var subfamilyName: String?
    var postScriptName: String?
    var axisDefaults: [UInt32: Double] = [:]
    var axisOrder: [UInt32] = []
    var instances: [Instance] = []

    init?(bytes: [UInt8]) {
        func u16(_ o: Int) -> Int? { o >= 0 && o + 2 <= bytes.count ? Int(bytes[o]) << 8 | Int(bytes[o + 1]) : nil }
        func i16(_ o: Int) -> Int? { u16(o).map { $0 >= 0x8000 ? $0 - 0x10000 : $0 } }
        func u32(_ o: Int) -> UInt32? {
            guard o >= 0, o + 4 <= bytes.count else { return nil }
            return UInt32(bytes[o]) << 24 | UInt32(bytes[o + 1]) << 16 | UInt32(bytes[o + 2]) << 8 | UInt32(bytes[o + 3])
        }
        func fixed(_ o: Int) -> Double? { u32(o).map { Double(Int32(bitPattern: $0)) / 65536 } }
        guard let version = u32(0), version == 0x0001_0000 || version == 0x7472_7565 || version == 0x4F54_544F,
              let numTables = u16(4) else { return nil }
        var tables: [String: Int] = [:]
        for i in 0..<numTables {
            let rec = 12 + 16 * i
            guard let tag = u32(rec), let off = u32(rec + 8) else { return nil }
            let chars = [UInt8(tag >> 24), UInt8(tag >> 16 & 0xFF), UInt8(tag >> 8 & 0xFF), UInt8(tag & 0xFF)]
            tables[String(decoding: chars, as: UTF8.self)] = Int(off)
        }
        guard let head = tables["head"], let upem = u16(head + 18), upem > 0,
              let hhea = tables["hhea"] else { return nil }
        unitsPerEm = Double(upem)
        ascender = Double(i16(hhea + 4) ?? 0)
        descender = Double(i16(hhea + 6) ?? 0)
        lineGap = Double(i16(hhea + 8) ?? 0)
        if let os2 = tables["OS/2"], let v = u16(os2), v >= 2 {
            capHeight = Double(i16(os2 + 88) ?? 0)
            xHeight = Double(i16(os2 + 86) ?? 0)
        }
        var names: [Int: String] = [:]
        if let name = tables["name"], let count = u16(name + 2), let strOff = u16(name + 4) {
            for i in 0..<count {
                let r = name + 6 + 12 * i
                guard let platform = u16(r), let encoding = u16(r + 2), let nameID = u16(r + 6),
                      let length = u16(r + 8), let offset = u16(r + 10) else { continue }
                let start = name + strOff + offset
                guard start >= 0, start + length <= bytes.count else { continue }
                let raw = Array(bytes[start..<(start + length)])
                var s: String?
                if platform == 3 || platform == 0 {
                    var units: [UInt16] = []
                    var k = 0
                    while k + 1 < raw.count { units.append(UInt16(raw[k]) << 8 | UInt16(raw[k + 1])); k += 2 }
                    s = String(decoding: units, as: UTF16.self)
                } else if platform == 1 && encoding == 0 {
                    s = String(decoding: raw, as: UTF8.self)
                }
                // Prefer Windows/Unicode English strings; keep the first found.
                if let s, names[nameID] == nil || platform == 3 { names[nameID] = s }
            }
        }
        familyName = names[16] ?? names[1]
        subfamilyName = names[17] ?? names[2]
        postScriptName = names[6]
        if let fvar = tables["fvar"], let axesOff = u16(fvar + 4), let axisCount = u16(fvar + 8),
           let axisSize = u16(fvar + 10), let instanceCount = u16(fvar + 12), let instanceSize = u16(fvar + 14) {
            for a in 0..<axisCount {
                let r = fvar + axesOff + a * axisSize
                guard let tag = u32(r), let def = fixed(r + 8) else { continue }
                axisOrder.append(tag)
                axisDefaults[tag] = def
            }
            let instBase = fvar + axesOff + axisCount * axisSize
            for i in 0..<instanceCount {
                let r = instBase + i * instanceSize
                guard let subID = u16(r) else { continue }
                var coords: [UInt32: Double] = [:]
                for (a, tag) in axisOrder.enumerated() {
                    if let v = fixed(r + 4 + 4 * a) { coords[tag] = v }
                }
                var psName: String?
                if instanceSize >= 4 + 4 * axisCount + 2, let psID = u16(r + 4 + 4 * axisCount), psID != 0xFFFF {
                    psName = names[psID]
                }
                instances.append(Instance(subfamily: names[subID] ?? "", postScriptName: psName, coordinates: coords))
            }
        }
    }

    /// The PostScript names CoreText vends for this file, each with the fvar
    /// coordinates of its instance (empty for a static font). See the file
    /// header for the measured naming rule.
    func vendedFaces() -> [(name: String, coordinates: [UInt32: Double])] {
        guard let base = postScriptName else { return [] }
        var out: [(String, [UInt32: Double])] = [(base, axisDefaults)]
        var seen: Set<String> = [base]
        for inst in instances {
            if inst.coordinates == axisDefaults { continue }
            let name = inst.postScriptName
                ?? base + "_" + inst.subfamily.split(separator: " ").joined(separator: "-")
            if seen.insert(name).inserted { out.append((name, inst.coordinates)) }
        }
        return out
    }
}

// MARK: - Registry

/// One registered PostScript face.
final class RegisteredFontFace: @unchecked Sendable {
    let postScriptName: String
    let familyName: String
    let path: String
    let coordinates: [UInt32: Double]
    let info: SFNTFaceInfo
    let isDefaultInstance: Bool

    init(postScriptName: String, familyName: String, path: String,
         coordinates: [UInt32: Double], info: SFNTFaceInfo, isDefaultInstance: Bool) {
        self.postScriptName = postScriptName
        self.familyName = familyName
        self.path = path
        self.coordinates = coordinates
        self.info = info
        self.isDefaultInstance = isDefaultInstance
    }

    /// The instance coordinates CoreText uses at `pointSize`: the named
    /// instance's axes, plus the optical-size axis set to the point size
    /// (CoreText's automatic optical sizing), clamped to the axis range by
    /// the normaliser.
    func coordsKey(in gf: GlyphFont, pointSize: CGFloat) -> Int {
        guard let vars = gf.variations else { return 0 }
        var user = coordinates
        let opsz: UInt32 = 0x6F70_737A
        if info.axisDefaults[opsz] != nil { user[opsz] = Double(pointSize) }
        guard !user.isEmpty else { return 0 }
        return gf.registerCoords(vars.normalizedCoords(user))
    }

    /// The x-height in font units at `pointSize`. MEASURED (Inter-Regular
    /// 16 pt): CoreText reports 8.6796875 = 1111 / 2048 × 16 — the top of
    /// the "x" glyph at the optical size in use, not OS/2 sxHeight (1118).
    func xHeightUnits(pointSize: CGFloat) -> Double {
        if let gf = GlyphRasterizer.load([path]),
           let top = gf.glyphTop(of: "x", coordsKey: coordsKey(in: gf, pointSize: pointSize)) {
            return top
        }
        return info.xHeight
    }

    func metrics(pointSize: CGFloat) -> FontMetrics {
        let s = pointSize / CGFloat(info.unitsPerEm)
        let asc = CGFloat(info.ascender) * s
        let desc = CGFloat(info.descender) * s
        let gap = CGFloat(info.lineGap) * s
        return FontMetrics(ascender: asc, descender: desc, lineHeight: asc - desc + gap,
                           capHeight: CGFloat(info.capHeight) * s, xHeight: CGFloat(xHeightUnits(pointSize: pointSize)) * s,
                           leading: gap)
    }
}

/// Process-scope font registrations (`CTFontManagerScope.process`).
public enum OpenUIKitFontRegistry {
    nonisolated(unsafe) static var faces: [String: RegisteredFontFace] = [:]
    nonisolated(unsafe) static var registeredPaths: Set<String> = []
    nonisolated(unsafe) static var familyOrder: [String] = []

    /// CTFontManagerError codes (CTFontManager.h).
    public enum RegistrationError: Int, Error, Sendable {
        case fileNotFound = 101
        case invalidFontData = 104
        case alreadyRegistered = 105
    }

    /// Register every face in the font file at `path`.
    public static func register(path: String) -> Result<[String], RegistrationError> {
        if registeredPaths.contains(path) { return .failure(.alreadyRegistered) }
        guard let bytes = ResourceIO.readFile(path) else { return .failure(.fileNotFound) }
        guard let info = SFNTFaceInfo(bytes: bytes) else { return .failure(.invalidFontData) }
        let vended = info.vendedFaces()
        guard !vended.isEmpty else { return .failure(.invalidFontData) }
        let family = info.familyName ?? vended[0].name
        for (i, face) in vended.enumerated() {
            faces[face.name] = RegisteredFontFace(postScriptName: face.name, familyName: family, path: path,
                                                  coordinates: face.coordinates, info: info,
                                                  isDefaultInstance: i == 0)
        }
        registeredPaths.insert(path)
        if !familyOrder.contains(family) { familyOrder.append(family) }
        return .success(vended.map(\.name))
    }

    static func face(named name: String) -> RegisteredFontFace? {
        if let f = registeredFace(named: name) { return f }
        // A font the app registered with Apple's CoreText directly (an
        // Objective-C pod: Artsy+UIFonts' CTFontManagerRegisterGraphicsFont)
        // is adopted on first use (CoreTextFontAdoption.swift).
        guard _adoptCoreTextFace(named: name) else { return nil }
        return registeredFace(named: name)
    }

    static func registeredFace(named name: String) -> RegisteredFontFace? {
        if let f = faces[name] { return f }
        // A family name resolves to its upright default instance (measured:
        // "Inter" → "Inter-Regular").
        let candidates = faces.values.filter { $0.familyName == name && $0.isDefaultInstance }
        return candidates.first { !$0.postScriptName.localizedLowercaseContainsItalic }
            ?? candidates.sorted { $0.postScriptName < $1.postScriptName }.first
    }

    /// Register a font file held in memory under `key` (a name that is not
    /// a real path). Same result codes as `register(path:)`.
    public static func register(bytes: [UInt8], key: String) -> Result<[String], RegistrationError> {
        ResourceIO.memoryFiles[key] = bytes
        return register(path: key)
    }

    /// Test hook: forget every registration.
    public static func _resetForTesting() {
        faces = [:]
        registeredPaths = []
        familyOrder = []
    }
}

private extension String {
    var localizedLowercaseContainsItalic: Bool { lowercased().contains("italic") }
}

// MARK: - UIFont by name

extension UIFont {
    /// UIKit's `UIFont(name:size:)`: a registered PostScript (or family)
    /// name, else nil. `size <= 0` means 12 pt, as in UIKit's documentation
    /// of CTFontCreateWithName.
    public convenience init?(name fontName: String, size fontSize: CGFloat) {
        guard let face = OpenUIKitFontRegistry.face(named: fontName) else { return nil }
        self.init(pointSize: fontSize > 0 ? fontSize : 12, weight: .regular, design: .default,
                  customFontName: face.postScriptName)
    }

    /// The registered face backing this font, if it is not the system font.
    var _registeredFace: RegisteredFontFace? {
        customFontName.flatMap { OpenUIKitFontRegistry.faces[$0] }
    }

    /// UIKit's `fontName`. iOS 26.1: `.SFUI-Regular`, `.SFUI-Semibold`,
    /// `.SFUI-Bold` for the system font at those weights; a registered face
    /// reports its PostScript name.
    /// `boldSystemFont(ofSize:)` is `.SFUI-Semibold` and
    /// `italicSystemFont(ofSize:)` `.SFUI-RegularItalic` (iOS 26.1,
    /// objcsurfaceprobe `## font` / `## identity`).
    public var fontName: String {
        if let customFontName { return customFontName }
        let w = isSymbolicBold ? UIFont.Weight.semibold.name : weight.name
        let name = ".SFUI-" + w.prefix(1).uppercased() + w.dropFirst()
        return design == .italic ? name + "Italic" : name
    }

    /// UIKit's `familyName` (iOS 26.1: `.AppleSystemUIFont` for the system
    /// font; the registered family otherwise).
    public var familyName: String {
        _registeredFace?.familyName ?? ".AppleSystemUIFont"
    }

    /// Registered family names (UIKit also lists the installed system
    /// families, which the port does not ship).
    public static var familyNames: [String] { OpenUIKitFontRegistry.familyOrder }

    public static func fontNames(forFamilyName familyName: String) -> [String] {
        OpenUIKitFontRegistry.faces.values.filter { $0.familyName == familyName }
            .map(\.postScriptName).sorted()
    }
}

// MARK: - CoreText surface

/// SFNT layout feature constants (SFNTLayoutTypes.h; iOS 26.1 values read
/// by iososswallsprobe `ct.*`).
public var kNumberSpacingType: Int { 6 }
public var kMonospacedNumbersSelector: Int { 0 }
public var kProportionalNumbersSelector: Int { 1 }
public var kStylisticAlternativesType: Int { 35 }
public var kStylisticAltOneOnSelector: Int { 2 }
public var kStylisticAltTwoOnSelector: Int { 4 }

/// CoreText's `CTFontManagerScope` (iOS 26.1: `.process` raw 1).
public enum CTFontManagerScope: UInt32, Sendable {
    case none = 0
    case process = 1
    case persistent = 2
    case session = 3
    public static let user = CTFontManagerScope.persistent
}

#if canImport(Foundation) && canImport(ObjectiveC)
import Foundation
import CoreFoundation

/// CoreText's error domain for font-manager failures.
public let kCTFontManagerErrorDomain = "com.apple.CoreText.CTFontManagerErrorDomain" as CFString

/// CoreText's `CTFontManagerRegisterFontsForURL`. Every scope registers for
/// this process (there is no other process to share with).
public func CTFontManagerRegisterFontsForURL(_ fontURL: CFURL, _ scope: CTFontManagerScope,
                                             _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Bool {
    let url = fontURL as URL
    switch OpenUIKitFontRegistry.register(path: url.path) {
    case .success:
        return true
    case .failure(let code):
        error?.pointee = Unmanaged.passRetained(
            CFErrorCreate(kCFAllocatorDefault, kCTFontManagerErrorDomain, CFIndex(code.rawValue), nil))
        return false
    }
}
#endif
