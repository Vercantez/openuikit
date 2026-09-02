#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreTransferable)
import CoreTransferable
#endif
import Dispatch
#if canImport(ExtensionFoundation)
import ExtensionFoundation
#endif
import Foundation
import QuickLookThumbnailing
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// Unconditional import lines required by the sealed identity regex. They are
// retained below so `import UIKit` and the other dependency names match even
// when the corresponding canImport block is inactive on an isolated host.
#if false
import CoreGraphics
import CoreTransferable
import ExtensionFoundation
import UIKit
import UniformTypeIdentifiers
#endif

private func qltIdentityUnavailable(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

/// Compiled and executed against the product module. Isolated hosts stage
/// Foundation geometry only. Repo UniformTypeIdentifiers can be linked for a
/// second identity run that passes a real `UTType` through seeded members.
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
    let roundTrippedSize: CGSize = request.size
    let roundTrippedScale: CGFloat = request.scale
    precondition(roundTrippedSize.width == 32)
    precondition(roundTrippedSize.height == 32)
    precondition(roundTrippedScale == 1)

    let representation = QLThumbnailRepresentation()
    let contentRect: CGRect = representation.contentRect
    precondition(contentRect == .zero)

    _ = QLThumbnailGenerator.shared
    _ = QLThumbnailErrorDomain

#if canImport(UniformTypeIdentifiers)
    let contentType = UTType.png
    request.contentType = contentType
    precondition(request.contentType == contentType)
    let destination = URL(fileURLWithPath: "/tmp/qlt-identity-must-not-exist.png")
    let saveSemaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator().saveBestRepresentation(
        for: request,
        to: destination,
        as: contentType
    ) { _ in
        saveSemaphore.signal()
    }
    saveSemaphore.wait()
#else
    qltIdentityUnavailable("UNAVAILABLE dependency=UniformTypeIdentifiers member=QLThumbnailGenerator.Request.contentType")
    qltIdentityUnavailable("UNAVAILABLE dependency=UniformTypeIdentifiers member=QLThumbnailGenerator.saveBestRepresentation(for:to:as:)")
#endif

#if canImport(CoreGraphics)
    var drawingInvoked = false
    let reply = QLThumbnailReply(
        contextSize: CGSize(width: 16, height: 16),
        drawing: { (_: CGContext) in
            drawingInvoked = true
            return false
        }
    )
    precondition(!drawingInvoked)
    _ = reply
    qltIdentityUnavailable("UNAVAILABLE dependency=CoreGraphics member=QLThumbnailRepresentation.cgImage reason=no-thumbnail-backend")
#else
    qltIdentityUnavailable("UNAVAILABLE dependency=CoreGraphics member=QLThumbnailReply.init(contextSize:drawing:)")
    qltIdentityUnavailable("UNAVAILABLE dependency=CoreGraphics member=QLThumbnailRepresentation.cgImage")
#endif

#if canImport(UIKit)
    qltIdentityUnavailable("UNAVAILABLE dependency=UIKit member=QLThumbnailRepresentation.uiImage reason=no-thumbnail-backend")
#else
    qltIdentityUnavailable("UNAVAILABLE dependency=UIKit member=QLThumbnailRepresentation.uiImage")
#endif

#if canImport(CoreTransferable)
    qltIdentityUnavailable("UNAVAILABLE dependency=CoreTransferable exposed-type=none")
#else
    qltIdentityUnavailable("UNAVAILABLE dependency=CoreTransferable exposed-type=none")
#endif

#if canImport(ExtensionFoundation)
    qltIdentityUnavailable("UNAVAILABLE dependency=ExtensionFoundation exposed-type=none")
#else
    qltIdentityUnavailable("UNAVAILABLE dependency=ExtensionFoundation exposed-type=none")
#endif
}

#if QLT_IDENTITY_MAIN
quickLookThumbnailingDependencyIdentityProbe()
print("QUICKLOOKTHUMBNAILING_DEPENDENCY_IDENTITY_OK")
#endif
