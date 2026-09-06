import Foundation

/// A dock accessory (tracking stand). Linux has no hardware session: host
/// construction exists so value types can be tested, and every hardware
/// command fail-closes with `DockKitError.notSupported`.
public final class DockAccessory: @unchecked Sendable {
    public let identifier: Identifier

    public private(set) var framingMode: FramingMode
    public private(set) var regionOfInterest: CGRect
    public var hardwareModel: String? { nil }
    public var firmwareVersion: String? { nil }

    public var debugDescription: String {
        identifier.debugDescription
    }

    /// Linux host constructor. Apple's surface does not expose a public
    /// designated initializer; accessories arrive from hardware state
    /// changes. This initializer never claims a live dock connection.
    public init(identifier: Identifier) {
        self.identifier = identifier
        self.framingMode = .automatic
        self.regionOfInterest = .zero
    }

    public var accessoryEvents: AccessoryEvents {
        get throws { throw dockKitUnsupported() }
    }

    public var motionStates: MotionStates {
        get throws { throw dockKitUnsupported() }
    }

    public var batteryStates: BatteryStates {
        get throws { throw dockKitUnsupported() }
    }

    public var trackingStates: TrackingStates {
        get throws { throw dockKitUnsupported() }
    }

    public var limits: Limits {
        get throws { throw dockKitUnsupported() }
    }

    public func selectSubject(at unitPoint: CGPoint) async throws {
        throw dockKitUnsupported()
    }

    public func selectSubjects(_ ids: [UUID]) async throws {
        throw dockKitUnsupported()
    }

    public func setFramingMode(_ mode: FramingMode) async throws {
        throw dockKitUnsupported()
    }

    public func setOrientation(
        _ rotation: Vector3D,
        duration: Duration = .seconds(0),
        relative: Bool = false
    ) throws -> Progress {
        throw dockKitUnsupported()
    }

    public func setOrientation(
        _ rotation: Vector3D,
        duration: Duration = .seconds(0),
        relative: Bool = false
    ) async throws -> Progress {
        throw dockKitUnsupported()
    }

    public func setOrientation(
        _ rotation: Rotation3D,
        duration: Duration = .seconds(0),
        relative: Bool = false
    ) throws -> Progress {
        throw dockKitUnsupported()
    }

    public func setOrientation(
        _ rotation: Rotation3D,
        duration: Duration = .seconds(0),
        relative: Bool = false
    ) async throws -> Progress {
        throw dockKitUnsupported()
    }

    public func setAngularVelocity(_ angularVelocity: Vector3D) async throws {
        throw dockKitUnsupported()
    }

    public func setRegionOfInterest(_ region: CGRect) async throws {
        throw dockKitUnsupported()
    }

    public func track(
        _ data: [Observation],
        cameraInformation: CameraInformation,
        image: CVPixelBuffer
    ) async throws {
        throw dockKitUnsupported()
    }

    public func track(
        _ metadata: [AVMetadataObject],
        cameraInformation: CameraInformation,
        image: CVPixelBuffer
    ) async throws {
        throw dockKitUnsupported()
    }

    public func track(
        _ data: [Observation],
        cameraInformation: CameraInformation
    ) async throws {
        throw dockKitUnsupported()
    }

    public func track(
        _ metadata: [AVMetadataObject],
        cameraInformation: CameraInformation
    ) async throws {
        throw dockKitUnsupported()
    }

    public func animate(motion: Animation) async throws -> Progress {
        throw dockKitUnsupported()
    }

    public func setLimits(_ limits: Limits) throws {
        throw dockKitUnsupported()
    }

    public static func == (lhs: DockAccessory, rhs: DockAccessory) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension DockAccessory: Equatable {}
extension DockAccessory: Hashable {}
extension DockAccessory: CustomDebugStringConvertible {}

// MARK: - Identifier

extension DockAccessory {
    public struct Identifier: Equatable, Hashable, Sendable, CustomDebugStringConvertible {
        public let name: String
        public let uuid: UUID
        public let category: Category

        public init(name: String, uuid: UUID, category: Category) {
            self.name = name
            self.uuid = uuid
            self.category = category
        }

        public var debugDescription: String {
            "\(name) (\(uuid.uuidString)) \(category)"
        }
    }
}

// MARK: - Category

extension DockAccessory {
    public enum Category: Codable, Equatable, Hashable, Sendable, CustomDebugStringConvertible {
        case trackingStand

        public var debugDescription: String { "trackingStand" }
    }
}

// MARK: - State

extension DockAccessory {
    public enum State: Equatable, Hashable, Sendable, CustomDebugStringConvertible {
        case undocked
        case docked

        public var debugDescription: String {
            switch self {
            case .undocked: return "undocked"
            case .docked: return "docked"
            }
        }
    }
}

// MARK: - Framing

extension DockAccessory {
    public enum FramingMode: Codable, Equatable, Hashable, Sendable {
        case automatic
        case center
        case left
        case right
    }
}

// MARK: - Animation

extension DockAccessory {
    public enum Animation: Equatable, Hashable, Sendable {
        case wakeup
        case yes
        case no
        case kapow
    }
}

// MARK: - Accessory events

extension DockAccessory {
    public enum AccessoryEvent: Equatable, Hashable, Sendable {
        case button(id: Int, pressed: Bool)
        case cameraShutter
        case cameraFlip
        case cameraZoom(factor: Double)
    }

    /// Empty hardware event stream. Hardware never emits on Linux.
    public struct AccessoryEvents: AsyncSequence {
        public typealias Element = AccessoryEvent
        public typealias AsyncIterator = Iterator

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = AccessoryEvent

            public init() {}

            public mutating func next() async -> AccessoryEvent? {
                nil
            }
        }
    }
}

// MARK: - State changes

extension DockAccessory {
    public struct StateChange: Sendable {
        public let trackingButtonEnabled: Bool
        public let state: State
        public let accessory: DockAccessory?

        public init(
            trackingButtonEnabled: Bool,
            state: State,
            accessory: DockAccessory?
        ) {
            self.trackingButtonEnabled = trackingButtonEnabled
            self.state = state
            self.accessory = accessory
        }
    }

    public struct StateChanges: AsyncSequence {
        public typealias Element = StateChange
        public typealias AsyncIterator = Iterator

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = StateChange

            public init() {}

            public mutating func next() async -> StateChange? {
                nil
            }
        }
    }
}

// MARK: - Motion

extension DockAccessory {
    public struct MotionState: Sendable {
        public let angularPositions: Vector3D
        public let angularVelocities: Vector3D
        public let error: (any Error)?
        public let timestamp: TimeInterval

        public init(
            angularPositions: Vector3D,
            angularVelocities: Vector3D,
            error: (any Error)?,
            timestamp: TimeInterval
        ) {
            self.angularPositions = angularPositions
            self.angularVelocities = angularVelocities
            self.error = error
            self.timestamp = timestamp
        }
    }

    public struct MotionStates: AsyncSequence {
        public typealias Element = MotionState
        public typealias AsyncIterator = Iterator

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = MotionState

            public init() {}

            public mutating func next() async -> MotionState? {
                nil
            }
        }
    }
}

// MARK: - Battery

extension DockAccessory {
    public enum BatteryChargeState: Equatable, Hashable, Sendable {
        case notCharging
        case charging
        case notChargeable
    }

    public struct BatteryState: Equatable, Hashable, Sendable {
        public let lowBattery: Bool
        public let chargeState: BatteryChargeState
        public let batteryLevel: Double
        public let name: String

        public init(
            name: String,
            batteryLevel: Double,
            chargeState: BatteryChargeState,
            lowBattery: Bool
        ) {
            self.name = name
            self.batteryLevel = batteryLevel
            self.chargeState = chargeState
            self.lowBattery = lowBattery
        }
    }

    public struct BatteryStates: AsyncSequence {
        public typealias Element = BatteryState
        public typealias AsyncIterator = Iterator

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = BatteryState

            public init() {}

            public mutating func next() async -> BatteryState? {
                nil
            }
        }
    }
}

// MARK: - Observation / camera

extension DockAccessory {
    public enum CameraOrientation: Equatable, Hashable, Sendable {
        case unknown
        case portrait
        case portraitUpsideDown
        case landscapeRight
        case landscapeLeft
        case faceUp
        case faceDown
        case corrected
    }

    public struct CameraInformation: Sendable {
        public let captureDevice: AVCaptureDevice.DeviceType
        public let cameraPosition: AVCaptureDevice.Position
        public let orientation: CameraOrientation
        public let cameraIntrinsics: matrix_float3x3?
        public let referenceDimensions: CGSize?

        public init(
            captureDevice: AVCaptureDevice.DeviceType,
            cameraPosition: AVCaptureDevice.Position,
            orientation: CameraOrientation,
            cameraIntrinsics: matrix_float3x3?,
            referenceDimensions: CGSize?
        ) {
            self.captureDevice = captureDevice
            self.cameraPosition = cameraPosition
            self.orientation = orientation
            self.cameraIntrinsics = cameraIntrinsics
            self.referenceDimensions = referenceDimensions
        }
    }

    public struct Observation: Sendable {
        public enum ObservationType: Equatable, Hashable, Sendable {
            case humanFace
            case humanBody
            case object
        }

        public let identifier: Int
        public let type: ObservationType
        public let rect: CGRect
        public let faceYawAngle: Measurement<UnitAngle>?

        public init(
            identifier: Int,
            type: ObservationType,
            rect: CGRect,
            faceYawAngle: Measurement<UnitAngle>? = nil
        ) {
            self.identifier = identifier
            self.type = type
            self.rect = rect
            self.faceYawAngle = faceYawAngle
        }
    }
}

// MARK: - Tracking

extension DockAccessory {
    public struct TrackedObject: Equatable, Sendable {
        public var identifier: UUID
        public var saliencyRank: Int?
        public var rect: CGRect

        public init(identifier: UUID, saliencyRank: Int? = nil, rect: CGRect) {
            self.identifier = identifier
            self.saliencyRank = saliencyRank
            self.rect = rect
        }
    }

    public struct TrackedPerson: Equatable, Sendable {
        public var identifier: UUID
        public var saliencyRank: Int?
        public var speakingConfidence: Double?
        public var lookingAtCameraConfidence: Double?
        public var rect: CGRect

        public init(
            identifier: UUID,
            saliencyRank: Int? = nil,
            speakingConfidence: Double? = nil,
            lookingAtCameraConfidence: Double? = nil,
            rect: CGRect
        ) {
            self.identifier = identifier
            self.saliencyRank = saliencyRank
            self.speakingConfidence = speakingConfidence
            self.lookingAtCameraConfidence = lookingAtCameraConfidence
            self.rect = rect
        }
    }

    public enum TrackedSubjectType: Equatable, Sendable {
        case person(TrackedPerson)
        case object(TrackedObject)
    }

    public struct TrackingState: Sendable {
        public var trackedSubjects: [TrackedSubjectType]
        public var time: Date

        public init(trackedSubjects: [TrackedSubjectType], time: Date) {
            self.trackedSubjects = trackedSubjects
            self.time = time
        }

        public var description: String {
            "TrackingState(subjects: \(trackedSubjects.count), time: \(time.timeIntervalSince1970))"
        }
    }

    public struct TrackingStates: AsyncSequence {
        public typealias Element = TrackingState
        public typealias AsyncIterator = Iterator

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = TrackingState

            public init() {}

            public mutating func next() async -> TrackingState? {
                nil
            }
        }
    }
}

// MARK: - Limits

extension DockAccessory {
    public struct Limits: Sendable {
        public let yaw: Limit?
        public let pitch: Limit?
        public let roll: Limit?

        public init(yaw: Limit?, pitch: Limit?, roll: Limit?) {
            self.yaw = yaw
            self.pitch = pitch
            self.roll = roll
        }

        public struct Limit: Sendable {
            public let positionRange: Range<Double>
            public let maximumSpeed: Double

            /// Throws `DockKitError.invalidParameter` for non-finite values,
            /// negative speeds, or an empty position range. Apple's exact
            /// acceptance bounds are unobserved.
            public init(positionRange: Range<Double>, maximumSpeed: Double) throws {
                guard
                    positionRange.lowerBound.isFinite,
                    positionRange.upperBound.isFinite,
                    !positionRange.isEmpty,
                    maximumSpeed.isFinite,
                    maximumSpeed >= 0
                else {
                    throw dockKitInvalidParameter()
                }
                self.positionRange = positionRange
                self.maximumSpeed = maximumSpeed
            }
        }
    }
}
