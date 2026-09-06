import Foundation
import AutomaticAssessmentConfiguration

func testParticipantType() {
    let participant = AEAssessmentParticipantConfiguration()
    aacExpect(type(of: participant) == AEAssessmentParticipantConfiguration.self, "type")
}

func testParticipantInit() {
    let participant = AEAssessmentParticipantConfiguration()
    aacExpect(!participant.allowsNetworkAccess, "default network")
    aacExpect(participant.configurationInfo.isEmpty, "default info")
    aacExpect(!participant.isRequired, "default required")
}

func testParticipantNew() {
    let participant = AEAssessmentParticipantConfiguration.new()
    aacExpect(type(of: participant) == AEAssessmentParticipantConfiguration.self, "new type")
    aacExpect(!participant.allowsNetworkAccess, "new defaults")
}

func testParticipantAllowsNetworkAccess() {
    let participant = AEAssessmentParticipantConfiguration()
    aacExpect(!participant.allowsNetworkAccess, "linux default false")
    participant.allowsNetworkAccess = true
    aacExpect(participant.allowsNetworkAccess, "set true")
    participant.allowsNetworkAccess = false
    aacExpect(!participant.allowsNetworkAccess, "set false")
}

func testParticipantConfigurationInfo() {
    let participant = AEAssessmentParticipantConfiguration()
    aacExpect(participant.configurationInfo.isEmpty, "empty")
    participant.configurationInfo = ["vendor": "linux", "n": 2]
    aacExpect(participant.configurationInfo["vendor"] as? String == "linux", "string")
    aacExpect(participant.configurationInfo["n"] as? Int == 2, "int")
}

func testParticipantIsRequired() {
    let participant = AEAssessmentParticipantConfiguration()
    aacExpect(!participant.isRequired, "linux default false")
    participant.isRequired = true
    aacExpect(participant.isRequired, "set true")
}
