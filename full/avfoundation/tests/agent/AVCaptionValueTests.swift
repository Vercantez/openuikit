import Foundation
import AVFoundation

func testAVCaptionStoresTextTimeRangeAndMutableOverrides() {
    let range = CMTimeRange(
        start: CMTime(seconds: 1, preferredTimescale: 600),
        duration: CMTime(seconds: 2, preferredTimescale: 600)
    )
    let caption = AVCaption("Hello", timeRange: range)
    precondition(caption.text == "Hello")
    precondition(caption.timeRange.start.seconds == 1)
    precondition(caption.timeRange.duration.seconds == 2)
    precondition(caption.region == nil)
    precondition(caption.textAlignment == .start)
    precondition(caption.animation == .none)

    let mutable = AVMutableCaption()
    mutable.text = "World"
    mutable.timeRange = range
    mutable.textAlignment = .center
    mutable.animation = .characterReveal
    let region = AVMutableCaptionRegion(identifier: "bottom")
    mutable.region = region
    precondition(mutable.text == "World")
    precondition(mutable.timeRange.duration.seconds == 2)
    precondition(mutable.textAlignment == .center)
    precondition(mutable.animation == .characterReveal)
    precondition(mutable.region === region)
}

func testAVCaptionRubyAndGeometryValueStorage() {
    let ruby = AVCaption.Ruby(text: "かな")
    precondition(ruby.text == "かな")
    precondition(ruby.position == .before)
    precondition(ruby.alignment == .start)

    let placed = AVCaption.Ruby(text: "ruby", position: .after, alignment: .center)
    precondition(placed.text == "ruby")
    precondition(placed.position == .after)
    precondition(placed.alignment == .center)

    let unspecified = AVCaptionDimension()
    precondition(unspecified.value == 0)
    precondition(unspecified.units == .unspecified)
    let dimension = AVCaptionDimension(value: 80, units: .percent)
    precondition(dimension.value == 80)
    precondition(dimension.units == .percent)

    let origin = AVCaptionPoint()
    precondition(origin.x.value == 0)
    let point = AVCaptionPoint(
        x: AVCaptionDimension(value: 10, units: .cells),
        y: AVCaptionDimension(value: 20, units: .percent)
    )
    precondition(point.x.value == 10)
    precondition(point.x.units == .cells)
    precondition(point.y.value == 20)
    precondition(point.y.units == .percent)

    let emptySize = AVCaptionSize()
    precondition(emptySize.width.value == 0)
    let size = AVCaptionSize(
        width: AVCaptionDimension(value: 100, units: .percent),
        height: AVCaptionDimension(value: 15, units: .cells)
    )
    precondition(size.width.value == 100)
    precondition(size.height.value == 15)
    precondition(size.height.units == .cells)
}

func testAVCaptionGroupGrouperAndFormatConformer() {
    let early = AVCaption(
        "one",
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1))
    )
    let late = AVCaption(
        "two",
        timeRange: CMTimeRange(
            start: CMTime(seconds: 5, preferredTimescale: 1),
            duration: CMTime(seconds: 1, preferredTimescale: 1)
        )
    )
    let group = AVCaptionGroup(
        captions: [early, late],
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 6, preferredTimescale: 1))
    )
    precondition(group.captions.count == 2)
    precondition(group.captions[0] === early)
    precondition(group.timeRange.duration.seconds == 6)

    let emptyRange = AVCaptionGroup(timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 1)))
    precondition(emptyRange.captions.isEmpty)
    precondition(emptyRange.timeRange.duration.seconds == 3)

    let grouper = AVCaptionGrouper()
    grouper.add(early)
    grouper.add(late)
    let flushed = grouper.flushAddedCaptions(upTo: CMTime(seconds: 2, preferredTimescale: 1))
    precondition(flushed.count == 1)
    precondition(flushed[0].captions.count == 1)
    precondition(flushed[0].captions[0] === early)
    let rest = grouper.flushAddedCaptions(upTo: CMTime(seconds: 10, preferredTimescale: 1))
    precondition(rest.count == 1)
    precondition(rest[0].captions[0] === late)
    precondition(grouper.flushAddedCaptions(upTo: CMTime(seconds: 10, preferredTimescale: 1)).isEmpty)

    let conformer = AVCaptionFormatConformer(conversionSettings: [.mediaType: AVMediaType.text])
    precondition(!conformer.conformsCaptionsToTimeRange)
    conformer.conformsCaptionsToTimeRange = true
    precondition(conformer.conformsCaptionsToTimeRange)
    let conformed = try! conformer.conformedCaption(for: early)
    precondition(conformed === early)
}

func testAVCaptionRegionRendererAndConversionModels() {
    let region = AVMutableCaptionRegion(identifier: "itt-bottom")
    precondition(region.identifier == "itt-bottom")
    region.origin = AVCaptionPoint(
        x: AVCaptionDimension(value: 5, units: .percent),
        y: AVCaptionDimension(value: 80, units: .percent)
    )
    region.size = AVCaptionSize(
        width: AVCaptionDimension(value: 90, units: .percent),
        height: AVCaptionDimension(value: 10, units: .percent)
    )
    region.scroll = .rollUp
    region.displayAlignment = .after
    region.writingMode = .topToBottomAndRightToLeft
    precondition(region.origin.y.value == 80)
    precondition(region.size.width.value == 90)
    precondition(region.scroll == .rollUp)
    precondition(region.displayAlignment == .after)
    precondition(region.writingMode == .topToBottomAndRightToLeft)

    let copy = region.mutableCopy() as! AVMutableCaptionRegion
    precondition(region.isEqual(copy))
    precondition(copy.identifier == "itt-bottom")
    copy.scroll = .none
    precondition(!region.isEqual(copy))
    precondition(!region.isEqual(NSObject()))

    let renderer = AVCaptionRenderer()
    precondition(renderer.captions.isEmpty)
    precondition(renderer.bounds == .zero)
    let caption = AVCaption("line", timeRange: .zero)
    renderer.captions = [caption]
    renderer.bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    precondition(renderer.captions.count == 1)
    precondition(renderer.bounds.width == 1920)
    precondition(renderer.captionSceneChanges(in: .zero).isEmpty)
    renderer.render(in: CGContext(), for: .zero)
    let scene = AVCaptionRenderer.Scene()
    precondition(scene.timeRange == .zero)
    precondition(!scene.hasActiveCaptions)
    precondition(!scene.needsPeriodicRefresh)

    let adjustment = AVCaptionConversionTimeRangeAdjustment()
    precondition(adjustment.adjustmentType == .timeRange)
    precondition(adjustment.startTimeOffset == .zero)
    precondition(adjustment.durationOffset == .zero)
    precondition(AVCaptionConversionAdjustment().adjustmentType.rawValue.isEmpty)

    let validator = AVCaptionConversionValidator(
        captions: [caption],
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1)),
        conversionSettings: [.mediaSubType: "srt"]
    )
    precondition(validator.status == .unknown)
    precondition(validator.captions.count == 1)
    precondition(validator.timeRange.duration.seconds == 1)
    precondition(validator.warnings.isEmpty)
    validator.stopValidating()
    precondition(validator.status == .stopped)

    let warning = AVCaptionConversionWarning()
    precondition(warning.warningType.rawValue.isEmpty)
    precondition(warning.adjustment == nil)
}
