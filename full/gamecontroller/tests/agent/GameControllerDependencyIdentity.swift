import Foundation
import Dispatch
import UIKit
import CoreServices
import GameController

/// Future clean-EC2 identity probe. Not compiled by the isolated host gate.
///
/// That run must build guest Foundation, Dispatch, UIKit, and CoreServices
/// first, compile GameController against their -I/-L paths, link this client,
/// and execute it with LD_LIBRARY_PATH so libGameController.dylib loads.

_ = kUTTypeData

@MainActor
final class _GCSceneDelegateProbe: NSObject, GCGameControllerSceneDelegate {
    private(set) var activatedScene: UIKit.UIScene?
    private(set) var activatedContext: GCGameControllerActivationContext?

    func scene(
        _ scene: UIKit.UIScene,
        didActivateGameControllerWith context: GCGameControllerActivationContext
    ) {
        activatedScene = scene
        activatedContext = context
    }
}

@MainActor
enum _GCDependencyIdentity {
    static func prove() {
        let controller = GCEventViewController()
        precondition(controller is UIKit.UIViewController)
        let asViewController: UIKit.UIViewController = controller
        _ = asViewController
        controller.controllerUserInteractionEnabled = true
        precondition(controller.controllerUserInteractionEnabled)

        let interaction = GCEventInteraction()
        let asInteraction: any UIKit.UIInteraction = interaction
        asInteraction.willMove(to: nil)
        asInteraction.didMove(to: nil)
        _ = asInteraction.view

        let probe = _GCSceneDelegateProbe()
        let delegate: any GCGameControllerSceneDelegate = probe
        let scene = UIKit.UIScene()
        let context = GCGameControllerActivationContext()
        delegate.scene(scene, didActivateGameControllerWith: context)
        precondition(probe.activatedScene === scene)
        precondition(probe.activatedContext === context)

        let elementConfig = GCVirtualController.ElementConfiguration()
        let path = UIKit.UIBezierPath()
        elementConfig.path = path
        precondition(elementConfig.path === path)

        let snapshot = GCController.withExtendedGamepad()
        let handlerQueue = DispatchQueue(label: "gc.dependency.handler")
        let handlerKey = DispatchSpecificKey<UInt8>()
        handlerQueue.setSpecific(key: handlerKey, value: 11)
        snapshot.handlerQueue = handlerQueue
        let handlerGate = DispatchSemaphore(value: 0)
        var handlerQueueHonored = false
        snapshot.extendedGamepad?.buttonA.valueChangedHandler = { _, _, _ in
            handlerQueueHonored = DispatchQueue.getSpecific(key: handlerKey) == 11
            handlerGate.signal()
        }
        snapshot.extendedGamepad?.buttonA.setValue(1)
        precondition(handlerGate.wait(timeout: .now() + 2) == .success)
        precondition(handlerQueueHonored)

        let discoveryGate = DispatchSemaphore(value: 0)
        var discoveryCount = 0
        GCController.startWirelessControllerDiscovery {
            discoveryCount += 1
            discoveryGate.signal()
        }
        precondition(discoveryCount == 0)
        precondition(discoveryGate.wait(timeout: .now() + 2) == .success)
        precondition(discoveryCount == 1)

        let virtual = GCVirtualController(configuration: GCVirtualController.Configuration())
        let virtualGate = DispatchSemaphore(value: 0)
        var virtualCount = 0
        var virtualError: (any Error)?
        virtual.connect { error in
            virtualError = error
            virtualCount += 1
            virtualGate.signal()
        }
        precondition(virtualCount == 0)
        precondition(virtualGate.wait(timeout: .now() + 2) == .success)
        precondition(virtualCount == 1)
        precondition(virtualError != nil)
    }
}

if Thread.isMainThread {
    MainActor.assumeIsolated {
        _GCDependencyIdentity.prove()
    }
} else {
    DispatchQueue.main.sync {
        MainActor.assumeIsolated {
            _GCDependencyIdentity.prove()
        }
    }
}

print("GAMECONTROLLER_DEPENDENCY_IDENTITY_OK")
