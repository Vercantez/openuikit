import Foundation
import CoreAudioKit
@_spi(OpenUIKitHost) import CoreAudioKit

func testCAInterAppAudioTransportViewClass() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    let asView: UIView = view
    precondition(asView === view)
    precondition(type(of: view) == CAInterAppAudioTransportView.self)
}

func testCAInterAppAudioTransportViewSetOutputAudioUnit() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(CoreAudioKitHostControl.attachedOutputAudioUnit(of: view) == nil)
    let unit = OpaquePointer(bitPattern: 0x44)!
    view.setOutputAudioUnit(unit)
    precondition(CoreAudioKitHostControl.attachedOutputAudioUnit(of: view) == unit)
    precondition(view.isConnected == false)
}

func testCAInterAppAudioTransportViewIsConnected() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.isConnected == false)
    view.setOutputAudioUnit(OpaquePointer(bitPattern: 0x55)!)
    precondition(view.isConnected == false)
}

func testCAInterAppAudioTransportViewCurrentTimeLabelFont() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.currentTimeLabelFont.pointSize == 12)
    let font = UIFont.systemFont(ofSize: 18)
    view.currentTimeLabelFont = font
    precondition(view.currentTimeLabelFont.pointSize == 18)
    precondition(view.currentTimeLabelFont.isEqual(font))
}

func testCAInterAppAudioTransportViewIsEnabled() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.isEnabled)
    view.isEnabled = false
    precondition(view.isEnabled == false)
    view.isEnabled = true
    precondition(view.isEnabled)
}

func testCAInterAppAudioTransportViewLabelColor() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.labelColor.isEqual(UIColor.white))
    view.labelColor = .black
    precondition(view.labelColor.isEqual(UIColor.black))
}

func testCAInterAppAudioTransportViewPauseButtonColor() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.pauseButtonColor.isEqual(UIColor.white))
    view.pauseButtonColor = .blue
    precondition(view.pauseButtonColor.isEqual(UIColor.blue))
}

func testCAInterAppAudioTransportViewPlayButtonColor() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.playButtonColor.isEqual(UIColor.white))
    view.playButtonColor = .green
    precondition(view.playButtonColor.isEqual(UIColor.green))
}

func testCAInterAppAudioTransportViewIsPlaying() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.isPlaying == false)
    view.isEnabled = true
    view.setOutputAudioUnit(OpaquePointer(bitPattern: 0x66)!)
    precondition(view.isPlaying == false)
}

func testCAInterAppAudioTransportViewRecordButtonColor() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.recordButtonColor.isEqual(UIColor.red))
    view.recordButtonColor = .black
    precondition(view.recordButtonColor.isEqual(UIColor.black))
}

func testCAInterAppAudioTransportViewIsRecording() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.isRecording == false)
    view.setOutputAudioUnit(OpaquePointer(bitPattern: 0x77)!)
    precondition(view.isRecording == false)
}

func testCAInterAppAudioTransportViewRewindButtonColor() {
    let view = CAInterAppAudioTransportView(frame: .zero)
    precondition(view.rewindButtonColor.isEqual(UIColor.white))
    view.rewindButtonColor = .red
    precondition(view.rewindButtonColor.isEqual(UIColor.red))
}
