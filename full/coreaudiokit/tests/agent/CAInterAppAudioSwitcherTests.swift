import Foundation
import CoreAudioKit
@_spi(OpenUIKitHost) import CoreAudioKit

func testCAInterAppAudioSwitcherViewClass() {
    let view = CAInterAppAudioSwitcherView(frame: .zero)
    let asView: UIView = view
    precondition(asView === view)
    precondition(type(of: view) == CAInterAppAudioSwitcherView.self)
}

func testCAInterAppAudioSwitcherViewContentWidth() {
    let view = CAInterAppAudioSwitcherView(
        frame: CGRect(x: 0, y: 0, width: 400, height: 44)
    )
    precondition(view.contentWidth() == 0)
    view.isShowingAppNames = true
    precondition(view.contentWidth() == 0)
    view.setOutputAudioUnit(OpaquePointer(bitPattern: 0x22)!)
    precondition(view.contentWidth() == 0)
}

func testCAInterAppAudioSwitcherViewSetOutputAudioUnit() {
    let view = CAInterAppAudioSwitcherView(frame: .zero)
    precondition(CoreAudioKitHostControl.attachedOutputAudioUnit(of: view) == nil)
    let unit = OpaquePointer(bitPattern: 0x33)!
    view.setOutputAudioUnit(unit)
    precondition(CoreAudioKitHostControl.attachedOutputAudioUnit(of: view) == unit)
    view.setOutputAudioUnit(nil)
    precondition(CoreAudioKitHostControl.attachedOutputAudioUnit(of: view) == nil)
}

func testCAInterAppAudioSwitcherViewShowingAppNames() {
    let view = CAInterAppAudioSwitcherView(frame: .zero)
    precondition(view.isShowingAppNames == false)
    view.isShowingAppNames = true
    precondition(view.isShowingAppNames)
    view.isShowingAppNames = false
    precondition(view.isShowingAppNames == false)
}
