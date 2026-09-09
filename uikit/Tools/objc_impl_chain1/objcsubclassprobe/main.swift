// Driver for the Objective-C subclass scenario so it can run where XCTest
// cannot be spawned (the iOS simulator via `simctl spawn`). Exit status 0
// only when every line is PASS. docs/agent_reports/objc-impl-chain1.md.
import Foundation
import OpenUIKit
import OpenUIKitObjCSubclassProbe

MainActor.assumeIsolated {
    let lines = OUIObjCSubclassScenario()
    for line in lines { print(line) }
    let failures = lines.filter { $0.hasPrefix("FAIL") }.count
    print("RESULT: \(lines.count - failures)/\(lines.count) PASS")
    exit(failures == 0 && lines.count >= 20 ? 0 : 1)
}
