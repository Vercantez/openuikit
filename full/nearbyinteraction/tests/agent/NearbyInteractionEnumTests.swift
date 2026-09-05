import NearbyInteraction

func testNIDLTDOACoordinatesTypeRawValues() {
    precondition(NIDLTDOACoordinatesType.geodetic.rawValue == 0)
    precondition(NIDLTDOACoordinatesType.relative.rawValue == 1)
    precondition(NIDLTDOACoordinatesType(rawValue: 0) == .geodetic)
    precondition(NIDLTDOACoordinatesType(rawValue: 1) == .relative)
    precondition(NIDLTDOACoordinatesType(rawValue: 2) == nil)
    precondition(NIDLTDOACoordinatesType.geodetic != .relative)

    var hasherA = Hasher()
    var hasherB = Hasher()
    NIDLTDOACoordinatesType.geodetic.hash(into: &hasherA)
    NIDLTDOACoordinatesType.geodetic.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(NIDLTDOACoordinatesType.geodetic.hashValue == NIDLTDOACoordinatesType.geodetic.hashValue)
}

func testNIDLTDOAMeasurementTypeRawValues() {
    precondition(NIDLTDOAMeasurementType.poll.rawValue == 0)
    precondition(NIDLTDOAMeasurementType.response.rawValue == 1)
    precondition(NIDLTDOAMeasurementType.final.rawValue == 2)
    precondition(NIDLTDOAMeasurementType(rawValue: 0) == .poll)
    precondition(NIDLTDOAMeasurementType(rawValue: 1) == .response)
    precondition(NIDLTDOAMeasurementType(rawValue: 2) == .final)
    precondition(NIDLTDOAMeasurementType(rawValue: 9) == nil)
    precondition(NIDLTDOAMeasurementType.poll != .response)

    var hasherA = Hasher()
    var hasherB = Hasher()
    NIDLTDOAMeasurementType.poll.hash(into: &hasherA)
    NIDLTDOAMeasurementType.poll.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(NIDLTDOAMeasurementType.final.hashValue == NIDLTDOAMeasurementType.final.hashValue)
}

func testNINearbyObjectRemovalReasonRawValues() {
    precondition(NINearbyObject.RemovalReason.timeout.rawValue == 0)
    precondition(NINearbyObject.RemovalReason.peerEnded.rawValue == 1)
    precondition(NINearbyObject.RemovalReason(rawValue: 0) == .timeout)
    precondition(NINearbyObject.RemovalReason(rawValue: 1) == .peerEnded)
    precondition(NINearbyObject.RemovalReason(rawValue: 4) == nil)
    precondition(NINearbyObject.RemovalReason.timeout != .peerEnded)

    var hasherA = Hasher()
    var hasherB = Hasher()
    NINearbyObject.RemovalReason.timeout.hash(into: &hasherA)
    NINearbyObject.RemovalReason.timeout.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(NINearbyObject.RemovalReason.peerEnded.hashValue == NINearbyObject.RemovalReason.peerEnded.hashValue)
}

func testNINearbyObjectVerticalDirectionEstimateRawValues() {
    precondition(NINearbyObject.VerticalDirectionEstimate.unknown.rawValue == 0)
    precondition(NINearbyObject.VerticalDirectionEstimate.same.rawValue == 1)
    precondition(NINearbyObject.VerticalDirectionEstimate.above.rawValue == 2)
    precondition(NINearbyObject.VerticalDirectionEstimate.below.rawValue == 3)
    precondition(NINearbyObject.VerticalDirectionEstimate.aboveOrBelow.rawValue == 4)
    precondition(NINearbyObject.VerticalDirectionEstimate(rawValue: 0) == .unknown)
    precondition(NINearbyObject.VerticalDirectionEstimate(rawValue: 4) == .aboveOrBelow)
    precondition(NINearbyObject.VerticalDirectionEstimate(rawValue: 5) == nil)
    precondition(NINearbyObject.VerticalDirectionEstimate.above != .below)

    var hasherA = Hasher()
    var hasherB = Hasher()
    NINearbyObject.VerticalDirectionEstimate.same.hash(into: &hasherA)
    NINearbyObject.VerticalDirectionEstimate.same.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        NINearbyObject.VerticalDirectionEstimate.unknown.hashValue
            == NINearbyObject.VerticalDirectionEstimate.unknown.hashValue
    )
}
