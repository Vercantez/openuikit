// Portable LinkPresentation metadata model. Linux has no system link-preview
// service, but applications can create, populate, and pass exact metadata
// objects through UIKit activity-item APIs without source changes.

import Foundation

open class LPLinkMetadata: NSObject, @unchecked Sendable {
    open var title: String?
    open var url: URL?
    open var originalURL: URL?
    open var remoteVideoURL: URL?

    public override init() {
        super.init()
    }
}
