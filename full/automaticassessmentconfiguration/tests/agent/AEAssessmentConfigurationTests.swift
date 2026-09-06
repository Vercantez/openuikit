import Foundation
import AutomaticAssessmentConfiguration

func testConfigurationType() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(type(of: configuration) == AEAssessmentConfiguration.self, "type")
}

func testAllowsAccessibilityLiveCaptions() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsAccessibilityLiveCaptions, "linux default")
    configuration.allowsAccessibilityLiveCaptions = true
    aacExpect(configuration.allowsAccessibilityLiveCaptions, "set")
}

func testAllowsAccessibilityReader() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsAccessibilityReader, "linux default")
    configuration.allowsAccessibilityReader = true
    aacExpect(configuration.allowsAccessibilityReader, "set")
}

func testAllowsAccessibilitySpeech() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsAccessibilitySpeech, "linux default")
    configuration.allowsAccessibilitySpeech = true
    aacExpect(configuration.allowsAccessibilitySpeech, "set")
}

func testAllowsAccessibilityTypingFeedback() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsAccessibilityTypingFeedback, "linux default")
    configuration.allowsAccessibilityTypingFeedback = true
    aacExpect(configuration.allowsAccessibilityTypingFeedback, "set")
}

func testAllowsActivityContinuation() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsActivityContinuation, "linux default")
    configuration.allowsActivityContinuation = true
    aacExpect(configuration.allowsActivityContinuation, "set")
}

func testAllowsContinuousPathKeyboard() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsContinuousPathKeyboard, "linux default")
    configuration.allowsContinuousPathKeyboard = true
    aacExpect(configuration.allowsContinuousPathKeyboard, "set")
}

func testAllowsDictation() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsDictation, "linux default")
    configuration.allowsDictation = true
    aacExpect(configuration.allowsDictation, "set")
}

func testAllowsKeyboardShortcuts() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsKeyboardShortcuts, "linux default")
    configuration.allowsKeyboardShortcuts = true
    aacExpect(configuration.allowsKeyboardShortcuts, "set")
}

func testAllowsPasswordAutoFill() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsPasswordAutoFill, "linux default")
    configuration.allowsPasswordAutoFill = true
    aacExpect(configuration.allowsPasswordAutoFill, "set")
}

func testAllowsPredictiveKeyboard() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsPredictiveKeyboard, "linux default")
    configuration.allowsPredictiveKeyboard = true
    aacExpect(configuration.allowsPredictiveKeyboard, "set")
}

func testAllowsSpellCheck() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(!configuration.allowsSpellCheck, "linux default")
    configuration.allowsSpellCheck = true
    aacExpect(configuration.allowsSpellCheck, "set")
}

func testConfigurationAutocorrectMode() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(configuration.autocorrectMode.isEmpty, "linux default none")
    configuration.autocorrectMode = [.spelling, .punctuation]
    aacExpect(configuration.autocorrectMode.contains(.spelling), "spelling")
    aacExpect(configuration.autocorrectMode.contains(.punctuation), "punctuation")
}

func testMainParticipantConfiguration() {
    let configuration = AEAssessmentConfiguration()
    let main = configuration.mainParticipantConfiguration
    aacExpect(type(of: main) == AEAssessmentParticipantConfiguration.self, "type")
    aacExpect(!main.allowsNetworkAccess, "default")
    main.allowsNetworkAccess = true
    aacExpect(configuration.mainParticipantConfiguration.allowsNetworkAccess, "same instance")
    aacExpect(configuration.mainParticipantConfiguration === main, "identity")
}

func testConfigurationsByApplicationEmpty() {
    let configuration = AEAssessmentConfiguration()
    aacExpect(configuration.configurationsByApplication.isEmpty, "empty")
}

func testSetConfigurationForApplication() {
    let configuration = AEAssessmentConfiguration()
    let app = AEAssessmentApplication(bundleIdentifier: "com.example.calc")
    let participant = AEAssessmentParticipantConfiguration()
    participant.allowsNetworkAccess = true
    participant.isRequired = true
    configuration.setConfiguration(participant, for: app)
    let stored = configuration.configurationsByApplication
    aacExpect(stored.count == 1, "one")
    let key = AEAssessmentApplication(bundleIdentifier: "com.example.calc")
    aacExpect(stored[key]?.allowsNetworkAccess == true, "network")
    aacExpect(stored[key]?.isRequired == true, "required")
    participant.allowsNetworkAccess = false
    aacExpect(configuration.configurationsByApplication[key]?.allowsNetworkAccess == true, "snapshot")
}

func testRemoveApplication() {
    let configuration = AEAssessmentConfiguration()
    let app = AEAssessmentApplication(bundleIdentifier: "com.example.notes")
    configuration.setConfiguration(AEAssessmentParticipantConfiguration(), for: app)
    aacExpect(!configuration.configurationsByApplication.isEmpty, "present")
    configuration.remove(AEAssessmentApplication(bundleIdentifier: "com.example.notes"))
    aacExpect(configuration.configurationsByApplication.isEmpty, "removed by bundle")
}

func testSetConfigurationReplacesSameBundle() {
    let configuration = AEAssessmentConfiguration()
    let first = AEAssessmentParticipantConfiguration()
    first.allowsNetworkAccess = false
    let second = AEAssessmentParticipantConfiguration()
    second.allowsNetworkAccess = true
    configuration.setConfiguration(first, for: AEAssessmentApplication(bundleIdentifier: "a.b"))
    configuration.setConfiguration(second, for: AEAssessmentApplication(bundleIdentifier: "a.b"))
    aacExpect(configuration.configurationsByApplication.count == 1, "replaced")
    aacExpect(
        configuration.configurationsByApplication[
            AEAssessmentApplication(bundleIdentifier: "a.b")
        ]?.allowsNetworkAccess == true,
        "latest"
    )
}
