import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Audio Unit extension view controller. Linux constructs the object and
/// never presents AUv3 chrome.
///
/// https://developer.apple.com/documentation/coreaudiokit/auviewcontroller
open class AUViewController: UIViewController {
    public override init() {
        super.init()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// Generic parameter UI for an `AUAudioUnit`. Linux stores `auAudioUnit` and
/// does not layout parameter clumps or host a remote AUv3 view.
///
/// https://developer.apple.com/documentation/coreaudiokit/augenericviewcontroller
open class AUGenericViewController: UIViewController {
    public var auAudioUnit: AUAudioUnit?

    public override init() {
        super.init()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
