import Foundation
import Dispatch
import GameController

func testPhysicalInputSourceAndSwitch() {
    final class AgentSource: NSObject, GCPhysicalInputSource {
        var direction: GCPhysicalInputSourceDirection = [.up, .right]
        var elementAliases: Set<String> = ["AgentTrigger"]
        var elementLocalizedName: String? = "Agent Trigger"
        var sfSymbolsName: String? = "gamecontroller.fill"
    }

    final class AgentSwitchPosition: NSObject, GCSwitchPositionInput {
        var canWrap: Bool = false
        var lastPositionLatency: TimeInterval = 0.001
        var lastPositionTimestamp: TimeInterval = 123.0
        var position: Int = 2
        var positionDidChangeHandler: ((any GCPhysicalInputElement, any GCSwitchPositionInput, Int) -> Void)?
        var positionRange: NSRange = NSRange(location: 0, length: 3)
        var isSequential: Bool = true
        var sources: Set<AnyHashable> = ["agent"]
    }

    final class AgentSwitch: NSObject, GCSwitchElement {
        var aliases: Set<String> = ["AgentSwitch"]
        var localizedName: String? = "Agent Switch"
        var sfSymbolsName: String? = "switch.2"
        let storedPosition = AgentSwitchPosition()
        var positionInput: any GCSwitchPositionInput { storedPosition }
    }

    _ = (any GCPhysicalInputSource).self
    let source: any GCPhysicalInputSource = AgentSource()
    precondition(source.direction == [.up, .right])
    precondition(source.elementAliases == ["AgentTrigger"])
    precondition(source.elementLocalizedName == "Agent Trigger")
    precondition(source.sfSymbolsName == "gamecontroller.fill")

    _ = (any GCSwitchElement).self
    _ = (any GCSwitchPositionInput).self
    let element: any GCSwitchElement = AgentSwitch()
    precondition(element.aliases == ["AgentSwitch"])
    let positionInput: any GCSwitchPositionInput = element.positionInput
    precondition(positionInput.position == 2)
    precondition(positionInput.canWrap == false)
    precondition(positionInput.lastPositionLatency == 0.001)
    precondition(positionInput.lastPositionTimestamp == 123.0)
    precondition(positionInput.positionRange == NSRange(location: 0, length: 3))
    precondition(positionInput.isSequential == true)
    let sequential = positionInput.isSequential
    precondition(sequential == true)
    precondition(positionInput.sources == ["agent"])
    var positionFires = 0
    let positionHandler: (any GCPhysicalInputElement, any GCSwitchPositionInput, Int) -> Void =
        { _, _, _ in positionFires += 1 }
    (positionInput as! AgentSwitchPosition).positionDidChangeHandler = positionHandler
    precondition((positionInput as! AgentSwitchPosition).positionDidChangeHandler != nil)
    (positionInput as! AgentSwitchPosition).positionDidChangeHandler?(element, positionInput, 2)
    precondition(positionFires == 1)
    _ = positionInput.positionDidChangeHandler
}
