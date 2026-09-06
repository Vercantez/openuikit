import BrowserKit
import Foundation

func testBEAvailabilityContextType() {
    let context: BEAvailability.Context = .webBrowser
    precondition(type(of: context) == BEAvailability.Context.self)
    precondition(context.rawValue == BEAvailability.Context.webBrowser.rawValue)
    let raw: Int = context.rawValue
    precondition(type(of: raw) == Int.self)
}

func testBEAvailabilityContextWebBrowserRawValue() {
    precondition(BEAvailability.Context.webBrowser.rawValue == 0)
    let again: BEAvailability.Context = .webBrowser
    precondition(again == .webBrowser)
    precondition(again.rawValue == 0)
}

func testBEAvailabilityContextInitRawValue() {
    precondition(BEAvailability.Context(rawValue: 0) == .webBrowser)
    precondition(BEAvailability.Context(rawValue: 0)?.rawValue == 0)
    precondition(BEAvailability.Context(rawValue: 1) == nil)
    precondition(BEAvailability.Context(rawValue: -1) == nil)
    precondition(BEAvailability.Context(rawValue: Int.max) == nil)
}

func testBEAvailabilityContextInequality() {
    let left = BEAvailability.Context.webBrowser
    let right = BEAvailability.Context(rawValue: 0)!
    precondition(!(left != right))
    precondition(left == right)
    precondition(!(BEAvailability.Context.webBrowser != .webBrowser))
}

func testBEAvailabilityContextHashValue() {
    let first = BEAvailability.Context.webBrowser.hashValue
    let second = BEAvailability.Context(rawValue: 0)!.hashValue
    precondition(first == second)
    precondition(BEAvailability.Context.webBrowser.hashValue == first)
}

func testBEAvailabilityContextHashInto() {
    var first = Hasher()
    var second = Hasher()
    BEAvailability.Context.webBrowser.hash(into: &first)
    BEAvailability.Context(rawValue: 0)!.hash(into: &second)
    var set = Set<BEAvailability.Context>()
    set.insert(.webBrowser)
    set.insert(BEAvailability.Context(rawValue: 0)!)
    precondition(set.count == 1)
    _ = first.finalize()
    _ = second.finalize()
}
