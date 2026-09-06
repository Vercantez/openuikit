import Foundation
import MediaAccessibility

func testFlashingLightsProcessorCannotProcessSurface() {
    let processor = MAFlashingLightsProcessor()
    let surface = IOSurfaceRef()
    precondition(processor.canProcessSurface(surface) == false)
}

func testFlashingLightsProcessorProcessSurfaceFailClosed() {
    let processor = MAFlashingLightsProcessor()
    let input = IOSurfaceRef()
    var output = IOSurfaceRef()
    let result = processor.processSurface(
        input,
        outSurface: &output,
        timestamp: 1.234,
        options: nil
    )
    precondition(result.surfaceProcessed == false)
    precondition(result.intensityLevel == 0)
    precondition(result.mitigationLevel == 0)
}

func testFlashingLightsProcessorResultFields() {
    let processor = MAFlashingLightsProcessor()
    var output = IOSurfaceRef()
    let result = processor.processSurface(
        IOSurfaceRef(),
        outSurface: &output,
        timestamp: 0,
        options: [:]
    )
    precondition(result.surfaceProcessed == false)
    _ = result.intensityLevel
    _ = result.mitigationLevel
}

func testFlashingLightsProcessorOptionKey() {
    let key = MAFlashingLightsProcessor.OptionKey(rawValue: "intensity")
    let aliased = MAFlashingLightsProcessor.OptionKey("intensity")
    precondition(key == aliased)
    precondition(key.rawValue == "intensity")
    precondition(key != MAFlashingLightsProcessor.OptionKey("other"))
    precondition(MAFlashingLightsProcessor.OptionKey("a") != MAFlashingLightsProcessor.OptionKey("b"))

    var hasherA = Hasher()
    var hasherB = Hasher()
    key.hash(into: &hasherA)
    aliased.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(key.hashValue == aliased.hashValue)
}
