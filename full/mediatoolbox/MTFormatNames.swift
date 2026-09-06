import CoreFoundation
import Foundation

private let internLock = NSLock()
private var internedNames: [String: NSString] = [:]

private func internedCFString(_ string: String) -> CFString {
    internLock.lock()
    defer { internLock.unlock() }
    if let existing = internedNames[string] {
        return unsafeBitCast(existing, to: CFString.self)
    }
    let ns = string as NSString
    internedNames[string] = ns
    return unsafeBitCast(ns, to: CFString.self)
}

/// English names for documented `kCMMediaType_*` FourCCs. Not Apple's
/// localized catalog.
private let mediaTypeNames: [UInt32: String] = [
    mtFourCC("vide"): "Video",
    mtFourCC("soun"): "Audio",
    mtFourCC("muxx"): "Muxed",
    mtFourCC("text"): "Text",
    mtFourCC("clcp"): "Closed Caption",
    mtFourCC("sbtl"): "Subtitle",
    mtFourCC("tmcd"): "Time Code",
    mtFourCC("meta"): "Metadata",
    mtFourCC("tbgr"): "Tagged Buffer Group",
]

/// English names for documented CoreMedia codec / format FourCCs, keyed by
/// media type then subtype. Unknown pairs return nil.
private let mediaSubTypeNames: [UInt32: [UInt32: String]] = [
    mtFourCC("vide"): [
        mtFourCC("avc1"): "H.264",
        mtFourCC("hvc1"): "HEVC",
        mtFourCC("jpeg"): "JPEG",
        mtFourCC("mp4v"): "MPEG-4 Video",
        mtFourCC("mp2v"): "MPEG-2 Video",
        mtFourCC("mp1v"): "MPEG-1 Video",
        mtFourCC("h263"): "H.263",
        mtFourCC("vp09"): "VP9",
        mtFourCC("av01"): "AV1",
        mtFourCC("apcn"): "Apple ProRes 422",
        mtFourCC("apch"): "Apple ProRes 422 HQ",
        mtFourCC("apcs"): "Apple ProRes 422 LT",
        mtFourCC("apco"): "Apple ProRes 422 Proxy",
        mtFourCC("ap4h"): "Apple ProRes 4444",
        mtFourCC("ap4x"): "Apple ProRes 4444 XQ",
        mtFourCC("2vuy"): "422YpCbCr8",
        mtFourCC("rle "): "Animation",
        mtFourCC("cvid"): "Cinepak",
        mtFourCC("dvh1"): "Dolby Vision HEVC",
    ],
    mtFourCC("soun"): [
        mtFourCC("lpcm"): "Linear PCM",
        mtFourCC("aac "): "AAC",
        mtFourCC("paac"): "AAC LC Protected",
        mtFourCC("alac"): "Apple Lossless",
        mtFourCC("ulaw"): "μ-Law",
        mtFourCC("alaw"): "A-Law",
        mtFourCC(".mp3"): "MPEG-1 Audio Layer 3",
    ],
    mtFourCC("clcp"): [
        mtFourCC("c608"): "CEA-608",
        mtFourCC("c708"): "CEA-708",
        mtFourCC("atcc"): "ATSC",
    ],
    mtFourCC("sbtl"): [
        mtFourCC("tx3g"): "3G Text",
        mtFourCC("wvtt"): "WebVTT",
    ],
    mtFourCC("muxx"): [
        mtFourCC("mp2t"): "MPEG-2 Transport",
        mtFourCC("mp2p"): "MPEG-2 Program",
        mtFourCC("mp1s"): "MPEG-1 System",
        mtFourCC("dv  "): "DV",
    ],
    mtFourCC("text"): [
        mtFourCC("text"): "Text",
        mtFourCC("tx3g"): "3G Text",
    ],
    mtFourCC("tmcd"): [
        mtFourCC("tmcd"): "Time Code 32",
        mtFourCC("tc64"): "Time Code 64",
        mtFourCC("cn32"): "Counter 32",
        mtFourCC("cn64"): "Counter 64",
    ],
    mtFourCC("meta"): [
        mtFourCC("mebx"): "Boxed Metadata",
        mtFourCC("id3 "): "ID3",
        mtFourCC("icy "): "ICY",
        mtFourCC("emsg"): "EMSG",
    ],
    mtFourCC("tbgr"): [
        mtFourCC("tbgr"): "Tagged Buffer Group",
    ],
]

public func MTCopyLocalizedNameForMediaType(_ mediaType: CMMediaType) -> CFString? {
    guard let name = mediaTypeNames[mediaType] else { return nil }
    return internedCFString(name)
}

public func MTCopyLocalizedNameForMediaSubType(
    _ mediaType: CMMediaType,
    _ mediaSubType: FourCharCode
) -> CFString? {
    guard let name = mediaSubTypeNames[mediaType]?[mediaSubType] else { return nil }
    return internedCFString(name)
}
