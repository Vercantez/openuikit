import Foundation

public struct PHLivePhotoBadgeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static var overContent: PHLivePhotoBadgeOptions { PHLivePhotoBadgeOptions(rawValue: 1 << 0) }
    public static var liveOff: PHLivePhotoBadgeOptions { PHLivePhotoBadgeOptions(rawValue: 1 << 1) }
}

public enum PHLivePhotoViewPlaybackStyle: Int, Hashable, Sendable {
    case undefined = 0
    case full = 1
    case hint = 2
}

public protocol PHLivePhotoViewDelegate: AnyObject {
    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        canBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) -> Bool

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    )

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    )

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        extraMinimumTouchDurationFor touch: UITouch,
        with playbackStyle: PHLivePhotoViewPlaybackStyle
    ) -> TimeInterval
}

extension PHLivePhotoViewDelegate {
    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        canBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) -> Bool {
        _ = livePhotoView
        _ = playbackStyle
        return true
    }

    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        _ = livePhotoView
        _ = playbackStyle
    }

    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        _ = livePhotoView
        _ = playbackStyle
    }

    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        extraMinimumTouchDurationFor touch: UITouch,
        with playbackStyle: PHLivePhotoViewPlaybackStyle
    ) -> TimeInterval {
        _ = livePhotoView
        _ = touch
        _ = playbackStyle
        return 0
    }
}

open class PHLivePhotoView: NSObject {
    public weak var delegate: (any PHLivePhotoViewDelegate)?
    public var livePhoto: PHLivePhoto?
    public var isMuted = false
    public var contentsRect = CGRect.zero
    public let playbackGestureRecognizer = UIGestureRecognizer()

    public override init() {
        super.init()
    }

    open class func livePhotoBadgeImage(
        options badgeOptions: PHLivePhotoBadgeOptions = []
    ) -> UIImage {
        _ = badgeOptions
        return UIImage()
    }

    open func startPlayback(with playbackStyle: PHLivePhotoViewPlaybackStyle) {
        _ = playbackStyle
    }

    open func stopPlayback() {}
}

extension PHLivePhoto {
    public typealias Representation = DataRepresentation<PHLivePhoto>

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) { (_: PHLivePhoto) in Data() }
    }

    public var suggestedFilename: String? { nil }

    public static func exportedContentTypes(
        visibility: TransferRepresentationVisibility = .all
    ) -> [UTType] {
        _ = visibility
        return []
    }

    public func exportedContentTypes(
        _ visibility: TransferRepresentationVisibility = .all
    ) -> [UTType] {
        _ = visibility
        return []
    }

    public func importedContentTypes() -> [UTType] {
        []
    }

    public func withExportedFile<Result>(
        contentType: UTType?,
        fileHandler: (URL) async throws -> Result
    ) async throws -> Result {
        _ = contentType
        _ = fileHandler
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.withExportedFile")
    }

    public func export(to destinationDirectory: URL, contentType: UTType?) async throws -> URL {
        _ = destinationDirectory
        _ = contentType
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.export")
    }

    public func exported(as contentType: UTType?) async throws -> Data {
        _ = contentType
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.exported")
    }

    public convenience init(importing file: URL, contentType: UTType?) async throws {
        _ = file
        _ = contentType
        self.init()
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.init(importing:file)")
    }

    public convenience init(importing data: Data, contentType: UTType?) async throws {
        _ = data
        _ = contentType
        self.init()
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.init(importing:data)")
    }
}
