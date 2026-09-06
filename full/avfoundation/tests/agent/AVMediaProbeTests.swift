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
    sampleDelta: UInt32 = 20,
    trackID: UInt32 = 1
) -> Data {
    let ftyp = avBox("ftyp", avU32(0x69736f6d) + avU32(0) + avU32(0x69736f6d))
    let trak = avMakeTrak(
        timescale: timescale,
        duration: duration,
        width: width,
        height: height,
        handler: handler,
        codec: codec,
        sampleDelta: sampleDelta,
        trackID: trackID
    )
    let moov = avBox("moov", avMakeMvhd(timescale: timescale, duration: duration, nextTrackID: trackID + 1) + trak)
    return ftyp + moov
}

private func avMakeMvhd(timescale: UInt32, duration: UInt32, nextTrackID: UInt32) -> Data {
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
    mvhd.append(avU32(nextTrackID))
    return avBox("mvhd", mvhd)
}

private func avMakeTrak(
    timescale: UInt32,
    duration: UInt32,
    width: UInt16,
    height: UInt16,
    handler: String,
    codec: String,
    sampleDelta: UInt32,
    trackID: UInt32
) -> Data {
    var tkhd = Data()
    tkhd.append(avU32(0x000003))
    tkhd.append(avU32(0))
    tkhd.append(avU32(0))
    tkhd.append(avU32(trackID))
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
    return avBox("trak", avBox("tkhd", tkhd) + mdia)
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
    precondition(abs(Double(asset.preferredVolume) - 1) < 0.01)
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
        CMTimeRange(start: .zero, duration: CMTime(seconds: 0.5, preferredTimescale: 600))
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

private func avMakeDualTrackMovie() -> Data {
    let ftyp = avBox("ftyp", avU32(0x69736f6d) + avU32(0) + avU32(0x69736f6d))
    let video = avMakeTrak(
        timescale: 600,
        duration: 1800,
        width: 320,
        height: 240,
        handler: "vide",
        codec: "avc1",
        sampleDelta: 20,
        trackID: 1
    )
    let audio = avMakeTrak(
        timescale: 44100,
        duration: 132300,
        width: 0,
        height: 0,
        handler: "soun",
        codec: "mp4a",
        sampleDelta: 1024,
        trackID: 2
    )
    let moov = avBox(
        "moov",
        avMakeMvhd(timescale: 600, duration: 1800, nextTrackID: 3) + video + audio
    )
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

func testAVMovieLocalFileProbeAndWriteHeaderFailClosed() {
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let movie = AVMovie(url: url)
    precondition(movie.url == url)
    precondition(abs(movie.duration.seconds - 3) < 0.01)
    precondition(movie.tracks.count == 1)
    precondition(movie.tracks[0] is AVMovieTrack)
    precondition(movie.defaultMediaDataStorage == nil)
    var loadedTrack: AVAssetTrack?
    movie.loadTrack(withTrackID: 1) { track, error in
        loadedTrack = track
        precondition(error == nil)
    }
    precondition(loadedTrack?.trackID == 1)
    var loadedType: [AVAssetTrack]?
    movie.loadTracks(withMediaType: .video) { tracks, error in
        loadedType = tracks
        precondition(error == nil)
    }
    precondition(loadedType?.count == 1)
    var loadedChar: [AVAssetTrack]?
    movie.loadTracks(withMediaCharacteristic: .visual) { tracks, error in
        loadedChar = tracks
        precondition(error == nil)
    }
    precondition(loadedChar?.count == 1)
    precondition(AVMovie.movieTypes().contains(.mp4))
    precondition(movie.is(compatibleWithFileType: .mp4))
    precondition(!movie.canContainMovieFragments)
    precondition(!movie.containsMovieFragments)
    do {
        _ = try movie.makeMovieHeader(fileType: .mp4)
        preconditionFailure("makeMovieHeader must fail closed")
    } catch let error as AVError {
        precondition(error.code == .encoderNotFound)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
    do {
        try movie.writeHeader(to: url, fileType: .mp4, options: [])
        preconditionFailure("writeHeader must fail closed")
    } catch let error as AVError {
        precondition(error.code == .encoderNotFound)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testAVMutableMovieLocalEdits() {
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let source = AVURLAsset(url: url)
    let movie = try! AVMutableMovie(url: url, options: nil, error: ())
    precondition(movie.url == url)
    precondition(movie.tracks.count == 1)
    precondition(movie.tracks[0] is AVMutableMovieTrack)
    precondition(abs(movie.duration.seconds - 3) < 0.01)
    precondition(!movie.isPlayable)
    precondition(!movie.isExportable)
    precondition(!movie.isReadable)
    precondition(!movie.isComposable)
    precondition(!movie.hasProtectedContent)
    precondition(movie.lyrics == nil)
    precondition(movie.commonMetadata.isEmpty)
    precondition(movie.metadata.isEmpty)
    precondition(movie.availableMetadataFormats.isEmpty)
    precondition(movie.metadata(forFormat: .quickTimeMetadata).isEmpty)
    precondition(movie.availableChapterLocales.isEmpty)
    precondition(movie.chapterMetadataGroups(bestMatchingPreferredLanguages: ["en"]).isEmpty)
    precondition(
        movie.chapterMetadataGroups(withTitleLocale: Locale(identifier: "en"), containingItemsWithCommonKeys: nil).isEmpty
    )
    precondition(movie.mediaSelectionGroup(forMediaCharacteristic: .audible) == nil)
    precondition(movie.track(withTrackID: 1) != nil)
    precondition(movie.tracks(withMediaType: .video).count == 1)
    precondition(movie.tracks(withMediaCharacteristic: .visual).count == 1)
    precondition(movie.unusedTrackID() == 2)
    precondition(movie.trackGroups.isEmpty)
    precondition(movie.allMediaSelections.isEmpty)
    precondition(movie.creationDate == nil)
    precondition(!movie.canContainFragments)
    precondition(!movie.containsFragments)
    precondition(!movie.isCompatibleWithAirPlayVideo)
    precondition(!movie.isCompatibleWithSavedPhotosAlbum)
    precondition(!movie.providesPreciseDurationAndTiming)
    precondition(!movie.overallDurationHint.isValid || movie.overallDurationHint.seconds >= 0)
    _ = movie.preferredMediaSelection
    precondition(movie.availableMediaCharacteristicsWithMediaSelectionOptions.isEmpty)
    movie.timescale = 600
    precondition(movie.timescale == 600)
    movie.interleavingPeriod = CMTime(seconds: 1, preferredTimescale: 600)
    precondition(movie.interleavingPeriod.seconds == 1)
    do {
        try movie.insertTimeRange(
            CMTimeRange(start: .zero, duration: source.duration),
            of: source,
            at: .zero,
            copySampleData: true
        )
        preconditionFailure("copySampleData must fail closed")
    } catch let error as AVError {
        precondition(error.code == .decoderNotFound)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
    let empty = AVMutableMovie()
    try! empty.insertTimeRange(
        CMTimeRange(start: .zero, duration: source.duration),
        of: source,
        at: .zero,
        copySampleData: false
    )
    precondition(empty.tracks.count == 1)
    precondition(abs(empty.duration.seconds - 3) < 0.01)
    empty.insertEmptyTimeRange(CMTimeRange(start: empty.duration, duration: CMTime(seconds: 1, preferredTimescale: 1)))
    precondition(abs(empty.duration.seconds - 4) < 0.01)
    empty.scale(CMTimeRange(start: .zero, duration: empty.duration), toDuration: CMTime(seconds: 2, preferredTimescale: 1))
    precondition(abs(empty.duration.seconds - 2) < 0.05)
    empty.removeTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: 0.5, preferredTimescale: 600)))
    precondition(abs(empty.duration.seconds - 1.5) < 0.1)
    let added = empty.addMutableTrack(withMediaType: .audio, copySettingsFrom: nil, options: nil)
    precondition(added != nil)
    precondition(empty.tracks.count == 2)
    empty.removeTrack(added!)
    precondition(empty.tracks.count == 1)
    precondition(empty.mutableTrack(compatibleWith: source.tracks[0]) != nil)
    let copied = empty.addMutableTracksCopyingSettings(from: source.tracks, options: nil)
    precondition(!copied.isEmpty)
    let fromSettings = try! AVMutableMovie(settingsFrom: movie, options: nil)
    precondition(fromSettings.tracks.isEmpty)
    let bytes = try! Data(contentsOf: url)
    let fromData = try! AVMutableMovie(data: bytes, options: nil, error: ())
    precondition(fromData.tracks.count == 1)
    var mutableLoaded: AVAssetTrack?
    movie.loadTrack(withTrackID: 1) { track, error in
        mutableLoaded = track
        precondition(error == nil)
    }
    precondition(mutableLoaded != nil)
    movie.loadTracks(withMediaType: .video) { tracks, error in
        precondition(tracks?.count == 1)
        precondition(error == nil)
    }
    movie.loadTracks(withMediaCharacteristic: .visual) { tracks, error in
        precondition(tracks?.count == 1)
        precondition(error == nil)
    }
    precondition(movie.defaultMediaDataStorage == nil)
    do {
        _ = try AVMutableMovie(url: URL(fileURLWithPath: "/tmp/openav-missing-movie-\(UUID().uuidString).mp4"), options: nil, error: ())
        preconditionFailure("missing movie must fail")
    } catch let error as AVError {
        precondition(error.code == .failedToLoadMediaData)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testAVMutableMovieTrackEdits() {
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    let source = AVURLAsset(url: url)
    let movie = AVMutableMovie()
    let track = movie.addMutableTrack(withMediaType: .video, copySettingsFrom: source.tracks[0], options: nil)!
    try! track.insertTimeRange(
        CMTimeRange(start: .zero, duration: source.duration),
        of: source.tracks[0],
        at: .zero,
        copySampleData: false
    )
    precondition(track.mediaType == .video)
    precondition(track.naturalSize.width == 320)
    precondition(abs(track.timeRange.duration.seconds - 3) < 0.01)
    precondition(track.samplePresentationTime(forTrackTime: CMTime(seconds: 1, preferredTimescale: 600)).seconds == 1)
    precondition(track.segment(forTrackTime: .zero) == nil)
    precondition(!track.isPlayable)
    precondition(!track.isDecodable)
    precondition(track.isEnabled)
    track.isEnabled = false
    precondition(!track.isEnabled)
    track.isEnabled = true
    track.naturalSize = CGSize(width: 640, height: 480)
    precondition(track.naturalSize.width == 640)
    track.preferredVolume = 0.5
    precondition(abs(Double(track.preferredVolume) - 0.5) < 0.01)
    track.timescale = 600
    precondition(track.timescale == 600)
    track.layer = 2
    precondition(track.layer == 2)
    track.cleanApertureDimensions = CGSize(width: 10, height: 10)
    precondition(track.cleanApertureDimensions.width == 10)
    track.productionApertureDimensions = CGSize(width: 11, height: 11)
    precondition(track.productionApertureDimensions.height == 11)
    track.encodedPixelsDimensions = CGSize(width: 12, height: 12)
    precondition(track.encodedPixelsDimensions.width == 12)
    track.preferredMediaChunkSize = 8
    precondition(track.preferredMediaChunkSize == 8)
    track.preferredMediaChunkDuration = CMTime(seconds: 1, preferredTimescale: 1)
    precondition(track.preferredMediaChunkDuration.seconds == 1)
    track.preferredMediaChunkAlignment = 16
    precondition(track.preferredMediaChunkAlignment == 16)
    track.sampleReferenceBaseURL = url
    precondition(track.sampleReferenceBaseURL == url)
    track.isModified = true
    precondition(track.isModified)
    precondition(!track.hasProtectedContent)
    precondition(!track.hasAudioSampleDependencies)
    precondition(!track.requiresFrameReordering)
    precondition(track.canProvideSampleCursors == false)
    precondition(track.formatDescriptions.isEmpty)
    precondition(track.commonMetadata.isEmpty)
    precondition(track.metadata.isEmpty)
    precondition(track.availableMetadataFormats.isEmpty)
    precondition(track.metadata(forFormat: .quickTimeMetadata).isEmpty)
    precondition(track.availableTrackAssociationTypes.isEmpty)
    precondition(track.alternateGroupID == 0)
    precondition(track.mediaDataStorage == nil)
    precondition(track.segments.isEmpty)
    precondition(track.hasMediaCharacteristic(.visual))
    track.insertEmptyTimeRange(CMTimeRange(start: track.timeRange.duration, duration: CMTime(seconds: 1, preferredTimescale: 1)))
    precondition(abs(track.timeRange.duration.seconds - 4) < 0.05)
    track.scaleTimeRange(
        CMTimeRange(start: .zero, duration: track.timeRange.duration),
        toDuration: CMTime(seconds: 2, preferredTimescale: 1)
    )
    precondition(abs(track.timeRange.duration.seconds - 2) < 0.1)
    track.removeTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: 0.5, preferredTimescale: 600)))
    let other = movie.addMutableTrack(withMediaType: .audio, copySettingsFrom: nil, options: nil)!
    track.addTrackAssociation(to: other, type: .audioFallback)
    precondition(track.associatedTracks(ofType: .audioFallback).count == 1)
    track.removeTrackAssociation(to: other, type: .audioFallback)
    precondition(track.associatedTracks(ofType: .audioFallback).isEmpty)
    track.replaceFormatDescription(CMFormatDescription(), with: CMFormatDescription())
    precondition(!track.insertMediaTimeRange(.zero, into: .zero))
    do {
        try track.append(CMSampleBuffer(), decodeTime: nil, presentationTime: nil)
        preconditionFailure("append sample must fail closed")
    } catch let error as AVError {
        precondition(error.code == .decoderNotFound)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
    do {
        try track.insertTimeRange(
            CMTimeRange(start: .zero, duration: source.duration),
            of: source.tracks[0],
            at: .zero,
            copySampleData: true
        )
        preconditionFailure("copySampleData must fail closed")
    } catch let error as AVError {
        precondition(error.code == .decoderNotFound)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testAVCompositionFailClosedSurface() {
    let composition = AVMutableComposition(urlAssetInitializationOptions: ["k": "v"])
    precondition(composition.urlAssetInitializationOptions["k"] as? String == "v")
    precondition(composition.naturalSize == .zero)
    precondition(composition.tracks.isEmpty)
    precondition(!composition.duration.isValid)
    precondition(!composition.isPlayable)
    precondition(!composition.isExportable)
    precondition(!composition.isReadable)
    precondition(!composition.isComposable)
    precondition(!composition.hasProtectedContent)
    precondition(composition.lyrics == nil)
    precondition(composition.commonMetadata.isEmpty)
    precondition(composition.metadata.isEmpty)
    precondition(composition.availableMetadataFormats.isEmpty)
    precondition(composition.metadata(forFormat: .quickTimeMetadata).isEmpty)
    precondition(composition.availableChapterLocales.isEmpty)
    precondition(composition.chapterMetadataGroups(bestMatchingPreferredLanguages: []).isEmpty)
    precondition(
        composition.chapterMetadataGroups(withTitleLocale: Locale(identifier: "en"), containingItemsWithCommonKeys: nil).isEmpty
    )
    precondition(composition.mediaSelectionGroup(forMediaCharacteristic: .visual) == nil)
    precondition(composition.tracks(withMediaType: .video).isEmpty)
    precondition(composition.tracks(withMediaCharacteristic: .visual).isEmpty)
    precondition(composition.trackGroups.isEmpty)
    precondition(composition.allMediaSelections.isEmpty)
    precondition(composition.creationDate == nil)
    precondition(!composition.canContainFragments)
    precondition(!composition.containsFragments)
    precondition(!composition.isCompatibleWithAirPlayVideo)
    precondition(!composition.isCompatibleWithSavedPhotosAlbum)
    precondition(!composition.providesPreciseDurationAndTiming)
    _ = composition.preferredMediaSelection
    precondition(composition.availableMediaCharacteristicsWithMediaSelectionOptions.isEmpty)
    let url = avWrite(avMakeFtypMoov(), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }
    try! composition.insertTimeRange(
        CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 600)),
        of: AVURLAsset(url: url),
        at: .zero
    )
    precondition(composition.naturalSize.width == 320)
    precondition(abs(composition.duration.seconds - 3) < 0.01)
    precondition(composition.preferredTransform == .identity)
    composition.loadTrack(withTrackID: 1) { track, error in
        precondition(track != nil)
        precondition(error == nil)
    }
    composition.loadTracks(withMediaType: .video) { tracks, error in
        precondition(tracks?.count == 1)
        precondition(error == nil)
    }
    composition.loadTracks(withMediaCharacteristic: .visual) { tracks, error in
        precondition(tracks?.count == 1)
        precondition(error == nil)
    }
}
