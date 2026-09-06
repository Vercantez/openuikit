import Foundation
import CoreAudioKit

func testAUAudioUnitViewConfigurationClass() {
    let configuration = AUAudioUnitViewConfiguration(
        width: 300,
        height: 200,
        hostHasController: false
    )
    precondition(type(of: configuration) == AUAudioUnitViewConfiguration.self)
    let asObject: NSObject = configuration
    precondition(asObject === configuration)
    precondition(AUAudioUnitViewConfiguration.supportsSecureCoding)
}

func testAUAudioUnitViewConfigurationInit() {
    let compact = AUAudioUnitViewConfiguration(
        width: 0,
        height: 0,
        hostHasController: true
    )
    precondition(compact.width == 0)
    precondition(compact.height == 0)
    precondition(compact.hostHasController)

    let full = AUAudioUnitViewConfiguration(
        width: 800,
        height: 600,
        hostHasController: false
    )
    precondition(full.width == 800)
    precondition(full.height == 600)
    precondition(full.hostHasController == false)
}

func testAUAudioUnitViewConfigurationWidth() {
    let configuration = AUAudioUnitViewConfiguration(
        width: 375.5,
        height: 1,
        hostHasController: false
    )
    precondition(configuration.width == 375.5)
    let other = AUAudioUnitViewConfiguration(
        width: 1024,
        height: 1,
        hostHasController: false
    )
    precondition(other.width == 1024)
    precondition(configuration.width != other.width)
}

func testAUAudioUnitViewConfigurationHeight() {
    let configuration = AUAudioUnitViewConfiguration(
        width: 1,
        height: 240.25,
        hostHasController: true
    )
    precondition(configuration.height == 240.25)
    let other = AUAudioUnitViewConfiguration(
        width: 1,
        height: 0,
        hostHasController: true
    )
    precondition(other.height == 0)
}

func testAUAudioUnitViewConfigurationHostHasController() {
    let hostOwns = AUAudioUnitViewConfiguration(
        width: 100,
        height: 100,
        hostHasController: true
    )
    precondition(hostOwns.hostHasController)
    let unitOwns = AUAudioUnitViewConfiguration(
        width: 100,
        height: 100,
        hostHasController: false
    )
    precondition(unitOwns.hostHasController == false)
}

func testAUAudioUnitViewConfigurationInitCoder() {
    let original = AUAudioUnitViewConfiguration(
        width: 512,
        height: 384,
        hostHasController: true
    )
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let restored = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: AUAudioUnitViewConfiguration.self,
        from: data
    )
    precondition(restored != nil)
    precondition(restored?.width == 512)
    precondition(restored?.height == 384)
    precondition(restored?.hostHasController == true)

    let emptyEncoder = NSKeyedArchiver(requiringSecureCoding: true)
    emptyEncoder.finishEncoding()
    let emptyDecoder = try! NSKeyedUnarchiver(forReadingFrom: emptyEncoder.encodedData)
    emptyDecoder.requiresSecureCoding = false
    let decodedEmpty = AUAudioUnitViewConfiguration(coder: emptyDecoder)
    precondition(decodedEmpty != nil)
    precondition(decodedEmpty?.width == 0)
    precondition(decodedEmpty?.height == 0)
    precondition(decodedEmpty?.hostHasController == false)
}
