import CoreGraphics
import CoreTransferable
import Dispatch
import ExtensionFoundation
import Foundation
import QuickLookThumbnailing
import UIKit
import UniformTypeIdentifiers

private func qltIdentityUnavailable(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

/// Compiled by the clean EC2 integration build, not the isolated host gate.
/// Import-only is not identity evidence. This probe passes genuine dependency
/// values through public QuickLookThumbnailing APIs when those exact seeded
/// members exist, and emits UNAVAILABLE markers when a dependency does not
/// participate in an exposed type or cannot return a real value.
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

    qltIdentityUnavailable("UNAVAILABLE dependency=CoreTransferable exposed-type=none")
    qltIdentityUnavailable("UNAVAILABLE dependency=ExtensionFoundation exposed-type=none")
}
