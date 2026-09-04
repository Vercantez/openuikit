// Stage first-party dependency identities when the guest modules are present.
// This file must not define module-local types that reuse CoreGraphics or UIKit names.

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#elseif canImport(OpenCoreGraphics)
@_exported import OpenCoreGraphics
#endif

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif
