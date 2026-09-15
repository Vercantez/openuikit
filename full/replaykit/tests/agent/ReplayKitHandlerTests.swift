import Foundation
import ReplayKit

private final class RKStoreProbe: RPBroadcastHandler {
    var lastURL: URL?
    var infoCount = 0

    override func updateBroadcast(_ broadcastURL: URL) {
        lastURL = broadcastURL
        super.updateBroadcast(broadcastURL)
    }

    override func updateServiceInfo(_ serviceInfo: [String: any NSCoding & NSObjectProtocol]) {
        infoCount += 1
        super.updateServiceInfo(serviceInfo)
    }
}

private final class RKSampleProbe: RPBroadcastSampleHandler {
    var started = false
    var paused = false
    var resumed = false
    var finished = false
    var annotated = false

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        _ = setupInfo
        started = true
    }

    override func broadcastPaused() {
        paused = true
    }

    override func broadcastResumed() {
        resumed = true
    }

    override func broadcastFinished() {
        finished = true
    }

    override func broadcastAnnotated(withApplicationInfo applicationInfo: [AnyHashable: Any]) {
        _ = applicationInfo
        annotated = true
    }
}

func testRPBroadcastHandlers() {
    let handler = RPBroadcastHandler()
    let url = URL(string: "https://example.invalid/stream")!
    handler.updateBroadcast(url)
    handler.updateServiceInfo(["app": "demo" as NSString])

    let probe = RKStoreProbe()
    probe.updateBroadcast(url)
    precondition(probe.lastURL == url)
    probe.updateServiceInfo(["app": "demo" as NSString])
    precondition(probe.infoCount == 1)

    let mp4 = RPBroadcastMP4ClipHandler()
    mp4.updateBroadcast(url)
    mp4.processMP4Clip(with: nil, setupInfo: nil, finished: true)
    mp4.processMP4Clip(
        with: URL(string: "https://example.invalid/clip.mp4"),
        setupInfo: ["key": "value" as NSString],
        finished: false
    )
    mp4.finishedProcessingMP4Clip(withUpdatedBroadcastConfiguration: nil, error: nil)
    let configuration = RPBroadcastConfiguration()
    configuration.clipDuration = 3
    mp4.finishedProcessingMP4Clip(
        withUpdatedBroadcastConfiguration: configuration,
        error: nil
    )

    let sample = RKSampleProbe()
    sample.broadcastStarted(withSetupInfo: nil)
    sample.broadcastPaused()
    sample.broadcastResumed()
    sample.broadcastFinished()
    sample.broadcastAnnotated(
        withApplicationInfo: [RPApplicationInfoBundleIdentifierKey: "demo.bundle"]
    )
    precondition(sample.started)
    precondition(sample.paused)
    precondition(sample.resumed)
    precondition(sample.finished)
    precondition(sample.annotated)

    let plain = RPBroadcastSampleHandler()
    plain.broadcastStarted(withSetupInfo: nil)
    plain.broadcastPaused()
    plain.broadcastResumed()
    plain.broadcastFinished()
    plain.broadcastAnnotated(withApplicationInfo: [:])
    let finish = NSError(
        domain: RPRecordingErrorDomain,
        code: RPRecordingErrorCode.disabled.rawValue,
        userInfo: nil
    )
    plain.finishBroadcastWithError(finish)
    sample.finishBroadcastWithError(finish)
}
