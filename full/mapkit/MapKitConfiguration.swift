import Foundation

open class MKMapConfiguration: NSObject {
    public enum ElevationStyle: Int, Hashable, Sendable {
        case flat = 0
        case realistic = 1
    }

    open var elevationStyle: ElevationStyle = .flat

    public override init() {
        super.init()
    }
}

open class MKStandardMapConfiguration: MKMapConfiguration {
    public enum EmphasisStyle: Int, Hashable, Sendable {
        case `default` = 0
        case muted = 1
    }

    open var emphasisStyle: EmphasisStyle = .default
    open var showsTraffic = false
    open var pointOfInterestFilter: MKPointOfInterestFilter?

    public override init() {
        super.init()
    }

    public init(elevationStyle: ElevationStyle) {
        super.init()
        self.elevationStyle = elevationStyle
    }

    public init(emphasisStyle: EmphasisStyle) {
        super.init()
        self.emphasisStyle = emphasisStyle
    }

    public init(elevationStyle: ElevationStyle, emphasisStyle: EmphasisStyle) {
        super.init()
        self.elevationStyle = elevationStyle
        self.emphasisStyle = emphasisStyle
    }
}

open class MKHybridMapConfiguration: MKMapConfiguration {
    open var showsTraffic = false
    open var pointOfInterestFilter: MKPointOfInterestFilter?

    public override init() {
        super.init()
    }

    public init(elevationStyle: ElevationStyle) {
        super.init()
        self.elevationStyle = elevationStyle
    }
}

open class MKImageryMapConfiguration: MKMapConfiguration {
    public override init() {
        super.init()
    }

    public init(elevationStyle: ElevationStyle) {
        super.init()
        self.elevationStyle = elevationStyle
    }
}

open class MKMapCamera: NSObject {
    open var centerMapPoint: MKMapPoint
    open var heading: Double
    open var pitch: CGFloat
    open var altitude: Double
    open var centerCoordinateDistance: Double

    public override init() {
        self.centerMapPoint = MKMapPoint(x: 0, y: 0)
        self.heading = 0
        self.pitch = 0
        self.altitude = 0
        self.centerCoordinateDistance = 0
        super.init()
    }

    public init(
        lookingAtCenterMapPoint centerMapPoint: MKMapPoint,
        fromDistance distance: Double,
        pitch: CGFloat,
        heading: Double
    ) {
        self.centerMapPoint = centerMapPoint
        self.centerCoordinateDistance = distance
        self.altitude = distance
        self.pitch = pitch
        self.heading = heading
        super.init()
    }
}

open class MKIconStyle: NSObject {}
