import XCTest
import UIKit
import Dispatch

/// iPhoneSimulator26.1.sdk UIKit.framework/Headers/UIImage.h:76 declares
/// `NS_SWIFT_SENDABLE @interface UIImage`. NetNewsWire Images
/// SingleFaviconDownloader.swift:102 resumes a CheckedContinuation with an
/// RSImage (= UIImage) from a non-isolated callback, which the Swift 6
/// checker only accepts for a Sendable type.
final class UIImageSendableTests: XCTestCase {
    private func requireSendable<T: Sendable>(_ value: T) -> T { value }

    func testUIImageIsSendableAndCrossesAContinuation() async {
        let image = requireSendable(UIImage(bitmap: Bitmap(width: 2, height: 3), scale: 1))
        let back: UIImage = await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: image)
            }
        }
        XCTAssertTrue(back === image)
        XCTAssertEqual(back.size, CGSize(width: 2, height: 3))
    }
}
