import CoreFoundation
import Foundation

/// Flashing-lights mitigation requires IOSurface pixel processing. Linux
/// reports that it cannot process surfaces and never claims mitigation.
open class MAFlashingLightsProcessor: NSObject {
    public override init() {
        super.init()
    }

    public struct OptionKey: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct Result: Sendable {
        public let surfaceProcessed: Bool
        public let mitigationLevel: Float
        public let intensityLevel: Float

        init(surfaceProcessed: Bool, mitigationLevel: Float, intensityLevel: Float) {
            self.surfaceProcessed = surfaceProcessed
            self.mitigationLevel = mitigationLevel
            self.intensityLevel = intensityLevel
        }
    }

    public func canProcessSurface(_ surface: IOSurfaceRef) -> Bool {
        _ = surface
        return false
    }

    public func processSurface(
        _ inSurface: IOSurfaceRef,
        outSurface: inout IOSurfaceRef,
        timestamp: CFAbsoluteTime,
        options: [MAFlashingLightsProcessor.OptionKey: Any]? = nil
    ) -> MAFlashingLightsProcessor.Result {
        _ = inSurface
        _ = outSurface
        _ = timestamp
        _ = options
        return Result(surfaceProcessed: false, mitigationLevel: 0, intensityLevel: 0)
    }
}

public func MADimFlashingLightsEnabled() -> Bool {
    false
}
