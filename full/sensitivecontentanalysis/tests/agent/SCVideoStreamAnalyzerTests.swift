@_spi(OpenUIKitHost) import SensitiveContentAnalysis

private func scExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testVideoStreamAnalyzerType() {
    let analyzer = try! SCVideoStreamAnalyzer(
        participantUUID: "participant-type",
        streamDirection: .incoming
    )
    scExpect((analyzer as Any) is NSObject, "SCVideoStreamAnalyzer subclasses NSObject")
    scExpect(type(of: analyzer) == SCVideoStreamAnalyzer.self, "dynamic type")
}

func testVideoStreamAnalyzerInit() {
    let uuid = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
    let incoming = try! SCVideoStreamAnalyzer(
        participantUUID: uuid,
        streamDirection: .incoming
    )
    scExpect(incoming.host_participantUUID == uuid, "stores participant UUID")
    scExpect(incoming.host_streamDirection == .incoming, "stores incoming")
    scExpect(incoming.host_continueCount == 0, "fresh continue count is 0")
    scExpect(incoming.host_sessionEnded == false, "fresh session is not ended")

    let outgoing = try! SCVideoStreamAnalyzer(
        participantUUID: "local-camera",
        streamDirection: .outgoing
    )
    scExpect(outgoing.host_streamDirection == .outgoing, "stores outgoing")
    scExpect(incoming !== outgoing, "distinct instances")
}

func testAnalysisNilAfterInit() {
    let analyzer = try! SCVideoStreamAnalyzer(
        participantUUID: "nil-analysis",
        streamDirection: .outgoing
    )
    scExpect(analyzer.analysis == nil, "Linux never has an analysis snapshot")
}

func testContinueStreamNoAnalysis() {
    let analyzer = try! SCVideoStreamAnalyzer(
        participantUUID: "continue",
        streamDirection: .incoming
    )
    analyzer.continueStream()
    analyzer.continueStream()
    scExpect(analyzer.host_continueCount == 2, "continueStream increments while active")
    scExpect(analyzer.analysis == nil, "continueStream does not invent analysis")
    scExpect(analyzer.host_sessionEnded == false, "continue does not end the session")
}

func testEndAnalysisClearsSession() {
    let analyzer = try! SCVideoStreamAnalyzer(
        participantUUID: "end",
        streamDirection: .outgoing
    )
    analyzer.continueStream()
    scExpect(analyzer.host_continueCount == 1, "one continue before end")
    analyzer.endAnalysis()
    scExpect(analyzer.host_sessionEnded == true, "endAnalysis marks the session ended")
    scExpect(analyzer.analysis == nil, "endAnalysis does not invent analysis")
    analyzer.continueStream()
    scExpect(analyzer.host_continueCount == 1, "continueStream is ignored after end")
}

func testAnalysisChangesAccessible() {
    let analyzer = try! SCVideoStreamAnalyzer(
        participantUUID: "changes",
        streamDirection: .incoming
    )
    let changes = analyzer.analysisChanges
    _ = changes
    scExpect(analyzer.host_analysisChangesNeverYields, "Linux stream never yields detections")
    scExpect(analyzer.analysis == nil, "accessing analysisChanges does not produce analysis")
}
