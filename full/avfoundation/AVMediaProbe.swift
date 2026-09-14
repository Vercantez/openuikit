import Foundation

/// Parsed local-container description. Not a decoder: sample bytes stay opaque.
struct AVLocalMediaTrack {
    var trackID: CMPersistentTrackID = 0
    var mediaType: AVMediaType = AVMediaType(rawValue: "")
    var handlerType: String = ""
    var duration: CMTime = .invalid
    var mediaTimescale: CMTimeScale = 0
    var naturalSize: CGSize = .zero
    var preferredTransform: CGAffineTransform = .identity
    var preferredVolume: Float = 1
    var nominalFrameRate: Float = 0
    var minFrameDuration: CMTime = .invalid
    var languageCode: String?
    var codec: String = ""
    var channelCount: Int = 0
    var sampleRate: Double = 0
    var isEnabled: Bool = true
    var isSelfContained: Bool = true
    var totalSampleDataLength: Int64 = 0
    var editEmptyDuration: CMTime = .zero
    var pixelAspectRatio = AVPixelAspectRatio()
}

struct AVLocalMediaProbe {
    var duration: CMTime = .invalid
    var preferredRate: Float = 1
    var preferredVolume: Float = 1
    var preferredTransform: CGAffineTransform = .identity
    var majorBrand: String = ""
    var nextTrackID: CMPersistentTrackID = 0
    var metadataItems: [AVMetadataItem] = []
    var tracks: [AVLocalMediaTrack] = []
    var kind: Kind = .unknown

    enum Kind: String {
        case unknown
        case isoBMFF
        case wav
        case aiff
    }

    static func probe(url: URL) -> AVLocalMediaProbe? {
        guard url.isFileURL else { return nil }
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            return nil
        }
        return probe(data: data)
    }

    static func probe(data: Data) -> AVLocalMediaProbe? {
        if data.count < 12 { return nil }
        if data.starts(with: Data([0x52, 0x49, 0x46, 0x46])) {
            return parseWAV(data)
        }
        if data.starts(with: Data([0x46, 0x4f, 0x52, 0x4d])) {
            return parseAIFF(data)
        }
        if let iso = parseISOBMFF(data) { return iso }
        return nil
    }
}

enum AVISOBoxParser {
    struct Box {
        var type: String
        var payload: Data
    }

    static func u32(_ data: Data, _ offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= data.count else { return nil }
        return data[offset..<(offset + 4)].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    static func u16(_ data: Data, _ offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= data.count else { return nil }
        return data[offset..<(offset + 2)].reduce(UInt16(0)) { ($0 << 8) | UInt16($1) }
    }

    static func u64(_ data: Data, _ offset: Int) -> UInt64? {
        guard offset >= 0, offset + 8 <= data.count else { return nil }
        return data[offset..<(offset + 8)].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
    }

    static func u32LE(_ data: Data, _ offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= data.count else { return nil }
        let bytes = [UInt8](data[offset..<(offset + 4)])
        return UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)
    }

    static func u16LE(_ data: Data, _ offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= data.count else { return nil }
        let bytes = [UInt8](data[offset..<(offset + 2)])
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }

    static func i32(_ data: Data, _ offset: Int) -> Int32? {
        guard let value = u32(data, offset) else { return nil }
        return Int32(bitPattern: value)
    }

    static func fourCC(_ data: Data, _ offset: Int) -> String? {
        guard offset >= 0, offset + 4 <= data.count else { return nil }
        let bytes = [UInt8](data[offset..<(offset + 4)])
        return String(bytes: bytes, encoding: .isoLatin1)
    }

    static func boxes(in data: Data) -> [Box] {
        var result: [Box] = []
        var offset = 0
        while offset + 8 <= data.count {
            guard let size32 = u32(data, offset), let type = fourCC(data, offset + 4) else {
                break
            }
            var header = 8
            var size = Int(size32)
            if size32 == 1 {
                guard let large = u64(data, offset + 8) else { break }
                header = 16
                size = Int(large)
            } else if size32 == 0 {
                size = data.count - offset
            }
            if size < header || offset + size > data.count {
                break
            }
            let payload = data.subdata(in: (offset + header)..<(offset + size))
            result.append(Box(type: type, payload: payload))
            offset += size
        }
        return result
    }

    static func walk(_ data: Data, into body: (Box) -> Void) {
        for box in boxes(in: data) {
            body(box)
            switch box.type {
            case "moov", "trak", "mdia", "minf", "stbl", "edts", "dinf":
                walk(box.payload, into: body)
            default:
                break
            }
        }
    }
}

private func parseISOBMFF(_ data: Data) -> AVLocalMediaProbe? {
    let top = AVISOBoxParser.boxes(in: data)
    guard top.contains(where: { $0.type == "ftyp" || $0.type == "moov" }) else {
        return nil
    }
    var probe = AVLocalMediaProbe()
    probe.kind = .isoBMFF
    if let ftyp = top.first(where: { $0.type == "ftyp" }) {
        probe.majorBrand = AVISOBoxParser.fourCC(ftyp.payload, 0) ?? ""
    }
    guard let moov = top.first(where: { $0.type == "moov" }) else {
        return probe
    }
    let moovBoxes = AVISOBoxParser.boxes(in: moov.payload)
    if let mvhd = moovBoxes.first(where: { $0.type == "mvhd" }) {
        let header = parseMVHD(mvhd.payload)
        probe.duration = header.duration
        probe.preferredRate = header.preferredRate
        probe.preferredVolume = header.preferredVolume
        probe.nextTrackID = header.nextTrackID
    }
    for trak in moovBoxes where trak.type == "trak" {
        if let track = parseTrak(trak.payload) {
            probe.tracks.append(track)
            if track.mediaType == .video, probe.preferredTransform == .identity {
                probe.preferredTransform = track.preferredTransform
            }
        }
    }
    for udta in moovBoxes where udta.type == "udta" {
        probe.metadataItems.append(contentsOf: parseUDTA(udta.payload, keySpace: .quickTimeUserData))
    }
    if let meta = moovBoxes.first(where: { $0.type == "meta" }) {
        probe.metadataItems.append(contentsOf: parseMeta(meta.payload))
    }
    if !probe.duration.isValid, let longest = probe.tracks.map(\.duration.seconds).max(), longest > 0 {
        probe.duration = AVTimeMath.time(seconds: longest)
    }
    return probe
}

private func parseMVHD(_ payload: Data) -> (duration: CMTime, preferredRate: Float, preferredVolume: Float, nextTrackID: CMPersistentTrackID) {
    guard let versionFlags = AVISOBoxParser.u32(payload, 0) else {
        return (.invalid, 1, 1, 0)
    }
    let version = versionFlags >> 24
    if version == 1 {
        guard let timescale = AVISOBoxParser.u32(payload, 20),
              let duration = AVISOBoxParser.u64(payload, 24),
              timescale > 0
        else { return (.invalid, 1, 1, 0) }
        let rate = AVISOBoxParser.u32(payload, 32).map { Float($0) / 65536 } ?? 1
        let volume = AVISOBoxParser.u16(payload, 36).map { Float($0) / 256 } ?? 1
        let next = AVISOBoxParser.u32(payload, 108).map { CMPersistentTrackID($0) } ?? 0
        return (
            CMTime(value: CMTimeValue(duration), timescale: CMTimeScale(timescale)),
            rate,
            volume,
            next
        )
    }
    guard let timescale = AVISOBoxParser.u32(payload, 12),
          let duration = AVISOBoxParser.u32(payload, 16),
          timescale > 0
    else { return (.invalid, 1, 1, 0) }
    let rate = AVISOBoxParser.u32(payload, 20).map { Float($0) / 65536 } ?? 1
    let volume = AVISOBoxParser.u16(payload, 24).map { Float($0) / 256 } ?? 1
    let next = AVISOBoxParser.u32(payload, 96).map { CMPersistentTrackID($0) } ?? 0
    return (
        CMTime(value: CMTimeValue(duration), timescale: CMTimeScale(timescale)),
        rate,
        volume,
        next
    )
}

private func parseTrak(_ payload: Data) -> AVLocalMediaTrack? {
    var track = AVLocalMediaTrack()
    let boxes = AVISOBoxParser.boxes(in: payload)
    if let tkhd = boxes.first(where: { $0.type == "tkhd" }) {
        parseTKHD(tkhd.payload, into: &track)
    }
    if let edts = boxes.first(where: { $0.type == "edts" }) {
        let edits = AVISOBoxParser.boxes(in: edts.payload)
        if let elst = edits.first(where: { $0.type == "elst" }) {
            parseELST(elst.payload, into: &track)
        }
    }
    guard let mdia = boxes.first(where: { $0.type == "mdia" }) else { return track }
    let mediaBoxes = AVISOBoxParser.boxes(in: mdia.payload)
    if let mdhd = mediaBoxes.first(where: { $0.type == "mdhd" }) {
        parseMDHD(mdhd.payload, into: &track)
    }
    if let hdlr = mediaBoxes.first(where: { $0.type == "hdlr" }) {
        let handler = AVISOBoxParser.fourCC(hdlr.payload, 8) ?? ""
        track.handlerType = handler
        track.mediaType = mediaType(forHandler: handler)
    }
    guard let minf = mediaBoxes.first(where: { $0.type == "minf" }) else { return track }
    let minfBoxes = AVISOBoxParser.boxes(in: minf.payload)
    if let dinf = minfBoxes.first(where: { $0.type == "dinf" }) {
        parseDREF(dinf.payload, into: &track)
    }
    guard let stbl = minfBoxes.first(where: { $0.type == "stbl" }) else { return track }
    let sampleBoxes = AVISOBoxParser.boxes(in: stbl.payload)
    if let stsd = sampleBoxes.first(where: { $0.type == "stsd" }) {
        parseSTSD(stsd.payload, into: &track)
    }
    if let stts = sampleBoxes.first(where: { $0.type == "stts" }) {
        parseSTTS(stts.payload, into: &track)
    }
    if let stsz = sampleBoxes.first(where: { $0.type == "stsz" }) {
        parseSTSZ(stsz.payload, into: &track)
    }
    return track
}

private func parseTKHD(_ payload: Data, into track: inout AVLocalMediaTrack) {
    guard let versionFlags = AVISOBoxParser.u32(payload, 0) else { return }
    let version = versionFlags >> 24
    let enabled = (versionFlags & 1) != 0
    track.isEnabled = enabled || versionFlags == 0
    if version == 1 {
        if let trackID = AVISOBoxParser.u32(payload, 20) {
            track.trackID = CMPersistentTrackID(trackID)
        }
        if let duration = AVISOBoxParser.u64(payload, 28) {
            track.duration = CMTime(value: CMTimeValue(duration), timescale: 600)
        }
        // reserved(8) starts at byte 36 in a version-1 tkhd.
        parseTKHDTail(payload, offset: 36, into: &track)
    } else {
        if let trackID = AVISOBoxParser.u32(payload, 12) {
            track.trackID = CMPersistentTrackID(trackID)
        }
        if let duration = AVISOBoxParser.u32(payload, 20) {
            track.duration = CMTime(value: CMTimeValue(duration), timescale: 600)
        }
        // reserved(8) starts at byte 24 in a version-0 tkhd.
        parseTKHDTail(payload, offset: 24, into: &track)
    }
}

private func parseTKHDTail(_ payload: Data, offset: Int, into track: inout AVLocalMediaTrack) {
    // reserved 8, layer 2, alternate 2, volume 2, reserved 2, matrix 36, width 4, height 4
    let matrixOffset = offset + 8 + 2 + 2 + 2 + 2
    if let volume = AVISOBoxParser.u16(payload, offset + 8 + 2 + 2) {
        track.preferredVolume = Float(volume) / 256
    }
    if let a = AVISOBoxParser.i32(payload, matrixOffset),
       let b = AVISOBoxParser.i32(payload, matrixOffset + 4),
       let c = AVISOBoxParser.i32(payload, matrixOffset + 12),
       let d = AVISOBoxParser.i32(payload, matrixOffset + 16),
       let x = AVISOBoxParser.i32(payload, matrixOffset + 24),
       let y = AVISOBoxParser.i32(payload, matrixOffset + 28)
    {
        track.preferredTransform = CGAffineTransform(
            a: CGFloat(a) / 65536,
            b: CGFloat(b) / 65536,
            c: CGFloat(c) / 65536,
            d: CGFloat(d) / 65536,
            tx: CGFloat(x) / 65536,
            ty: CGFloat(y) / 65536
        )
    }
    if let width = AVISOBoxParser.u32(payload, matrixOffset + 36),
       let height = AVISOBoxParser.u32(payload, matrixOffset + 40)
    {
        track.naturalSize = CGSize(
            width: CGFloat(width) / 65536,
            height: CGFloat(height) / 65536
        )
    }
}

private func parseMDHD(_ payload: Data, into track: inout AVLocalMediaTrack) {
    guard let versionFlags = AVISOBoxParser.u32(payload, 0) else { return }
    let version = versionFlags >> 24
    if version == 1 {
        guard let timescale = AVISOBoxParser.u32(payload, 20),
              let duration = AVISOBoxParser.u64(payload, 24),
              timescale > 0
        else { return }
        track.mediaTimescale = CMTimeScale(timescale)
        track.duration = CMTime(value: CMTimeValue(duration), timescale: CMTimeScale(timescale))
        if let packed = AVISOBoxParser.u16(payload, 32) {
            track.languageCode = unpackLanguage(packed)
        }
    } else {
        guard let timescale = AVISOBoxParser.u32(payload, 12),
              let duration = AVISOBoxParser.u32(payload, 16),
              timescale > 0
        else { return }
        track.mediaTimescale = CMTimeScale(timescale)
        track.duration = CMTime(value: CMTimeValue(duration), timescale: CMTimeScale(timescale))
        if let packed = AVISOBoxParser.u16(payload, 20) {
            track.languageCode = unpackLanguage(packed)
        }
    }
}

private func unpackLanguage(_ packed: UInt16) -> String? {
    let c1 = Character(UnicodeScalar(UInt8((packed >> 10) & 0x1F) + 0x60))
    let c2 = Character(UnicodeScalar(UInt8((packed >> 5) & 0x1F) + 0x60))
    let c3 = Character(UnicodeScalar(UInt8(packed & 0x1F) + 0x60))
    let code = String([c1, c2, c3])
    return code == "und" ? nil : code
}

private func parseSTSD(_ payload: Data, into track: inout AVLocalMediaTrack) {
    // version/flags 4, entry count 4, then sample entries
    guard payload.count >= 8 else { return }
    let entries = AVISOBoxParser.boxes(in: payload.subdata(in: 8..<payload.count))
    guard let entry = entries.first else { return }
    track.codec = entry.type
    let box = Data() + isoBox(type: entry.type, payload: entry.payload)
    if track.mediaType == .video || ["avc1", "mp4v", "hvc1", "hev1", "vp09"].contains(entry.type) {
        if track.mediaType.rawValue.isEmpty { track.mediaType = .video }
        if let width = AVISOBoxParser.u16(box, 32), let height = AVISOBoxParser.u16(box, 34) {
            if track.naturalSize == .zero {
                track.naturalSize = CGSize(width: CGFloat(width), height: CGFloat(height))
            }
        }
        // Visual sample entry is 86 bytes including the box header; remaining child boxes
        // include pasp (pixel aspect) and clap (clean aperture).
        if box.count > 86 {
            let extras = AVISOBoxParser.boxes(in: box.subdata(in: 86..<box.count))
            if let pasp = extras.first(where: { $0.type == "pasp" }),
               let horizontal = AVISOBoxParser.u32(pasp.payload, 0),
               let vertical = AVISOBoxParser.u32(pasp.payload, 4)
            {
                track.pixelAspectRatio = AVPixelAspectRatio(
                    horizontalSpacing: Int(horizontal),
                    verticalSpacing: Int(vertical)
                )
            }
        }
    }
    if track.mediaType == .audio || ["mp4a", "sowt", "twos", "lpcm", "aac "].contains(entry.type) {
        if track.mediaType.rawValue.isEmpty { track.mediaType = .audio }
        if let channels = AVISOBoxParser.u16(box, 24) {
            track.channelCount = Int(channels)
        }
        if let rate = AVISOBoxParser.u32(box, 32) {
            track.sampleRate = Double(rate) / 65536
        }
    }
}

private func isoBox(type: String, payload: Data) -> Data {
    var size = UInt32(8 + payload.count).bigEndian
    var data = Data(bytes: &size, count: 4)
    data.append(contentsOf: Array(type.utf8.prefix(4)))
    data.append(payload)
    return data
}

private func parseSTSZ(_ payload: Data, into track: inout AVLocalMediaTrack) {
    guard let sampleSize = AVISOBoxParser.u32(payload, 4),
          let sampleCount = AVISOBoxParser.u32(payload, 8)
    else { return }
    if sampleSize != 0 {
        track.totalSampleDataLength = Int64(sampleSize) * Int64(sampleCount)
        return
    }
    var total: Int64 = 0
    var offset = 12
    var remaining = Int(sampleCount)
    while remaining > 0, let size = AVISOBoxParser.u32(payload, offset) {
        total += Int64(size)
        offset += 4
        remaining -= 1
    }
    track.totalSampleDataLength = total
}

private func parseSTTS(_ payload: Data, into track: inout AVLocalMediaTrack) {
    guard let count = AVISOBoxParser.u32(payload, 4), count >= 1 else { return }
    guard let sampleCount = AVISOBoxParser.u32(payload, 8),
          let sampleDelta = AVISOBoxParser.u32(payload, 12),
          sampleDelta > 0
    else { return }
    let timescale = track.mediaTimescale == 0 ? 600 : track.mediaTimescale
    track.minFrameDuration = CMTime(value: CMTimeValue(sampleDelta), timescale: timescale)
    track.nominalFrameRate = Float(timescale) / Float(sampleDelta)
    _ = sampleCount
}

private func parseELST(_ payload: Data, into track: inout AVLocalMediaTrack) {
    guard let versionFlags = AVISOBoxParser.u32(payload, 0),
          let count = AVISOBoxParser.u32(payload, 4),
          count >= 1
    else { return }
    let version = versionFlags >> 24
    let mediaTime: Int64
    let segmentDuration: UInt64
    if version == 1 {
        guard let duration = AVISOBoxParser.u64(payload, 8),
              let time = AVISOBoxParser.u64(payload, 16)
        else { return }
        segmentDuration = duration
        mediaTime = Int64(bitPattern: time)
    } else {
        guard let duration = AVISOBoxParser.u32(payload, 8),
              let time = AVISOBoxParser.u32(payload, 12)
        else { return }
        segmentDuration = UInt64(duration)
        mediaTime = Int64(Int32(bitPattern: time))
    }
    if mediaTime < 0 {
        let scale = track.mediaTimescale == 0 ? 600 : track.mediaTimescale
        track.editEmptyDuration = CMTime(value: CMTimeValue(segmentDuration), timescale: scale)
    }
}

private func parseDREF(_ dinfPayload: Data, into track: inout AVLocalMediaTrack) {
    let boxes = AVISOBoxParser.boxes(in: dinfPayload)
    guard let dref = boxes.first(where: { $0.type == "dref" }), dref.payload.count >= 8 else { return }
    let entries = AVISOBoxParser.boxes(in: dref.payload.subdata(in: 8..<dref.payload.count))
    guard !entries.isEmpty else { return }
    track.isSelfContained = entries.allSatisfy { entry in
        guard let versionFlags = AVISOBoxParser.u32(entry.payload, 0) else { return true }
        return (versionFlags & 1) != 0
    }
}

private func parseUDTA(_ payload: Data, keySpace: AVMetadataKeySpace) -> [AVMetadataItem] {
    var items: [AVMetadataItem] = []
    for box in AVISOBoxParser.boxes(in: payload) {
        if box.type == "meta" {
            items.append(contentsOf: parseMeta(box.payload))
            continue
        }
        guard let item = metadataItem(fromUserData: box, keySpace: keySpace) else { continue }
        items.append(item)
    }
    return items
}

private func parseMeta(_ payload: Data) -> [AVMetadataItem] {
    // `meta` is a full box (version/flags) followed by child boxes.
    let body: Data
    if let type = AVISOBoxParser.fourCC(payload, 4),
       ["hdlr", "ilst", "udta", "dinf", "keys", "iloc"].contains(type)
    {
        body = payload.subdata(in: 4..<payload.count)
    } else {
        body = payload
    }
    let boxes = AVISOBoxParser.boxes(in: body)
    var items: [AVMetadataItem] = []
    if let ilst = boxes.first(where: { $0.type == "ilst" }) {
        for atom in AVISOBoxParser.boxes(in: ilst.payload) {
            let dataBoxes = AVISOBoxParser.boxes(in: atom.payload)
            if let data = dataBoxes.first(where: { $0.type == "data" }), data.payload.count >= 8 {
                let text = String(data: data.payload.subdata(in: 8..<data.payload.count), encoding: .utf8)
                    ?? String(data: data.payload.subdata(in: 8..<data.payload.count), encoding: .ascii)
                if let text, let item = metadataItem(fourCC: atom.type, string: text, keySpace: .iTunes) {
                    items.append(item)
                }
            }
        }
    }
    if let udta = boxes.first(where: { $0.type == "udta" }) {
        items.append(contentsOf: parseUDTA(udta.payload, keySpace: .quickTimeUserData))
    }
    return items
}

private func metadataItem(fromUserData box: AVISOBoxParser.Box, keySpace: AVMetadataKeySpace) -> AVMetadataItem? {
    var payload = box.payload
    if payload.count >= 2, let packed = AVISOBoxParser.u16(payload, 0), packed <= 0x7FFF {
        payload = payload.subdata(in: 2..<payload.count)
    }
    let stripped = Data(payload.filter { $0 != 0 })
    let text = String(data: stripped, encoding: .utf8)
        ?? String(data: stripped, encoding: .ascii)
    guard let text, !text.isEmpty else { return nil }
    return metadataItem(fourCC: box.type, string: text, keySpace: keySpace)
}

private func metadataItem(fourCC: String, string: String, keySpace: AVMetadataKeySpace) -> AVMetadataItem? {
    let item = AVMutableMetadataItem()
    item.keySpace = keySpace
    item.key = fourCC as NSString
    item.value = string as NSString
    switch fourCC {
    case "©nam", "name", "INAM":
        item.commonKey = .commonKeyTitle
        item.identifier = .commonIdentifierTitle
    case "©ART", "ART ", "IART":
        item.commonKey = .commonKeyArtist
        item.identifier = .commonIdentifierArtist
    case "©alb", "alb ", "©Alb":
        item.commonKey = .commonKeyAlbumName
        item.identifier = .commonIdentifierAlbumName
    case "©cmt", "cmt ", "©des", "ICMT":
        item.commonKey = .commonKeyDescription
        item.identifier = .commonIdentifierDescription
    case "©too", "too ", "ISFT":
        item.commonKey = .commonKeySoftware
        item.identifier = .commonIdentifierSoftware
    case "©day", "day ", "©xyz", "ICRD":
        item.commonKey = .commonKeyCreationDate
        item.identifier = .commonIdentifierCreationDate
    case "©cpy", "cprt":
        item.commonKey = .commonKeyCopyrights
        item.identifier = .commonIdentifierCopyrights
    case "©aut", "AUTH":
        item.commonKey = .commonKeyAuthor
        item.identifier = .commonIdentifierAuthor
    default:
        item.identifier = AVMetadataItem.identifier(forKey: fourCC, keySpace: keySpace)
    }
    return item
}

private func mediaType(forHandler handler: String) -> AVMediaType {
    switch handler {
    case "vide": return .video
    case "soun": return .audio
    case "text", "sbtl", "subt": return .subtitle
    case "meta", "mebx": return .metadata
    case "tmcd": return .timecode
    case "clcp": return .closedCaption
    default: return AVMediaType(rawValue: handler)
    }
}

private func parseWAV(_ data: Data) -> AVLocalMediaProbe? {
    guard AVISOBoxParser.fourCC(data, 8) == "WAVE" else { return nil }
    var offset = 12
    var channels = 0
    var sampleRate = 0
    var byteRate = 0
    var bits = 0
    var dataBytes = 0
    var probeMetadata: [AVMetadataItem] = []
    while offset + 8 <= data.count {
        guard let chunk = AVISOBoxParser.fourCC(data, offset),
              let size = AVISOBoxParser.u32LE(data, offset + 4)
        else { break }
        let payloadStart = offset + 8
        let payloadEnd = min(payloadStart + Int(size), data.count)
        if chunk == "fmt " {
            if let ch = AVISOBoxParser.u16LE(data, payloadStart + 2) { channels = Int(ch) }
            if let sr = AVISOBoxParser.u32LE(data, payloadStart + 4) { sampleRate = Int(sr) }
            if let br = AVISOBoxParser.u32LE(data, payloadStart + 8) { byteRate = Int(br) }
            if let bps = AVISOBoxParser.u16LE(data, payloadStart + 14) { bits = Int(bps) }
        } else if chunk == "data" {
            dataBytes = Int(size)
        } else if chunk == "LIST", payloadEnd - payloadStart >= 4,
                  AVISOBoxParser.fourCC(data, payloadStart) == "INFO"
        {
            probeMetadata.append(contentsOf: parseWAVInfo(data.subdata(in: (payloadStart + 4)..<payloadEnd)))
        }
        offset = payloadEnd + (Int(size) % 2)
    }
    let durationSeconds: Double
    if byteRate > 0 {
        durationSeconds = Double(dataBytes) / Double(byteRate)
    } else if sampleRate > 0, channels > 0, bits > 0 {
        durationSeconds = Double(dataBytes) / (Double(sampleRate) * Double(channels) * Double(bits / 8))
    } else {
        return nil
    }
    var track = AVLocalMediaTrack()
    track.trackID = 1
    track.mediaType = .audio
    track.handlerType = "soun"
    track.duration = AVTimeMath.time(seconds: durationSeconds, timescale: CMTimeScale(max(sampleRate, 1)))
    track.mediaTimescale = CMTimeScale(max(sampleRate, 1))
    track.channelCount = channels
    track.sampleRate = Double(sampleRate)
    track.codec = "sowt"
    track.totalSampleDataLength = Int64(dataBytes)
    track.preferredVolume = 1
    var probe = AVLocalMediaProbe()
    probe.kind = .wav
    probe.majorBrand = "WAVE"
    probe.duration = track.duration
    probe.nextTrackID = 2
    probe.metadataItems = probeMetadata
    probe.tracks = [track]
    return probe
}

private func parseWAVInfo(_ payload: Data) -> [AVMetadataItem] {
    var items: [AVMetadataItem] = []
    var offset = 0
    while offset + 8 <= payload.count {
        guard let chunk = AVISOBoxParser.fourCC(payload, offset),
              let size = AVISOBoxParser.u32LE(payload, offset + 4)
        else { break }
        let start = offset + 8
        let end = min(start + Int(size), payload.count)
        let chunkBytes = Data(payload.subdata(in: start..<end).prefix { $0 != 0 })
        let text = String(data: chunkBytes, encoding: .utf8)
            ?? String(data: chunkBytes, encoding: .ascii)
        if let text, let item = metadataItem(fourCC: chunk, string: text, keySpace: .quickTimeUserData) {
            items.append(item)
        }
        offset = end + (Int(size) % 2)
    }
    return items
}

private func parseAIFF(_ data: Data) -> AVLocalMediaProbe? {
    guard let form = AVISOBoxParser.fourCC(data, 8), form == "AIFF" || form == "AIFC" else {
        return nil
    }
    var offset = 12
    var channels = 0
    var frames = 0
    var sampleRate = 0.0
    var bits = 0
    var dataBytes = 0
    var probeMetadata: [AVMetadataItem] = []
    while offset + 8 <= data.count {
        guard let chunk = AVISOBoxParser.fourCC(data, offset),
              let size = AVISOBoxParser.u32(data, offset + 4)
        else { break }
        let payloadStart = offset + 8
        if chunk == "COMM" {
            if let ch = AVISOBoxParser.u16(data, payloadStart) { channels = Int(ch) }
            if let fr = AVISOBoxParser.u32(data, payloadStart + 2) { frames = Int(fr) }
            if let bps = AVISOBoxParser.u16(data, payloadStart + 6) { bits = Int(bps) }
            sampleRate = extended80(data, payloadStart + 8)
        } else if chunk == "SSND" {
            dataBytes = Int(size)
        } else if chunk == "NAME" || chunk == "AUTH" || chunk == "ANNO" || chunk == "(c) " {
            let payloadEnd = min(payloadStart + Int(size), data.count)
            let chunkBytes = Data(data.subdata(in: payloadStart..<payloadEnd).prefix { $0 != 0 })
            let text = String(data: chunkBytes, encoding: .utf8)
                ?? String(data: chunkBytes, encoding: .ascii)
            let mapped = chunk == "NAME" ? "©nam" : (chunk == "AUTH" ? "©aut" : (chunk == "(c) " ? "cprt" : "©cmt"))
            if let text, let item = metadataItem(fourCC: mapped, string: text, keySpace: .quickTimeUserData) {
                probeMetadata.append(item)
            }
        }
        let payloadEnd = min(payloadStart + Int(size), data.count)
        offset = payloadEnd + (Int(size) % 2)
    }
    guard sampleRate > 0, frames > 0 else { return nil }
    let durationSeconds = Double(frames) / sampleRate
    var track = AVLocalMediaTrack()
    track.trackID = 1
    track.mediaType = .audio
    track.handlerType = "soun"
    track.duration = AVTimeMath.time(seconds: durationSeconds, timescale: CMTimeScale(max(Int32(sampleRate.rounded()), 1)))
    track.mediaTimescale = CMTimeScale(max(Int32(sampleRate.rounded()), 1))
    track.channelCount = channels
    track.sampleRate = sampleRate
    track.codec = "twos"
    track.totalSampleDataLength = Int64(dataBytes == 0 ? frames * channels * max(bits / 8, 1) : dataBytes)
    track.preferredVolume = 1
    var probe = AVLocalMediaProbe()
    probe.kind = .aiff
    probe.majorBrand = form
    probe.duration = track.duration
    probe.nextTrackID = 2
    probe.metadataItems = probeMetadata
    probe.tracks = [track]
    return probe
}

private func extended80(_ data: Data, _ offset: Int) -> Double {
    guard offset + 10 <= data.count else { return 0 }
    let bytes = [UInt8](data[offset..<(offset + 10)])
    let sign = (bytes[0] & 0x80) != 0
    let exponent = Int((UInt16(bytes[0] & 0x7F) << 8) | UInt16(bytes[1]))
    var mantissa: UInt64 = 0
    for index in 2..<10 {
        mantissa = (mantissa << 8) | UInt64(bytes[index])
    }
    if exponent == 0 && mantissa == 0 { return 0 }
    let magnitude = Double(mantissa) * pow(2.0, Double(exponent - 16383 - 63))
    return sign ? -magnitude : magnitude
}

extension AVAsset {
    func attachPortableProbe(_ probe: AVLocalMediaProbe) {
        loadState.lock.lock()
        loadState.probe = probe
        loadState.lock.unlock()
        let built = probe.tracks.map { AVAssetTrack(portable: $0, asset: self) }
        loadState.lock.lock()
        loadState.storedTracks = built
        loadState.loadedKeys.formUnion(["duration", "tracks", "isPlayable", "preferredTransform"])
        loadState.lock.unlock()
    }

    func portableProbe() -> AVLocalMediaProbe? {
        loadState.lock.lock()
        defer { loadState.lock.unlock() }
        return loadState.probe
    }

    func portableStoredTracks() -> [AVAssetTrack] {
        loadState.lock.lock()
        defer { loadState.lock.unlock() }
        return loadState.storedTracks
    }
}
