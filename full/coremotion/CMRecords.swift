open class CMPedometerData: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public private(set) var startDate: Date
    public private(set) var endDate: Date
    public private(set) var numberOfSteps: NSNumber
    public private(set) var distance: NSNumber?
    public private(set) var floorsAscended: NSNumber?
    public private(set) var floorsDescended: NSNumber?
    public private(set) var currentPace: NSNumber?
    public private(set) var currentCadence: NSNumber?
    public private(set) var averageActivePace: NSNumber?

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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostStartDate startDate: Date,
        endDate: Date,
        numberOfSteps: NSNumber,
        distance: NSNumber? = nil,
        floorsAscended: NSNumber? = nil,
        floorsDescended: NSNumber? = nil,
        currentPace: NSNumber? = nil,
        currentCadence: NSNumber? = nil,
        averageActivePace: NSNumber? = nil
    ) {
        self.init(
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

    public required init?(coder: NSCoder) {
        guard let startDate = coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?,
              let endDate = coder.decodeObject(of: NSDate.self, forKey: "endDate") as Date?,
              let numberOfSteps = coder.decodeObject(of: NSNumber.self, forKey: "numberOfSteps")
        else {
            return nil
        }
        self.startDate = startDate
        self.endDate = endDate
        self.numberOfSteps = numberOfSteps
        distance = coder.decodeObject(of: NSNumber.self, forKey: "distance")
        floorsAscended = coder.decodeObject(of: NSNumber.self, forKey: "floorsAscended")
        floorsDescended = coder.decodeObject(of: NSNumber.self, forKey: "floorsDescended")
        currentPace = coder.decodeObject(of: NSNumber.self, forKey: "currentPace")
        currentCadence = coder.decodeObject(of: NSNumber.self, forKey: "currentCadence")
        averageActivePace = coder.decodeObject(of: NSNumber.self, forKey: "averageActivePace")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(startDate as NSDate, forKey: "startDate")
        coder.encode(endDate as NSDate, forKey: "endDate")
        coder.encode(numberOfSteps, forKey: "numberOfSteps")
        coder.encode(distance, forKey: "distance")
        coder.encode(floorsAscended, forKey: "floorsAscended")
        coder.encode(floorsDescended, forKey: "floorsDescended")
        coder.encode(currentPace, forKey: "currentPace")
        coder.encode(currentCadence, forKey: "currentCadence")
        coder.encode(averageActivePace, forKey: "averageActivePace")
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

open class CMPedometerEvent: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public private(set) var date: Date
    public private(set) var type: CMPedometerEventType

    init(date: Date, type: CMPedometerEventType) {
        self.date = date
        self.type = type
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostDate date: Date, type: CMPedometerEventType) {
        self.init(date: date, type: type)
    }

    public required init?(coder: NSCoder) {
        guard let date = coder.decodeObject(of: NSDate.self, forKey: "date") as Date? else {
            return nil
        }
        self.date = date
        type = CMPedometerEventType(rawValue: Int(coder.decodeInt64(forKey: "type"))) ?? .pause
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(date as NSDate, forKey: "date")
        coder.encode(Int64(type.rawValue), forKey: "type")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMPedometerEvent(date: date, type: type)
    }
}

open class CMOdometerData: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public class var supportsSecureCoding: Bool { true }

    public private(set) var startDate: Date
    public private(set) var endDate: Date
    public private(set) var deltaDistance: CLLocationDistance
    public private(set) var deltaDistanceAccuracy: CLLocationAccuracy
    public private(set) var speed: CLLocationSpeed
    public private(set) var speedAccuracy: CLLocationSpeedAccuracy
    public private(set) var gpsDate: Date
    public private(set) var deltaAltitude: CLLocationDistance
    public private(set) var verticalAccuracy: CLLocationAccuracy
    public private(set) var originDevice: CMOdometerOriginDevice
    public private(set) var slope: Double?
    public private(set) var maxAbsSlope: Double?

    init(
        startDate: Date,
        endDate: Date,
        deltaDistance: CLLocationDistance,
        deltaDistanceAccuracy: CLLocationAccuracy,
        speed: CLLocationSpeed,
        speedAccuracy: CLLocationSpeedAccuracy,
        gpsDate: Date,
        deltaAltitude: CLLocationDistance,
        verticalAccuracy: CLLocationAccuracy,
        originDevice: CMOdometerOriginDevice,
        slope: Double?,
        maxAbsSlope: Double?
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.deltaDistance = deltaDistance
        self.deltaDistanceAccuracy = deltaDistanceAccuracy
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.gpsDate = gpsDate
        self.deltaAltitude = deltaAltitude
        self.verticalAccuracy = verticalAccuracy
        self.originDevice = originDevice
        self.slope = slope
        self.maxAbsSlope = maxAbsSlope
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostStartDate startDate: Date,
        endDate: Date,
        deltaDistance: CLLocationDistance,
        deltaDistanceAccuracy: CLLocationAccuracy,
        speed: CLLocationSpeed,
        speedAccuracy: CLLocationSpeedAccuracy,
        gpsDate: Date,
        deltaAltitude: CLLocationDistance,
        verticalAccuracy: CLLocationAccuracy,
        originDevice: CMOdometerOriginDevice,
        slope: Double?,
        maxAbsSlope: Double?
    ) {
        self.init(
            startDate: startDate,
            endDate: endDate,
            deltaDistance: deltaDistance,
            deltaDistanceAccuracy: deltaDistanceAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            gpsDate: gpsDate,
            deltaAltitude: deltaAltitude,
            verticalAccuracy: verticalAccuracy,
            originDevice: originDevice,
            slope: slope,
            maxAbsSlope: maxAbsSlope
        )
    }

    public required init?(coder: NSCoder) {
        guard let startDate = coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?,
              let endDate = coder.decodeObject(of: NSDate.self, forKey: "endDate") as Date?,
              let gpsDate = coder.decodeObject(of: NSDate.self, forKey: "gpsDate") as Date?
        else {
            return nil
        }
        self.startDate = startDate
        self.endDate = endDate
        self.gpsDate = gpsDate
        deltaDistance = coder.decodeDouble(forKey: "deltaDistance")
        deltaDistanceAccuracy = coder.decodeDouble(forKey: "deltaDistanceAccuracy")
        speed = coder.decodeDouble(forKey: "speed")
        speedAccuracy = coder.decodeDouble(forKey: "speedAccuracy")
        deltaAltitude = coder.decodeDouble(forKey: "deltaAltitude")
        verticalAccuracy = coder.decodeDouble(forKey: "verticalAccuracy")
        originDevice = CMOdometerOriginDevice(
            rawValue: Int(coder.decodeInt64(forKey: "originDevice"))
        ) ?? .unknown
        if coder.containsValue(forKey: "slope") {
            slope = coder.decodeDouble(forKey: "slope")
        } else {
            slope = nil
        }
        if coder.containsValue(forKey: "maxAbsSlope") {
            maxAbsSlope = coder.decodeDouble(forKey: "maxAbsSlope")
        } else {
            maxAbsSlope = nil
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(startDate as NSDate, forKey: "startDate")
        coder.encode(endDate as NSDate, forKey: "endDate")
        coder.encode(deltaDistance, forKey: "deltaDistance")
        coder.encode(deltaDistanceAccuracy, forKey: "deltaDistanceAccuracy")
        coder.encode(speed, forKey: "speed")
        coder.encode(speedAccuracy, forKey: "speedAccuracy")
        coder.encode(gpsDate as NSDate, forKey: "gpsDate")
        coder.encode(deltaAltitude, forKey: "deltaAltitude")
        coder.encode(verticalAccuracy, forKey: "verticalAccuracy")
        coder.encode(Int64(originDevice.rawValue), forKey: "originDevice")
        if let slope {
            coder.encode(slope, forKey: "slope")
        }
        if let maxAbsSlope {
            coder.encode(maxAbsSlope, forKey: "maxAbsSlope")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMOdometerData(
            startDate: startDate,
            endDate: endDate,
            deltaDistance: deltaDistance,
            deltaDistanceAccuracy: deltaDistanceAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            gpsDate: gpsDate,
            deltaAltitude: deltaAltitude,
            verticalAccuracy: verticalAccuracy,
            originDevice: originDevice,
            slope: slope,
            maxAbsSlope: maxAbsSlope
        )
    }
}

open class CMDyskineticSymptomResult: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public private(set) var startDate: Date
    public private(set) var endDate: Date
    public private(set) var percentUnlikely: Float
    public private(set) var percentLikely: Float

    init(startDate: Date, endDate: Date, percentUnlikely: Float, percentLikely: Float) {
        self.startDate = startDate
        self.endDate = endDate
        self.percentUnlikely = percentUnlikely
        self.percentLikely = percentLikely
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostStartDate startDate: Date,
        endDate: Date,
        percentUnlikely: Float,
        percentLikely: Float
    ) {
        self.init(
            startDate: startDate,
            endDate: endDate,
            percentUnlikely: percentUnlikely,
            percentLikely: percentLikely
        )
    }

    public required init?(coder: NSCoder) {
        guard let startDate = coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?,
              let endDate = coder.decodeObject(of: NSDate.self, forKey: "endDate") as Date?
        else {
            return nil
        }
        self.startDate = startDate
        self.endDate = endDate
        percentUnlikely = coder.decodeFloat(forKey: "percentUnlikely")
        percentLikely = coder.decodeFloat(forKey: "percentLikely")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(startDate as NSDate, forKey: "startDate")
        coder.encode(endDate as NSDate, forKey: "endDate")
        coder.encode(percentUnlikely, forKey: "percentUnlikely")
        coder.encode(percentLikely, forKey: "percentLikely")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMDyskineticSymptomResult(
            startDate: startDate,
            endDate: endDate,
            percentUnlikely: percentUnlikely,
            percentLikely: percentLikely
        )
    }
}

open class CMTremorResult: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public private(set) var startDate: Date
    public private(set) var endDate: Date
    public private(set) var percentUnknown: Float
    public private(set) var percentNone: Float
    public private(set) var percentSlight: Float
    public private(set) var percentMild: Float
    public private(set) var percentModerate: Float
    public private(set) var percentStrong: Float

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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostStartDate startDate: Date,
        endDate: Date,
        percentUnknown: Float,
        percentNone: Float,
        percentSlight: Float,
        percentMild: Float,
        percentModerate: Float,
        percentStrong: Float
    ) {
        self.init(
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

    public required init?(coder: NSCoder) {
        guard let startDate = coder.decodeObject(of: NSDate.self, forKey: "startDate") as Date?,
              let endDate = coder.decodeObject(of: NSDate.self, forKey: "endDate") as Date?
        else {
            return nil
        }
        self.startDate = startDate
        self.endDate = endDate
        percentUnknown = coder.decodeFloat(forKey: "percentUnknown")
        percentNone = coder.decodeFloat(forKey: "percentNone")
        percentSlight = coder.decodeFloat(forKey: "percentSlight")
        percentMild = coder.decodeFloat(forKey: "percentMild")
        percentModerate = coder.decodeFloat(forKey: "percentModerate")
        percentStrong = coder.decodeFloat(forKey: "percentStrong")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(startDate as NSDate, forKey: "startDate")
        coder.encode(endDate as NSDate, forKey: "endDate")
        coder.encode(percentUnknown, forKey: "percentUnknown")
        coder.encode(percentNone, forKey: "percentNone")
        coder.encode(percentSlight, forKey: "percentSlight")
        coder.encode(percentMild, forKey: "percentMild")
        coder.encode(percentModerate, forKey: "percentModerate")
        coder.encode(percentStrong, forKey: "percentStrong")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
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
}

open class CMWaterSubmersionEvent: NSObject, NSSecureCoding, NSCopying {
    public enum State: Int, Sendable, Hashable, BitwiseCopyable {
        case unknown = 0
        case notSubmerged = 1
        case submerged = 2
    }

    public class var supportsSecureCoding: Bool { true }

    public private(set) var date: Date
    public private(set) var state: CMWaterSubmersionEvent.State

    init(date: Date, state: CMWaterSubmersionEvent.State) {
        self.date = date
        self.state = state
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostDate date: Date, state: CMWaterSubmersionEvent.State) {
        self.init(date: date, state: state)
    }

    public required init?(coder: NSCoder) {
        guard let date = coder.decodeObject(of: NSDate.self, forKey: "date") as Date? else {
            return nil
        }
        self.date = date
        state = CMWaterSubmersionEvent.State(
            rawValue: Int(coder.decodeInt64(forKey: "state"))
        ) ?? .unknown
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(date as NSDate, forKey: "date")
        coder.encode(Int64(state.rawValue), forKey: "state")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMWaterSubmersionEvent(date: date, state: state)
    }
}

open class CMWaterSubmersionMeasurement: NSObject, NSSecureCoding, NSCopying {
    public enum DepthState: Int, Sendable, Hashable, BitwiseCopyable {
        case unknown = 0
        case notSubmerged = 1
        case submergedShallow = 2
        case submergedDeep = 3
        case approachingMaxDepth = 4
        case pastMaxDepth = 5
        case sensorDepthError = 6
    }

    public class var supportsSecureCoding: Bool { true }

    public private(set) var date: Date
    public private(set) var depth: Measurement<UnitLength>?
    public private(set) var pressure: Measurement<UnitPressure>?
    public private(set) var surfacePressure: Measurement<UnitPressure>
    public private(set) var submersionState: CMWaterSubmersionMeasurement.DepthState

    init(
        date: Date,
        depth: Measurement<UnitLength>?,
        pressure: Measurement<UnitPressure>?,
        surfacePressure: Measurement<UnitPressure>,
        submersionState: CMWaterSubmersionMeasurement.DepthState
    ) {
        self.date = date
        self.depth = depth
        self.pressure = pressure
        self.surfacePressure = surfacePressure
        self.submersionState = submersionState
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostDate date: Date,
        depth: Measurement<UnitLength>?,
        pressure: Measurement<UnitPressure>?,
        surfacePressure: Measurement<UnitPressure>,
        submersionState: CMWaterSubmersionMeasurement.DepthState
    ) {
        self.init(
            date: date,
            depth: depth,
            pressure: pressure,
            surfacePressure: surfacePressure,
            submersionState: submersionState
        )
    }

    public required init?(coder: NSCoder) {
        guard let date = coder.decodeObject(of: NSDate.self, forKey: "date") as Date? else {
            return nil
        }
        self.date = date
        if coder.containsValue(forKey: "depthMeters") {
            depth = Measurement(value: coder.decodeDouble(forKey: "depthMeters"), unit: .meters)
        } else {
            depth = nil
        }
        if coder.containsValue(forKey: "pressureKPa") {
            pressure = Measurement(
                value: coder.decodeDouble(forKey: "pressureKPa"),
                unit: .kilopascals
            )
        } else {
            pressure = nil
        }
        surfacePressure = Measurement(
            value: coder.decodeDouble(forKey: "surfacePressureKPa"),
            unit: .kilopascals
        )
        submersionState = CMWaterSubmersionMeasurement.DepthState(
            rawValue: Int(coder.decodeInt64(forKey: "submersionState"))
        ) ?? .unknown
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(date as NSDate, forKey: "date")
        if let depth {
            coder.encode(depth.converted(to: .meters).value, forKey: "depthMeters")
        }
        if let pressure {
            coder.encode(pressure.converted(to: .kilopascals).value, forKey: "pressureKPa")
        }
        coder.encode(surfacePressure.converted(to: .kilopascals).value, forKey: "surfacePressureKPa")
        coder.encode(Int64(submersionState.rawValue), forKey: "submersionState")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMWaterSubmersionMeasurement(
            date: date,
            depth: depth,
            pressure: pressure,
            surfacePressure: surfacePressure,
            submersionState: submersionState
        )
    }
}

open class CMWaterTemperature: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public private(set) var date: Date
    public private(set) var temperature: Measurement<UnitTemperature>
    public private(set) var temperatureUncertainty: Measurement<UnitTemperature>

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

    @_spi(OpenUIKitHost)
    public convenience init(
        hostDate date: Date,
        temperature: Measurement<UnitTemperature>,
        temperatureUncertainty: Measurement<UnitTemperature>
    ) {
        self.init(
            date: date,
            temperature: temperature,
            temperatureUncertainty: temperatureUncertainty
        )
    }

    public required init?(coder: NSCoder) {
        guard let date = coder.decodeObject(of: NSDate.self, forKey: "date") as Date? else {
            return nil
        }
        self.date = date
        temperature = Measurement(
            value: coder.decodeDouble(forKey: "temperatureC"),
            unit: .celsius
        )
        temperatureUncertainty = Measurement(
            value: coder.decodeDouble(forKey: "temperatureUncertaintyC"),
            unit: .celsius
        )
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(date as NSDate, forKey: "date")
        coder.encode(temperature.converted(to: .celsius).value, forKey: "temperatureC")
        coder.encode(
            temperatureUncertainty.converted(to: .celsius).value,
            forKey: "temperatureUncertaintyC"
        )
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CMWaterTemperature(
            date: date,
            temperature: temperature,
            temperatureUncertainty: temperatureUncertainty
        )
    }
}

open class CMSensorDataList: NSObject, Sequence {
    public typealias Element = Any

    private let items: [Any]

    public override init() {
        self.items = []
        super.init()
    }

    init(items: [Any]) {
        self.items = items
        super.init()
    }

    public func makeIterator() -> IndexingIterator<[Any]> {
        items.makeIterator()
    }
}
