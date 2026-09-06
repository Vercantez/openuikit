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
    mdhd.append(avU16(0x15C7))
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
    let stsz = avBox("stsz", avU32(0) + avU32(1000) + avU32(90))
    let stbl = avBox("stbl", stsd + stts + stsz)
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
    precondition(track.languageCode == "eng")
    precondition(track.extendedLanguageTag == "eng")
    precondition(track.totalSampleDataLength == 90_000)
    precondition(abs(Double(track.estimatedDataRate) - 240_000) < 1)
    precondition(abs(track.minFrameDuration.seconds - (1.0 / 30.0)) < 0.001)
    precondition(track.timeRange.start == .zero)
    precondition(abs(track.timeRange.duration.seconds - 3) < 0.01)
    precondition(track.preferredVolume == 0)
    precondition(!track.isPlayable)
    precondition(!track.isDecodable)
    precondition(track.isSelfContained)
    precondition(track.asset === asset)
    precondition(track.commonMetadata.isEmpty)
    precondition(track.metadata.isEmpty)
    precondition(track.availableMetadataFormats.isEmpty)
    precondition(!track.hasAudioSampleDependencies)
    precondition(!track.requiresFrameReordering)
    precondition(track.segments.isEmpty)
    precondition(track.samplePresentationTime(forTrackTime: CMTime(seconds: 1, preferredTimescale: 600)).seconds == 1)
    precondition(track.makeSampleCursor(presentationTimeStamp: .zero) == nil)
    precondition(asset.preferredRate == 1)
    precondition(asset.preferredVolume == 0)
    precondition(!asset.isExportable)
    precondition(!asset.isReadable)
    precondition(!asset.isComposable)
    precondition(!asset.hasProtectedContent)
    precondition(!asset.containsFragments)
    precondition(!asset.canContainFragments)
    precondition(asset.lyrics == nil)
    precondition(asset.commonMetadata.isEmpty)
    precondition(asset.availableMetadataFormats.isEmpty)
    precondition(asset.metadata(forFormat: .quickTimeMetadata).isEmpty)
    precondition(item.isPlaybackLikelyToKeepUp)
    precondition(!item.isPlaybackBufferEmpty)
    precondition(!item.isPlaybackBufferFull)
    precondition(item.seekableTimeRanges.count == 1)
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
    precondition(abs(Double(asset.tracks[0].preferredVolume) - 1) < 0.01)
    precondition(asset.preferredVolume == 1)
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
    precondition(asset.tracks[0].totalSampleDataLength == 16000)
    precondition(abs(Double(asset.tracks[0].estimatedDataRate) - 128000) < 1)
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
    composition.removeTrack(added!)
    precondition(composition.tracks.count == 1)
    composition.insertEmptyTimeRange(
        CMTimeRange(start: composition.duration, duration: CMTime(seconds: 1, preferredTimescale: 1))
    )
    precondition(abs(composition.duration.seconds - 4) < 0.01)
    composition.scaleTimeRange(
        CMTimeRange(start: .zero, duration: composition.duration),
        toDuration: CMTime(seconds: 2, preferredTimescale: 1)
    )
    precondition(abs(composition.duration.seconds - 2) < 0.02)
    composition.removeTimeRange(
        CMTimeRange(start: .zero, duration: CMTime(seconds: 0.5, preferredTimescale: 1))
    )
    precondition(abs(composition.duration.seconds - 1.5) < 0.05)
}

func testMissingLocalAssetStaysFailClosed() {
    let url = URL(fileURLWithPath: "/tmp/openav-missing-\(UUID().uuidString).mp4")
    let asset = AVURLAsset(url: url)
    precondition(!asset.duration.isValid)
    precondition(asset.tracks.isEmpty)
    precondition(!asset.isPlayable)
}

func testISOBMFFAudioAndVideoTracks() {
    let url = avWrite(avMakeDualTrackMovie(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    precondition(asset.tracks.count == 2)
    precondition(asset.tracks(withMediaType: .video).count == 1)
    precondition(asset.tracks(withMediaType: .audio).count == 1)
    precondition(asset.tracks(withMediaCharacteristic: .visual).count == 1)
    precondition(asset.tracks(withMediaCharacteristic: .audible).count == 1)
    precondition(asset.unusedTrackID() == 3)
    precondition(asset.track(withTrackID: 2)?.mediaType == .audio)
}

private func avReadBoxes(_ data: Data) -> [(String, Data)] {
    var result: [(String, Data)] = []
    var offset = 0
    while offset + 8 <= data.count {
        let size = data[offset..<(offset + 4)].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let type = String(bytes: data[(offset + 4)..<(offset + 8)], encoding: .ascii) ?? ""
        let total = Int(size)
        if total < 8 || offset + total > data.count { break }
        result.append((type, data[(offset + 8)..<(offset + total)]))
        offset += total
    }
    return result
}

private func avMakeDualTrackMovie() -> Data {
    let video = avMakeFtypMoov()
    let audio = avMakeFtypMoov(
        timescale: 44100,
        duration: 132300,
        width: 0,
        height: 0,
        handler: "soun",
        codec: "mp4a",
        sampleDelta: 1024
    )
    func trak(from data: Data) -> Data {
        guard let moov = avReadBoxes(data).first(where: { $0.0 == "moov" }) else { return Data() }
        guard let trak = avReadBoxes(moov.1).first(where: { $0.0 == "trak" }) else { return Data() }
        return avBox("trak", trak.1)
    }
    let ftyp = avBox("ftyp", avU32(0x69736f6d) + avU32(0) + avU32(0x69736f6d))
    var mvhd = Data()
    mvhd.append(avU32(0))
    mvhd.append(avU32(0))
    mvhd.append(avU32(0))
    mvhd.append(avU32(600))
    mvhd.append(avU32(1800))
    mvhd.append(avU32(0x00010000))
    mvhd.append(avU16(0x0100))
    mvhd.append(avU16(0))
    mvhd.append(Data(count: 8))
    mvhd.append(avIdentityMatrix())
    mvhd.append(Data(count: 24))
    mvhd.append(avU32(3))
    var audioTrak = trak(from: audio)
    // version-0 tkhd track_id is 12 bytes into the tkhd payload; the trak box
    // contains tkhd as the first child (size 4 + type 4 + payload).
    let audioBoxes = avReadBoxes(audioTrak)
    if let tkhd = audioBoxes.first(where: { $0.0 == "tkhd" }), tkhd.1.count >= 16 {
        var payload = tkhd.1
        payload.replaceSubrange(12..<16, with: avU32(2))
        var rebuilt = Data()
        for (type, body) in audioBoxes {
            rebuilt.append(avBox(type, type == "tkhd" ? payload : body))
        }
        audioTrak = avBox("trak", rebuilt)
    }
    let moov = avBox("moov", avBox("mvhd", mvhd) + trak(from: video) + audioTrak)
    return ftyp + moov
}

func testLocalAssetLoadAccessors() {
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    let loaded = avfAwait { try await asset.load(.duration, .tracks, .isPlayable) }
    switch loaded {
    case .success(let triple):
        precondition(abs(triple.0.seconds - 3) < 0.01)
        precondition(triple.1.count == 1)
        precondition(triple.2 == false)
    default:
        preconditionFailure("local load must complete")
    }
    switch asset.status(of: .duration) {
    case .loaded(let time):
        precondition(abs(time.seconds - 3) < 0.01)
    default:
        preconditionFailure("duration should be loaded")
    }
    let track = avfAwait { try await asset.loadTrack(withTrackID: 1) }
    switch track {
    case .success(let loadedTrack):
        precondition(loadedTrack?.trackID == 1)
    default:
        preconditionFailure("loadTrack must complete")
    }
    let seen = AVFLocked(false)
    asset.loadTrack(withTrackID: 1) { loadedTrack, error in
        seen.store(true)
        precondition(error == nil)
        precondition(loadedTrack?.trackID == 1)
    }
    precondition(seen.load())
}

func testURLAssetAudiovisualTypes() {
    let types = AVURLAsset.audiovisualTypes()
    precondition(types.contains(.mp4))
    precondition(types.contains(.m4a))
    precondition(types.contains(.mov))
    let mime = AVURLAsset.audiovisualMIMETypes()
    precondition(mime.contains("video/mp4"))
    precondition(mime.contains("audio/wav"))
    precondition(!AVURLAsset.isPlayableExtendedMIMEType("video/mp4"))
    let url = URL(fileURLWithPath: "/tmp/openav-types.mp4")
    let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    precondition(!asset.mayRequireContentKeysForMediaDataProcessing)
    precondition(asset.variants.isEmpty)
    precondition(asset.assetCache == nil)
    _ = asset.httpSessionIdentifier
    _ = asset.resourceLoader
    let composition = AVMutableComposition()
    precondition(asset.compatibleTrack(for: AVCompositionTrack()) == nil)
    _ = composition
}
