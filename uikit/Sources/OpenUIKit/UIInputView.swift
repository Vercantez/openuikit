// UIInputView descriptors measured with Tools/oracle2/inputviewprobe/main.swift
// on iPhone 16 / iOS 26.1, 393 x 852 @3x; retained output:
// fixtures/oracles/inputview-ios26.1.json.
// The host has no input-view keyboard presenter or click-audio backend.

#if canImport(Foundation)
import Foundation
#endif

public enum UIInputViewStyle: Int, Sendable {
    // MEASURED `init.detached`, `frame.detached`, `default.detached` and
    // `keyboard.detached`: styles 0, 0, 0 and 1, respectively.
    case `default` = 0
    case keyboard = 1
}

@preconcurrency @MainActor
open class UIInputView: UIView {
    public typealias Style = UIInputViewStyle
    public let inputViewStyle: Style

    // MEASURED all four initializer samples: false initially, true after
    // assignment; intrinsicContentSize remains (-1,-1), and sizeThatFits
    // remains the bounds size for both (0,0) and (400,200) proposals. A host
    // keyboard presenter is required for this flag to change keyboard size.
    public var allowsSelfSizing = false

    public init(frame: CGRect, inputViewStyle: Style) {
        self.inputViewStyle = inputViewStyle
        super.init(frame: frame)
        // MEASURED frames (0,0,0,0), (4,6,140,70), (20,150,300,80) are
        // unchanged; background=nil, opaque=true, clips=false, matching the
        // existing UIView defaults. UIKit's private keyboard content views
        // and keyboard-style material are not reproduced by this descriptor.
    }

    public override convenience init(frame: CGRect) {
        self.init(frame: frame, inputViewStyle: .default)
    }

    public required init?(coder: NSCoder) {
        // Fail closed: no carried UIInputView archive oracle or decoder.
        return nil
    }
}

@preconcurrency @MainActor
public protocol UIInputViewAudioFeedback: AnyObject {
    var enableInputClicksWhenVisible: Bool { get }
}

public extension UIInputViewAudioFeedback {
    // MEASURED `audioFeedback`: a conformance with no optional getter returns
    // nil through UIKit's protocol, while an explicit true getter returns
    // true. Swift default requirements express the absent capability as
    // false; no enabling audio behavior is inferred from conformance alone.
    var enableInputClicksWhenVisible: Bool { false }
}

public extension UIDevice {
    func playInputClick() {
        // MEASURED `playInputClick`: two simulator calls return normally.
        // No audible result was measured; without a host audio backend this
        // remains silent and reports no fabricated playback success.
    }
}
