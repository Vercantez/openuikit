// SwiftPM resource accessor for unchanged package sources in the guest build.
import Foundation
extension Foundation.Bundle {
    static let module: Bundle = {
#if FOCUS_DESIGN_SYSTEM
        let name = "FocusDesignSystem"
#else
        let name = "FocusLicenses"
#endif
        guard let bundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent(name + ".bundle")) else {
            preconditionFailure("Missing guest package resource bundle: " + name)
        }
        return bundle
    }()
}
