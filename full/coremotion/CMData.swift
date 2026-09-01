open class CMLogItem: NSObject, NSSecureCoding, NSCopying {
    public private(set) var timestamp: TimeInterval

    public class var supportsSecureCoding: Bool { true }

    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostTimestamp timestamp: TimeInterval) {
        self.init(timestamp: timestamp)
    }

    public required init?(coder: NSCoder) {
        timestamp = coder.decodeDouble(forKey: "timestamp")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(timestamp, forKey: "timestamp")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        CMLogItem(timestamp: timestamp)
    }
}

open class CMAccelerometerData: CMLogItem {
    public private(set) var acceleration: CMAcceleration

    init(timestamp: TimeInterval, acceleration: CMAcceleration) {
        self.acceleration = acceleration
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        acceleration: CMAcceleration
    ) {
        self.init(timestamp: timestamp, acceleration: acceleration)
    }

    public required init?(coder: NSCoder) {
        acceleration = CMAcceleration(
            x: coder.decodeDouble(forKey: "ax"),
            y: coder.decodeDouble(forKey: "ay"),
            z: coder.decodeDouble(forKey: "az")
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(acceleration.x, forKey: "ax")
        coder.encode(acceleration.y, forKey: "ay")
        coder.encode(acceleration.z, forKey: "az")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMAccelerometerData(timestamp: timestamp, acceleration: acceleration)
    }
}

open class CMGyroData: CMLogItem {
    public private(set) var rotationRate: CMRotationRate

    init(timestamp: TimeInterval, rotationRate: CMRotationRate) {
        self.rotationRate = rotationRate
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        rotationRate: CMRotationRate
    ) {
        self.init(timestamp: timestamp, rotationRate: rotationRate)
    }

    public required init?(coder: NSCoder) {
        rotationRate = CMRotationRate(
            x: coder.decodeDouble(forKey: "gx"),
            y: coder.decodeDouble(forKey: "gy"),
            z: coder.decodeDouble(forKey: "gz")
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(rotationRate.x, forKey: "gx")
        coder.encode(rotationRate.y, forKey: "gy")
        coder.encode(rotationRate.z, forKey: "gz")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMGyroData(timestamp: timestamp, rotationRate: rotationRate)
    }
}

open class CMMagnetometerData: CMLogItem {
    public private(set) var magneticField: CMMagneticField

    init(timestamp: TimeInterval, magneticField: CMMagneticField) {
        self.magneticField = magneticField
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        magneticField: CMMagneticField
    ) {
        self.init(timestamp: timestamp, magneticField: magneticField)
    }

    public required init?(coder: NSCoder) {
        magneticField = CMMagneticField(
            x: coder.decodeDouble(forKey: "mx"),
            y: coder.decodeDouble(forKey: "my"),
            z: coder.decodeDouble(forKey: "mz")
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(magneticField.x, forKey: "mx")
        coder.encode(magneticField.y, forKey: "my")
        coder.encode(magneticField.z, forKey: "mz")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMMagnetometerData(timestamp: timestamp, magneticField: magneticField)
    }
}

open class CMAttitude: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    private var storage: CMQuaternion

    public var quaternion: CMQuaternion { storage }

    public var roll: Double { cm_euler(from: storage).roll }
    public var pitch: Double { cm_euler(from: storage).pitch }
    public var yaw: Double { cm_euler(from: storage).yaw }
    public var rotationMatrix: CMRotationMatrix { cm_rotationMatrix(from: storage) }

    init(quaternion: CMQuaternion) {
        self.storage = quaternion
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostQuaternion quaternion: CMQuaternion) {
        self.init(quaternion: quaternion)
    }

    public required init?(coder: NSCoder) {
        storage = CMQuaternion(
            x: coder.decodeDouble(forKey: "qx"),
            y: coder.decodeDouble(forKey: "qy"),
            z: coder.decodeDouble(forKey: "qz"),
            w: coder.decodeDouble(forKey: "qw")
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(storage.x, forKey: "qx")
        coder.encode(storage.y, forKey: "qy")
        coder.encode(storage.z, forKey: "qz")
        coder.encode(storage.w, forKey: "qw")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMAttitude(quaternion: storage)
    }

    public func multiply(byInverseOf attitude: CMAttitude) {
        storage = cm_quaternionMultiply(storage, cm_quaternionInverse(attitude.storage))
    }
}

open class CMDeviceMotion: CMLogItem {
    public enum SensorLocation: Int, Sendable, Hashable, BitwiseCopyable {
        case `default` = 0
        case headphoneLeft = 1
        case headphoneRight = 2
    }

    public private(set) var attitude: CMAttitude
    public private(set) var rotationRate: CMRotationRate
    public private(set) var gravity: CMAcceleration
    public private(set) var userAcceleration: CMAcceleration
    public private(set) var magneticField: CMCalibratedMagneticField
    public private(set) var heading: Double
    public private(set) var sensorLocation: CMDeviceMotion.SensorLocation

    init(
        timestamp: TimeInterval,
        attitude: CMAttitude,
        rotationRate: CMRotationRate,
        gravity: CMAcceleration,
        userAcceleration: CMAcceleration,
        magneticField: CMCalibratedMagneticField,
        heading: Double,
        sensorLocation: CMDeviceMotion.SensorLocation
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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        attitude: CMAttitude,
        rotationRate: CMRotationRate,
        gravity: CMAcceleration,
        userAcceleration: CMAcceleration,
        magneticField: CMCalibratedMagneticField,
        heading: Double,
        sensorLocation: CMDeviceMotion.SensorLocation
    ) {
        self.init(
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

    public required init?(coder: NSCoder) {
        guard let attitude = coder.decodeObject(of: CMAttitude.self, forKey: "attitude") else {
            return nil
        }
        self.attitude = attitude
        rotationRate = CMRotationRate(
            x: coder.decodeDouble(forKey: "rx"),
            y: coder.decodeDouble(forKey: "ry"),
            z: coder.decodeDouble(forKey: "rz")
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
                x: coder.decodeDouble(forKey: "mx"),
                y: coder.decodeDouble(forKey: "my"),
                z: coder.decodeDouble(forKey: "mz")
            ),
            accuracy: CMMagneticFieldCalibrationAccuracy(
                rawValue: coder.decodeInt32(forKey: "ma")
            ) ?? .uncalibrated
        )
        heading = coder.decodeDouble(forKey: "heading")
        sensorLocation = CMDeviceMotion.SensorLocation(
            rawValue: Int(coder.decodeInt64(forKey: "sensorLocation"))
        ) ?? .default
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(attitude, forKey: "attitude")
        coder.encode(rotationRate.x, forKey: "rx")
        coder.encode(rotationRate.y, forKey: "ry")
        coder.encode(rotationRate.z, forKey: "rz")
        coder.encode(gravity.x, forKey: "gx")
        coder.encode(gravity.y, forKey: "gy")
        coder.encode(gravity.z, forKey: "gz")
        coder.encode(userAcceleration.x, forKey: "ux")
        coder.encode(userAcceleration.y, forKey: "uy")
        coder.encode(userAcceleration.z, forKey: "uz")
        coder.encode(magneticField.field.x, forKey: "mx")
        coder.encode(magneticField.field.y, forKey: "my")
        coder.encode(magneticField.field.z, forKey: "mz")
        coder.encode(magneticField.accuracy.rawValue, forKey: "ma")
        coder.encode(heading, forKey: "heading")
        coder.encode(Int64(sensorLocation.rawValue), forKey: "sensorLocation")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMDeviceMotion(
            timestamp: timestamp,
            attitude: attitude.copy() as! CMAttitude,
            rotationRate: rotationRate,
            gravity: gravity,
            userAcceleration: userAcceleration,
            magneticField: magneticField,
            heading: heading,
            sensorLocation: sensorLocation
        )
    }
}

open class CMAltitudeData: CMLogItem {
    public private(set) var relativeAltitude: NSNumber
    public private(set) var pressure: NSNumber

    init(timestamp: TimeInterval, relativeAltitude: NSNumber, pressure: NSNumber) {
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        relativeAltitude: NSNumber,
        pressure: NSNumber
    ) {
        self.init(timestamp: timestamp, relativeAltitude: relativeAltitude, pressure: pressure)
    }

    public required init?(coder: NSCoder) {
        guard let relativeAltitude = coder.decodeObject(of: NSNumber.self, forKey: "relativeAltitude"),
              let pressure = coder.decodeObject(of: NSNumber.self, forKey: "pressure")
        else {
            return nil
        }
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(relativeAltitude, forKey: "relativeAltitude")
        coder.encode(pressure, forKey: "pressure")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMAltitudeData(
            timestamp: timestamp,
            relativeAltitude: relativeAltitude,
            pressure: pressure
        )
    }
}

open class CMAbsoluteAltitudeData: CMLogItem {
    public private(set) var altitude: Double
    public private(set) var accuracy: Double
    public private(set) var precision: Double

    init(timestamp: TimeInterval, altitude: Double, accuracy: Double, precision: Double) {
        self.altitude = altitude
        self.accuracy = accuracy
        self.precision = precision
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        altitude: Double,
        accuracy: Double,
        precision: Double
    ) {
        self.init(timestamp: timestamp, altitude: altitude, accuracy: accuracy, precision: precision)
    }

    public required init?(coder: NSCoder) {
        altitude = coder.decodeDouble(forKey: "altitude")
        accuracy = coder.decodeDouble(forKey: "accuracy")
        precision = coder.decodeDouble(forKey: "precision")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(altitude, forKey: "altitude")
        coder.encode(accuracy, forKey: "accuracy")
        coder.encode(precision, forKey: "precision")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMAbsoluteAltitudeData(
            timestamp: timestamp,
            altitude: altitude,
            accuracy: accuracy,
            precision: precision
        )
    }
}

open class CMAmbientPressureData: CMLogItem {
    public private(set) var pressure: Measurement<UnitPressure>
    public private(set) var temperature: Measurement<UnitTemperature>

    init(
        timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>
    ) {
        self.pressure = pressure
        self.temperature = temperature
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>
    ) {
        self.init(timestamp: timestamp, pressure: pressure, temperature: temperature)
    }

    public required init?(coder: NSCoder) {
        pressure = Measurement(
            value: coder.decodeDouble(forKey: "pressureKPa"),
            unit: .kilopascals
        )
        temperature = Measurement(
            value: coder.decodeDouble(forKey: "temperatureC"),
            unit: .celsius
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(pressure.converted(to: .kilopascals).value, forKey: "pressureKPa")
        coder.encode(temperature.converted(to: .celsius).value, forKey: "temperatureC")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMAmbientPressureData(timestamp: timestamp, pressure: pressure, temperature: temperature)
    }
}

open class CMRecordedAccelerometerData: CMAccelerometerData {
    public private(set) var identifier: UInt64
    public private(set) var startDate: Date

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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        acceleration: CMAcceleration,
        identifier: UInt64,
        startDate: Date
    ) {
        self.init(
            timestamp: timestamp,
            acceleration: acceleration,
            identifier: identifier,
            startDate: startDate
        )
    }

    public required init?(coder: NSCoder) {
        identifier = UInt64(bitPattern: coder.decodeInt64(forKey: "identifier"))
        startDate = (coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?) ?? Date.distantPast
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(bitPattern: identifier), forKey: "identifier")
        coder.encode(startDate as NSDate, forKey: "startDate")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMRecordedAccelerometerData(
            timestamp: timestamp,
            acceleration: acceleration,
            identifier: identifier,
            startDate: startDate
        )
    }
}

open class CMRecordedPressureData: CMAmbientPressureData {
    public private(set) var identifier: UInt64
    public private(set) var startDate: Date

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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        pressure: Measurement<UnitPressure>,
        temperature: Measurement<UnitTemperature>,
        identifier: UInt64,
        startDate: Date
    ) {
        self.init(
            timestamp: timestamp,
            pressure: pressure,
            temperature: temperature,
            identifier: identifier,
            startDate: startDate
        )
    }

    public required init?(coder: NSCoder) {
        identifier = UInt64(bitPattern: coder.decodeInt64(forKey: "identifier"))
        startDate = (coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?) ?? Date.distantPast
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(bitPattern: identifier), forKey: "identifier")
        coder.encode(startDate as NSDate, forKey: "startDate")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMRecordedPressureData(
            timestamp: timestamp,
            pressure: pressure,
            temperature: temperature,
            identifier: identifier,
            startDate: startDate
        )
    }
}

open class CMRotationRateData: CMLogItem {
    public private(set) var rotationRate: CMRotationRate

    init(timestamp: TimeInterval, rotationRate: CMRotationRate) {
        self.rotationRate = rotationRate
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        rotationRate: CMRotationRate
    ) {
        self.init(timestamp: timestamp, rotationRate: rotationRate)
    }

    public required init?(coder: NSCoder) {
        rotationRate = CMRotationRate(
            x: coder.decodeDouble(forKey: "rrx"),
            y: coder.decodeDouble(forKey: "rry"),
            z: coder.decodeDouble(forKey: "rrz")
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(rotationRate.x, forKey: "rrx")
        coder.encode(rotationRate.y, forKey: "rry")
        coder.encode(rotationRate.z, forKey: "rrz")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMRotationRateData(timestamp: timestamp, rotationRate: rotationRate)
    }
}

open class CMRecordedRotationRateData: CMRotationRateData {
    public private(set) var startDate: Date

    init(timestamp: TimeInterval, rotationRate: CMRotationRate, startDate: Date) {
        self.startDate = startDate
        super.init(timestamp: timestamp, rotationRate: rotationRate)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        rotationRate: CMRotationRate,
        startDate: Date
    ) {
        self.init(timestamp: timestamp, rotationRate: rotationRate, startDate: startDate)
    }

    public required init?(coder: NSCoder) {
        startDate = (coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?) ?? Date.distantPast
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(startDate as NSDate, forKey: "startDate")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMRecordedRotationRateData(
            timestamp: timestamp,
            rotationRate: rotationRate,
            startDate: startDate
        )
    }
}

open class CMHighFrequencyHeartRateData: CMLogItem {
    public private(set) var heartRate: Double
    public private(set) var confidence: CMHighFrequencyHeartRateDataConfidence
    public private(set) var date: Date?

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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        heartRate: Double,
        confidence: CMHighFrequencyHeartRateDataConfidence,
        date: Date?
    ) {
        self.init(
            timestamp: timestamp,
            heartRate: heartRate,
            confidence: confidence,
            date: date
        )
    }

    public required init?(coder: NSCoder) {
        heartRate = coder.decodeDouble(forKey: "heartRate")
        confidence = CMHighFrequencyHeartRateDataConfidence(
            rawValue: Int(coder.decodeInt64(forKey: "confidence"))
        ) ?? .low
        date = coder.decodeObject(of: NSDate.self, forKey: "date") as Date?
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(heartRate, forKey: "heartRate")
        coder.encode(Int64(confidence.rawValue), forKey: "confidence")
        if let date {
            coder.encode(date as NSDate, forKey: "date")
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMHighFrequencyHeartRateData(
            timestamp: timestamp,
            heartRate: heartRate,
            confidence: confidence,
            date: date
        )
    }
}

open class CMMotionActivity: CMLogItem {
    public private(set) var confidence: CMMotionActivityConfidence
    public private(set) var startDate: Date
    public private(set) var unknown: Bool
    public private(set) var stationary: Bool
    public private(set) var walking: Bool
    public private(set) var running: Bool
    public private(set) var automotive: Bool
    public private(set) var cycling: Bool

    init(
        timestamp: TimeInterval,
        confidence: CMMotionActivityConfidence,
        startDate: Date,
        unknown: Bool,
        stationary: Bool,
        walking: Bool,
        running: Bool,
        automotive: Bool,
        cycling: Bool
    ) {
        self.confidence = confidence
        self.startDate = startDate
        self.unknown = unknown
        self.stationary = stationary
        self.walking = walking
        self.running = running
        self.automotive = automotive
        self.cycling = cycling
        super.init(timestamp: timestamp)
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostTimestamp timestamp: TimeInterval,
        confidence: CMMotionActivityConfidence,
        startDate: Date,
        unknown: Bool,
        stationary: Bool,
        walking: Bool,
        running: Bool,
        automotive: Bool,
        cycling: Bool
    ) {
        self.init(
            timestamp: timestamp,
            confidence: confidence,
            startDate: startDate,
            unknown: unknown,
            stationary: stationary,
            walking: walking,
            running: running,
            automotive: automotive,
            cycling: cycling
        )
    }

    public required init?(coder: NSCoder) {
        confidence = CMMotionActivityConfidence(
            rawValue: Int(coder.decodeInt64(forKey: "confidence"))
        ) ?? .low
        startDate = (coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?) ?? Date.distantPast
        unknown = coder.decodeBool(forKey: "unknown")
        stationary = coder.decodeBool(forKey: "stationary")
        walking = coder.decodeBool(forKey: "walking")
        running = coder.decodeBool(forKey: "running")
        automotive = coder.decodeBool(forKey: "automotive")
        cycling = coder.decodeBool(forKey: "cycling")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(confidence.rawValue), forKey: "confidence")
        coder.encode(startDate as NSDate, forKey: "startDate")
        coder.encode(unknown, forKey: "unknown")
        coder.encode(stationary, forKey: "stationary")
        coder.encode(walking, forKey: "walking")
        coder.encode(running, forKey: "running")
        coder.encode(automotive, forKey: "automotive")
        coder.encode(cycling, forKey: "cycling")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CMMotionActivity(
            timestamp: timestamp,
            confidence: confidence,
            startDate: startDate,
            unknown: unknown,
            stationary: stationary,
            walking: walking,
            running: running,
            automotive: automotive,
            cycling: cycling
        )
    }
}
