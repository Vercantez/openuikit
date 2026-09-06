import Foundation
import ExposureNotification

func testENAuthorizationStatusRawValues() {
    precondition(ENAuthorizationStatus.unknown.rawValue == 0)
    precondition(ENAuthorizationStatus.restricted.rawValue == 1)
    precondition(ENAuthorizationStatus.notAuthorized.rawValue == 2)
    precondition(ENAuthorizationStatus.authorized.rawValue == 3)
    precondition(ENAuthorizationStatus(rawValue: 0) == .unknown)
    precondition(ENAuthorizationStatus(rawValue: 3) == .authorized)
    precondition(ENAuthorizationStatus(rawValue: 99) == nil)
    precondition(ENAuthorizationStatus.unknown != .authorized)
}

func testENStatusRawValues() {
    precondition(ENStatus.unknown.rawValue == 0)
    precondition(ENStatus.active.rawValue == 1)
    precondition(ENStatus.disabled.rawValue == 2)
    precondition(ENStatus.bluetoothOff.rawValue == 3)
    precondition(ENStatus.restricted.rawValue == 4)
    precondition(ENStatus.paused.rawValue == 5)
    precondition(ENStatus.unauthorized.rawValue == 6)
    precondition(ENStatus(rawValue: 1) == .active)
    precondition(ENStatus(rawValue: 6) == .unauthorized)
    precondition(ENStatus(rawValue: -1) == nil)
    precondition(ENStatus.active != .disabled)
}

func testENCalibrationConfidenceRawValues() {
    precondition(ENCalibrationConfidence.lowest.rawValue == 0)
    precondition(ENCalibrationConfidence.low.rawValue == 1)
    precondition(ENCalibrationConfidence.medium.rawValue == 2)
    precondition(ENCalibrationConfidence.high.rawValue == 3)
    precondition(ENCalibrationConfidence(rawValue: 0) == .lowest)
    precondition(ENCalibrationConfidence(rawValue: 3) == .high)
    precondition(ENCalibrationConfidence(rawValue: 4) == nil)
    precondition(ENCalibrationConfidence.low != .high)
}

func testENInfectiousnessRawValues() {
    precondition(ENInfectiousness.none.rawValue == 0)
    precondition(ENInfectiousness.standard.rawValue == 1)
    precondition(ENInfectiousness.high.rawValue == 2)
    precondition(ENInfectiousness(rawValue: 1) == .standard)
    precondition(ENInfectiousness(rawValue: 9) == nil)
    precondition(ENInfectiousness.none != .high)
}

func testENDiagnosisReportTypeRawValues() {
    precondition(ENDiagnosisReportType.unknown.rawValue == 0)
    precondition(ENDiagnosisReportType.confirmedTest.rawValue == 1)
    precondition(ENDiagnosisReportType.confirmedClinicalDiagnosis.rawValue == 2)
    precondition(ENDiagnosisReportType.selfReported.rawValue == 3)
    precondition(ENDiagnosisReportType.recursive.rawValue == 4)
    precondition(ENDiagnosisReportType.revoked.rawValue == 5)
    precondition(ENDiagnosisReportType(rawValue: 2) == .confirmedClinicalDiagnosis)
    precondition(ENDiagnosisReportType(rawValue: 6) == nil)
    precondition(ENDiagnosisReportType.confirmedTest != .revoked)
}

func testENVariantOfConcernTypeRawValues() {
    precondition(ENVariantOfConcernType.typeUnknown.rawValue == 0)
    precondition(ENVariantOfConcernType.type1.rawValue == 1)
    precondition(ENVariantOfConcernType.type2.rawValue == 2)
    precondition(ENVariantOfConcernType.type3.rawValue == 3)
    precondition(ENVariantOfConcernType.type4.rawValue == 4)
    precondition(ENVariantOfConcernType(rawValue: 0) == .typeUnknown)
    precondition(ENVariantOfConcernType(rawValue: 4) == .type4)
    precondition(ENVariantOfConcernType(rawValue: 5) == nil)
    precondition(ENVariantOfConcernType.type1 != .type2)
}

func testENAuthorizationStatusHashable() {
    precondition(ENAuthorizationStatus.restricted.hashValue == ENAuthorizationStatus.restricted.hashValue)
    var hasher = Hasher()
    ENAuthorizationStatus.authorized.hash(into: &hasher)
    _ = hasher.finalize()
}

func testENStatusHashable() {
    precondition(ENStatus.paused.hashValue == ENStatus.paused.hashValue)
    var hasher = Hasher()
    ENStatus.bluetoothOff.hash(into: &hasher)
    _ = hasher.finalize()
}

func testENCalibrationConfidenceHashable() {
    precondition(ENCalibrationConfidence.medium.hashValue == ENCalibrationConfidence.medium.hashValue)
    var hasher = Hasher()
    ENCalibrationConfidence.high.hash(into: &hasher)
    _ = hasher.finalize()
}

func testENInfectiousnessHashable() {
    precondition(ENInfectiousness.standard.hashValue == ENInfectiousness.standard.hashValue)
    var hasher = Hasher()
    ENInfectiousness.high.hash(into: &hasher)
    _ = hasher.finalize()
}

func testENDiagnosisReportTypeHashable() {
    precondition(ENDiagnosisReportType.selfReported.hashValue == ENDiagnosisReportType.selfReported.hashValue)
    var hasher = Hasher()
    ENDiagnosisReportType.recursive.hash(into: &hasher)
    _ = hasher.finalize()
}

func testENVariantOfConcernTypeHashable() {
    precondition(ENVariantOfConcernType.type3.hashValue == ENVariantOfConcernType.type3.hashValue)
    var hasher = Hasher()
    ENVariantOfConcernType.type4.hash(into: &hasher)
    _ = hasher.finalize()
}
