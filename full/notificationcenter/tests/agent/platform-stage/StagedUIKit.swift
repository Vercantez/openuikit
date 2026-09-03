// UNIT FIXTURE ONLY. This file invents UIEdgeInsets, UIVibrancyEffectStyle,
// and UIVibrancyEffect. It is a test-owned lookalike, not guest UIKit, and
// must never be compiled as -module-name UIKit for platform identity evidence.
//
// tests/agent/test_unit_fixture.sh may compile it only when
// NOTIFICATIONCENTER_UNIT_FIXTURE=1. tests/agent/test_platform_identities.sh
// must not consume this file.

#if NOTIFICATIONCENTER_UNIT_FIXTURE
import Foundation

public struct UIEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public static let zero = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

public enum UIVibrancyEffectStyle: Int, Equatable, Hashable, Sendable {
    case label = 0
    case secondaryLabel = 1
    case tertiaryLabel = 2
    case quaternaryLabel = 3
    case fill = 4
    case secondaryFill = 5
    case tertiaryFill = 6
    case separator = 7
}

open class UIVibrancyEffect: NSObject {
    public override init() {
        super.init()
    }
}
#endif
