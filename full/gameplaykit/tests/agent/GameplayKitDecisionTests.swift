import Foundation
import GameplayKit

func testDecisionTreeFindActionAndBranches() {
    let decision = GKDecisionTree(attribute: "color" as NSString)
    precondition(decision.rootNode != nil)
    let go = decision.rootNode?.createBranch(value: 1, attribute: "go" as NSString)
    _ = decision.rootNode?.createBranch(weight: 2, attribute: "wait" as NSString)
    _ = decision.rootNode?.createBranch(predicate: NSPredicate(value: false), attribute: "skip" as NSString)
    _ = go
    let action = decision.findAction(forAnswers: ["color" as NSString: 1 as NSNumber]) as? NSString
    precondition(action == "go")
    _ = decision.randomSource
    decision.randomSource = GKARC4RandomSource(seed: Data([1]))

    let examples: [[any NSObjectProtocol]] = [["red" as NSString], ["blue" as NSString]]
    let tree = GKDecisionTree(
        examples: examples,
        actions: ["left" as NSString, "right" as NSString],
        attributes: ["color" as NSString]
    )
    _ = tree.findAction(forAnswers: [:])
}

func testDecisionTreeFailClosedImportExport() {
    let url = URL(fileURLWithPath: "/tmp/openuikit-missing.gktree")
    let imported = GKDecisionTree(url: url, error: nil)
    _ = imported.rootNode
    let alt = GKDecisionTree(URL: url, error: nil)
    _ = alt.rootNode
    let tree = GKDecisionTree(attribute: "root" as NSString)
    precondition(tree.export(to: url, error: nil) == false)
}
