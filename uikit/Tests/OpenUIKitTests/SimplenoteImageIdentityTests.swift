import Foundation
import XCTest
import UIKit

#if !os(Linux)
import ObjectiveC

private extension UIImage {
    // The same boundary as unmodified Gridicons' two @objc factories.
    @objc(simplenoteIdentityImage)
    static func simplenoteIdentityImage() -> UIImage { UIImage() }
}
#endif

#if !os(Linux)
@MainActor
#endif
final class SimplenoteImageIdentityTests: XCTestCase {
    func testEmptyImageHasNSObjectIdentityAndOracleGeometry() {
        // iPhone 16 / iOS 26.1: NSObject, size (0,0), scale 1.
        let image = UIImage()
        let object: NSObject = image
        XCTAssertTrue(object === image)
        XCTAssertEqual(image.size, .zero)
        XCTAssertEqual(image.scale, 1)
    }

    #if !os(Linux)
    func testImageFactoryIsCallableThroughObjectiveCRuntime() {
        XCTAssertTrue(class_getSuperclass(UIImage.self) == NSObject.self)
        let selector = #selector(UIImage.simplenoteIdentityImage)
        XCTAssertTrue(UIImage.responds(to: selector))
        let result = UIImage.perform(selector)?.takeUnretainedValue()
        XCTAssertTrue(result is UIImage)
    }
    #endif
}
