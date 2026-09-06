import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Inter-App Audio app switcher. Deprecated on iOS 13 in favor of Audio Unit
/// extension UI. Linux stores `isShowingAppNames` and the last
/// `setOutputAudioUnit` handle. There are no IAA apps, so `contentWidth()`
/// is always `0`.
///
/// https://developer.apple.com/documentation/coreaudiokit/cainterappaudioswitcherview
open class CAInterAppAudioSwitcherView: UIView {
    public var isShowingAppNames: Bool = false
    private var attachedOutputAudioUnit: AudioUnit?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func contentWidth() -> CGFloat {
        0
    }

    public func setOutputAudioUnit(_ au: AudioUnit?) {
        attachedOutputAudioUnit = au
    }

    var hostAttachedOutputAudioUnit: AudioUnit? { attachedOutputAudioUnit }
}

/// Inter-App Audio transport strip. Deprecated on iOS 13. Linux stores
/// `isEnabled` and the color/font properties. `isConnected`, `isPlaying`,
/// and `isRecording` stay false: there is no IAA host. Color/font defaults
/// are Linux host placeholders, not claimed Apple RGB values.
///
/// https://developer.apple.com/documentation/coreaudiokit/cainterappaudiotransportview
open class CAInterAppAudioTransportView: UIView {
    public var isEnabled: Bool = true
    public var labelColor: UIColor = .white
    public var currentTimeLabelFont: UIFont = .systemFont(ofSize: 12)
    public var rewindButtonColor: UIColor = .white
    public var playButtonColor: UIColor = .white
    public var pauseButtonColor: UIColor = .white
    public var recordButtonColor: UIColor = .red
    private var attachedOutputAudioUnit: AudioUnit?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public var isConnected: Bool { false }

    public var isPlaying: Bool { false }

    public var isRecording: Bool { false }

    public func setOutputAudioUnit(_ au: AudioUnit) {
        attachedOutputAudioUnit = au
    }

    var hostAttachedOutputAudioUnit: AudioUnit? { attachedOutputAudioUnit }
}
