import Foundation
import Cinematic

func testCNDetectionIDRawValueInit() {
    let identifier = CNDetectionID(rawValue: 42)
    precondition(identifier.rawValue == 42)
}

func testCNDetectionIDUnlabeledInit() {
    let identifier = CNDetectionID(7)
    precondition(identifier.rawValue == 7)
    precondition(identifier == CNDetectionID(rawValue: 7))
}

func testCNDetectionIDInequalityAndHashable() {
    precondition(CNDetectionID(1) != CNDetectionID(2))
    precondition(!(CNDetectionID(3) != CNDetectionID(3)))
    precondition(CNDetectionID(9).hashValue == CNDetectionID(9).hashValue)
    precondition(CNDetectionID(9).hashValue != CNDetectionID(10).hashValue)
    var hasher = Hasher()
    CNDetectionID(11).hash(into: &hasher)
    _ = hasher.finalize()
}

func testCNDetectionGroupIDRawValueInit() {
    let identifier = CNDetectionGroupID(rawValue: 100)
    precondition(identifier.rawValue == 100)
}

func testCNDetectionGroupIDUnlabeledInit() {
    let identifier = CNDetectionGroupID(5)
    precondition(identifier.rawValue == 5)
}

func testCNDetectionGroupIDInequalityAndHashable() {
    precondition(CNDetectionGroupID(1) != CNDetectionGroupID(2))
    precondition(CNDetectionGroupID(4).hashValue == CNDetectionGroupID(4).hashValue)
    var hasher = Hasher()
    CNDetectionGroupID(8).hash(into: &hasher)
    _ = hasher.finalize()
}
