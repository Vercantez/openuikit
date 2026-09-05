import Foundation
import Dispatch
import GameController

func testPhysicalInputElementCollection() {
    GCSimulatedInput.reset()
    let empty = GCPhysicalInputElementCollection<any GCPhysicalInputElement>()
    precondition(empty.startIndex == empty.endIndex)
    let emptyIdx = empty.startIndex
    precondition(emptyIdx == empty.endIndex)
    precondition(emptyIdx <= empty.endIndex)
    _ = emptyIdx..<empty.endIndex
    _ = ..<empty.endIndex
    precondition(empty[GCButtonElementName.a] == nil)
    precondition(empty[GCAxisElementName(rawValue: "x")] == nil)
    precondition(empty[GCSwitchElementName(rawValue: "s")] == nil)
    precondition(empty[GCPhysicalInputElementName(rawValue: "p")] == nil)
    precondition(empty[GCDirectionPadElementName.directionPad] == nil)
    precondition(empty[GCInputButtonA] == nil)

    let simulated = GCSimulatedInput.makeExtendedGamepad()
    let buttons = simulated.input.buttons
    let start = buttons.startIndex
    precondition(start < buttons.endIndex)
    _ = buttons[start]
    _ = buttons.index(after: start)
    _ = GCPhysicalInputElementCollection<any GCPhysicalInputElement>.self
    _ = GCPhysicalInputElementCollection<any GCPhysicalInputElement>.Index.self
    GCSimulatedInput.reset()
}
