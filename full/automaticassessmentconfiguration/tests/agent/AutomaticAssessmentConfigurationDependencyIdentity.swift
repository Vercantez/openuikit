import AutomaticAssessmentConfiguration
import Foundation

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func automaticAssessmentConfigurationDependencyIdentityProbe() {
    let created = Date(timeIntervalSince1970: 1)
    let payload = Data([0x4f, 0x4b])
    let info: [String: Any] = ["when": created, "blob": payload]
    let error = AEAssessmentError(.unsupportedPlatform, userInfo: info)
    _ = error.errorCode
    _ = AEAssessmentErrorDomain
    let participant = AEAssessmentParticipantConfiguration()
    participant.configurationInfo = info
    _ = participant.configurationInfo
    let application = AEAssessmentApplication(bundleIdentifier: "com.example.exam")
    _ = application.bundleIdentifier
    let configuration = AEAssessmentConfiguration()
    configuration.setConfiguration(participant, for: application)
    _ = configuration.configurationsByApplication
}
