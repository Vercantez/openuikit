import Foundation
import ExposureNotification

func testENRangeConstants() {
    precondition(ENAttenuationMin == 0)
    precondition(ENAttenuationMax == 0xFF)
    precondition(ENRiskLevelMin == 0)
    precondition(ENRiskLevelMax == 7)
    precondition(ENRiskLevelValueMin == 0)
    precondition(ENRiskLevelValueMax == 8)
    precondition(ENRiskScoreMin == 0)
    precondition(ENRiskScoreMax == 255)
    precondition(ENRiskWeightDefault == 1)
    precondition(ENRiskWeightDefaultV2 == 100)
    precondition(ENRiskWeightMax == 100)
    precondition(ENRiskWeightMaxV2 == 250)
    precondition(ENRiskWeightMin == 0)
    precondition(ENAttenuationMin < ENAttenuationMax)
    precondition(ENRiskWeightMin < ENRiskWeightDefault)
    precondition(ENRiskWeightDefaultV2 <= ENRiskWeightMaxV2)
}

func testENDaysSinceOnsetOfSymptomsUnknown() {
    precondition(ENDaysSinceOnsetOfSymptomsUnknown == Int(Int32.max))
    precondition(ENDaysSinceOnsetOfSymptomsUnknown > 14)
}

func testENFeatureGeneral() {
    precondition(EN_FEATURE_GENERAL == 1)
}

func testENTypealiases() {
    let attenuation: ENAttenuation = 42
    precondition(attenuation == 42)
    let interval: ENIntervalNumber = 144
    precondition(interval == 144)
    let level: ENRiskLevel = 3
    precondition(level == 3)
    let value: ENRiskLevelValue = 8
    precondition(value == 8)
    let score: ENRiskScore = 200
    precondition(score == 200)

    let flags: ENActivityFlags = .periodicRun
    let activity: ENActivityHandler = { received in
        precondition(received.contains(.periodicRun))
    }
    activity(flags)

    var detectCalled = false
    let detect: ENDetectExposuresHandler = { summary, error in
        detectCalled = true
        precondition(summary == nil)
        precondition(error != nil)
    }
    detect(nil, ENError(.unsupported))
    precondition(detectCalled)

    var keysHandlerRan = false
    let available: ENDiagnosisKeysAvailableHandler = { keys in
        keysHandlerRan = true
        precondition(keys.isEmpty)
    }
    available([])
    precondition(keysHandlerRan)

    var errorHandlerRan = false
    let onError: ENErrorHandler = { error in
        errorHandlerRan = true
        precondition(error != nil)
    }
    onError(ENError(.notEnabled))
    precondition(errorHandlerRan)

    var diagnosisRan = false
    let diagnosis: ENGetDiagnosisKeysHandler = { keys, error in
        diagnosisRan = true
        precondition(keys == nil)
        precondition(error != nil)
    }
    diagnosis(nil, ENError(.unsupported))
    precondition(diagnosisRan)

    var infoRan = false
    let info: ENGetExposureInfoHandler = { exposures, error in
        infoRan = true
        precondition(exposures == nil)
        precondition(error != nil)
    }
    info(nil, ENError(.unsupported))
    precondition(infoRan)

    var windowsRan = false
    let windows: ENGetExposureWindowsHandler = { windows, error in
        windowsRan = true
        precondition(windows == nil)
        precondition(error != nil)
    }
    windows(nil, ENError(.unsupported))
    precondition(windowsRan)

    var traveledRan = false
    let traveled: ENGetUserTraveledHandler = { traveled, error in
        traveledRan = true
        precondition(traveled == false)
        precondition(error != nil)
    }
    traveled(false, ENError(.travelStatusNotAvailable))
    precondition(traveledRan)
}

func testENErrorOutType() {
    precondition(ENErrorOutType.self == UnsafeMutablePointer<NSError?>.self)
}
