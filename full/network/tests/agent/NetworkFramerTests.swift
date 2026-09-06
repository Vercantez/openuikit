import Foundation
import Network

private func framerExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

/// Length-prefixed (2-byte big-endian) framer used as the host-driver probe.
final class LengthPrefixFramer: NWProtocolFramerImplementation {
    required init(framer: NWProtocolFramer.Instance) { _ = framer }

    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        .ready
    }

    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        var consumed = 0
        while true {
            var length = -1
            let headerReady = framer.parseInput(
                minimumIncompleteLength: 2,
                maximumLength: 2
            ) { buffer, _ in
                guard let buffer, buffer.count >= 2, let base = buffer.baseAddress else {
                    return 0
                }
                let high = base.load(fromByteOffset: 0, as: UInt8.self)
                let low = base.load(fromByteOffset: 1, as: UInt8.self)
                length = Int(high) << 8 | Int(low)
                return 2
            }
            if !headerReady || length < 0 { return consumed }
            consumed += 2
            var payload = Data()
            let bodyReady = framer.parseInput(
                minimumIncompleteLength: length,
                maximumLength: length
            ) { buffer, _ in
                guard let buffer, buffer.count >= length else { return 0 }
                payload = Data(buffer.prefix(length))
                return length
            }
            if !bodyReady { return consumed }
            consumed += length
            let message = NWProtocolFramer.Message(definition: framer.options.definition)
            message["n"] = payload.count
            framer.deliverInput(data: payload, message: message, isComplete: true)
        }
    }

    func handleOutput(
        framer: NWProtocolFramer.Instance,
        message: NWProtocolFramer.Message,
        messageLength: Int,
        isComplete: Bool
    ) {
        _ = message
        _ = isComplete
        let high = UInt8((messageLength >> 8) & 0xff)
        let low = UInt8(messageLength & 0xff)
        framer.writeOutput(data: Data([high, low]))
        try? framer.writeOutputNoCopy(length: messageLength)
    }

    func wakeup(framer: NWProtocolFramer.Instance) { _ = framer }
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func cleanup(framer: NWProtocolFramer.Instance) { _ = framer }
}

func testFramerHostDriverParseInputWriteOutput() {
    let driver = NWProtocolFramerHostDriver(implementation: LengthPrefixFramer.self)
    framerExpect(driver.startResult == .ready, "start ready")
    framerExpect(driver.instance.isReady, "marked ready")
    let payload = Data([1, 2, 3, 4])
    var framed = Data([0x00, 0x04])
    framed.append(payload)
    let consumed = driver.handleIncoming(framed, complete: true)
    framerExpect(consumed == 6, "consumed header+body")
    framerExpect(driver.instance.deliveredMessages.count == 1, "one message")
    framerExpect(driver.instance.deliveredMessages[0].data == payload, "payload")
    framerExpect(driver.instance.deliveredMessages[0].isComplete, "complete")
    if let count = driver.instance.deliveredMessages[0].message["n"] as? Int {
        framerExpect(count == 4, "message metadata")
    } else {
        preconditionFailure("message n")
    }

    let message = NWProtocolFramer.Message(definition: driver.instance.options.definition)
    driver.handleOutgoing(message: message, payload: payload, isComplete: true)
    framerExpect(driver.output == framed, "writeOutput length prefix")
}

func testFramerParseInputWaitsForMinimum() {
    let instance = NWProtocolFramer.Instance()
    instance.hostFeedInput(Data([0x00]), isComplete: false)
    var called = false
    let ready = instance.parseInput(minimumIncompleteLength: 2, maximumLength: 8) { _, _ in
        called = true
        return 0
    }
    framerExpect(!ready, "not enough bytes")
    framerExpect(!called, "parse not invoked")
    instance.hostFeedInput(Data([0x04, 1, 2, 3, 4]), isComplete: true)
    var consumed = 0
    let nowReady = instance.parseInput(minimumIncompleteLength: 2, maximumLength: 2) { buffer, complete in
        framerExpect(buffer?.count == 2, "max 2")
        framerExpect(!complete, "more bytes remain")
        consumed = 2
        return 2
    }
    framerExpect(nowReady, "header available")
    framerExpect(consumed == 2, "consumed 2")
}

func testFramerPassThroughMarkFailedAndAsync() {
    let definition = NWProtocolFramer.Definition(implementation: LengthPrefixFramer.self)
    let options = NWProtocolFramer.Options(definition: definition)
    let parameters = NWParameters.tcp
    let local = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .http)
    let instance = NWProtocolFramer.Instance(
        options: options,
        parameters: parameters,
        local: local,
        remote: local
    )
    framerExpect(instance.parameters === parameters, "parameters")
    framerExpect(instance.local == local, "local")
    framerExpect(instance.remote == local, "remote")
    framerExpect(instance.options.definition.identifier == definition.identifier, "options")
    instance.passThroughInput()
    instance.passThroughOutput()
    instance.passInput(to: NWProtocolTCP.definition)
    instance.markFailed(error: .posix(.EPIPE))
    framerExpect(instance.failedError == .posix(.EPIPE), "failed")
    var ran = false
    instance.async { ran = true }
    framerExpect(ran, "async runs inline on Linux")
    try? instance.prependApplicationProtocol(options: NWProtocolTCP.Options())
    instance.scheduleWakeup(wakeupTime: .milliseconds(5))
    if case .milliseconds(let value) = instance.lastWakeup {
        framerExpect(value == 5, "ms wakeup")
    } else {
        preconditionFailure("milliseconds")
    }
    instance.scheduleWakeup(wakeupTime: .forever)
    framerExpect(instance.lastWakeup == .forever, "forever")
    instance.scheduleWakeup(wakeupTime: .now)
    instance.scheduleWakeup(wakeupTime: .interval(0.01))
    _ = instance.debugDescription
    framerExpect(instance.deliverInputNoCopy(
        length: 0,
        message: NWProtocolFramer.Message(definition: definition),
        isComplete: true
    ), "zero copy empty")
    instance.writeOutput(data: Data([9]))
    instance.writeOutput(data: [UInt8(8)])
    framerExpect(instance.hostCollectedOutput == Data([9, 8]), "generic writeOutput")
    _ = NWProtocolFramer.StartResult.willMarkReady
}
