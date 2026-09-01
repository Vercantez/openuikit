import CoreLocation
import Foundation

@_silgen_name("OpenCoreLocationMixedDistance")
private func openCoreLocationMixedDistance() -> Double

@main
struct CoreLocationMixedConsumer {
  static func main() {
    let swiftDistance = CLLocation(latitude: 40.7128, longitude: -74.0060)
      .distance(from: CLLocation(latitude: 51.5074, longitude: -0.1278))
    let objcDistance = openCoreLocationMixedDistance()
    precondition(swiftDistance > 0)
    precondition(abs(swiftDistance - objcDistance) < 0.001)
    print("CORELOCATION_MIXED_ABI_OK c=coordinate,constants,objc swift=module,class identity=one-dylib")
  }
}
