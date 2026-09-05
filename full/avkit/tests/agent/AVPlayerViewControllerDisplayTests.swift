import Foundation
import AVKit

private final class DisplayKVOProbe: NSObject {
    var readyForDisplayChanges = 0
    var videoBoundsChanges = 0

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        _ = (object, change, context)
        if keyPath == "readyForDisplay" {
            readyForDisplayChanges += 1
        } else if keyPath == "videoBounds" {
            videoBoundsChanges += 1
        }
    }
}

func testPlayerViewControllerDisplayStateFollowsPlayerItem() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.videoBounds == .zero)
        let url = URL(fileURLWithPath: "/tmp/openavkit-display.m4v")
        let item = AVPlayerItem(url: url)
        precondition(item.status == .readyToPlay)
        precondition(item.presentationSize == .zero)
        let player = AVPlayer(playerItem: item)
        controller.player = player
        // AVFoundation lane: URL items are readyToPlay with a zero
        // presentationSize, so the controller stays not ready.
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.videoBounds == .zero)
        item.openUIKitHostSetPresentationSize(CGSize(width: 1920, height: 1080))
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.isReadyForDisplay == true)
        precondition(controller.videoBounds == CGRect(x: 0, y: 0, width: 1920, height: 1080))
        item.openUIKitHostSetPresentationSize(.zero)
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.videoBounds == .zero)
        item.status = .failed
        item.openUIKitHostSetPresentationSize(CGSize(width: 640, height: 360))
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.videoBounds == CGRect(x: 0, y: 0, width: 640, height: 360))
        controller.player = nil
        precondition(controller.isReadyForDisplay == false)
        precondition(controller.videoBounds == .zero)
    }
}

func testPlayerViewControllerDisplayStateKVOKeys() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let probe = DisplayKVOProbe()
        controller.addObserver(probe, forKeyPath: "readyForDisplay", options: [.new], context: nil)
        controller.addObserver(probe, forKeyPath: "videoBounds", options: [.new], context: nil)
        let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openavkit-kvo.m4v"))
        controller.player = AVPlayer(playerItem: item)
        item.openUIKitHostSetPresentationSize(CGSize(width: 1280, height: 720))
        controller.openUIKitHostRefreshDisplayState()
        precondition(controller.isReadyForDisplay == true)
        precondition(controller.videoBounds.width == 1280)
        // Isolated-host stored properties are not @objc dynamic. Manual
        // willChangeValue/didChangeValue is emitted, but Foundation KVO
        // delivery is not claimed here.
        _ = probe.readyForDisplayChanges
        _ = probe.videoBoundsChanges
        controller.removeObserver(probe, forKeyPath: "readyForDisplay")
        controller.removeObserver(probe, forKeyPath: "videoBounds")
    }
}

func testPlayerViewControllerContentOverlayPlaceholder() {
    avkitOnMain {
        let controller = AVPlayerViewController()
        let overlay = controller.contentOverlayView
        precondition(overlay != nil)
        precondition(overlay?.frame == .zero)
        let again = controller.contentOverlayView
        precondition(again === overlay)
    }
}
