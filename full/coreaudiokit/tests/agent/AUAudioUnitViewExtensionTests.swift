import Foundation
import CoreAudioKit
@_spi(OpenUIKitHost) import CoreAudioKit

func testAUAudioUnitRequestViewControllerFailClosed() {
    let unit = AUAudioUnit()
    var calls = 0
    var delivered: UIViewController? = AUViewController()
    unit.requestViewController { viewController in
        calls += 1
        delivered = viewController
    }
    precondition(calls == 1)
    precondition(delivered == nil)
}

func testAUAudioUnitSelectViewConfiguration() {
    let unit = AUAudioUnit()
    precondition(CoreAudioKitHostControl.selectedViewConfiguration(unit) == nil)
    let configuration = AUAudioUnitViewConfiguration(
        width: 640,
        height: 480,
        hostHasController: true
    )
    unit.select(configuration)
    let selected = CoreAudioKitHostControl.selectedViewConfiguration(unit)
    precondition(selected != nil)
    precondition(selected?.width == 640)
    precondition(selected?.height == 480)
    precondition(selected?.hostHasController == true)
    let replacement = AUAudioUnitViewConfiguration(
        width: 100,
        height: 80,
        hostHasController: false
    )
    unit.select(replacement)
    let latest = CoreAudioKitHostControl.selectedViewConfiguration(unit)
    precondition(latest?.width == 100)
    precondition(latest?.hostHasController == false)
}

func testAUAudioUnitSupportedViewConfigurations() {
    let unit = AUAudioUnit()
    let empty = unit.supportedViewConfigurations([])
    precondition(empty.isEmpty)
    let available = [
        AUAudioUnitViewConfiguration(width: 300, height: 200, hostHasController: false),
        AUAudioUnitViewConfiguration(width: 800, height: 600, hostHasController: true),
    ]
    let supported = unit.supportedViewConfigurations(available)
    precondition(supported.isEmpty)
    precondition(supported.contains(0) == false)
    precondition(supported.contains(1) == false)
}
