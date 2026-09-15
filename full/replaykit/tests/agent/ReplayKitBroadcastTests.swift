import Foundation
import ReplayKit

private final class RKBroadcastControllerProbe: NSObject, RPBroadcastControllerDelegate {
    var finishCount = 0
    var urlCount = 0
    var infoCount = 0

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didFinishWithError error: (any Error)?
    ) {
        _ = broadcastController
        _ = error
        finishCount += 1
    }

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateBroadcast broadcastURL: URL
    ) {
        _ = broadcastController
        _ = broadcastURL
        urlCount += 1
    }

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateServiceInfo serviceInfo: [String: any NSCoding & NSObjectProtocol]
    ) {
        _ = broadcastController
        _ = serviceInfo
        infoCount += 1
    }
}

func testRPBroadcastControllerFailClosed() {
    let controller = RPBroadcastController()
    precondition(!controller.isBroadcasting)
    precondition(!controller.isPaused)
    precondition(controller.broadcastURL.absoluteString == "replaykit://unstarted")
    precondition(controller.serviceInfo == nil)
    precondition(controller.broadcastExtensionBundleID == nil)

    let probe = RKBroadcastControllerProbe()
    controller.delegate = probe
    precondition(controller.delegate === probe)

    controller.startBroadcast(handler: { _ in })
    precondition(!controller.isBroadcasting)
    controller.pauseBroadcast()
    controller.resumeBroadcast()
    precondition(!controller.isPaused)
    controller.finishBroadcast(handler: { _ in })
    precondition(!controller.isBroadcasting)
    precondition(controller.serviceInfo == nil)
    precondition(controller.broadcastExtensionBundleID == nil)
}

func testRPBroadcastControllerDelegate() {
    let controller = RPBroadcastController()
    let probe = RKBroadcastControllerProbe()
    let existential: any RPBroadcastControllerDelegate = probe
    existential.broadcastController(controller, didFinishWithError: nil)
    existential.broadcastController(
        controller,
        didUpdateBroadcast: URL(string: "https://example.invalid/broadcast")!
    )
    existential.broadcastController(
        controller,
        didUpdateServiceInfo: ["bundle": "id" as NSString]
    )
    precondition(probe.finishCount == 1)
    precondition(probe.urlCount == 1)
    precondition(probe.infoCount == 1)
}

func testRPBroadcastConfigurationValues() {
    let configuration = RPBroadcastConfiguration()
    precondition(configuration.clipDuration == 0)
    configuration.clipDuration = 7.5
    precondition(configuration.clipDuration == 7.5)
    configuration.videoCompressionProperties = ["ProfileLevel": "main" as NSString]
    precondition(configuration.videoCompressionProperties?["ProfileLevel"] as? NSString == "main")
    configuration.videoCompressionProperties = nil
    precondition(configuration.videoCompressionProperties == nil)
    configuration.clipDuration = 7.5

    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: configuration,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: RPBroadcastConfiguration.self,
        from: data
    )
    precondition(decoded != nil)
    precondition(decoded!.clipDuration == 7.5)
}
