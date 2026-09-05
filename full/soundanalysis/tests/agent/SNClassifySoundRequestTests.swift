@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testClassifySoundRequestVersion1Init() {
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    snExpect(request.overlapFactor == 0, "Linux default overlap is 0")
    snExpect(request.windowDuration == .invalid, "Linux default window is invalid")
}

func testClassifySoundRequestUnknownIdentifierFails() {
    do {
        _ = try SNClassifySoundRequest(
            classifierIdentifier: SNClassifierIdentifier(rawValue: "not-a-classifier")
        )
        preconditionFailure("unknown identifier must fail closed")
    } catch let error as SNError {
        snExpect(error.code == .invalidModel, "invalidModel")
    } catch {
        preconditionFailure("expected SNError")
    }
}

func testClassifySoundRequestOverlapFactorClamp() {
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    request.overlapFactor = 0.25
    snExpect(request.overlapFactor == 0.25, "in-range value")
    request.overlapFactor = -0.5
    snExpect(request.overlapFactor == 0, "clamp low")
    request.overlapFactor = 1.5
    snExpect(request.overlapFactor == 1, "clamp high")
}

func testClassifySoundRequestWindowDuration() {
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let duration = CMTime(value: 3, timescale: 2)
    request.windowDuration = duration
    snExpect(request.windowDuration == duration, "windowDuration stores the set value")
}

func testClassifySoundRequestKnownClassificationsEmpty() {
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    snExpect(request.knownClassifications.isEmpty, "Linux has no Apple label inventory")
}

func testClassifySoundRequestWindowDurationConstraint() {
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    if case .enumeratedDurations(let times) = request.windowDurationConstraint {
        snExpect(times.isEmpty, "fail-closed empty enumerated constraint")
    } else {
        preconditionFailure("Linux version1 constraint is empty enumeratedDurations")
    }
}
