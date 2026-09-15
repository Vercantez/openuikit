import Foundation
import Dispatch
import GameController

func testElementCollectionAssociatedTypes() {
    typealias ButtonCollection = GCPhysicalInputElementCollection<any GCButtonElement>
    typealias CollectedElement = ButtonCollection.Element
    typealias CollectedSlice = ButtonCollection.SubSequence
    typealias CollectedIndices = ButtonCollection.Indices
    typealias CollectedIterator = ButtonCollection.Iterator

    _ = CollectedElement.self
    _ = CollectedSlice.self
    _ = CollectedIndices.self
    _ = CollectedIterator.self

    GCSimulatedInput.reset()
    let simulated = GCSimulatedInput.makeExtendedGamepad()
    let buttons: ButtonCollection = simulated.input.buttons
    precondition(buttons.startIndex < buttons.endIndex)
    let first: CollectedElement = buttons[buttons.startIndex]
    _ = first.aliases

    let indices: CollectedIndices = buttons.indices
    precondition(!indices.isEmpty)

    var iterator: CollectedIterator = buttons.makeIterator()
    let iterated = iterator.next()
    precondition(iterated != nil)

    var walked = 0
    for _ in buttons {
        walked += 1
    }
    precondition(walked > 0)

    let slice: CollectedSlice = buttons[buttons.startIndex..<buttons.endIndex]
    precondition(slice.count == walked)
    precondition(slice.startIndex == buttons.startIndex)
    GCSimulatedInput.reset()
}
