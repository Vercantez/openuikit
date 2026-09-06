import Foundation
import Cinematic

func testCNDecisionInitWithDetectionID() {
    let time = CMTime(seconds: 2, preferredTimescale: 600)
    let decision = CNDecision(time: time, detectionID: CNDetectionID(3), strong: true)
    precondition(decision.time == time)
    precondition(decision.isStrongDecision)
    precondition(!decision.isUserDecision)
    precondition(decision.focusDetectionID == .single(CNDetectionID(3)))
}

func testCNDecisionInitWithDetectionGroupID() {
    let time = CMTime(seconds: 4, preferredTimescale: 600)
    let decision = CNDecision(
        time: time,
        detectionGroupID: CNDetectionGroupID(9),
        strong: false
    )
    precondition(decision.time.seconds == 4)
    precondition(!decision.isStrongDecision)
    precondition(decision.focusDetectionID == .group(CNDetectionGroupID(9)))
}

func testCNDecisionIsUserDecisionFalseOnConstruct() {
    let decision = CNDecision(time: .zero, detectionID: CNDetectionID(1), strong: false)
    precondition(decision.isUserDecision == false)
}

func testCNDecisionIsStrongDecision() {
    let strong = CNDecision(time: .zero, detectionID: CNDetectionID(1), strong: true)
    let weak = CNDecision(time: .zero, detectionID: CNDetectionID(1), strong: false)
    precondition(strong.isStrongDecision)
    precondition(!weak.isStrongDecision)
}

func testCNDecisionFocusDetectionIDCases() {
    let single = CNDecision.FocusDetectionID.single(CNDetectionID(2))
    let group = CNDecision.FocusDetectionID.group(CNDetectionGroupID(4))
    precondition(single == .single(CNDetectionID(2)))
    precondition(group == .group(CNDetectionGroupID(4)))
    precondition(single != group)
}

func testCNDecisionEquality() {
    let a = CNDecision(time: .zero, detectionID: CNDetectionID(1), strong: true)
    let b = CNDecision(time: .zero, detectionID: CNDetectionID(1), strong: true)
    let c = CNDecision(time: .zero, detectionID: CNDetectionID(2), strong: true)
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))
}

func testCNDecisionFocusDetectionIDEquality() {
    precondition(
        CNDecision.FocusDetectionID.single(CNDetectionID(1)) ==
            .single(CNDetectionID(1))
    )
    precondition(
        CNDecision.FocusDetectionID.single(CNDetectionID(1)) !=
            .single(CNDetectionID(2))
    )
    precondition(
        CNDecision.FocusDetectionID.group(CNDetectionGroupID(1)) !=
            .single(CNDetectionID(1))
    )
}

func testCNDecisionTimeProperty() {
    let time = CMTime(value: 300, timescale: 30)
    let decision = CNDecision(time: time, detectionID: CNDetectionID(8), strong: false)
    precondition(decision.time.value == 300)
    precondition(decision.time.timescale == 30)
}
