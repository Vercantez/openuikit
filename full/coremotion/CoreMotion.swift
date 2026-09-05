@_exported import Foundation

// MARK: - CoreLocation numeric aliases
//
// Isolated CoreMotion compiles against Foundation only. These names match the
// graph's CMOdometerData property types. They are local Double aliases, not a
// CoreLocation import and not Apple location services.

public typealias CLLocationDistance = Double
public typealias CLLocationAccuracy = Double
public typealias CLLocationSpeed = Double
public typealias CLLocationSpeedAccuracy = Double

// MARK: - Error domain
//
// The Darwin string payload is an Apple-oracle question. Linux uses the public
// identifier spelling as a source-compatible fallback and never claims the
// bytes were measured on device.

public let CMErrorDomain = "CMErrorDomain"

/// Bridged `NS_ERROR_ENUM` overlay. Named-constant raw values follow the
/// public `CMError.h` C enumeration (`CMErrorNULL = 100`, then sequential
/// members in header order). `CMErrorNilData` and `CMErrorSize` were appended
/// after `CMErrorNotAuthorized`.
public struct CMError: RawRepresentable, Hashable, Equatable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var CMErrorNULL: CMError { CMError(100) }
public var CMErrorDeviceRequiresMovement: CMError { CMError(101) }
public var CMErrorTrueNorthNotAvailable: CMError { CMError(102) }
public var CMErrorUnknown: CMError { CMError(103) }
public var CMErrorMotionActivityNotAvailable: CMError { CMError(104) }
public var CMErrorMotionActivityNotAuthorized: CMError { CMError(105) }
public var CMErrorMotionActivityNotEntitled: CMError { CMError(106) }
public var CMErrorInvalidParameter: CMError { CMError(107) }
public var CMErrorInvalidAction: CMError { CMError(108) }
public var CMErrorNotAvailable: CMError { CMError(109) }
public var CMErrorNotEntitled: CMError { CMError(110) }
public var CMErrorNotAuthorized: CMError { CMError(111) }
public var CMErrorNilData: CMError { CMError(112) }
public var CMErrorSize: CMError { CMError(113) }

func coreMotionUnavailableError() -> NSError {
    NSError(
        domain: CMErrorDomain,
        code: Int(CMErrorNotAvailable.rawValue),
        userInfo: [
            NSLocalizedDescriptionKey: "CoreMotion hardware is unavailable on this Linux host"
        ]
    )
}

// MARK: - Public enums
//
// Raw values follow common public-header order. Tests exercise
// constructibility, inequality, hashing, and round-trip.

public enum CMAuthorizationStatus: Int, Sendable, Hashable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
}

public enum CMMagneticFieldCalibrationAccuracy: Int32, Sendable, Hashable {
    case uncalibrated = -1
    case low = 0
    case medium = 1
    case high = 2
}

public enum CMMotionActivityConfidence: Int, Sendable, Hashable {
    case low = 0
    case medium = 1
    case high = 2
}

public enum CMPedometerEventType: Int, Sendable, Hashable {
    case pause = 0
    case resume = 1
}

public enum CMOdometerOriginDevice: Int, Sendable, Hashable {
    case unknown = 0
    case local = 1
    case remote = 2
}

public enum CMHighFrequencyHeartRateDataConfidence: Int, Sendable, Hashable {
    case low = 0
    case medium = 1
    case high = 2
    case highest = 3
}

/// Option set whose bit layout follows the public header (`1 << 0` … `1 << 3`).
/// SetAlgebra behavior is real.
public struct CMAttitudeReferenceFrame: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let xArbitraryZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 0)
    public static let xArbitraryCorrectedZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 1)
    public static let xMagneticNorthZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 2)
    public static let xTrueNorthZVertical = CMAttitudeReferenceFrame(rawValue: 1 << 3)
}

// MARK: - Handlers

public typealias CMAccelerometerHandler = (CMAccelerometerData?, (any Error)?) -> Void
public typealias CMGyroHandler = (CMGyroData?, (any Error)?) -> Void
public typealias CMMagnetometerHandler = (CMMagnetometerData?, (any Error)?) -> Void
public typealias CMDeviceMotionHandler = (CMDeviceMotion?, (any Error)?) -> Void
public typealias CMAltitudeHandler = (CMAltitudeData?, (any Error)?) -> Void
public typealias CMAbsoluteAltitudeHandler = (CMAbsoluteAltitudeData?, (any Error)?) -> Void
public typealias CMMotionActivityHandler = (CMMotionActivity?) -> Void
public typealias CMMotionActivityQueryHandler = ([CMMotionActivity]?, (any Error)?) -> Void
public typealias CMPedometerHandler = (CMPedometerData?, (any Error)?) -> Void
public typealias CMPedometerEventHandler = (CMPedometerEvent?, (any Error)?) -> Void
public typealias CMStepQueryHandler = (Int, (any Error)?) -> Void
public typealias CMStepUpdateHandler = (Int, Date, (any Error)?) -> Void

// MARK: - Completion delivery
//
// Fail-closed callbacks hop once onto the caller-supplied `OperationQueue`
// (or a private serial queue when the API has no queue). Delivery is never
// inline on the caller stack. Nested `async` work is queued behind a running
// handler.

private struct CoreMotionUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

final class CoreMotionOnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var delivered = false

    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if delivered {
            return false
        }
        delivered = true
        return true
    }
}

let coreMotionPrivateQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "CoreMotion.completion"
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

/// Linux host-test control. Hidden from ordinary `import CoreMotion` clients.
@_spi(OpenUIKitHost)
public enum CoreMotionHostControl {
    public static var completionQueue: OperationQueue { coreMotionPrivateQueue }

    public static func enqueueCompletionProbe(_ body: @escaping () -> Void) {
        let work = CoreMotionUncheckedWork(body: body)
        coreMotionPrivateQueue.addOperation {
            work.body()
        }
    }

    public static func enqueueCompletionProbe(
        on queue: OperationQueue,
        _ body: @escaping () -> Void
    ) {
        let work = CoreMotionUncheckedWork(body: body)
        queue.addOperation {
            work.body()
        }
    }

    public static func makeLogItem(timestamp: TimeInterval) -> CMLogItem {
        CMLogItem(timestamp: timestamp)
    }

    public static func makeAccelerometerData(
        timestamp: TimeInterval,
        acceleration: CMAcceleration
    ) -> CMAccelerometerData {
        CMAccelerometerData(timestamp: timestamp, acceleration: acceleration)
    }

    public static func makeGyroData(
        timestamp: TimeInterval,
        rotationRate: CMRotationRate
    ) -> CMGyroData {
        CMGyroData(timestamp: timestamp, rotationRate: rotationRate)
    }

    public static func makeMagnetometerData(
        timestamp: TimeInterval,
        magneticField: CMMagneticField
    ) -> CMMagnetometerData {
        CMMagnetometerData(timestamp: timestamp, magneticField: magneticField)
    }

    public static func makeAttitude(quaternion: CMQuaternion) -> CMAttitude {
        CMAttitude(quaternion: quaternion)
    }

    public static func makeDeviceMotion(
        timestamp: TimeInterval,
        attitude: CMAttitude,
        rotationRate: CMRotationRate,
        gravity: CMAcceleration,
        userAcceleration: CMAcceleration,
        magneticField: CMCalibratedMagneticField,
        heading: Double,
        sensorLocation: CMDeviceMotion.SensorLocation
    ) -> CMDeviceMotion {
        CMDeviceMotion(
            timestamp: timestamp,
            attitude: attitude,
            rotationRate: rotationRate,
            gravity: gravity,
            userAcceleration: userAcceleration,
            magneticField: magneticField,
            heading: heading,
            sensorLocation: sensorLocation
        )
    }

    public static func makeAltitudeData(
        timestamp: TimeInterval,
        relativeAltitude: Double,
        pressure: Double
    ) -> CMAltitudeData {
        CMAltitudeData(
            timestamp: timestamp,
            relativeAltitude: NSNumber(value: relativeAltitude),
            pressure: NSNumber(value: pressure)
        )
    }

    public static func makeAbsoluteAltitudeData(
        timestamp: TimeInterval,
        altitude: Double,
        accuracy: Double,
        precision: Double
    ) -> CMAbsoluteAltitudeData {
        CMAbsoluteAltitudeData(
            timestamp: timestamp,
            altitude: altitude,
            accuracy: accuracy,
            precision: precision
        )
    }

    public static func makeAmbientPressureData(
        timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>
    ) -> CMAmbientPressureData {
        CMAmbientPressureData(
            timestamp: timestamp,
            pressure: pressure,
            temperature: temperature
        )
    }

    public static func makeMotionActivity(
        startDate: Date,
        confidence: CMMotionActivityConfidence,
        unknown: Bool,
        stationary: Bool,
        walking: Bool,
        running: Bool,
        automotive: Bool,
        cycling: Bool
    ) -> CMMotionActivity {
        CMMotionActivity(
            startDate: startDate,
            confidence: confidence,
            unknown: unknown,
            stationary: stationary,
            walking: walking,
            running: running,
            automotive: automotive,
            cycling: cycling
        )
    }

    public static func makePedometerData(
        startDate: Date,
        endDate: Date,
        numberOfSteps: Int,
        distance: Double?,
        floorsAscended: Int?,
        floorsDescended: Int?,
        currentPace: Double?,
        currentCadence: Double?,
        averageActivePace: Double?
    ) -> CMPedometerData {
        CMPedometerData(
            startDate: startDate,
            endDate: endDate,
            numberOfSteps: NSNumber(value: numberOfSteps),
            distance: distance.map(NSNumber.init(value:)),
            floorsAscended: floorsAscended.map(NSNumber.init(value:)),
            floorsDescended: floorsDescended.map(NSNumber.init(value:)),
            currentPace: currentPace.map(NSNumber.init(value:)),
            currentCadence: currentCadence.map(NSNumber.init(value:)),
            averageActivePace: averageActivePace.map(NSNumber.init(value:))
        )
    }

    public static func makePedometerEvent(
        date: Date,
        type: CMPedometerEventType
    ) -> CMPedometerEvent {
        CMPedometerEvent(date: date, type: type)
    }

    public static func makeRecordedAccelerometerData(
        timestamp: TimeInterval,
        acceleration: CMAcceleration,
        identifier: UInt64,
        startDate: Date
    ) -> CMRecordedAccelerometerData {
        CMRecordedAccelerometerData(
            timestamp: timestamp,
            acceleration: acceleration,
            identifier: identifier,
            startDate: startDate
        )
    }

    public static func makeRecordedRotationRateData(
        timestamp: TimeInterval,
        rotationRate: CMRotationRate,
        startDate: Date
    ) -> CMRecordedRotationRateData {
        CMRecordedRotationRateData(
            timestamp: timestamp,
            rotationRate: rotationRate,
            startDate: startDate
        )
    }

    public static func makeRecordedPressureData(
        timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>,
        identifier: UInt64,
        startDate: Date
    ) -> CMRecordedPressureData {
        CMRecordedPressureData(
            timestamp: timestamp,
            pressure: pressure,
            temperature: temperature,
            identifier: identifier,
            startDate: startDate
        )
    }

    public static func makeOdometerData(
        startDate: Date,
        endDate: Date,
        deltaDistance: CLLocationDistance,
        deltaDistanceAccuracy: CLLocationAccuracy,
        speed: CLLocationSpeed,
        speedAccuracy: CLLocationSpeedAccuracy,
        deltaAltitude: CLLocationDistance,
        verticalAccuracy: CLLocationAccuracy,
        originDevice: CMOdometerOriginDevice,
        gpsDate: Date,
        slope: Double?,
        maxAbsSlope: Double?
    ) -> CMOdometerData {
        CMOdometerData(
            startDate: startDate,
            endDate: endDate,
            deltaDistance: deltaDistance,
            deltaDistanceAccuracy: deltaDistanceAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            deltaAltitude: deltaAltitude,
            verticalAccuracy: verticalAccuracy,
            originDevice: originDevice,
            gpsDate: gpsDate,
            slope: slope,
            maxAbsSlope: maxAbsSlope
        )
    }

    public static func makeDyskineticSymptomResult(
        startDate: Date,
        endDate: Date,
        percentLikely: Float,
        percentUnlikely: Float
    ) -> CMDyskineticSymptomResult {
        CMDyskineticSymptomResult(
            startDate: startDate,
            endDate: endDate,
            percentLikely: percentLikely,
            percentUnlikely: percentUnlikely
        )
    }

    public static func makeTremorResult(
        startDate: Date,
        endDate: Date,
        percentUnknown: Float,
        percentNone: Float,
        percentSlight: Float,
        percentMild: Float,
        percentModerate: Float,
        percentStrong: Float
    ) -> CMTremorResult {
        CMTremorResult(
            startDate: startDate,
            endDate: endDate,
            percentUnknown: percentUnknown,
            percentNone: percentNone,
            percentSlight: percentSlight,
            percentMild: percentMild,
            percentModerate: percentModerate,
            percentStrong: percentStrong
        )
    }

    public static func makeHeartRateData(
        timestamp: TimeInterval,
        heartRate: Double,
        confidence: CMHighFrequencyHeartRateDataConfidence,
        date: Date?
    ) -> CMHighFrequencyHeartRateData {
        CMHighFrequencyHeartRateData(
            timestamp: timestamp,
            heartRate: heartRate,
            confidence: confidence,
            date: date
        )
    }

    public static func makeWaterSubmersionEvent(
        date: Date,
        state: CMWaterSubmersionEvent.State
    ) -> CMWaterSubmersionEvent {
        CMWaterSubmersionEvent(date: date, state: state)
    }

    public static func makeWaterSubmersionMeasurement(
        date: Date,
        depth: Measurement<UnitLength>?,
        pressure: Measurement<UnitPressure>?,
        surfacePressure: Measurement<UnitPressure>,
        submersionState: CMWaterSubmersionMeasurement.DepthState
    ) -> CMWaterSubmersionMeasurement {
        CMWaterSubmersionMeasurement(
            date: date,
            depth: depth,
            pressure: pressure,
            surfacePressure: surfacePressure,
            submersionState: submersionState
        )
    }

    public static func makeWaterTemperature(
        date: Date,
        temperature: Measurement<UnitTemperature>,
        temperatureUncertainty: Measurement<UnitTemperature>
    ) -> CMWaterTemperature {
        CMWaterTemperature(
            date: date,
            temperature: temperature,
            temperatureUncertainty: temperatureUncertainty
        )
    }

    public static func makeSensorDataList(
        items: [CMRecordedAccelerometerData]
    ) -> CMSensorDataList {
        CMSensorDataList(items: items)
    }
}

func coreMotionDeliver(on queue: OperationQueue, _ body: @escaping () -> Void) {
    let once = CoreMotionOnceFlag()
    let work = CoreMotionUncheckedWork(body: body)
    queue.addOperation {
        guard once.take() else { return }
        work.body()
    }
}

func coreMotionDeliverPrivate(_ body: @escaping () -> Void) {
    coreMotionDeliver(on: coreMotionPrivateQueue, body)
}

enum CoreMotionArchive {
    static let markerKey = "OpenUIKit.CoreMotion.archive"

    static func encodeMarker(_ coder: NSCoder) {
        coder.encode(true, forKey: markerKey)
    }

    static func hasMarker(_ coder: NSCoder) -> Bool {
        coder.containsValue(forKey: markerKey) && coder.decodeBool(forKey: markerKey)
    }
}
