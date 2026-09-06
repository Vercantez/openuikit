import Foundation
import CoreAudioKit

func testAUAppleCustomViewLoaderClass() {
    let loader = AUAppleCustomViewLoader()
    let asObject: NSObject = loader
    precondition(asObject === loader)
    precondition(type(of: loader) == AUAppleCustomViewLoader.self)
}

func testAUAppleCustomViewLoaderInit() {
    let first = AUAppleCustomViewLoader()
    let second = AUAppleCustomViewLoader()
    precondition(first !== second)
}

func testAUAppleCustomViewLoaderCustomViewControllerFailClosed() {
    let loader = AUAppleCustomViewLoader()
    let description = AudioComponentDescription(
        componentType: 0x61756678,
        componentSubType: 0x64656d6f,
        componentManufacturer: 0x6170706c
    )
    let audioUnit = OpaquePointer(bitPattern: 0xA1)!
    let missing = loader.customViewController(for: description, audioUnit: audioUnit)
    precondition(missing == nil)
    let v3 = AUAudioUnit(componentDescription: description)
    let stillMissing = loader.customViewController(
        for: description,
        audioUnit: audioUnit,
        v3AU: v3
    )
    precondition(stillMissing == nil)
}
