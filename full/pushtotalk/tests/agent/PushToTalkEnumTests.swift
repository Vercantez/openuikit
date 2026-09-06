import PushToTalk

func testPTChannelJoinReasonRawValues() {
    precondition(PTChannelJoinReason.developerRequest.rawValue == 0)
    precondition(PTChannelJoinReason.channelRestoration.rawValue == 1)
    precondition(PTChannelJoinReason(rawValue: 0) == .developerRequest)
    precondition(PTChannelJoinReason(rawValue: 1) == .channelRestoration)
    precondition(PTChannelJoinReason(rawValue: 2) == nil)
    precondition(PTChannelJoinReason.developerRequest != .channelRestoration)

    var hasherA = Hasher()
    var hasherB = Hasher()
    PTChannelJoinReason.developerRequest.hash(into: &hasherA)
    PTChannelJoinReason.developerRequest.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        PTChannelJoinReason.channelRestoration.hashValue
            == PTChannelJoinReason.channelRestoration.hashValue
    )
}

func testPTChannelLeaveReasonRawValues() {
    precondition(PTChannelLeaveReason.unknown.rawValue == 0)
    precondition(PTChannelLeaveReason.userRequest.rawValue == 1)
    precondition(PTChannelLeaveReason.developerRequest.rawValue == 2)
    precondition(PTChannelLeaveReason.systemPolicy.rawValue == 3)
    precondition(PTChannelLeaveReason(rawValue: 0) == .unknown)
    precondition(PTChannelLeaveReason(rawValue: 3) == .systemPolicy)
    precondition(PTChannelLeaveReason(rawValue: 4) == nil)
    precondition(PTChannelLeaveReason.userRequest != .developerRequest)

    var hasherA = Hasher()
    var hasherB = Hasher()
    PTChannelLeaveReason.systemPolicy.hash(into: &hasherA)
    PTChannelLeaveReason.systemPolicy.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(PTChannelLeaveReason.unknown.hashValue == PTChannelLeaveReason.unknown.hashValue)
}

func testPTChannelTransmitRequestSourceRawValues() {
    precondition(PTChannelTransmitRequestSource.unknown.rawValue == 0)
    precondition(PTChannelTransmitRequestSource.userRequest.rawValue == 1)
    precondition(PTChannelTransmitRequestSource.developerRequest.rawValue == 2)
    precondition(PTChannelTransmitRequestSource.handsfreeButton.rawValue == 3)
    precondition(PTChannelTransmitRequestSource(rawValue: 0) == .unknown)
    precondition(PTChannelTransmitRequestSource(rawValue: 3) == .handsfreeButton)
    precondition(PTChannelTransmitRequestSource(rawValue: 4) == nil)
    precondition(PTChannelTransmitRequestSource.userRequest != .handsfreeButton)

    var hasherA = Hasher()
    var hasherB = Hasher()
    PTChannelTransmitRequestSource.developerRequest.hash(into: &hasherA)
    PTChannelTransmitRequestSource.developerRequest.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        PTChannelTransmitRequestSource.unknown.hashValue
            == PTChannelTransmitRequestSource.unknown.hashValue
    )
}

func testPTServiceStatusRawValues() {
    precondition(PTServiceStatus.ready.rawValue == 0)
    precondition(PTServiceStatus.connecting.rawValue == 1)
    precondition(PTServiceStatus.unavailable.rawValue == 2)
    precondition(PTServiceStatus(rawValue: 0) == .ready)
    precondition(PTServiceStatus(rawValue: 2) == .unavailable)
    precondition(PTServiceStatus(rawValue: 3) == nil)
    precondition(PTServiceStatus.ready != .connecting)

    var hasherA = Hasher()
    var hasherB = Hasher()
    PTServiceStatus.connecting.hash(into: &hasherA)
    PTServiceStatus.connecting.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(PTServiceStatus.unavailable.hashValue == PTServiceStatus.unavailable.hashValue)
}

func testPTTransmissionModeRawValues() {
    precondition(PTTransmissionMode.fullDuplex.rawValue == 0)
    precondition(PTTransmissionMode.halfDuplex.rawValue == 1)
    precondition(PTTransmissionMode.listenOnly.rawValue == 2)
    precondition(PTTransmissionMode(rawValue: 0) == .fullDuplex)
    precondition(PTTransmissionMode(rawValue: 2) == .listenOnly)
    precondition(PTTransmissionMode(rawValue: 3) == nil)
    precondition(PTTransmissionMode.fullDuplex != .halfDuplex)

    var hasherA = Hasher()
    var hasherB = Hasher()
    PTTransmissionMode.listenOnly.hash(into: &hasherA)
    PTTransmissionMode.listenOnly.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(PTTransmissionMode.halfDuplex.hashValue == PTTransmissionMode.halfDuplex.hashValue)
}
