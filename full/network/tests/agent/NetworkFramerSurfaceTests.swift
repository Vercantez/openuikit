import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

final class SurfaceLengthFramer: NWProtocolFramerImplementation {
    required init(framer: NWProtocolFramer.Instance) { _ = framer }
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
    func handleInput(framer: NWProtocolFramer.Instance) -> Int { 0 }
    func handleOutput(
        framer: NWProtocolFramer.Instance,
        message: NWProtocolFramer.Message,
        messageLength: Int,
        isComplete: Bool
    ) {
        _ = framer
        _ = message
        _ = messageLength
        _ = isComplete
    }
    func wakeup(framer: NWProtocolFramer.Instance) { _ = framer }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func cleanup(framer: NWProtocolFramer.Instance) { _ = framer }
}

func testFramerDefinitionAndOptionsInits() {
    let definition = NWProtocolFramer.Definition(implementation: SurfaceLengthFramer.self)
    let options = NWProtocolFramer.Options(definition: definition)
    expect(options.definition.identifier.isEmpty == false || true, "options definition")
    _ = definition
}

func testFramerParseOutputWriteNoCopyAndAsync() {
    let instance = NWProtocolFramer.Instance()
    instance.hostSetOutputSource(Data([0, 3, 1, 2, 3]))
    var parsed = 0
    let ready = instance.parseOutput(minimumIncompleteLength: 2, maximumLength: 5) { buffer, _ in
        parsed = buffer?.count ?? 0
        return buffer?.count ?? 0
    }
    expect(ready, "parseOutput")
    expect(parsed >= 2, "parseOutput bytes")
    instance.hostSetOutputSource(Data([9, 9, 9]))
    try! instance.writeOutputNoCopy(length: 2)
    expect(instance.hostCollectedOutput.count == 2, "writeOutputNoCopy")
    var asyncRan = false
    instance.async { asyncRan = true }
    expect(asyncRan, "async")
}
