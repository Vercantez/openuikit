import Foundation
import CoreFoundation
import MediaToolbox

func testLocalizedMediaTypeNames() {
    let pairs: [(UInt32, String)] = [
        (mtFourCC("vide"), "Video"),
        (mtFourCC("soun"), "Audio"),
        (mtFourCC("muxx"), "Muxed"),
        (mtFourCC("text"), "Text"),
        (mtFourCC("clcp"), "Closed Caption"),
        (mtFourCC("sbtl"), "Subtitle"),
        (mtFourCC("tmcd"), "Time Code"),
        (mtFourCC("meta"), "Metadata"),
        (mtFourCC("tbgr"), "Tagged Buffer Group"),
    ]
    for (code, expected) in pairs {
        guard let cfName = MTCopyLocalizedNameForMediaType(code) else {
            fatalError("MEDIATOOLBOX_RUNTIME_FAIL missing name for \(expected)")
        }
        mtExpect(mtString(cfName) == expected, "media type \(expected)")
    }
    mtExpect(MTCopyLocalizedNameForMediaType(mtFourCC("xxxx")) == nil, "unknown type is nil")
    mtExpect(MTCopyLocalizedNameForMediaType(0) == nil, "zero type is nil")
    let first = MTCopyLocalizedNameForMediaType(mtFourCC("vide"))
    let second = MTCopyLocalizedNameForMediaType(mtFourCC("vide"))
    mtExpect(first != nil && second != nil, "repeat lookup")
    mtExpect(mtString(first!) == mtString(second!), "interned video name")
}

func testLocalizedMediaSubTypeNames() {
    let pairs: [(UInt32, UInt32, String)] = [
        (mtFourCC("vide"), mtFourCC("avc1"), "H.264"),
        (mtFourCC("vide"), mtFourCC("hvc1"), "HEVC"),
        (mtFourCC("vide"), mtFourCC("jpeg"), "JPEG"),
        (mtFourCC("vide"), mtFourCC("apcn"), "Apple ProRes 422"),
        (mtFourCC("soun"), mtFourCC("lpcm"), "Linear PCM"),
        (mtFourCC("soun"), mtFourCC("aac "), "AAC"),
        (mtFourCC("clcp"), mtFourCC("c608"), "CEA-608"),
        (mtFourCC("sbtl"), mtFourCC("wvtt"), "WebVTT"),
        (mtFourCC("muxx"), mtFourCC("mp2t"), "MPEG-2 Transport"),
        (mtFourCC("meta"), mtFourCC("mebx"), "Boxed Metadata"),
        (mtFourCC("tmcd"), mtFourCC("tc64"), "Time Code 64"),
        (mtFourCC("text"), mtFourCC("tx3g"), "3G Text"),
        (mtFourCC("tbgr"), mtFourCC("tbgr"), "Tagged Buffer Group"),
    ]
    for (mediaType, subType, expected) in pairs {
        guard let cfName = MTCopyLocalizedNameForMediaSubType(mediaType, subType) else {
            fatalError("MEDIATOOLBOX_RUNTIME_FAIL missing subtype \(expected)")
        }
        mtExpect(mtString(cfName) == expected, "subtype \(expected)")
    }
    mtExpect(
        MTCopyLocalizedNameForMediaSubType(mtFourCC("vide"), mtFourCC("zzzz")) == nil,
        "unknown subtype is nil"
    )
    mtExpect(
        MTCopyLocalizedNameForMediaSubType(mtFourCC("soun"), mtFourCC("avc1")) == nil,
        "H.264 is not an audio subtype"
    )
}
