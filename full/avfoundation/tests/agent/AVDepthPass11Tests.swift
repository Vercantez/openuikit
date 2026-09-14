import Foundation
import AVFoundation

func testAVFragmentedMovieTrackQueries() {
    let movie = AVFragmentedMovie()
    precondition(movie.tracks.isEmpty)
    precondition(movie.track(withTrackID: 1) == nil)
    precondition(movie.tracks(withMediaType: .video).isEmpty)
    precondition(movie.tracks(withMediaCharacteristic: .visual).isEmpty)
    var loadedTrack: AVAssetTrack?
    var loadedTrackError: (any Error)?
    movie.loadTrack(withTrackID: 1) { track, error in
        loadedTrack = track
        loadedTrackError = error
    }
    precondition(loadedTrack == nil)
    precondition(loadedTrackError == nil)
    var loadedByType: [AVAssetTrack]?
    movie.loadTracks(withMediaType: .video) { tracks, error in
        loadedByType = tracks
        precondition(error == nil)
    }
    precondition(loadedByType?.isEmpty == true)
    var loadedByCharacteristic: [AVAssetTrack]?
    movie.loadTracks(withMediaCharacteristic: .visual) { tracks, error in
        loadedByCharacteristic = tracks
        precondition(error == nil)
    }
    precondition(loadedByCharacteristic?.isEmpty == true)
}

func testAVFragmentedMovieMinderMembership() {
    let movie = AVFragmentedMovie()
    let track = AVFragmentedMovieTrack()
    precondition(track.trackID == 0)
    let minder = AVFragmentedMovieMinder(movie: movie, mindingInterval: 0.5)
    precondition(minder.movies.isEmpty)
    minder.mindingInterval = 1.25
    precondition(minder.mindingInterval == 1.25)
    let extra = AVFragmentedMovie()
    minder.add(extra)
    precondition(minder.movies.isEmpty)
    minder.remove(extra)
    precondition(minder.movies.isEmpty)
}

func testAVMediaSelectionFailClosedQueries() {
    let selection = AVMediaSelection()
    precondition(selection.asset == nil)
    let group = AVMediaSelectionGroup()
    precondition(selection.selectedMediaOption(in: group) == nil)
    precondition(selection.mediaSelectionCriteriaCanBeAppliedAutomatically(to: group) == false)

    let mutable = AVMutableMediaSelection()
    precondition(mutable.asset == nil)
    mutable.select(nil, in: group)
    precondition(mutable.selectedMediaOption(in: group) == nil)
    mutable.select(AVMediaSelectionOption(), in: group)
    precondition(mutable.selectedMediaOption(in: group) == nil)
}

func testAVCustomMediaSelectionAndPresentationScheme() {
    let scheme = AVCustomMediaSelectionScheme()
    precondition(scheme.shouldOfferLanguageSelection == false)
    precondition(scheme.availableLanguages.isEmpty)

    let selector = AVMediaPresentationSelector()
    precondition(selector.identifier.isEmpty)
    precondition(selector.settings.isEmpty)
    precondition(selector.displayName(forLocaleIdentifier: "en").isEmpty)

    let setting = AVMediaPresentationSetting()
    precondition(setting.mediaCharacteristic.rawValue.isEmpty)
    precondition(setting.displayName(forLocaleIdentifier: "en").isEmpty)
}

func testAVMetadataFaceBodyObjectDefaults() {
    let body = AVMetadataBodyObject()
    precondition(body.bodyID == 0)
    precondition(AVMetadataCatBodyObject().bodyID == 0)
    precondition(AVMetadataDogBodyObject().bodyID == 0)
    precondition(AVMetadataHumanBodyObject().bodyID == 0)
    precondition(AVMetadataHumanFullBodyObject().bodyID == 0)
    _ = AVMetadataCatHeadObject()
    _ = AVMetadataDogHeadObject()
    let salient = AVMetadataSalientObject()
    precondition(salient.objectID == 0)
}

func testAVMetadataMachineReadableCodeDefaults() {
    let code = AVMetadataMachineReadableCodeObject()
    precondition(code.corners.isEmpty)
    precondition(code.stringValue == nil)
    precondition(code.descriptor == nil)
}

func testAVRenderedCaptionImageAndRegionEncoding() {
    let image = AVRenderedCaptionImage()
    _ = image.pixelBuffer
    _ = image.readOnlyPixelBuffer
    precondition(image.position == .zero)

    let region = AVCaptionRegion()
    region.encode(with: NSCoder())
}

func testAVMutableCaptionAttributeEditors() {
    let caption = AVMutableCaption()
    let range = NSRange(location: 0, length: 0)
    caption.setTextColor(CGColor(), in: range)
    caption.setBackgroundColor(CGColor(), in: range)
    caption.setFontWeight(.bold, in: range)
    caption.setFontStyle(.italic, in: range)
    caption.setDecoration(.underline, in: range)
    caption.setTextCombine(.all, in: range)
    caption.setRuby(AVCaption.Ruby(text: "ruby"), in: range)
    caption.removeTextColor(in: range)
    caption.removeBackgroundColor(in: range)
    caption.removeFontWeight(in: range)
    caption.removeFontStyle(in: range)
    caption.removeDecoration(in: range)
    caption.removeTextCombine(in: range)
    caption.removeRuby(in: range)
    precondition(caption.text.isEmpty)
}

func testAVCaptionRawValueIdentities() {
    let decorations: [(AVCaption.Decoration, UInt)] = [
        (.underline, 1 << 0),
        (.lineThrough, 1 << 1),
        (.overline, 1 << 2),
    ]
    for (value, raw) in decorations {
        precondition(value.rawValue == raw)
        precondition(AVCaption.Decoration(rawValue: raw) == value)
    }
    let settings: [(AVCaptionSettingsKey, String)] = [
        (.mediaType, "mediaType"),
        (.mediaSubType, "mediaSubType"),
        (.timeCodeFrameDuration, "timeCodeFrameDuration"),
        (.useDropFrameTimeCode, "useDropFrameTimeCode"),
    ]
    for (value, raw) in settings {
        precondition(value.rawValue == raw)
        precondition(AVCaptionSettingsKey(rawValue: raw) == value)
    }
    let objectTypes: [(AVMetadataObject.ObjectType, String)] = [
        (.face, "face"),
        (.qr, "qr"),
        (.humanBody, "humanBody"),
        (.salientObject, "salientObject"),
    ]
    for (value, raw) in objectTypes {
        precondition(value.rawValue == raw)
        precondition(AVMetadataObject.ObjectType(rawValue: raw) == value)
    }
    precondition(
        AVCaptionConversionWarning.WarningType(rawValue: "excessMediaData") == .excessMediaData
    )
    precondition(
        AVCaptionConversionWarning.WarningType("excessMediaData").rawValue == "excessMediaData"
    )
    precondition(
        AVCaptionConversionAdjustment.AdjustmentType(rawValue: "timeRange") == .timeRange
    )
    precondition(
        AVCaptionConversionAdjustment.AdjustmentType("timeRange").rawValue == "timeRange"
    )
}

func testAVMutableMovieTrackAppendFailClosed() {
    let track = AVMutableMovieTrack()
    let buffer = CMReadySampleBuffer(content: CMSampleBuffer.DynamicContent.portable)
    do {
        _ = try track.append(buffer)
        precondition(false, "AVMutableMovieTrack.append must stay fail-closed without a decoder")
    } catch {
        precondition((error as? AVError)?.code == .decoderNotFound)
    }
}

func testAVAssetRenewalAndPixelBufferAdaptorFailClosed() {
    let renewal = AVAssetResourceRenewalRequest()
    precondition(renewal.isFinished == false)
    precondition(renewal.isCancelled == false)

    let input = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input)
    precondition(adaptor.append(CVPixelBuffer(), withPresentationTime: .zero) == false)
}
