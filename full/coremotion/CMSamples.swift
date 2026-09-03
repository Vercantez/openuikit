import Foundation

public class CMLogItem: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public let timestamp: TimeInterval

    public override init() {
        timestamp = 0
        super.init()
    }

    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        timestamp = coder.decodeDouble(forKey: "timestamp")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(timestamp, forKey: "timestamp")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMLogItem(timestamp: timestamp)
    }
}

public class CMAccelerometerData: CMLogItem {
    public let acceleration: CMAcceleration

    public override init() {
        acceleration = CMAcceleration()
        super.init()
    }

    init(timestamp: TimeInterval, acceleration: CMAcceleration) {
        self.acceleration = acceleration
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        acceleration = CMAcceleration(
            x: coder.decodeDouble(forKey: "ax"),
            y: coder.decodeDouble(forKey: "ay"),
            z: coder.decodeDouble(forKey: "az")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(acceleration.x, forKey: "ax")
        coder.encode(acceleration.y, forKey: "ay")
        coder.encode(acceleration.z, forKey: "az")
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        CMAccelerometerData(timestamp: timestamp, acceleration: acceleration)
    }
}

public class CMGyroData: CMLogItem {
    public let rotationRate: CMRotationRate

    public override init() {
        rotationRate = CMRotationRate()
        super.init()
    }

    init(timestamp: TimeInterval, rotationRate: CMRotationRate) {
        self.rotationRate = rotationRate
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        rotationRate = CMRotationRate(
            x: coder.decodeDouble(forKey: "gx"),
            y: coder.decodeDouble(forKey: "gy"),
            z: coder.decodeDouble(forKey: "gz")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(rotationRate.x, forKey: "gx")
        coder.encode(rotationRate.y, forKey: "gy")
        coder.encode(rotationRate.z, forKey: "gz")
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        CMGyroData(timestamp: timestamp, rotationRate: rotationRate)
    }
}

public class CMRotationRateData: CMLogItem {
    public let rotationRate: CMRotationRate

    public override init() {
        rotationRate = CMRotationRate()
        super.init()
    }

    init(timestamp: TimeInterval, rotationRate: CMRotationRate) {
        self.rotationRate = rotationRate
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        rotationRate = CMRotationRate(
            x: coder.decodeDouble(forKey: "rx"),
            y: coder.decodeDouble(forKey: "ry"),
            z: coder.decodeDouble(forKey: "rz")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(rotationRate.x, forKey: "rx")
        coder.encode(rotationRate.y, forKey: "ry")
        coder.encode(rotationRate.z, forKey: "rz")
    }
}

public class CMMagnetometerData: CMLogItem {
    public let magneticField: CMMagneticField

    public override init() {
        magneticField = CMMagneticField()
        super.init()
    }

    init(timestamp: TimeInterval, magneticField: CMMagneticField) {
        self.magneticField = magneticField
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        magneticField = CMMagneticField(
            x: coder.decodeDouble(forKey: "mx"),
            y: coder.decodeDouble(forKey: "my"),
            z: coder.decodeDouble(forKey: "mz")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(magneticField.x, forKey: "mx")
        coder.encode(magneticField.y, forKey: "my")
        coder.encode(magneticField.z, forKey: "mz")
    }
}

public class CMDeviceMotion: CMLogItem {
    public enum SensorLocation: Int, Sendable, Hashable {
        case `default` = 0
        case headphoneLeft = 1
        case headphoneRight = 2
    }

    public let attitude: CMAttitude
    public let rotationRate: CMRotationRate
    public let gravity: CMAcceleration
    public let userAcceleration: CMAcceleration
    public let magneticField: CMCalibratedMagneticField
    /// Linux invalid-heading fallback is `-1`. Darwin's sentinel is unobserved.
    public let heading: Double
    public let sensorLocation: SensorLocation

    public override init() {
        attitude = CMAttitude()
        rotationRate = CMRotationRate()
        gravity = CMAcceleration()
        userAcceleration = CMAcceleration()
        magneticField = CMCalibratedMagneticField()
        heading = -1
        sensorLocation = .default
        super.init()
    }

    init(
        timestamp: TimeInterval,
        attitude: CMAttitude,
        rotationRate: CMRotationRate,
        gravity: CMAcceleration,
        userAcceleration: CMAcceleration,
        magneticField: CMCalibratedMagneticField,
        heading: Double,
        sensorLocation: SensorLocation
    ) {
        self.attitude = attitude
        self.rotationRate = rotationRate
        self.gravity = gravity
        self.userAcceleration = userAcceleration
        self.magneticField = magneticField
        self.heading = heading
        self.sensorLocation = sensorLocation
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        guard let attitude = coder.decodeObject(
            of: CMAttitude.self,
            forKey: "attitude"
        ) else {
            return nil
        }
        self.attitude = attitude
        rotationRate = CMRotationRate(
            x: coder.decodeDouble(forKey: "rrx"),
            y: coder.decodeDouble(forKey: "rry"),
            z: coder.decodeDouble(forKey: "rrz")
        )
        gravity = CMAcceleration(
            x: coder.decodeDouble(forKey: "gx"),
            y: coder.decodeDouble(forKey: "gy"),
            z: coder.decodeDouble(forKey: "gz")
        )
        userAcceleration = CMAcceleration(
            x: coder.decodeDouble(forKey: "ux"),
            y: coder.decodeDouble(forKey: "uy"),
            z: coder.decodeDouble(forKey: "uz")
        )
        magneticField = CMCalibratedMagneticField(
            field: CMMagneticField(
                x: coder.decodeDouble(forKey: "mfx"),
                y: coder.decodeDouble(forKey: "mfy"),
                z: coder.decodeDouble(forKey: "mfz")
            ),
            accuracy: CMMagneticFieldCalibrationAccuracy(
                rawValue: coder.decodeInt32(forKey: "mfa")
            ) ?? .uncalibrated
        )
        heading = coder.decodeDouble(forKey: "heading")
        sensorLocation = SensorLocation(rawValue: coder.decodeInteger(forKey: "sensorLocation"))
            ?? .default
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(attitude, forKey: "attitude")
        coder.encode(rotationRate.x, forKey: "rrx")
        coder.encode(rotationRate.y, forKey: "rry")
        coder.encode(rotationRate.z, forKey: "rrz")
        coder.encode(gravity.x, forKey: "gx")
        coder.encode(gravity.y, forKey: "gy")
        coder.encode(gravity.z, forKey: "gz")
        coder.encode(userAcceleration.x, forKey: "ux")
        coder.encode(userAcceleration.y, forKey: "uy")
        coder.encode(userAcceleration.z, forKey: "uz")
        coder.encode(magneticField.field.x, forKey: "mfx")
        coder.encode(magneticField.field.y, forKey: "mfy")
        coder.encode(magneticField.field.z, forKey: "mfz")
        coder.encode(magneticField.accuracy.rawValue, forKey: "mfa")
        coder.encode(heading, forKey: "heading")
        coder.encode(sensorLocation.rawValue, forKey: "sensorLocation")
    }
}

public class CMAltitudeData: CMLogItem {
    public let relativeAltitude: NSNumber
    public let pressure: NSNumber

    public override init() {
        relativeAltitude = 0
        pressure = 0
        super.init()
    }

    init(timestamp: TimeInterval, relativeAltitude: NSNumber, pressure: NSNumber) {
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        relativeAltitude = NSNumber(value: coder.decodeDouble(forKey: "relativeAltitude"))
        pressure = NSNumber(value: coder.decodeDouble(forKey: "pressure"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(relativeAltitude.doubleValue, forKey: "relativeAltitude")
        coder.encode(pressure.doubleValue, forKey: "pressure")
    }
}

public class CMAbsoluteAltitudeData: CMLogItem {
    public let altitude: Double
    public let accuracy: Double
    public let precision: Double

    public override init() {
        altitude = 0
        accuracy = 0
        precision = 0
        super.init()
    }

    init(
        timestamp: TimeInterval,
        altitude: Double,
        accuracy: Double,
        precision: Double
    ) {
        self.altitude = altitude
        self.accuracy = accuracy
        self.precision = precision
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        altitude = coder.decodeDouble(forKey: "altitude")
        accuracy = coder.decodeDouble(forKey: "accuracy")
        precision = coder.decodeDouble(forKey: "precision")
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(altitude, forKey: "altitude")
        coder.encode(accuracy, forKey: "accuracy")
        coder.encode(precision, forKey: "precision")
    }
}

public class CMAmbientPressureData: CMLogItem {
    public let pressure: Measurement<UnitPressure>
    public let temperature: Measurement<UnitTemperature>

    public override init() {
        pressure = Measurement(value: 0, unit: .kilopascals)
        temperature = Measurement(value: 0, unit: .celsius)
        super.init()
    }

    init(
        timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>
    ) {
        self.pressure = pressure
        self.temperature = temperature
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        pressure = Measurement(
            value: coder.decodeDouble(forKey: "pressure"),
            unit: .kilopascals
        )
        temperature = Measurement(
            value: coder.decodeDouble(forKey: "temperature"),
            unit: .celsius
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(pressure.converted(to: .kilopascals).value, forKey: "pressure")
        coder.encode(temperature.converted(to: .celsius).value, forKey: "temperature")
    }
}

public class CMRecordedAccelerometerData: CMAccelerometerData {
    public let identifier: UInt64
    public let startDate: Date

    public override init() {
        identifier = 0
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        super.init()
    }

    init(
        timestamp: TimeInterval,
        acceleration: CMAcceleration,
        identifier: UInt64,
        startDate: Date
    ) {
        self.identifier = identifier
        self.startDate = startDate
        super.init(timestamp: timestamp, acceleration: acceleration)
    }

    public required init?(coder: NSCoder) {
        identifier = UInt64(bitPattern: Int64(coder.decodeInt64(forKey: "identifier")))
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(bitPattern: identifier), forKey: "identifier")
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
    }
}

public class CMRecordedRotationRateData: CMRotationRateData {
    public let startDate: Date

    public override init() {
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        super.init()
    }

    init(timestamp: TimeInterval, rotationRate: CMRotationRate, startDate: Date) {
        self.startDate = startDate
        super.init(timestamp: timestamp, rotationRate: rotationRate)
    }

    public required init?(coder: NSCoder) {
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
    }
}

public class CMRecordedPressureData: CMAmbientPressureData {
    public let identifier: UInt64
    public let startDate: Date

    public override init() {
        identifier = 0
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        super.init()
    }

    init(
        timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>,
        identifier: UInt64,
        startDate: Date
    ) {
        self.identifier = identifier
        self.startDate = startDate
        super.init(timestamp: timestamp, pressure: pressure, temperature: temperature)
    }

    public required init?(coder: NSCoder) {
        identifier = UInt64(bitPattern: Int64(coder.decodeInt64(forKey: "identifier")))
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(bitPattern: identifier), forKey: "identifier")
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
    }
}

public class CMMotionActivity: CMLogItem {
    public let confidence: CMMotionActivityConfidence
    public let startDate: Date
    public let unknown: Bool
    public let stationary: Bool
    public let walking: Bool
    public let running: Bool
    public let automotive: Bool
    public let cycling: Bool

    public override init() {
        confidence = .low
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        unknown = true
        stationary = false
        walking = false
        running = false
        automotive = false
        cycling = false
        super.init()
    }

    init(
        startDate: Date,
        confidence: CMMotionActivityConfidence,
        unknown: Bool,
        stationary: Bool,
        walking: Bool,
        running: Bool,
        automotive: Bool,
        cycling: Bool
    ) {
        self.startDate = startDate
        self.confidence = confidence
        self.unknown = unknown
        self.stationary = stationary
        self.walking = walking
        self.running = running
        self.automotive = automotive
        self.cycling = cycling
        super.init(timestamp: startDate.timeIntervalSinceReferenceDate)
    }

    public required init?(coder: NSCoder) {
        confidence = CMMotionActivityConfidence(
            rawValue: coder.decodeInteger(forKey: "confidence")
        ) ?? .low
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        unknown = coder.decodeBool(forKey: "unknown")
        stationary = coder.decodeBool(forKey: "stationary")
        walking = coder.decodeBool(forKey: "walking")
        running = coder.decodeBool(forKey: "running")
        automotive = coder.decodeBool(forKey: "automotive")
        cycling = coder.decodeBool(forKey: "cycling")
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(confidence.rawValue, forKey: "confidence")
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
        coder.encode(unknown, forKey: "unknown")
        coder.encode(stationary, forKey: "stationary")
        coder.encode(walking, forKey: "walking")
        coder.encode(running, forKey: "running")
        coder.encode(automotive, forKey: "automotive")
        coder.encode(cycling, forKey: "cycling")
    }
}

public class CMPedometerData: NSObject, NSSecureCoding, NSCopying {
    public static var supportsSecureCoding: Bool { true }

    public let startDate: Date
    public let endDate: Date
    public let numberOfSteps: NSNumber
    public let distance: NSNumber?
    public let floorsAscended: NSNumber?
    public let floorsDescended: NSNumber?
    public let currentPace: NSNumber?
    public let currentCadence: NSNumber?
    public let averageActivePace: NSNumber?

    public override init() {
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        endDate = Date(timeIntervalSinceReferenceDate: 0)
        numberOfSteps = 0
        distance = nil
        floorsAscended = nil
        floorsDescended = nil
        currentPace = nil
        currentCadence = nil
        averageActivePace = nil
        super.init()
    }

    init(
        startDate: Date,
        endDate: Date,
        numberOfSteps: NSNumber,
        distance: NSNumber?,
        floorsAscended: NSNumber?,
        floorsDescended: NSNumber?,
        currentPace: NSNumber?,
        currentCadence: NSNumber?,
        averageActivePace: NSNumber?
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.numberOfSteps = numberOfSteps
        self.distance = distance
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
        self.currentPace = currentPace
        self.currentCadence = currentCadence
        self.averageActivePace = averageActivePace
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        endDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "endDate")
        )
        numberOfSteps = NSNumber(value: coder.decodeInteger(forKey: "numberOfSteps"))
        distance = coder.containsValue(forKey: "distance")
            ? NSNumber(value: coder.decodeDouble(forKey: "distance"))
            : nil
        floorsAscended = coder.containsValue(forKey: "floorsAscended")
            ? NSNumber(value: coder.decodeInteger(forKey: "floorsAscended"))
            : nil
        floorsDescended = coder.containsValue(forKey: "floorsDescended")
            ? NSNumber(value: coder.decodeInteger(forKey: "floorsDescended"))
            : nil
        currentPace = coder.containsValue(forKey: "currentPace")
            ? NSNumber(value: coder.decodeDouble(forKey: "currentPace"))
            : nil
        currentCadence = coder.containsValue(forKey: "currentCadence")
            ? NSNumber(value: coder.decodeDouble(forKey: "currentCadence"))
            : nil
        averageActivePace = coder.containsValue(forKey: "averageActivePace")
            ? NSNumber(value: coder.decodeDouble(forKey: "averageActivePace"))
            : nil
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
        coder.encode(endDate.timeIntervalSinceReferenceDate, forKey: "endDate")
        coder.encode(numberOfSteps.intValue, forKey: "numberOfSteps")
        if let distance {
            coder.encode(distance.doubleValue, forKey: "distance")
        }
        if let floorsAscended {
            coder.encode(floorsAscended.intValue, forKey: "floorsAscended")
        }
        if let floorsDescended {
            coder.encode(floorsDescended.intValue, forKey: "floorsDescended")
        }
        if let currentPace {
            coder.encode(currentPace.doubleValue, forKey: "currentPace")
        }
        if let currentCadence {
            coder.encode(currentCadence.doubleValue, forKey: "currentCadence")
        }
        if let averageActivePace {
            coder.encode(averageActivePace.doubleValue, forKey: "averageActivePace")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMPedometerData(
            startDate: startDate,
            endDate: endDate,
            numberOfSteps: numberOfSteps,
            distance: distance,
            floorsAscended: floorsAscended,
            floorsDescended: floorsDescended,
            currentPace: currentPace,
            currentCadence: currentCadence,
            averageActivePace: averageActivePace
        )
    }
}

public class CMPedometerEvent: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let date: Date
    public let type: CMPedometerEventType

    public override init() {
        date = Date(timeIntervalSinceReferenceDate: 0)
        type = .pause
        super.init()
    }

    init(date: Date, type: CMPedometerEventType) {
        self.date = date
        self.type = type
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        date = Date(timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "date"))
        type = CMPedometerEventType(rawValue: coder.decodeInteger(forKey: "type")) ?? .pause
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(date.timeIntervalSinceReferenceDate, forKey: "date")
        coder.encode(type.rawValue, forKey: "type")
    }
}

public class CMOdometerData: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let startDate: Date
    public let endDate: Date
    public let deltaDistance: CLLocationDistance
    public let deltaDistanceAccuracy: CLLocationAccuracy
    public let speed: CLLocationSpeed
    public let speedAccuracy: CLLocationSpeedAccuracy
    public let deltaAltitude: CLLocationDistance
    public let verticalAccuracy: CLLocationAccuracy
    public let originDevice: CMOdometerOriginDevice
    public let gpsDate: Date
    public let slope: Double?
    public let maxAbsSlope: Double?

    public override init() {
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        endDate = Date(timeIntervalSinceReferenceDate: 0)
        deltaDistance = 0
        deltaDistanceAccuracy = 0
        speed = 0
        speedAccuracy = 0
        deltaAltitude = 0
        verticalAccuracy = 0
        originDevice = .unknown
        gpsDate = Date(timeIntervalSinceReferenceDate: 0)
        slope = nil
        maxAbsSlope = nil
        super.init()
    }

    init(
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
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.deltaDistance = deltaDistance
        self.deltaDistanceAccuracy = deltaDistanceAccuracy
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.deltaAltitude = deltaAltitude
        self.verticalAccuracy = verticalAccuracy
        self.originDevice = originDevice
        self.gpsDate = gpsDate
        self.slope = slope
        self.maxAbsSlope = maxAbsSlope
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        endDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "endDate")
        )
        deltaDistance = coder.decodeDouble(forKey: "deltaDistance")
        deltaDistanceAccuracy = coder.decodeDouble(forKey: "deltaDistanceAccuracy")
        speed = coder.decodeDouble(forKey: "speed")
        speedAccuracy = coder.decodeDouble(forKey: "speedAccuracy")
        deltaAltitude = coder.decodeDouble(forKey: "deltaAltitude")
        verticalAccuracy = coder.decodeDouble(forKey: "verticalAccuracy")
        originDevice = CMOdometerOriginDevice(
            rawValue: coder.decodeInteger(forKey: "originDevice")
        ) ?? .unknown
        gpsDate = Date(timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "gpsDate"))
        slope = coder.containsValue(forKey: "slope")
            ? coder.decodeDouble(forKey: "slope")
            : nil
        maxAbsSlope = coder.containsValue(forKey: "maxAbsSlope")
            ? coder.decodeDouble(forKey: "maxAbsSlope")
            : nil
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
        coder.encode(endDate.timeIntervalSinceReferenceDate, forKey: "endDate")
        coder.encode(deltaDistance, forKey: "deltaDistance")
        coder.encode(deltaDistanceAccuracy, forKey: "deltaDistanceAccuracy")
        coder.encode(speed, forKey: "speed")
        coder.encode(speedAccuracy, forKey: "speedAccuracy")
        coder.encode(deltaAltitude, forKey: "deltaAltitude")
        coder.encode(verticalAccuracy, forKey: "verticalAccuracy")
        coder.encode(originDevice.rawValue, forKey: "originDevice")
        coder.encode(gpsDate.timeIntervalSinceReferenceDate, forKey: "gpsDate")
        if let slope {
            coder.encode(slope, forKey: "slope")
        }
        if let maxAbsSlope {
            coder.encode(maxAbsSlope, forKey: "maxAbsSlope")
        }
    }
}

public class CMDyskineticSymptomResult: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let startDate: Date
    public let endDate: Date
    public let percentLikely: Float
    public let percentUnlikely: Float

    public override init() {
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        endDate = Date(timeIntervalSinceReferenceDate: 0)
        percentLikely = 0
        percentUnlikely = 0
        super.init()
    }

    init(
        startDate: Date,
        endDate: Date,
        percentLikely: Float,
        percentUnlikely: Float
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.percentLikely = percentLikely
        self.percentUnlikely = percentUnlikely
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        endDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "endDate")
        )
        percentLikely = coder.decodeFloat(forKey: "percentLikely")
        percentUnlikely = coder.decodeFloat(forKey: "percentUnlikely")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
        coder.encode(endDate.timeIntervalSinceReferenceDate, forKey: "endDate")
        coder.encode(percentLikely, forKey: "percentLikely")
        coder.encode(percentUnlikely, forKey: "percentUnlikely")
    }
}

public class CMTremorResult: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let startDate: Date
    public let endDate: Date
    public let percentUnknown: Float
    public let percentNone: Float
    public let percentSlight: Float
    public let percentMild: Float
    public let percentModerate: Float
    public let percentStrong: Float

    public override init() {
        startDate = Date(timeIntervalSinceReferenceDate: 0)
        endDate = Date(timeIntervalSinceReferenceDate: 0)
        percentUnknown = 0
        percentNone = 0
        percentSlight = 0
        percentMild = 0
        percentModerate = 0
        percentStrong = 0
        super.init()
    }

    init(
        startDate: Date,
        endDate: Date,
        percentUnknown: Float,
        percentNone: Float,
        percentSlight: Float,
        percentMild: Float,
        percentModerate: Float,
        percentStrong: Float
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.percentUnknown = percentUnknown
        self.percentNone = percentNone
        self.percentSlight = percentSlight
        self.percentMild = percentMild
        self.percentModerate = percentModerate
        self.percentStrong = percentStrong
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        startDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "startDate")
        )
        endDate = Date(
            timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "endDate")
        )
        percentUnknown = coder.decodeFloat(forKey: "percentUnknown")
        percentNone = coder.decodeFloat(forKey: "percentNone")
        percentSlight = coder.decodeFloat(forKey: "percentSlight")
        percentMild = coder.decodeFloat(forKey: "percentMild")
        percentModerate = coder.decodeFloat(forKey: "percentModerate")
        percentStrong = coder.decodeFloat(forKey: "percentStrong")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(startDate.timeIntervalSinceReferenceDate, forKey: "startDate")
        coder.encode(endDate.timeIntervalSinceReferenceDate, forKey: "endDate")
        coder.encode(percentUnknown, forKey: "percentUnknown")
        coder.encode(percentNone, forKey: "percentNone")
        coder.encode(percentSlight, forKey: "percentSlight")
        coder.encode(percentMild, forKey: "percentMild")
        coder.encode(percentModerate, forKey: "percentModerate")
        coder.encode(percentStrong, forKey: "percentStrong")
    }
}

public class CMHighFrequencyHeartRateData: CMLogItem {
    public let heartRate: Double
    public let confidence: CMHighFrequencyHeartRateDataConfidence
    public let date: Date?

    public override init() {
        heartRate = 0
        confidence = .low
        date = nil
        super.init()
    }

    init(
        timestamp: TimeInterval,
        heartRate: Double,
        confidence: CMHighFrequencyHeartRateDataConfidence,
        date: Date?
    ) {
        self.heartRate = heartRate
        self.confidence = confidence
        self.date = date
        super.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        heartRate = coder.decodeDouble(forKey: "heartRate")
        confidence = CMHighFrequencyHeartRateDataConfidence(
            rawValue: coder.decodeInteger(forKey: "confidence")
        ) ?? .low
        date = coder.containsValue(forKey: "date")
            ? Date(timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "date"))
            : nil
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(heartRate, forKey: "heartRate")
        coder.encode(confidence.rawValue, forKey: "confidence")
        if let date {
            coder.encode(date.timeIntervalSinceReferenceDate, forKey: "date")
        }
    }
}

public class CMWaterSubmersionEvent: NSObject, NSSecureCoding {
    public enum State: Int, Sendable, Hashable {
        case unknown = 0
        case notSubmerged = 1
        case submerged = 2
    }

    public static var supportsSecureCoding: Bool { true }

    public let date: Date
    public let state: State

    public override init() {
        date = Date(timeIntervalSinceReferenceDate: 0)
        state = .unknown
        super.init()
    }

    init(date: Date, state: State) {
        self.date = date
        self.state = state
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        date = Date(timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "date"))
        state = State(rawValue: coder.decodeInteger(forKey: "state")) ?? .unknown
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(date.timeIntervalSinceReferenceDate, forKey: "date")
        coder.encode(state.rawValue, forKey: "state")
    }
}

public class CMWaterSubmersionMeasurement: NSObject, NSSecureCoding {
    public enum DepthState: Int, Sendable, Hashable {
        case unknown = 0
        case notSubmerged = 1
        case submergedShallow = 2
        case submergedDeep = 3
        case approachingMaxDepth = 4
        case pastMaxDepth = 5
        case sensorDepthError = 6
    }

    public static var supportsSecureCoding: Bool { true }

    public let date: Date
    public let depth: Measurement<UnitLength>?
    public let pressure: Measurement<UnitPressure>?
    public let surfacePressure: Measurement<UnitPressure>
    public let submersionState: DepthState

    public override init() {
        date = Date(timeIntervalSinceReferenceDate: 0)
        depth = nil
        pressure = nil
        surfacePressure = Measurement(value: 101.325, unit: .kilopascals)
        submersionState = .unknown
        super.init()
    }

    init(
        date: Date,
        depth: Measurement<UnitLength>?,
        pressure: Measurement<UnitPressure>?,
        surfacePressure: Measurement<UnitPressure>,
        submersionState: DepthState
    ) {
        self.date = date
        self.depth = depth
        self.pressure = pressure
        self.surfacePressure = surfacePressure
        self.submersionState = submersionState
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        date = Date(timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "date"))
        depth = coder.containsValue(forKey: "depth")
            ? Measurement(value: coder.decodeDouble(forKey: "depth"), unit: .meters)
            : nil
        pressure = coder.containsValue(forKey: "pressure")
            ? Measurement(value: coder.decodeDouble(forKey: "pressure"), unit: .kilopascals)
            : nil
        surfacePressure = Measurement(
            value: coder.decodeDouble(forKey: "surfacePressure"),
            unit: .kilopascals
        )
        submersionState = DepthState(rawValue: coder.decodeInteger(forKey: "submersionState"))
            ?? .unknown
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(date.timeIntervalSinceReferenceDate, forKey: "date")
        if let depth {
            coder.encode(depth.converted(to: .meters).value, forKey: "depth")
        }
        if let pressure {
            coder.encode(pressure.converted(to: .kilopascals).value, forKey: "pressure")
        }
        coder.encode(
            surfacePressure.converted(to: .kilopascals).value,
            forKey: "surfacePressure"
        )
        coder.encode(submersionState.rawValue, forKey: "submersionState")
    }
}

public class CMWaterTemperature: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let date: Date
    public let temperature: Measurement<UnitTemperature>
    public let temperatureUncertainty: Measurement<UnitTemperature>

    public override init() {
        date = Date(timeIntervalSinceReferenceDate: 0)
        temperature = Measurement(value: 0, unit: .celsius)
        temperatureUncertainty = Measurement(value: 0, unit: .celsius)
        super.init()
    }

    init(
        date: Date,
        temperature: Measurement<UnitTemperature>,
        temperatureUncertainty: Measurement<UnitTemperature>
    ) {
        self.date = date
        self.temperature = temperature
        self.temperatureUncertainty = temperatureUncertainty
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard CoreMotionArchive.hasMarker(coder) else { return nil }
        date = Date(timeIntervalSinceReferenceDate: coder.decodeDouble(forKey: "date"))
        temperature = Measurement(
            value: coder.decodeDouble(forKey: "temperature"),
            unit: .celsius
        )
        temperatureUncertainty = Measurement(
            value: coder.decodeDouble(forKey: "temperatureUncertainty"),
            unit: .celsius
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        CoreMotionArchive.encodeMarker(coder)
        coder.encode(date.timeIntervalSinceReferenceDate, forKey: "date")
        coder.encode(temperature.converted(to: .celsius).value, forKey: "temperature")
        coder.encode(
            temperatureUncertainty.converted(to: .celsius).value,
            forKey: "temperatureUncertainty"
        )
    }
}

public class CMSensorDataList: NSObject, Sequence {
    public typealias Element = CMRecordedAccelerometerData

    private let items: [CMRecordedAccelerometerData]

    public override init() {
        items = []
        super.init()
    }

    init(items: [CMRecordedAccelerometerData]) {
        self.items = items
        super.init()
    }

    public func makeIterator() -> IndexingIterator<[CMRecordedAccelerometerData]> {
        items.makeIterator()
    }

    public var count: Int { items.count }
}
