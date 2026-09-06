import Foundation
import Assignables

func testAssignableConfiguration() {
    var document = assignablesMakeDocument()
    assignablesExpect(document.configuration.correctScoreMarkType == .checkmark, "default mark")
    assignablesExpect(document.configuration.pointsPerCorrectScoreMark == 1, "correct")
    assignablesExpect(document.configuration.pointsPerIncorrectScoreMark == 0, "incorrect")
    assignablesExpect(document.configuration.pointsPerBonusScoreMark == 0, "bonus")
    assignablesExpect(document.configuration.maxScore == nil, "max")
    document.configuration.correctScoreMarkType = .star
    document.configuration.pointsPerCorrectScoreMark = 3
    document.configuration.pointsPerIncorrectScoreMark = -0.5
    document.configuration.pointsPerBonusScoreMark = 1
    document.configuration.maxScore = 10
    assignablesExpect(document.configuration.correctScoreMarkType == .star, "set mark")
    assignablesExpect(document.configuration.pointsPerCorrectScoreMark == 3, "set correct")
    assignablesExpect(document.configuration.pointsPerIncorrectScoreMark == -0.5, "set incorrect")
    assignablesExpect(document.configuration.pointsPerBonusScoreMark == 1, "set bonus")
    assignablesExpect(document.configuration.maxScore == 10, "set max")
}

func testWorkConfiguration() {
    var work = try! assignablesMakeDocument().makeAssignedWorkDocument(id: "cfg")
    assignablesExpect(work.configuration.manualScore == nil, "default")
    work.configuration.manualScore = 12.5
    assignablesExpect(work.configuration.manualScore == 12.5, "set")
    assignablesExpect(work.computeScore() == 12.5, "manual used")
}
