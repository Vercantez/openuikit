// The Lottie stand-in must never claim to animate.
import Foundation
import XCTest
import Lottie
import UIKit

@MainActor
final class LottieStandInTests: XCTestCase {
    func testPlayStartsNothing() {
        let view = LottieAnimationView(name: "onboarding-flow-welcome", bundle: .main)
        view.loopMode = .loop
        var finished: Bool?
        view.play { finished = $0 }
        XCTAssertFalse(view.isAnimationPlaying)
        XCTAssertEqual(finished, false, "the completion reports an animation that did not finish")
        view.stop()
        XCTAssertFalse(view.isAnimationPlaying)
        XCTAssertEqual(view.animationName, "onboarding-flow-welcome")
        XCTAssertTrue(view.subviews.isEmpty, "no rendered content")
    }

    func testEmptyInitializerIsAnEmptyView() {
        let view = LottieAnimationView()
        XCTAssertNil(view.animationName)
        XCTAssertEqual(view.loopMode, .playOnce)
    }
}
