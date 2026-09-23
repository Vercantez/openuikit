// Fonts registered with Apple's CoreText, seen by OpenUIKit's registry.
//
// On an Apple toolchain an app's Objective-C code registers fonts with the
// real CoreText: Artsy+UIFonts 3.1.3 (Eidolon) reads each .ttf, builds a
// CGFont and calls `CTFontManagerRegisterGraphicsFont`, then asks
// `+[UIFont fontWithName:size:]` for "AGaramondPro-Regular". OpenUIKit's
// registry (CTFontManager.swift) knew only faces registered through its own
// `CTFontManagerRegisterFontsForURL`, so that lookup answered nil and the
// labels fell back to the system face.
//
// MEASURED kioskrowsprobe `## font` (iPad Pro 11-inch M4 / iOS 26.1, the
// pod's own EBGaramond12-Regular.ttf): before registration
// `fontWithName:@"AGaramondPro-Regular"` is nil; after it the font is
// "AGaramondPro-Regular" / family "Adobe Garamond Pro"; a second
// registration fails with kCTFontManagerErrorAlreadyRegistered (305 on
// iOS 26.1); the family name resolves to the same face.
//
// A name OpenUIKit's registry does not know is looked up in CoreText. It is
// adopted only when CoreText resolves it to a font whose PostScript or
// family name IS that name (CoreText answers every unknown name with a
// fallback — "NoSuchFont" gives Helvetica) and which the process registered
// itself: no file URL (registered from bytes) or a URL outside the system
// font directories. Installed system fonts ("Helvetica") stay unavailable,
// as they are on the guest, which ships no font files (CTFontManager.swift).
// The face's SFNT tables are copied back out of CoreText into an in-memory
// font file and registered like any other: metrics and glyphs come from
// those bytes.

#if canImport(CoreText) && canImport(Foundation)
// Scoped imports, as elsewhere in OpenUIKit: CoreGraphics' names must not
// collide with OpenCoreGraphics' in this file.
import struct Foundation.URL
import struct Foundation.Data
import CoreFoundation
import func CoreText.CTFontCreateWithName
import func CoreText.CTFontCopyPostScriptName
import func CoreText.CTFontCopyFamilyName
import func CoreText.CTFontCopyAttribute
import func CoreText.CTFontCopyAvailableTables
import func CoreText.CTFontCopyTable
import var CoreText.kCTFontURLAttribute
import class CoreText.CTFont

extension OpenUIKitFontRegistry {
    /// A miss is not cached: the app may register the font with CoreText
    /// after asking for it once (Artsy+UIFonts' loader, and the probe's
    /// "before register" line, ask first).
    static func _adoptCoreTextFace(named name: String) -> Bool {
        let font = CTFontCreateWithName(name as CFString, 12, nil)
        let ps = CTFontCopyPostScriptName(font) as String
        let family = CTFontCopyFamilyName(font) as String
        guard ps == name || family == name else { return false }
        if let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL {
            let path = url.path
            if path.hasPrefix("/System/") || path.hasPrefix("/Library/Fonts/") { return false }
            switch register(path: path) {
            case .success, .failure(.alreadyRegistered): return registeredFace(named: name) != nil
            case .failure: return false
            }
        }
        guard let bytes = sfntBytes(font) else { return false }
        switch register(bytes: bytes, key: "coretext:" + ps) {
        case .success, .failure(.alreadyRegistered): return registeredFace(named: name) != nil
        case .failure: return false
        }
    }

    /// An SFNT file of the font's tables, as CoreText vends them.
    static func sfntBytes(_ font: CTFont) -> [UInt8]? {
        guard let array = CTFontCopyAvailableTables(font, []) else { return nil }
        // The array holds the four-character tags as raw pointer-sized
        // values, not CFNumbers (CTFont.h).
        var tables: [(tag: UInt32, data: [UInt8])] = []
        for i in 0..<CFArrayGetCount(array) {
            let raw = UInt(bitPattern: CFArrayGetValueAtIndex(array, i))
            let tag = UInt32(truncatingIfNeeded: raw)
            guard let data = CTFontCopyTable(font, tag, []) else { continue }
            tables.append((tag, [UInt8](data as Data)))
        }
        guard !tables.isEmpty else { return nil }
        tables.sort { $0.tag < $1.tag }
        let isCFF = tables.contains { $0.tag == 0x4346_4620 }   // 'CFF '
        var out: [UInt8] = []
        func u16(_ v: Int) { out += [UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)] }
        func u32(_ v: UInt32) { out += [UInt8(v >> 24), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)] }
        let n = tables.count
        var entrySelector = 0
        while (1 << (entrySelector + 1)) <= n { entrySelector += 1 }
        let searchRange = (1 << entrySelector) * 16
        u32(isCFF ? 0x4F54_544F : 0x0001_0000)
        u16(n); u16(searchRange); u16(entrySelector); u16(n * 16 - searchRange)
        var offset = 12 + 16 * n
        for t in tables {
            var sum: UInt32 = 0
            var i = 0
            while i < t.data.count {
                var word: UInt32 = 0
                for k in 0..<4 { word = word << 8 | UInt32(i + k < t.data.count ? t.data[i + k] : 0) }
                sum = sum &+ word
                i += 4
            }
            u32(t.tag); u32(sum); u32(UInt32(offset)); u32(UInt32(t.data.count))
            offset += (t.data.count + 3) & ~3
        }
        for t in tables {
            out += t.data
            while out.count % 4 != 0 { out.append(0) }
        }
        return out
    }
}
#else
extension OpenUIKitFontRegistry {
    static func _adoptCoreTextFace(named name: String) -> Bool { false }
}
#endif
