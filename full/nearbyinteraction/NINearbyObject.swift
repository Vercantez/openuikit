import Foundation

public class NINearbyObject: NSObject, NSCopying, NSSecureCoding {
    public enum RemovalReason: Int, Equatable, Hashable, Sendable {
        case timeout = 0
        case peerEnded = 1
    }

    public enum VerticalDirectionEstimate: Int, Equatable, Hashable, Sendable {
        case unknown = 0
        case same = 1
        case above = 2
        case below = 3
        case aboveOrBelow = 4
    }

    public let discoveryToken: NIDiscoveryToken
    public let distance: Float?
    public let direction: simd_float3?
    public let horizontalAngle: Float?
    public let verticalDirectionEstimate: VerticalDirectionEstimate

    public static var supportsSecureCoding: Bool { true }

    internal init(
        discoveryToken: NIDiscoveryToken,
        distance: Float?,
        direction: simd_float3?,
        horizontalAngle: Float?,
        verticalDirectionEstimate: VerticalDirectionEstimate
    ) {
        self.discoveryToken = (discoveryToken.copy() as? NIDiscoveryToken) ?? discoveryToken
        self.distance = distance
        self.direction = direction
        self.horizontalAngle = horizontalAngle
        self.verticalDirectionEstimate = verticalDirectionEstimate
        super.init()
    }

    @_spi(OpenUIKitHost)
    public static func hostObject(
        discoveryToken: NIDiscoveryToken,
        distance: Float? = nil,
        direction: simd_float3? = nil,
        horizontalAngle: Float? = nil,
        verticalDirectionEstimate: VerticalDirectionEstimate = .unknown
    ) -> NINearbyObject {
        NINearbyObject(
            discoveryToken: discoveryToken,
            distance: distance,
            direction: direction,
            horizontalAngle: horizontalAngle,
            verticalDirectionEstimate: verticalDirectionEstimate
        )
    }

    public required init?(coder: NSCoder) {
        guard let token = coder.decodeObject(of: NIDiscoveryToken.self, forKey: "discoveryToken") else {
            return nil
        }
        self.discoveryToken = token
        if coder.containsValue(forKey: "distance") {
            self.distance = Float(coder.decodeFloat(forKey: "distance"))
        } else {
            self.distance = nil
        }
        if coder.containsValue(forKey: "directionX") {
            self.direction = simd_float3(
                coder.decodeFloat(forKey: "directionX"),
                coder.decodeFloat(forKey: "directionY"),
                coder.decodeFloat(forKey: "directionZ")
            )
        } else {
            self.direction = nil
        }
        if coder.containsValue(forKey: "horizontalAngle") {
            self.horizontalAngle = coder.decodeFloat(forKey: "horizontalAngle")
        } else {
            self.horizontalAngle = nil
        }
        self.verticalDirectionEstimate =
            VerticalDirectionEstimate(rawValue: coder.decodeInteger(forKey: "verticalDirectionEstimate"))
            ?? .unknown
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(discoveryToken, forKey: "discoveryToken")
        if let distance {
            coder.encode(distance, forKey: "distance")
        }
        if let direction {
            coder.encode(direction.x, forKey: "directionX")
            coder.encode(direction.y, forKey: "directionY")
            coder.encode(direction.z, forKey: "directionZ")
        }
        if let horizontalAngle {
            coder.encode(horizontalAngle, forKey: "horizontalAngle")
        }
        coder.encode(verticalDirectionEstimate.rawValue, forKey: "verticalDirectionEstimate")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        NINearbyObject(
            discoveryToken: discoveryToken,
            distance: distance,
            direction: direction,
            horizontalAngle: horizontalAngle,
            verticalDirectionEstimate: verticalDirectionEstimate
        )
    }
}

public class NIDLTDOAMeasurement: NSObject, NSCopying, NSSecureCoding {
    public let address: Int
    public let measurementType: NIDLTDOAMeasurementType
    public let transmitTime: Double
    public let receiveTime: Double
    public let signalStrength: Double
    public let carrierFrequencyOffset: Double
    public let coordinatesType: NIDLTDOACoordinatesType
    public let coordinates: simd_double3

    public static var supportsSecureCoding: Bool { true }

    internal init(
        address: Int,
        measurementType: NIDLTDOAMeasurementType,
        transmitTime: Double,
        receiveTime: Double,
        signalStrength: Double,
        carrierFrequencyOffset: Double,
        coordinatesType: NIDLTDOACoordinatesType,
        coordinates: simd_double3
    ) {
        self.address = address
        self.measurementType = measurementType
        self.transmitTime = transmitTime
        self.receiveTime = receiveTime
        self.signalStrength = signalStrength
        self.carrierFrequencyOffset = carrierFrequencyOffset
        self.coordinatesType = coordinatesType
        self.coordinates = coordinates
        super.init()
    }

    @_spi(OpenUIKitHost)
    public static func hostMeasurement(
        address: Int,
        measurementType: NIDLTDOAMeasurementType,
        transmitTime: Double,
        receiveTime: Double,
        signalStrength: Double,
        carrierFrequencyOffset: Double,
        coordinatesType: NIDLTDOACoordinatesType,
        coordinates: simd_double3
    ) -> NIDLTDOAMeasurement {
        NIDLTDOAMeasurement(
            address: address,
            measurementType: measurementType,
            transmitTime: transmitTime,
            receiveTime: receiveTime,
            signalStrength: signalStrength,
            carrierFrequencyOffset: carrierFrequencyOffset,
            coordinatesType: coordinatesType,
            coordinates: coordinates
        )
    }

    public required init?(coder: NSCoder) {
        self.address = coder.decodeInteger(forKey: "address")
        guard let measurementType = NIDLTDOAMeasurementType(rawValue: coder.decodeInteger(forKey: "measurementType")),
              let coordinatesType = NIDLTDOACoordinatesType(rawValue: coder.decodeInteger(forKey: "coordinatesType"))
        else {
            return nil
        }
        self.measurementType = measurementType
        self.transmitTime = coder.decodeDouble(forKey: "transmitTime")
        self.receiveTime = coder.decodeDouble(forKey: "receiveTime")
        self.signalStrength = coder.decodeDouble(forKey: "signalStrength")
        self.carrierFrequencyOffset = coder.decodeDouble(forKey: "carrierFrequencyOffset")
        self.coordinatesType = coordinatesType
        self.coordinates = simd_double3(
            coder.decodeDouble(forKey: "coordinateX"),
            coder.decodeDouble(forKey: "coordinateY"),
            coder.decodeDouble(forKey: "coordinateZ")
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(address, forKey: "address")
        coder.encode(measurementType.rawValue, forKey: "measurementType")
        coder.encode(transmitTime, forKey: "transmitTime")
        coder.encode(receiveTime, forKey: "receiveTime")
        coder.encode(signalStrength, forKey: "signalStrength")
        coder.encode(carrierFrequencyOffset, forKey: "carrierFrequencyOffset")
        coder.encode(coordinatesType.rawValue, forKey: "coordinatesType")
        coder.encode(coordinates.x, forKey: "coordinateX")
        coder.encode(coordinates.y, forKey: "coordinateY")
        coder.encode(coordinates.z, forKey: "coordinateZ")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        NIDLTDOAMeasurement(
            address: address,
            measurementType: measurementType,
            transmitTime: transmitTime,
            receiveTime: receiveTime,
            signalStrength: signalStrength,
            carrierFrequencyOffset: carrierFrequencyOffset,
            coordinatesType: coordinatesType,
            coordinates: coordinates
        )
    }
}
