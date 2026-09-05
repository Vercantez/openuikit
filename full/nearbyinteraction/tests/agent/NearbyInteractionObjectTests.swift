@_spi(OpenUIKitHost) import NearbyInteraction
import Foundation

func testNINearbyObjectProperties() {
    let token = NIDiscoveryToken.hostToken()
    let direction = simd_float3(0, 1, 0)
    let object = NINearbyObject.hostObject(
        discoveryToken: token,
        distance: 2.5,
        direction: direction,
        horizontalAngle: 0.25,
        verticalDirectionEstimate: .above
    )
    precondition(object.discoveryToken.isEqual(token))
    precondition(object.distance == 2.5)
    precondition(object.direction == direction)
    precondition(object.horizontalAngle == 0.25)
    precondition(object.verticalDirectionEstimate == .above)

    let empty = NINearbyObject.hostObject(discoveryToken: token)
    precondition(empty.distance == nil)
    precondition(empty.direction == nil)
    precondition(empty.horizontalAngle == nil)
    precondition(empty.verticalDirectionEstimate == .unknown)

    let copy = object.copy() as! NINearbyObject
    precondition(copy !== object)
    precondition(copy.distance == 2.5)
    precondition(copy.verticalDirectionEstimate == .above)
}

func testNIDLTDOAMeasurementProperties() {
    let coordinates = simd_double3(1.0, 2.0, 3.0)
    let measurement = NIDLTDOAMeasurement.hostMeasurement(
        address: 17,
        measurementType: .response,
        transmitTime: 1.5,
        receiveTime: 1.75,
        signalStrength: -42.0,
        carrierFrequencyOffset: 0.125,
        coordinatesType: .geodetic,
        coordinates: coordinates
    )
    precondition(measurement.address == 17)
    precondition(measurement.measurementType == .response)
    precondition(measurement.transmitTime == 1.5)
    precondition(measurement.receiveTime == 1.75)
    precondition(measurement.signalStrength == -42.0)
    precondition(measurement.carrierFrequencyOffset == 0.125)
    precondition(measurement.coordinatesType == .geodetic)
    precondition(measurement.coordinates == coordinates)

    let copy = measurement.copy() as! NIDLTDOAMeasurement
    precondition(copy !== measurement)
    precondition(copy.address == 17)
    precondition(copy.measurementType == .response)
    precondition(copy.coordinates == coordinates)
}

func testSimdFloat4x4Identity() {
    let identity = simd_float4x4.identity
    precondition(identity.columns.0 == SIMD4<Float>(1, 0, 0, 0))
    precondition(identity.columns.3 == SIMD4<Float>(0, 0, 0, 1))
    precondition(identity == simd_float4x4.identity)
}
