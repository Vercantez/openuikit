import Foundation
import ARKit

func testSessionFailClosedIO() {
    ARKitTestHook.removeSimulatedDevice()
    let session = ARSession()
    arkitWait { done in
        session.captureHighResolutionFrame { frame, error in
            arkitRequire(frame == nil, "no hi-res frame")
            arkitRequire((error as? ARError)?.code == .unsupportedConfiguration, "hi-res code")
            done()
        }
    }
    let worldError = arkitAwaitError { _ = try await session.currentWorldMap() }
    arkitRequire((worldError as? ARError)?.code == .unsupportedConfiguration, "world map idle")
    let objectError = arkitAwaitError {
        _ = try await session.createReferenceObject(
            transform: .identity,
            center: simd_float3(repeating: 0),
            extent: simd_float3(repeating: 1)
        )
    }
    arkitRequire((objectError as? ARError)?.code == .unsupportedConfiguration, "create object")
}

func testSimulatedSessionWorldMapStillFailClosed() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }
    let session = ARSession()
    session.run(ARWorldTrackingConfiguration())
    let worldError = arkitAwaitError { _ = try await session.currentWorldMap() }
    arkitRequire((worldError as? ARError)?.code == .invalidWorldMap, "invalidWorldMap")
    let captureError = arkitAwaitError { _ = try await session.captureHighResolutionFrame(using: nil) }
    arkitRequire((captureError as? ARError)?.code == .unsupportedConfiguration, "hi-res using")
    let geoError = arkitAwaitError { _ = try await session.geoLocation(forPoint: simd_float3(repeating: 0)) }
    arkitRequire((geoError as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "geo location")
}

func testGeoAvailabilityFailClosed() {
    arkitWait { done in
        ARGeoTrackingConfiguration.checkAvailability { available, error in
            arkitRequire(!available, "availability")
            arkitRequire((error as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "geo error")
            done()
        }
    }
    arkitWait { done in
        ARGeoTrackingConfiguration.checkAvailability(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)) { available, error in
            arkitRequire(!available, "coord availability")
            arkitRequire((error as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "coord error")
            done()
        }
    }
}
