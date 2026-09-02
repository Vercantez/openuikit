import CoreGraphics
import CoreTransferable
import ExtensionFoundation
import Foundation
import QuickLookThumbnailing
import UIKit
import UniformTypeIdentifiers

/// Compiled by the clean EC2 integration build, not the isolated host gate.
/// Passes genuine CoreGraphics geometry values through public
/// `QLThumbnailGenerator.Request` APIs. Thumbnail image and UTType members
/// stay fail-closed / deferred until those dependency modules are linked.
func quickLookThumbnailingDependencyIdentityProbe() {
    let size = CGSize(width: 32, height: 32)
    let scale: CGFloat = 1
    let url = URL(fileURLWithPath: "/tmp/qlt-dependency-identity")
    let request = QLThumbnailGenerator.Request(
        fileAt: url,
        size: size,
        scale: scale,
        representationTypes: .icon
    )
    _ = request.size
    _ = request.scale
    _ = QLThumbnailGenerator.shared
    _ = QLThumbnailErrorDomain
}
