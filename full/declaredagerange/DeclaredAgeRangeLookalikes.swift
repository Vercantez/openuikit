import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Isolated-host stand-ins for UIKit and SwiftUI types named by the public
/// `DeclaredAgeRange` surface. The sealed host gate compiles this module with
/// Foundation only. When a real UIKit or SwiftUI module is on the link line,
/// these blocks compile out. They are not a Linux UIKit or SwiftUI port and
/// are not a substitute for those dependency-owned types in an integrated
/// guest build.

#if !canImport(UIKit) && !canImport(OpenUIKit)

/// Presenter stand-in for `requestAgeRange(ageGates:_:_:in:)`. Linux never
/// presents system age-range UI.
open class UIViewController: NSObject {
    public override init() {
        super.init()
    }
}

#endif

#if !canImport(SwiftUI)

/// Environment container stand-in for `EnvironmentValues.requestAgeRange`.
/// Linux has no SwiftUI environment; the property still returns a fail-closed
/// ``DeclaredAgeRangeAction``.
public struct EnvironmentValues: Sendable {
    public init() {}
}

#endif
