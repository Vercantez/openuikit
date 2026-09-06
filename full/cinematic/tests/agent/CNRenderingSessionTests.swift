import Foundation
import Cinematic

func testCNRenderingSessionHostAttributes() {
    let attributes = CNRenderingSession.Attributes.host_make(renderingVersion: 2)
    precondition(attributes.renderingVersion == 2)
}

func testCNRenderingSessionStoresInitArguments() {
    let queue = CNHostMTLCommandQueue()
    let attributes = CNRenderingSession.Attributes.host_make(renderingVersion: 1)
    let transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0)
    let session = CNRenderingSession(
        commandQueue: queue,
        sessionAttributes: attributes,
        preferredTransform: transform,
        quality: .preview
    )
    precondition(session.sessionAttributes.renderingVersion == 1)
    precondition(session.preferredTransform == transform)
    precondition(session.quality == .preview)
    precondition(session.commandQueue is CNHostMTLCommandQueue)
}

func testCNRenderingSessionPixelFormatListsAreEmpty() {
    precondition(CNRenderingSession.sourcePixelFormatTypes.isEmpty)
    precondition(CNRenderingSession.destinationPixelFormatTypes.isEmpty)
}

func testCNRenderingSessionFrameAttributesFromSampleBufferNil() {
    let attributes = CNRenderingSession.Attributes.host_make(renderingVersion: 1)
    let frame = CNRenderingSession.FrameAttributes(
        sampleBuffer: CMSampleBuffer(),
        sessionAttributes: attributes
    )
    precondition(frame == nil)
}

func testCNRenderingSessionFrameAttributesFromTimedMetadataNil() {
    let attributes = CNRenderingSession.Attributes.host_make(renderingVersion: 1)
    let frame = CNRenderingSession.FrameAttributes(
        timedMetadataGroup: AVTimedMetadataGroup(),
        sessionAttributes: attributes
    )
    precondition(frame == nil)
}

func testCNRenderingSessionFrameAttributesHostMake() {
    var frame = CNRenderingSession.FrameAttributes.host_make(
        focusDisparity: 0.4,
        fNumber: 2.8
    )
    precondition(frame.focusDisparity == 0.4)
    precondition(frame.fNumber == 2.8)
    frame.focusDisparity = 0.9
    frame.fNumber = 1.8
    precondition(frame.focusDisparity == 0.9)
    precondition(frame.fNumber == 1.8)
}

func testCNRenderingSessionEncodeRenderImageFailsClosed() {
    let session = CNRenderingSession(
        commandQueue: CNHostMTLCommandQueue(),
        sessionAttributes: .host_make(renderingVersion: 1),
        preferredTransform: .identity,
        quality: .thumbnail
    )
    let ok = session.encodeRender(
        to: CNHostMTLCommandBuffer(),
        frameAttributes: .host_make(focusDisparity: 0.2, fNumber: 2.0),
        sourceImage: CVPixelBuffer(),
        sourceDisparity: CVPixelBuffer(),
        destinationImage: CVPixelBuffer()
    )
    precondition(ok == false)
}

func testCNRenderingSessionEncodeRenderRGBAFailsClosed() {
    let session = CNRenderingSession(
        commandQueue: CNHostMTLCommandQueue(),
        sessionAttributes: .host_make(renderingVersion: 1),
        preferredTransform: .identity,
        quality: .export
    )
    let ok = session.encodeRender(
        to: CNHostMTLCommandBuffer(),
        frameAttributes: .host_make(focusDisparity: 0.2, fNumber: 2.0),
        sourceImage: CVPixelBuffer(),
        sourceDisparity: CVPixelBuffer(),
        destinationRGBA: CNHostMTLTexture()
    )
    precondition(ok == false)
}

func testCNRenderingSessionEncodeRenderLumaChromaFailsClosed() {
    let session = CNRenderingSession(
        commandQueue: CNHostMTLCommandQueue(),
        sessionAttributes: .host_make(renderingVersion: 1),
        preferredTransform: .identity,
        quality: .exportHigh
    )
    let ok = session.encodeRender(
        to: CNHostMTLCommandBuffer(),
        frameAttributes: .host_make(focusDisparity: 0.2, fNumber: 2.0),
        sourceImage: CVPixelBuffer(),
        sourceDisparity: CVPixelBuffer(),
        destinationLuma: CNHostMTLTexture(),
        destinationChroma: CNHostMTLTexture()
    )
    precondition(ok == false)
}

func testCNObjectTrackerIsSupportedFalse() {
    precondition(CNObjectTracker.isSupported == false)
}

func testCNObjectTrackerFindObjectReturnsNil() {
    let tracker = CNObjectTracker(commandQueue: CNHostMTLCommandQueue())
    let prediction = tracker.findObject(at: CGPoint(x: 0.5, y: 0.5), sourceImage: CVPixelBuffer())
    precondition(prediction == nil)
}

func testCNObjectTrackerStartTrackingReturnsFalse() {
    let tracker = CNObjectTracker(commandQueue: CNHostMTLCommandQueue())
    let started = tracker.startTracking(
        at: .zero,
        within: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
        sourceImage: CVPixelBuffer(),
        sourceDisparity: CVPixelBuffer()
    )
    precondition(started == false)
}

func testCNObjectTrackerContinueTrackingReturnsNil() {
    let tracker = CNObjectTracker(commandQueue: CNHostMTLCommandQueue())
    let prediction = tracker.continueTracking(
        at: CMTime(seconds: 0.1, preferredTimescale: 600),
        sourceImage: CVPixelBuffer(),
        sourceDisparity: CVPixelBuffer()
    )
    precondition(prediction == nil)
}

func testCNObjectTrackerResetAndFinishEmptyTrack() {
    let tracker = CNObjectTracker(commandQueue: CNHostMTLCommandQueue())
    tracker.resetDetectionTrack()
    let finished = tracker.finishDetectionTrack()
    precondition(finished.detections(in: CMTimeRange(start: .zero, duration: CMTime(seconds: 10, preferredTimescale: 600))).isEmpty)
    if let custom = finished as? CNCustomDetectionTrack {
        precondition(custom.allDetections.isEmpty)
    } else {
        preconditionFailure("finishDetectionTrack should return an empty custom track")
    }
}
