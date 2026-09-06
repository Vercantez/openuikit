@_spi(OpenUIKitHost) import SensitiveContentAnalysis

private func scExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testSensitivityAnalysisHostSnapshot() {
    let analysis = SCSensitivityAnalysis.host_makeUnanalyzed()
    scExpect(analysis is NSObject, "SCSensitivityAnalysis subclasses NSObject")
    scExpect(type(of: analysis) == SCSensitivityAnalysis.self, "dynamic type")
}

func testIsSensitiveFalse() {
    let unset = SCSensitivityAnalysis.host_makeUnanalyzed()
    scExpect(unset.isSensitive == false, "unanalyzed snapshot is not sensitive")
    let flagged = SCSensitivityAnalysis.host_makeUnanalyzed(isSensitive: true)
    scExpect(flagged.isSensitive == true, "host snapshot stores isSensitive")
}

func testShouldIndicateSensitivityFalse() {
    let unset = SCSensitivityAnalysis.host_makeUnanalyzed()
    scExpect(unset.shouldIndicateSensitivity == false, "unanalyzed does not indicate")
    let flagged = SCSensitivityAnalysis.host_makeUnanalyzed(shouldIndicateSensitivity: true)
    scExpect(flagged.shouldIndicateSensitivity == true, "host snapshot stores shouldIndicateSensitivity")
}

func testShouldInterruptVideoFalse() {
    let unset = SCSensitivityAnalysis.host_makeUnanalyzed()
    scExpect(unset.shouldInterruptVideo == false, "unanalyzed does not interrupt")
    let flagged = SCSensitivityAnalysis.host_makeUnanalyzed(shouldInterruptVideo: true)
    scExpect(flagged.shouldInterruptVideo == true, "host snapshot stores shouldInterruptVideo")
}

func testShouldMuteAudioFalse() {
    let unset = SCSensitivityAnalysis.host_makeUnanalyzed()
    scExpect(unset.shouldMuteAudio == false, "unanalyzed does not mute")
    let flagged = SCSensitivityAnalysis.host_makeUnanalyzed(shouldMuteAudio: true)
    scExpect(flagged.shouldMuteAudio == true, "host snapshot stores shouldMuteAudio")
}
