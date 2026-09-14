import Foundation
import AVFoundation

private func av10U32(_ value: UInt32) -> Data {
    var be = value.bigEndian
    return Data(bytes: &be, count: 4)
}

private func av10U16(_ value: UInt16) -> Data {
    var be = value.bigEndian
    return Data(bytes: &be, count: 2)
}

private func av10Box(_ type: String, _ payload: Data) -> Data {
    var size = UInt32(8 + payload.count).bigEndian
    var data = Data(bytes: &size, count: 4)
    data.append(contentsOf: Array(type.utf8.prefix(4)))
    data.append(payload)
    return data
}

private func av10IdentityMatrix() -> Data {
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

private func av10Write(_ data: Data, suffix: String) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openav10-\(UUID().uuidString).\(suffix)")
    try! data.write(to: url)
    return url
}

func testOraclePinnedMediaFileAndCodecRawValues() {
    let media: [(AVMediaType, String)] = [
        (.video, "vide"),
        (.audio, "soun"),
        (.text, "text"),
        (.closedCaption, "clcp"),
        (.subtitle, "sbtl"),
        (.timecode, "tmcd"),
        (.metadata, "meta"),
        (.muxed, "muxx"),
        (.haptic, "hapt"),
        (.depthData, "dpth"),
        (.auxiliaryPicture, "auxv"),
    ]
    for (value, raw) in media {
        precondition(value.rawValue == raw)
        precondition(AVMediaType(rawValue: raw) == value)
        precondition(AVMediaType(raw) == value)
    }
    precondition(AVMediaCharacteristic("AVMediaCharacteristicVisual") == .visual)
    precondition(AVMediaCharacteristic(rawValue: "public.translation.dubbed") == .dubbedTranslation)
    precondition(AVMediaCharacteristic.voiceOverTranslation.rawValue == "public.translation.voice-over")
    precondition(AVMediaCharacteristic.tactileMinimal.rawValue == "public.haptics.minimal")
    precondition(AVMediaCharacteristic.carriesVideoStereoMetadata.rawValue == "com.apple.quicktime.video.stereo-metadata")
    precondition(AVMediaCharacteristic.machineGenerated.rawValue == "public.machine-generated")
    precondition(AVMediaCharacteristic.isOriginalContent.rawValue == "public.original-content")
    precondition(AVMediaCharacteristic.containsOnlyForcedSubtitles.rawValue == "public.subtitles.forced-only")
    precondition(AVMediaCharacteristic.indicatesHorizontalFieldOfView.rawValue == "public.indicates-horizontal-field-of-view")
    precondition(AVMediaCharacteristic.indicatesNonRectilinearProjection.rawValue == "public.indicates-non-rectilinear-projection")

    let files: [(AVFileType, String)] = [
        (.mp4, "public.mpeg-4"),
        (.mov, "com.apple.quicktime-movie"),
        (.m4a, "com.apple.m4a-audio"),
        (.m4v, "com.apple.m4v-video"),
        (.mobile3GPP, "public.3gpp"),
        (.mobile3GPP2, "public.3gpp2"),
        (.caf, "com.apple.coreaudio-format"),
        (.wav, "com.microsoft.waveform-audio"),
        (.aiff, "public.aiff-audio"),
        (.aifc, "public.aifc-audio"),
        (.amr, "org.3gpp.adaptive-multi-rate-audio"),
        (.mp3, "public.mp3"),
        (.au, "public.au-audio"),
        (.ac3, "public.ac3-audio"),
        (.eac3, "public.enhanced-ac3-audio"),
        (.jpg, "public.jpeg"),
        (.dng, "com.adobe.raw-image"),
        (.heic, "public.heic"),
        (.avci, "public.avci"),
        (.heif, "public.heif"),
        (.tif, "public.tiff"),
        (.appleiTT, "com.apple.itunes-timed-text"),
        (.SCC, "com.scenarist.closed-caption"),
        (.AHAP, "public.haptics-content"),
        (.qta, "com.apple.quicktime-audio"),
        (.dcm, "org.nema.dicom"),
    ]
    for (value, raw) in files {
        precondition(value.rawValue == raw, "\(value.rawValue) != \(raw)")
        precondition(AVFileType(rawValue: raw) == value)
        precondition(AVFileType(raw) == value)
    }
    precondition(AVFileTypeProfile.mpeg4AppleHLS.rawValue == "MPEG4AppleHLS")
    precondition(AVFileTypeProfile.mpeg4CMAFCompliant.rawValue == "MPEG4CMAFCompliant")
    precondition(AVFileTypeProfile(rawValue: "MPEG4AppleHLS") == .mpeg4AppleHLS)
    precondition(AVFileTypeProfile("MPEG4CMAFCompliant") == .mpeg4CMAFCompliant)

    precondition(AVVideoCodecType(rawValue: "avc1") == .h264)
    precondition(AVVideoCodecType("hvc1") == .hevc)
    precondition(AVMetadataKey("title") == .commonKeyTitle)
    precondition(AVMetadataKey(rawValue: "artist") == .commonKeyArtist)
    precondition(AVMetadataIdentifier("common/title") == .commonIdentifierTitle)
    precondition(AVMetadataIdentifier(rawValue: "common/software") == .commonIdentifierSoftware)
    precondition(AVMetadataKeySpace("comn") == .common)
    precondition(AVMetadataKeySpace(rawValue: "udta") == .quickTimeUserData)
    precondition(AVMetadataFormat(rawValue: "com.apple.itunes") == .iTunesMetadata)
    precondition(AVMetadataExtraAttributeKey("info") == .info)
}

func testAVEdgeWidthsAndPixelAspectRatioValues() {
    let zeroEdges = AVEdgeWidths()
    precondition(zeroEdges.left == 0)
    precondition(zeroEdges.top == 0)
    precondition(zeroEdges.right == 0)
    precondition(zeroEdges.bottom == 0)
    let edges = AVEdgeWidths(left: 1, top: 2, right: 3, bottom: 4)
    precondition(edges.left == 1)
    precondition(edges.top == 2)
    precondition(edges.right == 3)
    precondition(edges.bottom == 4)

    let zeroPAR = AVPixelAspectRatio()
    precondition(zeroPAR.horizontalSpacing == 0)
    precondition(zeroPAR.verticalSpacing == 0)
    let par = AVPixelAspectRatio(horizontalSpacing: 16, verticalSpacing: 9)
    precondition(par.horizontalSpacing == 16)
    precondition(par.verticalSpacing == 9)
}

func testAVDateRangeAndTimedMetadataGroups() {
    let title = AVMutableMetadataItem()
    title.identifier = .commonIdentifierTitle
    title.value = "Depth" as NSString
    let start = Date(timeIntervalSince1970: 10)
    let end = Date(timeIntervalSince1970: 20)
    let dated = AVDateRangeMetadataGroup(items: [title], start: start, end: end)
    precondition(dated.items.count == 1)
    precondition(dated.items[0].stringValue == "Depth")
    precondition(dated.startDate.timeIntervalSince1970 == 10)
    precondition(dated.endDate?.timeIntervalSince1970 == 20)
    precondition(dated.classifyingLabel == nil)
    precondition(dated.uniqueID == nil)

    let mutableDate = AVMutableDateRangeMetadataGroup()
    mutableDate.items = [title]
    mutableDate.startDate = start
    mutableDate.endDate = end
    precondition(mutableDate.items.count == 1)
    precondition(mutableDate.startDate.timeIntervalSince1970 == 10)
    precondition(mutableDate.endDate?.timeIntervalSince1970 == 20)

    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: 1.5, preferredTimescale: 10))
    let timed = AVTimedMetadataGroup(items: [title], timeRange: range)
    precondition(timed.items.count == 1)
    precondition(abs(timed.timeRange.duration.seconds - 1.5) < 0.001)
    precondition(timed.copyFormatDescription() == nil)
    precondition(AVTimedMetadataGroup(sampleBuffer: CMSampleBuffer()) == nil)
    precondition(AVTimedMetadataGroup(sampleBuffer: CMReadySampleBuffer(content: CMSampleBuffer.DynamicContent.portable)) == nil)

    let mutableTimed = AVMutableTimedMetadataGroup()
    mutableTimed.items = [title]
    mutableTimed.timeRange = range
    precondition(mutableTimed.items.count == 1)
    precondition(abs(mutableTimed.timeRange.duration.seconds - 1.5) < 0.001)

    let group = AVMetadataGroup()
    precondition(group.items.isEmpty)
    precondition(group.classifyingLabel == nil)
    precondition(group.uniqueID == nil)
}

func testAVFragmentedAssetLocalProbeAndMinder() {
    let ftyp = av10Box("ftyp", av10U32(0x69736f6d) + av10U32(0) + av10U32(0x69736f6d))
    var mvhd = Data()
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(600))
    mvhd.append(av10U32(1800))
    mvhd.append(av10U32(0x00010000))
    mvhd.append(av10U16(0x0100))
    mvhd.append(av10U16(0))
    mvhd.append(Data(count: 8))
    mvhd.append(av10IdentityMatrix())
    mvhd.append(Data(count: 24))
    mvhd.append(av10U32(9))
    var tkhd = Data()
    tkhd.append(av10U32(0x000003))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(1))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(1800))
    tkhd.append(Data(count: 8))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10IdentityMatrix())
    tkhd.append(av10U32(UInt32(320) << 16))
    tkhd.append(av10U32(UInt32(240) << 16))
    var mdhd = Data()
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(600))
    mdhd.append(av10U32(1800))
    mdhd.append(av10U16(0x15C7))
    mdhd.append(av10U16(0))
    var hdlr = Data()
    hdlr.append(av10U32(0))
    hdlr.append(av10U32(0))
    hdlr.append(contentsOf: Array("vide".utf8))
    hdlr.append(Data(count: 12))
    hdlr.append(contentsOf: Array("VideoHandler\0".utf8))
    var sample = Data(count: 6)
    sample.append(av10U16(1))
    sample.append(av10U16(0))
    sample.append(av10U16(0))
    sample.append(Data(count: 12))
    sample.append(av10U16(320))
    sample.append(av10U16(240))
    sample.append(av10U32(0x00480000))
    sample.append(av10U32(0x00480000))
    sample.append(av10U32(0))
    sample.append(av10U16(1))
    sample.append(Data(count: 32))
    sample.append(av10U16(0x0018))
    sample.append(av10U16(0xFFFF))
    let stsd = av10Box("stsd", av10U32(0) + av10U32(1) + av10Box("avc1", sample))
    let stts = av10Box("stts", av10U32(0) + av10U32(1) + av10U32(90) + av10U32(20))
    let stsz = av10Box("stsz", av10U32(0) + av10U32(1000) + av10U32(90))
    let mdia = av10Box("mdia", av10Box("mdhd", mdhd) + av10Box("hdlr", hdlr) + av10Box("minf", av10Box("stbl", stsd + stts + stsz)))
    let trak = av10Box("trak", av10Box("tkhd", tkhd) + mdia)
    let url = av10Write(ftyp + av10Box("moov", av10Box("mvhd", mvhd) + trak), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }

    let factory = AVFragmentedAsset.fragmentedAsset(with: url, options: nil)
    precondition(factory.url == url)
    precondition(factory.tracks.count == 1)
    precondition(factory.tracks[0].mediaType == .video)
    precondition(factory.track(withTrackID: 1)?.mediaType == .video)
    precondition(factory.tracks(withMediaType: .video).count == 1)
    precondition(factory.tracks(withMediaCharacteristic: .visual).count == 1)
    precondition(factory.unusedTrackID() == 9)
    var loadedType: [AVAssetTrack]?
    factory.loadTracks(withMediaType: .video) { tracks, error in
        loadedType = tracks
        precondition(error == nil)
    }
    precondition(loadedType?.count == 1)
    var loadedChar: [AVAssetTrack]?
    factory.loadTracks(withMediaCharacteristic: .visual) { tracks, error in
        loadedChar = tracks
        precondition(error == nil)
    }
    precondition(loadedChar?.count == 1)
    var loadedTrack: AVAssetTrack?
    factory.loadTrack(withTrackID: 1) { track, error in
        loadedTrack = track
        precondition(error == nil)
    }
    precondition(loadedTrack?.trackID == 1)
    precondition(!factory.isAssociatedWithFragmentMinder)

    let minder = AVFragmentedAssetMinder(asset: factory, mindingInterval: 0.5)
    precondition(minder.mindingInterval == 0.5)
    precondition(minder.assets.count == 1)
    precondition(factory.isAssociatedWithFragmentMinder)
    minder.mindingInterval = 1.25
    precondition(minder.mindingInterval == 1.25)
    let extra = AVFragmentedAsset(url: url)
    minder.addFragmentedAsset(extra)
    precondition(minder.assets.count == 2)
    minder.removeFragmentedAsset(extra)
    precondition(minder.assets.count == 1)
    _ = AVFragmentedAssetTrack()
}

func testAVErrorBridgedNSErrorWitnesses() {
    let stamped = AVError(.decoderNotFound, userInfo: ["reason": "none"])
    precondition(stamped.errorCode == -11833)
    precondition((stamped as CustomNSError).errorUserInfo["reason"] as? String == "none")
    precondition(!stamped.localizedDescription.isEmpty)
    precondition(stamped.hashValue == AVError(.decoderNotFound).hashValue)
    precondition(AVError(.decoderNotFound) == AVError(.decoderNotFound))
    precondition(AVError.Code.decoderNotFound ~= stamped)
    precondition(AVError(rawValue: -11800)?.code == .unknown)
    precondition(AVError(rawValue: 0) == nil)
    var hasher = Hasher()
    stamped.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAVAssetCacheSegmentReportAndTrackGroupFailClosed() {
    let cache = AVAssetCache()
    precondition(!cache.isPlayableOffline)
    precondition(cache.mediaSelectionOptions(in: AVMediaSelectionGroup()).isEmpty)
    precondition(cache.mediaPresentationLanguages(for: AVMediaSelectionGroup()).isEmpty)

    let report = AVAssetSegmentReport()
    precondition(report.segmentType == .initialization)
    precondition(report.trackReports.isEmpty)
    let sample = AVAssetSegmentReportSampleInformation()
    precondition(sample.presentationTimeStamp == .zero)
    precondition(sample.offset == 0)
    precondition(sample.length == 0)
    precondition(!sample.isSyncSample)
    let trackReport = AVAssetSegmentTrackReport()
    precondition(trackReport.trackID == 0)
    precondition(trackReport.mediaType.rawValue.isEmpty)
    precondition(trackReport.earliestPresentationTimeStamp == .zero)
    precondition(trackReport.duration == .zero)
    precondition(trackReport.firstVideoSampleInformation == nil)

    let group = AVAssetTrackGroup()
    precondition(group.trackIDs.isEmpty)
    let emptySegment = AVAssetTrackSegment()
    precondition(emptySegment.isEmpty)
    precondition(emptySegment.timeMapping.target.duration == .zero)
    precondition(AVAssetTrackGroupOutputHandling(rawValue: 1) == .preserveAlternateTracks)
    precondition(AVAssetReferenceRestrictions(rawValue: 1 << 4) == .forbidAll)
}

func testAVAssetSynchronousLoadCompletionHandlers() {
    let ftyp = av10Box("ftyp", av10U32(0x69736f6d) + av10U32(0) + av10U32(0x69736f6d))
    var mvhd = Data()
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(600))
    mvhd.append(av10U32(600))
    mvhd.append(av10U32(0x00010000))
    mvhd.append(av10U16(0x0100))
    mvhd.append(av10U16(0))
    mvhd.append(Data(count: 8))
    mvhd.append(av10IdentityMatrix())
    mvhd.append(Data(count: 24))
    mvhd.append(av10U32(2))
    var tkhd = Data()
    tkhd.append(av10U32(0x000003))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(1))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(600))
    tkhd.append(Data(count: 8))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10IdentityMatrix())
    tkhd.append(av10U32(UInt32(64) << 16))
    tkhd.append(av10U32(UInt32(64) << 16))
    var mdhd = Data()
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(600))
    mdhd.append(av10U32(600))
    mdhd.append(av10U16(0x15C7))
    mdhd.append(av10U16(0))
    var hdlr = Data()
    hdlr.append(av10U32(0))
    hdlr.append(av10U32(0))
    hdlr.append(contentsOf: Array("vide".utf8))
    hdlr.append(Data(count: 12))
    var sample = Data(count: 6)
    sample.append(av10U16(1))
    sample.append(Data(count: 70))
    let stsd = av10Box("stsd", av10U32(0) + av10U32(1) + av10Box("avc1", sample))
    let mdia = av10Box("mdia", av10Box("mdhd", mdhd) + av10Box("hdlr", hdlr) + av10Box("minf", av10Box("stbl", stsd)))
    let url = av10Write(
        ftyp + av10Box("moov", av10Box("mvhd", mvhd) + av10Box("trak", av10Box("tkhd", tkhd) + mdia)),
        suffix: "mp4"
    )
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    var metadata: [AVMetadataItem]?
    asset.loadMetadata(for: .quickTimeUserData) { items, error in
        metadata = items
        precondition(error == nil)
    }
    precondition(metadata?.isEmpty == true)
    var chapters: [AVTimedMetadataGroup]?
    asset.loadChapterMetadataGroups(bestMatchingPreferredLanguages: ["en"]) { groups, error in
        chapters = groups
        precondition(error == nil)
    }
    precondition(chapters?.isEmpty == true)
    var sawSelection = false
    asset.loadMediaSelectionGroup(for: .audible) { group, error in
        sawSelection = true
        precondition(group == nil)
        precondition(error == nil)
    }
    precondition(sawSelection)
    var tracks: [AVAssetTrack]?
    asset.loadTracks(withMediaType: .video) { loaded, error in
        tracks = loaded
        precondition(error == nil)
    }
    precondition(tracks?.count == 1)
    var chars: [AVAssetTrack]?
    asset.loadTracks(withMediaCharacteristic: .visual) { loaded, error in
        chars = loaded
        precondition(error == nil)
    }
    precondition(chars?.count == 1)

    let compositionTrack = AVMutableComposition().addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
    var compatible: AVAssetTrack?
    asset.findCompatibleTrack(for: compositionTrack) { track, error in
        compatible = track
        precondition(error == nil)
    }
    precondition(compatible?.mediaType == .video)
    _ = AVPartialAsyncProperty<AVURLAsset>.tracks
    _ = AVPartialAsyncProperty<AVURLAsset>.variants
}

func testISOBMFFRemainingProbeFields() {
    let ftyp = av10Box("ftyp", av10U32(0x69736f6d) + av10U32(0) + av10U32(0x69736f6d))
    var mvhd = Data()
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(0))
    mvhd.append(av10U32(600))
    mvhd.append(av10U32(2400))
    mvhd.append(av10U32(0x00010000))
    mvhd.append(av10U16(0x0100))
    mvhd.append(av10U16(0))
    mvhd.append(Data(count: 8))
    mvhd.append(av10IdentityMatrix())
    mvhd.append(Data(count: 24))
    mvhd.append(av10U32(4))
    var tkhd = Data()
    tkhd.append(av10U32(0x000003))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(1))
    tkhd.append(av10U32(0))
    tkhd.append(av10U32(2400))
    tkhd.append(Data(count: 8))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10U16(0))
    tkhd.append(av10IdentityMatrix())
    tkhd.append(av10U32(UInt32(320) << 16))
    tkhd.append(av10U32(UInt32(240) << 16))
    var elst = Data()
    elst.append(av10U32(0))
    elst.append(av10U32(2))
    elst.append(av10U32(600))
    elst.append(av10U32(0xFFFFFFFF))
    elst.append(av10U32(0x00010000))
    elst.append(av10U32(1800))
    elst.append(av10U32(0))
    elst.append(av10U32(0x00010000))
    var mdhd = Data()
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(0))
    mdhd.append(av10U32(600))
    mdhd.append(av10U32(1800))
    mdhd.append(av10U16(0x15C7))
    mdhd.append(av10U16(0))
    var hdlr = Data()
    hdlr.append(av10U32(0))
    hdlr.append(av10U32(0))
    hdlr.append(contentsOf: Array("vide".utf8))
    hdlr.append(Data(count: 12))
    var sample = Data(count: 6)
    sample.append(av10U16(1))
    sample.append(av10U16(0))
    sample.append(av10U16(0))
    sample.append(Data(count: 12))
    sample.append(av10U16(320))
    sample.append(av10U16(240))
    sample.append(av10U32(0x00480000))
    sample.append(av10U32(0x00480000))
    sample.append(av10U32(0))
    sample.append(av10U16(1))
    sample.append(Data(count: 32))
    sample.append(av10U16(0x0018))
    sample.append(av10U16(0xFFFF))
    sample.append(av10Box("pasp", av10U32(16) + av10U32(9)))
    let stsd = av10Box("stsd", av10U32(0) + av10U32(1) + av10Box("avc1", sample))
    let stts = av10Box("stts", av10U32(0) + av10U32(1) + av10U32(90) + av10U32(20))
    let stsz = av10Box("stsz", av10U32(0) + av10U32(1000) + av10U32(90))
    let urlBox = av10Box("url ", av10U32(1))
    let dref = av10Box("dref", av10U32(0) + av10U32(1) + urlBox)
    let minf = av10Box("minf", av10Box("dinf", dref) + av10Box("stbl", stsd + stts + stsz))
    let mdia = av10Box("mdia", av10Box("mdhd", mdhd) + av10Box("hdlr", hdlr) + minf)
    let trak = av10Box("trak", av10Box("tkhd", tkhd) + av10Box("edts", av10Box("elst", elst)) + mdia)
    var name = Data()
    name.append(av10U16(0x15C7))
    name.append(contentsOf: Array("OpenTitle".utf8))
    let udta = av10Box("udta", av10Box("©nam", name))
    let url = av10Write(ftyp + av10Box("moov", av10Box("mvhd", mvhd) + trak + udta), suffix: "mp4")
    defer { try? FileManager.default.removeItem(at: url) }

    let asset = AVURLAsset(url: url)
    precondition(asset.unusedTrackID() == 4)
    precondition(asset.tracks[0].isSelfContained)
    precondition(asset.tracks[0].segment(forTrackTime: .zero) != nil)
    let shifted = asset.tracks[0].samplePresentationTime(forTrackTime: CMTime(seconds: 1, preferredTimescale: 600))
    precondition(abs(shifted.seconds - 0) < 0.02)
    precondition(asset.samplePresentationInvalidBeforeEdit())
    precondition(!asset.metadata.isEmpty)
    precondition(asset.commonMetadata.contains(where: { $0.stringValue == "OpenTitle" }))
    precondition(asset.availableMetadataFormats.contains(.quickTimeUserData))
    precondition(asset.metadata(forFormat: .quickTimeUserData).contains(where: { $0.stringValue == "OpenTitle" }))
}

private extension AVURLAsset {
    func samplePresentationInvalidBeforeEdit() -> Bool {
        !tracks[0].samplePresentationTime(forTrackTime: CMTime(seconds: 0.1, preferredTimescale: 600)).isValid
    }
}

func testWAVListInfoMetadataProbe() {
    func le32(_ value: UInt32) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 4)
    }
    func le16(_ value: UInt16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 2)
    }
    var info = Data()
    info.append(contentsOf: Array("INAM".utf8))
    info.append(le32(5))
    info.append(contentsOf: Array("Title".utf8))
    info.append(0)
    var wav = Data()
    wav.append(contentsOf: Array("RIFF".utf8))
    let listPayload = Data(Array("INFO".utf8)) + info
    let dataSize: UInt32 = 16000
    let riffSize = UInt32(4 + (8 + 16) + (8 + Int(dataSize)) + (8 + listPayload.count))
    wav.append(le32(riffSize))
    wav.append(contentsOf: Array("WAVE".utf8))
    wav.append(contentsOf: Array("fmt ".utf8))
    wav.append(le32(16))
    wav.append(le16(1))
    wav.append(le16(1))
    wav.append(le32(8000))
    wav.append(le32(16000))
    wav.append(le16(2))
    wav.append(le16(16))
    wav.append(contentsOf: Array("data".utf8))
    wav.append(le32(dataSize))
    wav.append(Data(count: Int(dataSize)))
    wav.append(contentsOf: Array("LIST".utf8))
    wav.append(le32(UInt32(listPayload.count)))
    wav.append(listPayload)
    let url = av10Write(wav, suffix: "wav")
    defer { try? FileManager.default.removeItem(at: url) }
    let asset = AVURLAsset(url: url)
    precondition(asset.tracks[0].mediaType == .audio)
    precondition(asset.commonMetadata.contains(where: { $0.stringValue == "Title" }))
    precondition(asset.availableMetadataFormats.contains(.quickTimeUserData))
}
