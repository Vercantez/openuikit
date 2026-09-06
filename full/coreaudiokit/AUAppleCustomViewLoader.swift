import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Loader for Apple-bundled Audio Unit custom views. Linux never has those
/// bundles, so `customViewController(for:audioUnit:v3AU:)` returns `nil`.
open class AUAppleCustomViewLoader: NSObject {
    public override init() {
        super.init()
    }

    public func customViewController(
        for componentDescription: AudioComponentDescription,
        audioUnit: AudioUnit,
        v3AU: AUAudioUnit? = nil
    ) -> UIViewController? {
        _ = componentDescription
        _ = audioUnit
        _ = v3AU
        return nil
    }
}
