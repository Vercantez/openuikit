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
    private var lastPlaybackStyle: PHLivePhotoViewPlaybackStyle = .undefined
    private var playbackActive = false

    public override init() {
        super.init()
    }

    @_spi(OpenUIKitHost)
    public var _lastPlaybackStyle: PHLivePhotoViewPlaybackStyle { lastPlaybackStyle }

    @_spi(OpenUIKitHost)
    public var _playbackActive: Bool { playbackActive }

    open class func livePhotoBadgeImage(
        options badgeOptions: PHLivePhotoBadgeOptions = []
    ) -> UIImage {
        _ = badgeOptions
        return UIImage()
    }

    /// Fail-closed: no Live Photo engine. Records the requested style for
    /// host observation and does not invoke `delegate`. Apple's willBegin/didEnd
    /// timing with a nil `livePhoto` is unobserved (oracle-questions.tsv).
    /// https://developer.apple.com/documentation/photosui/phlivephotoview
    open func startPlayback(with playbackStyle: PHLivePhotoViewPlaybackStyle) {
        lastPlaybackStyle = playbackStyle
        playbackActive = true
    }

    open func stopPlayback() {
        playbackActive = false
        lastPlaybackStyle = .undefined
    }
}

extension PHLivePhoto: Transferable {
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

    /// Linux host: throws inline. Apple's Transferable export is async.
    public func withExportedFile<Result>(
        contentType: UTType?,
        fileHandler: (URL) throws -> Result
    ) throws -> Result {
        _ = contentType
        _ = fileHandler
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.withExportedFile")
    }

    public func export(to destinationDirectory: URL, contentType: UTType?) throws -> URL {
        _ = destinationDirectory
        _ = contentType
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.export")
    }

    public func exported(as contentType: UTType?) throws -> Data {
        _ = contentType
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.exported")
    }

    public convenience init(importing file: URL, contentType: UTType?) throws {
        _ = file
        _ = contentType
        self.init()
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.init(importing:file)")
    }

    public convenience init(importing data: Data, contentType: UTType?) throws {
        _ = data
        _ = contentType
        self.init()
        throw PhotosUIUnavailable.linuxHost(operation: "PHLivePhoto.init(importing:data)")
    }
}
