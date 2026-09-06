import Foundation

/// An HVAC electrical load event. Session state is a value snapshot
/// (`begin` / `end` / `active`); this host does not drive HVAC hardware.
public struct ElectricHVACLoadEvent: ElectricalLoadEventProtocol, Codable, Identifiable, Sendable {
    public typealias ID = UUID

    public struct ElectricalMeasurement: Codable, Sendable {
        public let stage: Int

        public init(stage: Int) {
            self.stage = stage
        }
    }

    public struct Session: Codable, Sendable {
        public enum State: Codable, Equatable, Hashable, Sendable {
            case begin
            case end
            case active
        }

        public struct GuidanceState: Codable, Sendable {
            public let wasFollowingGuidance: Bool
            public var guidanceToken: UUID

            public init(wasFollowingGuidance: Bool, guidanceToken: UUID) {
                self.wasFollowingGuidance = wasFollowingGuidance
                self.guidanceToken = guidanceToken
            }
        }

        public let id: UUID
        public let state: ElectricHVACLoadEvent.Session.State
        public let guidanceState: ElectricHVACLoadEvent.Session.GuidanceState

        public init(
            id: UUID,
            state: ElectricHVACLoadEvent.Session.State,
            guidanceState: ElectricHVACLoadEvent.Session.GuidanceState
        ) {
            self.id = id
            self.state = state
            self.guidanceState = guidanceState
        }
    }

    public let id: UUID
    public let timestamp: Date
    public let measurement: ElectricHVACLoadEvent.ElectricalMeasurement
    public let session: ElectricHVACLoadEvent.Session
    public let deviceID: String

    public init(
        timestamp: Date,
        measurement: ElectricHVACLoadEvent.ElectricalMeasurement,
        session: ElectricHVACLoadEvent.Session,
        deviceID: String
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.measurement = measurement
        self.session = session
        self.deviceID = deviceID
    }
}

/// An electric-vehicle electrical load event. Charge, power, and energy are
/// stored measurements; this host does not talk to a vehicle or charger.
public struct ElectricVehicleLoadEvent: ElectricalLoadEventProtocol, Codable, Identifiable, Sendable {
    public typealias ID = UUID

    public struct ElectricalMeasurement: Codable, Sendable {
        public let stateOfCharge: Int
        public let direction: ElectricityFlowDirection
        public let power: Measurement<UnitPower>
        public let energy: Measurement<UnitEnergy>

        public init(
            stateOfCharge: Int,
            direction: ElectricityFlowDirection,
            power: Measurement<UnitPower>,
            energy: Measurement<UnitEnergy>
        ) {
            self.stateOfCharge = stateOfCharge
            self.direction = direction
            self.power = power
            self.energy = energy
        }
    }

    public struct Session: Codable, Sendable {
        public enum State: Codable, Equatable, Hashable, Sendable {
            case begin
            case end
            case active
        }

        public struct GuidanceState: Codable, Sendable {
            public let wasFollowingGuidance: Bool
            public var guidanceToken: UUID

            public init(wasFollowingGuidance: Bool, guidanceToken: UUID) {
                self.wasFollowingGuidance = wasFollowingGuidance
                self.guidanceToken = guidanceToken
            }
        }

        public let id: UUID
        public let state: ElectricVehicleLoadEvent.Session.State
        public let guidanceState: ElectricVehicleLoadEvent.Session.GuidanceState

        public init(
            id: UUID,
            state: ElectricVehicleLoadEvent.Session.State,
            guidanceState: ElectricVehicleLoadEvent.Session.GuidanceState
        ) {
            self.id = id
            self.state = state
            self.guidanceState = guidanceState
        }
    }

    public let id: UUID
    public let timestamp: Date
    public let measurement: ElectricVehicleLoadEvent.ElectricalMeasurement
    public let session: ElectricVehicleLoadEvent.Session
    public let deviceID: String

    public init(
        timestamp: Date,
        measurement: ElectricVehicleLoadEvent.ElectricalMeasurement,
        session: ElectricVehicleLoadEvent.Session,
        deviceID: String
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.measurement = measurement
        self.session = session
        self.deviceID = deviceID
    }
}
