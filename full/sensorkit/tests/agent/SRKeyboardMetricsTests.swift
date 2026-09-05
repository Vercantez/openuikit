import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testKeyboardScalarCounts() {
    let metrics = SRKeyboardMetrics(
        keyboardIdentifier: "en-US",
        version: "1.2",
        duration: 30,
        width: Measurement(value: 0.2, unit: .meters),
        height: Measurement(value: 0.1, unit: .meters),
        inputModes: ["en"],
        sessionIdentifiers: ["a", "b"],
        totalWords: 10,
        totalAlteredWords: 1,
        totalTaps: 20,
        totalDrags: 1,
        totalDeletes: 2,
        totalEmojis: 3,
        totalPaths: 4,
        totalPathTime: 5,
        totalPathLength: Measurement(value: 1.5, unit: .meters),
        totalAutoCorrections: 6,
        totalSpaceCorrections: 7,
        totalRetroCorrections: 8,
        totalTranspositionCorrections: 9,
        totalInsertKeyCorrections: 10,
        totalSkipTouchCorrections: 11,
        totalNearKeyCorrections: 12,
        totalHitTestCorrections: 13,
        totalSubstitutionCorrections: 14,
        totalTypingDuration: 15,
        totalTypingEpisodes: 16,
        totalPauses: 17,
        totalPathPauses: 18,
        pathTypingSpeed: 1.1,
        typingSpeed: 2.2,
        pathErrorDistanceRatio: [NSNumber(value: 0.25)]
    )
    skExpect(metrics.keyboardIdentifier == "en-US", "id")
    skExpect(metrics.version == "1.2", "ver")
    skExpect(metrics.duration == 30, "dur")
    skExpect(metrics.width.value == 0.2, "w")
    skExpect(metrics.height.value == 0.1, "h")
    skExpect(metrics.inputModes == ["en"], "modes")
    skExpect(metrics.sessionIdentifiers == ["a", "b"], "sessions")
    skExpect(metrics.totalWords == 10, "words")
    skExpect(metrics.totalAlteredWords == 1, "altered")
    skExpect(metrics.totalTaps == 20, "taps")
    skExpect(metrics.totalDrags == 1, "drags")
    skExpect(metrics.totalDeletes == 2, "del")
    skExpect(metrics.totalEmojis == 3, "emoji")
    skExpect(metrics.totalPaths == 4, "paths")
    skExpect(metrics.totalPathTime == 5, "ptime")
    skExpect(metrics.totalPathLength.value == 1.5, "plen")
    skExpect(metrics.totalAutoCorrections == 6, "auto")
    skExpect(metrics.totalSpaceCorrections == 7, "space")
    skExpect(metrics.totalRetroCorrections == 8, "retro")
    skExpect(metrics.totalTranspositionCorrections == 9, "trans")
    skExpect(metrics.totalInsertKeyCorrections == 10, "ins")
    skExpect(metrics.totalSkipTouchCorrections == 11, "skip")
    skExpect(metrics.totalNearKeyCorrections == 12, "near")
    skExpect(metrics.totalHitTestCorrections == 13, "hit")
    skExpect(metrics.totalSubstitutionCorrections == 14, "sub")
    skExpect(metrics.totalTypingDuration == 15, "tdur")
    skExpect(metrics.totalTypingEpisodes == 16, "ep")
    skExpect(metrics.totalPauses == 17, "pause")
    skExpect(metrics.totalPathPauses == 18, "ppause")
    skExpect(metrics.pathTypingSpeed == 1.1, "pspeed")
    skExpect(metrics.typingSpeed == 2.2, "tspeed")
    skExpect(metrics.pathErrorDistanceRatio.first?.doubleValue == 0.25, "ratio")
}

func testKeyboardProbabilityMetrics() {
    let durationSample = Measurement(value: 0.05, unit: UnitDuration.seconds)
    let lengthSample = Measurement(value: 0.01, unit: UnitLength.meters)
    let metrics = SRKeyboardMetrics(
        durationSamples: [durationSample],
        lengthSamples: [lengthSample]
    )
    skExpect(metrics.anyTapToCharKey.distributionSampleValues == [durationSample], "anyTapToCharKey")
    skExpect(metrics.anyTapToPlaneChangeKey.distributionSampleValues == [durationSample], "anyTapToPlane")
    skExpect(metrics.charKeyToAnyTapKey.distributionSampleValues == [durationSample], "charAny")
    skExpect(metrics.charKeyToDelete.distributionSampleValues == [durationSample], "charDel")
    skExpect(metrics.charKeyToPlaneChangeKey.distributionSampleValues == [durationSample], "charPlane")
    skExpect(metrics.charKeyToPrediction.distributionSampleValues == [durationSample], "charPred")
    skExpect(metrics.charKeyToSpaceKey.distributionSampleValues == [durationSample], "charSpace")
    skExpect(metrics.deleteToCharKey.distributionSampleValues == [durationSample], "delChar")
    skExpect(metrics.deleteToDelete.distributionSampleValues == [durationSample], "delDel")
    skExpect(metrics.deleteToDeletes.count == 1, "delDeletes")
    skExpect(metrics.deleteToPath.distributionSampleValues == [durationSample], "delPath")
    skExpect(metrics.deleteToPlaneChangeKey.distributionSampleValues == [durationSample], "delPlane")
    skExpect(metrics.deleteToShiftKey.distributionSampleValues == [durationSample], "delShift")
    skExpect(metrics.deleteToSpaceKey.distributionSampleValues == [durationSample], "delSpace")
    skExpect(metrics.deleteTouchDownUp.distributionSampleValues == [durationSample], "delTDU")
    skExpect(metrics.pathToDelete.distributionSampleValues == [durationSample], "pathDel")
    skExpect(metrics.pathToPath.distributionSampleValues == [durationSample], "pathPath")
    skExpect(metrics.pathToSpace.distributionSampleValues == [durationSample], "pathSpace")
    skExpect(metrics.planeChangeKeyToCharKey.distributionSampleValues == [durationSample], "planeChar")
    skExpect(metrics.planeChangeToAnyTap.distributionSampleValues == [durationSample], "planeAny")
    skExpect(metrics.shortWordCharKeyToCharKey.distributionSampleValues == [durationSample], "shortChar")
    skExpect(metrics.shortWordCharKeyTouchDownUp.distributionSampleValues == [durationSample], "shortTDU")
    skExpect(metrics.spaceToCharKey.distributionSampleValues == [durationSample], "spaceChar")
    skExpect(metrics.spaceToDeleteKey.distributionSampleValues == [durationSample], "spaceDel")
    skExpect(metrics.spaceToPath.distributionSampleValues == [durationSample], "spacePath")
    skExpect(metrics.spaceToPlaneChangeKey.distributionSampleValues == [durationSample], "spacePlane")
    skExpect(metrics.spaceToPredictionKey.distributionSampleValues == [durationSample], "spacePred")
    skExpect(metrics.spaceToShiftKey.distributionSampleValues == [durationSample], "spaceShift")
    skExpect(metrics.spaceToSpaceKey.distributionSampleValues == [durationSample], "spaceSpace")
    skExpect(metrics.spaceTouchDownUp.distributionSampleValues == [durationSample], "spaceTDU")
    skExpect(metrics.touchDownDown.distributionSampleValues == [durationSample], "TDD")
    skExpect(metrics.touchDownUp.distributionSampleValues == [durationSample], "TDU")
    skExpect(metrics.touchUpDown.distributionSampleValues == [durationSample], "TUD")
    skExpect(metrics.deleteDownErrorDistance.distributionSampleValues == [lengthSample], "delDown")
    skExpect(metrics.deleteUpErrorDistance.distributionSampleValues == [lengthSample], "delUp")
    skExpect(metrics.downErrorDistance.distributionSampleValues == [lengthSample], "down")
    skExpect(metrics.upErrorDistance.distributionSampleValues == [lengthSample], "up")
    skExpect(metrics.spaceDownErrorDistance.distributionSampleValues == [lengthSample], "spaceDown")
    skExpect(metrics.spaceUpErrorDistance.distributionSampleValues == [lengthSample], "spaceUp")
    skExpect(metrics.shortWordCharKeyDownErrorDistance.distributionSampleValues == [lengthSample], "shortDown")
    skExpect(metrics.shortWordCharKeyUpErrorDistance.distributionSampleValues == [lengthSample], "shortUp")
    skExpect(metrics.longWordDownErrorDistance.count == 1, "longDown")
    skExpect(metrics.longWordTouchDownDown.count == 1, "longTDD")
    skExpect(metrics.longWordTouchDownUp.count == 1, "longTDU")
    skExpect(metrics.longWordTouchUpDown.count == 1, "longTUD")
    skExpect(metrics.longWordUpErrorDistance.count == 1, "longUp")
}

func testKeyboardSentimentCounts() {
    let metrics = SRKeyboardMetrics(
        wordCounts: [.anger: 4, .positive: 7],
        emojiCounts: [.sad: 2, .confused: 1]
    )
    skExpect(metrics.wordCount(for: .anger) == 4, "word anger")
    skExpect(metrics.wordCount(for: .positive) == 7, "word pos")
    skExpect(metrics.wordCount(for: .death) == 0, "word missing")
    skExpect(metrics.emojiCount(for: .sad) == 2, "emoji sad")
    skExpect(metrics.emojiCount(for: .confused) == 1, "emoji conf")
    skExpect(metrics.emojiCount(for: .health) == 0, "emoji missing")
}
