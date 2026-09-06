import Foundation
import CoreAudioKit
@_spi(OpenUIKitHost) import CoreAudioKit

func testCABTMIDICentralViewControllerClass() {
    let controller = CABTMIDICentralViewController()
    let asTable: UITableViewController = controller
    precondition(asTable === controller)
    precondition(type(of: controller) == CABTMIDICentralViewController.self)
    precondition(controller.tableView.style == .plain)
    precondition(CoreAudioKitHostControl.discoveredBluetoothMIDIPeripheralCount(controller) == 0)
}

func testCABTMIDILocalPeripheralViewControllerClass() {
    let controller = CABTMIDILocalPeripheralViewController()
    let asController: UIViewController = controller
    precondition(asController === controller)
    precondition(type(of: controller) == CABTMIDILocalPeripheralViewController.self)
    precondition(CoreAudioKitHostControl.localMIDIPeripheralAdvertising(controller) == false)
}
