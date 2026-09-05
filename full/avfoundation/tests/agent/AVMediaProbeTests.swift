import Foundation
import AVFoundation

private func avU32(_ value: UInt32) -> Data {
    var be = value.bigEndian
    return Data(bytes: &be, count: 4)
}

private func avU16(_ value: UInt16) -> Data {
    var be = value.bigEndian
    return Data(bytes: &be, count: 2)
}

private func avBox(_ type: String, _ payload: Data) -> Data {
    var size = UInt32(8 + payload.count).bigEndian
    var data = Data(bytes: &size, count: 4)
    data.append(contentsOf: Array(type.utf8.prefix(4)))
    data.append(payload)
    return data
}

private func avIdentityMatrix() -> Data {
    var data = Data()
    let values: [Int32] = [
        0x00010000, 0, 0,
        0, 0x00010000, 0,
        0, 0, 0x40000000,
    ]
    for value in values {
        var be = UInt32(bitPattern: value).bigEndian
        data.append(Data(bytes: &be, count: 4))
    }
    return data
}

private func avWrite(_ data: Data, suffix: String) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav-\(UUID().uuidString).\(suffix)")
    try! data.write(to: url)
    return url
}

private func avMakeFtypMoov(
    timescale: UInt32 = 600,
    duration: UInt32 = 1800,
    width: UInt16 = 320,
    height: UInt16 = 240,
    handler: String = "vide",
    codec: String = "avc1",
    sampleDelta: UInt32 = 20
) -> Data {
    let ftyp = avBox("ftyp", avU32(0x69736f6d) + avU32(0) + avU32(0x69736f6d))
    var mvhd = Data()
    mvhd.append(avU32(0))
    mvhd.append(avU32(0))
    mvhd.append(avU32(0))
    mvhd.append(avU32(timescale))
    mvhd.append(avU32(duration))
    mvhd.append(avU32(0x00010000))
    mvhd.append(avU16(0x0100))
    mvhd.append(avU16(0))
    mvhd.append(Data(count: 8))
    mvhd.append(avIdentityMatrix())
    mvhd.append(Data(count: 24))
    mvhd.append(avU32(2))

    var tkhd = Data()
    tkhd.append(avU32(0x000003))
    tkhd.append(avU32(0))
    tkhd.append(avU32(0))
    tkhd.append(avU32(1))
    tkhd.append(avU32(0))
    tkhd.append(avU32(duration))
    tkhd.append(Data(count: 8))
    tkhd.append(avU16(0))
    tkhd.append(avU16(0))
    tkhd.append(avU16(handler == "soun" ? 0x0100 : 0))
    tkhd.append(avU16(0))
    tkhd.append(avIdentityMatrix())
    tkhd.append(avU32(UInt32(width) << 16))
    tkhd.append(avU32(UInt32(height) << 16))

    var mdhd = Data()
    mdhd.append(avU32(0))
    mdhd.append(avU32(0))
    mdhd.append(avU32(0))
    mdhd.append(avU32(timescale))
    mdhd.append(avU32(duration))
    mdhd.append(avU16(0x55C4))
    mdhd.append(avU16(0))

    var hdlr = Data()
    hdlr.append(avU32(0))
    hdlr.append(avU32(0))
    hdlr.append(contentsOf: Array(handler.utf8.prefix(4)))
    hdlr.append(Data(count: 12))
    hdlr.append(contentsOf: Array("VideoHandler\0".utf8))

    var sample = Data(count: 6)
    sample.append(avU16(1))
    if handler == "vide" {
        sample.append(avU16(0))
        sample.append(avU16(0))
        sample.append(Data(count: 12))
        sample.append(avU16(width))
        sample.append(avU16(height))
        sample.append(avU32(0x00480000))
        sample.append(avU32(0x00480000))
        sample.append(avU32(0))
        sample.append(avU16(1))
        sample.append(Data(count: 32))
        sample.append(avU16(0x0018))
        sample.append(avU16(0xFFFF))
    } else {
        sample.append(Data(count: 8))
        sample.append(avU16(1))
        sample.append(avU16(16))
        sample.append(avU16(0))
        sample.append(avU16(0))
        sample.append(avU32(UInt32(timescale) << 16))
    }
    let stsd = avBox(
        "stsd",
        avU32(0) + avU32(1) + avBox(codec, sample)
    )
    let stts = avBox("stts", avU32(0) + avU32(1) + avU32(90) + avU32(sampleDelta))
    let stbl = avBox("stbl", stsd + stts)
    let minf = avBox("minf", stbl)
    let mdia = avBox("mdia", avBox("mdhd", mdhd) + avBox("hdlr", hdlr) + minf)
    let trak = avBox("trak", avBox("tkhd", tkhd) + mdia)
    let moov = avBox("moov", avBox("mvhd", mvhd) + trak)
    return ftyp + moov
}

private func avLE32(_ value: UInt32) -> Data {
    var le = value.littleEndian
    return Data(bytes: &le, count: 4)
}

private func avLE16(_ value: UInt16) -> Data {
    var le = value.littleEndian
    return Data(bytes: &le, count: 2)
}

func testISOBMFFLocalAssetProbe() {
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    precondition(asset.url == url)
    precondition(abs(asset.duration.seconds - 3) < 0.01)
    precondition(asset.tracks.count == 1)
    let track = asset.tracks[0]
    precondition(track.trackID == 1)
    precondition(track.mediaType == .video)
    precondition(track.naturalSize.width == 320)
    precondition(track.naturalSize.height == 240)
    precondition(track.preferredTransform == .identity)
    precondition(abs(Double(track.nominalFrameRate) - 30) < 0.01)
    precondition(track.naturalTimeScale == 600)
    precondition(track.hasMediaCharacteristic(.visual))
    precondition(!track.hasMediaCharacteristic(.audible))
    precondition(track.isEnabled)
    precondition(asset.track(withTrackID: 1) === track)
    precondition(asset.tracks(withMediaType: .video).count == 1)
    precondition(asset.unusedTrackID() == 2)
    let item = AVPlayerItem(asset: asset)
    precondition(item.duration.seconds == asset.duration.seconds)
    precondition(item.tracks.count == 1)
    precondition(item.tracks[0].assetTrack?.trackID == 1)
    precondition(item.presentationSize.width == 320)
    let ranges = item.loadedTimeRanges
    precondition(ranges.count == 1)
    let range = AVCMTimeRangeValue.range(from: ranges[0])
    precondition(range.start.seconds == 0)
    precondition(abs(range.duration.seconds - 3) < 0.01)
}

func testM4ALocalAssetProbe() {
    let url = avWrite(
        avMakeFtypMoov(
            timescale: 44100,
            duration: 44100,
            width: 0,
            height: 0,
            handler: "soun",
            codec: "mp4a",
            sampleDelta: 1024
        ),
        suffix: "m4a"
    )
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    precondition(abs(asset.duration.seconds - 1) < 0.02)
    precondition(asset.tracks.count == 1)
    precondition(asset.tracks[0].mediaType == .audio)
    precondition(asset.tracks[0].hasMediaCharacteristic(.audible))
}

func testWAVLocalAssetProbe() {
    var wav = Data()
    wav.append(contentsOf: Array("RIFF".utf8))
    wav.append(avLE32(36 + 16000))
    wav.append(contentsOf: Array("WAVE".utf8))
    wav.append(contentsOf: Array("fmt ".utf8))
    wav.append(avLE32(16))
    wav.append(avLE16(1))
    wav.append(avLE16(1))
    wav.append(avLE32(8000))
    wav.append(avLE32(16000))
    wav.append(avLE16(2))
    wav.append(avLE16(16))
    wav.append(contentsOf: Array("data".utf8))
    wav.append(avLE32(16000))
    wav.append(Data(count: 16000))
    let url = avWrite(wav, suffix: "wav")
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    precondition(abs(asset.duration.seconds - 1) < 0.01)
    precondition(asset.tracks.count == 1)
    precondition(asset.tracks[0].mediaType == .audio)
    precondition(asset.tracks[0].naturalTimeScale == 8000)
}

func testAIFFLocalAssetProbe() {
    var comm = Data()
    comm.append(avU16(1))
    comm.append(avU32(8000))
    comm.append(avU16(16))
    comm.append(contentsOf: [
        0x40, 0x0B, 0xFA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ])
    let ssnd = avU32(0) + avU32(0) + Data(count: 16000)
    var form = Data()
    form.append(contentsOf: Array("FORM".utf8))
    let payload = Data(Array("AIFF".utf8)) + avBox("COMM", comm) + avBox("SSND", ssnd)
    form.append(avU32(UInt32(payload.count)))
    form.append(payload)
    let url = avWrite(form, suffix: "aiff")
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    precondition(abs(asset.duration.seconds - 1) < 0.05)
    precondition(asset.tracks[0].mediaType == .audio)
}

func testAVMutableCompositionInsertsLocalTracks() {
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let source = AVURLAsset(url: url)
    let composition = AVMutableComposition()
    try! composition.insertTimeRange(
        CMTimeRange(start: .zero, duration: source.duration),
        of: source,
        at: .zero
    )
    precondition(composition.tracks.count == 1)
    let track = composition.tracks[0]
    precondition(track.mediaType == .video)
    precondition(track.naturalSize.width == 320)
    precondition(abs(composition.duration.seconds - 3) < 0.01)
    let added = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
    precondition(added != nil)
    precondition(composition.tracks.count == 2)
    composition.removeTrack(added as! AVCompositionTrack)
    precondition(composition.tracks.count == 1)
}

func testMissingLocalAssetStaysFailClosed() {
    let url = URL(fileURLWithPath: "/tmp/openav-missing-\(UUID().uuidString).mp4")
    let asset = AVURLAsset(url: url)
    precondition(!asset.duration.isValid)
    precondition(asset.tracks.isEmpty)
    precondition(!asset.isPlayable)
}
