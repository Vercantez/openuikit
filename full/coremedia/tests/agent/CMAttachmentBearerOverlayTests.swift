import CoreFoundation
import CoreMedia
import Foundation

func testCMAttachmentBearerAttachmentsOverlay() {
    let attachments = CMAttachmentBearerAttachments()
    precondition(attachments.propagated.isEmpty)
    precondition(attachments.nonPropagated.isEmpty)
    attachments["keep"] = .shouldPropagate("yes")
    attachments["hide"] = .shouldNotPropagate(1)
    precondition(attachments["keep"] != nil)
    precondition(attachments["keep"]!.mode == .shouldPropagate)
    precondition(attachments["hide"]!.mode == .shouldNotPropagate)
    let propagatedValue = attachments["keep"]!.value as? String
    precondition(propagatedValue == "yes")
    precondition(attachments.propagated["keep"] as? String == "yes")
    precondition(attachments.nonPropagated["hide"] as? Int == 1)
    attachments.merge(["extra": "more"], mode: .shouldPropagate)
    precondition(attachments["extra"] != nil)
    let source = CMBlockBuffer(data: Data([1]))
    let destination = CMBlockBuffer(data: Data([2]))
    source.attachments["shared"] = .shouldPropagate("value")
    source.propagateAttachments(to: destination)
    precondition(destination.attachments["shared"] != nil)
    attachments.removeAll()
    precondition(attachments.propagated.isEmpty)
}

func testCMAttachmentBearerModeRawValues() {
    precondition(CMAttachmentBearerAttachments.Mode.shouldPropagate.rawValue == kCMAttachmentMode_ShouldPropagate)
    precondition(CMAttachmentBearerAttachments.Mode.shouldNotPropagate.rawValue == kCMAttachmentMode_ShouldNotPropagate)
    precondition(CMAttachmentBearerAttachments.Mode(rawValue: kCMAttachmentMode_ShouldPropagate) == .shouldPropagate)
    precondition(CMAttachmentBearerAttachments.Mode(rawValue: kCMAttachmentMode_ShouldNotPropagate) == .shouldNotPropagate)
    precondition(CMAttachmentBearerAttachments.Mode.shouldPropagate != .shouldNotPropagate)
    var hasher = Hasher()
    CMAttachmentBearerAttachments.Mode.shouldPropagate.hash(into: &hasher)
    _ = hasher.finalize()
    _ = CMAttachmentBearerAttachments.Mode.shouldNotPropagate.hashValue
}

func testCMSampleBufferAttachmentBearerOverlay() {
    let buffer = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([9])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1],
        dataReady: true
    )
    buffer.attachments["meta"] = .shouldPropagate("sbuf")
    let copy = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([8])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1],
        dataReady: true
    )
    buffer.propagateAttachments(to: copy)
    precondition(copy.attachments["meta"] != nil)
    let key = CMSampleBuffer.AttachmentKey.forceKeyFrame
    precondition(CFEqual(key.rawValue, kCMSampleBufferAttachmentKey_ForceKeyFrame))
    precondition(CMSampleBuffer.AttachmentKey(rawValue: key.rawValue) == key)
}
