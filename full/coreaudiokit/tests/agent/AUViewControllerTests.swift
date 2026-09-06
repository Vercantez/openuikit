import Foundation
import CoreAudioKit

func testAUViewControllerClass() {
    let controller = AUViewController()
    let asController: UIViewController = controller
    precondition(asController === controller)
    precondition(type(of: controller) == AUViewController.self)
    let fromNib = AUViewController(nibName: nil, bundle: nil)
    precondition(type(of: fromNib) == AUViewController.self)
}

func testAUGenericViewControllerClass() {
    let controller = AUGenericViewController()
    let asController: UIViewController = controller
    precondition(asController === controller)
    precondition(type(of: controller) == AUGenericViewController.self)
    precondition(controller.auAudioUnit == nil)
}

func testAUGenericViewControllerAuAudioUnit() {
    let controller = AUGenericViewController()
    precondition(controller.auAudioUnit == nil)
    let unit = AUAudioUnit()
    controller.auAudioUnit = unit
    precondition(controller.auAudioUnit === unit)
    controller.auAudioUnit = nil
    precondition(controller.auAudioUnit == nil)
}
