@_spi(OpenUIKitHost) import TipKit
import Foundation

func testActionStringProtocolInit() {
    let fired = TipKitLocked(0)
    let action = Tips.Action(id: "open-settings", title: "Open Settings") {
        fired.store(fired.load() + 1)
    }
    precondition(action.id == "open-settings")
    precondition(action.index == nil)
    precondition(action.titleText == "Open Settings")
    tipKitAwait {
        await MainActor.run {
            action.handler()
        }
    }
    precondition(fired.load() == 1)
    let inferred = Tips.Action(title: "OnlyTitle")
    precondition(inferred.id == "OnlyTitle")
}

func testParameterAndRuleSPI() {
    let parameter = Tips.Parameter(wrappedValue: true, id: "seen-onboarding", options: .transient)
    precondition(parameter.id == "seen-onboarding")
    precondition(parameter.wrappedValue == true)
    parameter.wrappedValue = false
    precondition(parameter.wrappedValue == false)
    precondition(parameter.projectedValue.id == "seen-onboarding")
    precondition(Tips.ParameterOption.transient == .transient)

    let yes = Tips.Rule(hostPredicate: { true })
    let no = Tips.Rule(hostPredicate: { false })
    precondition(yes.evaluateHost())
    precondition(no.evaluateHost() == false)
    let and = Tips.Rule.conjunction(yes, no)
    precondition(and.evaluateHost() == false)
    precondition(and.hostOperation == .conjunction)
    let or = Tips.Rule.disjunction(yes, no)
    precondition(or.evaluateHost())
    precondition(or.hostOperation == .disjunction)
    precondition(Tips.Rule.CompoundOperation.conjunction != .disjunction)
    var hasher = Hasher()
    Tips.Rule.CompoundOperation.conjunction.hash(into: &hasher)
    _ = Tips.Rule.CompoundOperation.disjunction.hashValue
}
