// Fail-closed stand-in for Lottie 4.5.1 (047aa81b) on route (b).
//
// The pinned Lottie compiles its `canImport(UIKit)` branch against OpenUIKit
// on the macOS target and stops at 169 errors in 24 files (its Core
// Animation rendering engine needs CALayer / CAAnimation surface OpenUIKit
// does not have: `CALayerContentsGravity`, layer `bounds` in 32 extension
// sites, `CAAnimation` overrides; ios-oss-launch2-walls.md). This module
// provides exactly the surface the app calls and PLAYS NOTHING: the view is
// an empty, transparent UIView; `play()` does not start an animation and
// `isAnimationPlaying` stays false. The onboarding illustration band is
// therefore empty — the band the iOS 26.1 golden already has to mask because
// it animates.
//
// Call sites covered (ios-oss 2f2dabb4):
//   LottieAnimationView() / (name:bundle:)   Library OnboardingUseCase.swift:40/46/238
//   .contentMode .loopMode = .loop           Framework ResizableLottieView.swift:11-12
//   .isAnimationPlaying .play() .stop()      Framework ResizableLottieView.swift:17-20
import Foundation
import UIKit

/// Lottie's loop mode.
public enum LottieLoopMode: Hashable {
    case playOnce
    case loop
    case autoReverse
    case `repeat`(Float)
    case repeatBackwards(Float)
}

/// Lottie's animation view. Records its configuration; never animates.
open class LottieAnimationView: UIView {
    /// The animation name the app asked for (nil for the empty initializer).
    public let animationName: String?
    public var loopMode: LottieLoopMode = .playOnce
    public var animationSpeed: CGFloat = 1
    /// Always false: nothing is ever playing.
    public private(set) var isAnimationPlaying = false

    public init(name: String, bundle: Bundle = .main) {
        animationName = name
        super.init(frame: .zero)
        isOpaque = false
    }

    public init() {
        animationName = nil
        super.init(frame: .zero)
        isOpaque = false
    }

    public override init(frame: CGRect) {
        animationName = nil
        super.init(frame: frame)
        isOpaque = false
    }

    public required init?(coder: NSCoder) {
        animationName = nil
        super.init(coder: coder)
    }

    /// Does not start anything (no Lottie renderer on OpenUIKit).
    public func play(completion: ((Bool) -> Void)? = nil) {
        completion?(false)
    }

    public func stop() {}
    public func pause() {}
}
