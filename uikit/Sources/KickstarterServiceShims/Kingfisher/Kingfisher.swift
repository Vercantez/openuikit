// Fail-closed stand-in for Kingfisher 8.5.0 (2015fda7) on route (b).
//
// Why a stand-in and not the real library: Kingfisher chooses its platform
// with `#if os(macOS)` (56 sites) — on the macOS target the Apple toolchain
// builds for, `KFCrossPlatformImage` is `NSImage`, the view extensions are
// `NSImageView`/`NSButton`, and `KFImage` is an `NSViewRepresentable`. A
// compiler flag cannot change `os()`, and editing the pinned source is not
// allowed, so the iOS branch the app is written against cannot be compiled
// here (ios-oss-launch.md measured 69 errors; ios-oss-launch2-walls.md keeps
// that wall OPEN). This module provides exactly the Kingfisher surface the
// app and KingfisherWebP call, with the same names and shapes, and it never
// produces an image: every download or prefetch fails, and every caller
// sees what it would see offline (the placeholder stays up).
//
// Call sites covered (ios-oss 2f2dabb4):
//   Kingfisher.Source .network(URL)          Library ProjectCardProperties(+Parsing),
//                                            SimilarProjectsCardViewModel,
//                                            Framework PPOProjectCardModel(+Parsing)
//   KFImage(URL?) / KFImage(source:)         Framework PPOProjectDetails,
//     .placeholder { } .resizable() .fade()  VideoFeedShareSheetView / OverlayView /
//                                            RightRailView
//   KFAnimatedImage(URL?) .placeholder { _ in }  ServerDrivenUI ImageBlock
//   AnimatedImageView                        Framework GIFAnimatedImageView
//   KingfisherOptionsInfo .processor / .cacheSerializer, ImagePrefetcher,
//   ImageCache.default.retrieveImage, ImageDownloader.default.cancelAll
//                                            Framework UIImageView+URL.swift
//   ImageProcessor, CacheSerializer, ImageProcessItem,
//   KingfisherParsedOptionsInfo, KFCrossPlatformImage, DefaultImageProcessor,
//   DefaultCacheSerializer                   KingfisherWebP stand-in
import Foundation
import SwiftUI
import UIKit

public typealias KFCrossPlatformImage = UIImage
public typealias KFCrossPlatformImageView = UIImageView

// MARK: - Resources and sources

/// Kingfisher's `Resource`: something with a cache key and a download URL.
public protocol Resource {
    var cacheKey: String { get }
    var downloadURL: URL { get }
}

extension URL: Resource {
    public var cacheKey: String { absoluteString }
    public var downloadURL: URL { self }
}

/// Kingfisher's `Source`. Only `.network` is used by the app.
public enum Source {
    case network(any Resource)

    public var url: URL? {
        switch self {
        case .network(let r): return r.downloadURL
        }
    }

    public var cacheKey: String {
        switch self {
        case .network(let r): return r.cacheKey
        }
    }
}

// MARK: - Errors

/// Every operation that would reach the network reports this.
public enum KingfisherError: Error {
    /// OpenUIKit route (b) has no Kingfisher: nothing is downloaded.
    case unavailableOnOpenUIKit(URL?)
}

// MARK: - Processing / serialisation (the KingfisherWebP contract)

public enum ImageProcessItem {
    case image(KFCrossPlatformImage)
    case data(Data)
}

/// The parsed options a processor receives. The stand-in carries none of
/// Kingfisher's tuning; it exists so processors keep their signature.
public struct KingfisherParsedOptionsInfo {
    public init(_ info: KingfisherOptionsInfo?) {}
}

public protocol ImageProcessor {
    var identifier: String { get }
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
}

public protocol CacheSerializer {
    func data(with image: KFCrossPlatformImage, original: Data?) -> Data?
    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
}

/// Upstream's default processor: decode data with the platform decoder.
public struct DefaultImageProcessor: ImageProcessor {
    public static let `default` = DefaultImageProcessor()
    public let identifier = ""
    public init() {}
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image): return image
        case .data(let data): return UIImage(data: data)
        }
    }
}

/// Upstream's default serializer: keep the original bytes, else PNG.
public struct DefaultCacheSerializer: CacheSerializer {
    public static let `default` = DefaultCacheSerializer()
    public init() {}
    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        original ?? image.pngData().map { Data($0) }
    }
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        UIImage(data: data)
    }
}

public enum KingfisherOptionsInfoItem {
    case processor(any ImageProcessor)
    case cacheSerializer(any CacheSerializer)
    case forceRefresh
    case cacheOriginalImage
}

public typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]

// MARK: - Cache / downloader / prefetcher

public enum CacheType {
    case none, memory, disk
}

/// Kingfisher's `ImageCacheResult`.
public enum ImageCacheResult {
    case disk(KFCrossPlatformImage)
    case memory(KFCrossPlatformImage)
    case none

    public var image: KFCrossPlatformImage? {
        switch self {
        case .disk(let i), .memory(let i): return i
        case .none: return nil
        }
    }
}

public final class ImageCache: @unchecked Sendable {
    public static let `default` = ImageCache()
    private init() {}

    /// The cache is always empty: nothing was ever downloaded. Kingfisher
    /// reports a miss as `.success(.none)`, and so does this.
    public func retrieveImage(forKey key: String, options: KingfisherOptionsInfo? = nil,
                              callbackQueue: DispatchQueue = .main,
                              completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?) {
        callbackQueue.async { completionHandler?(.success(.none)) }
    }
}

public final class ImageDownloader: @unchecked Sendable {
    public static let `default` = ImageDownloader()
    private init() {}
    /// Nothing is ever in flight.
    public func cancelAll() {}
}

/// Kingfisher's prefetcher. `start()` reports every resource as failed.
public final class ImagePrefetcher {
    public typealias PrefetcherCompletionHandler =
        ((_ skippedResources: [any Resource], _ failedResources: [any Resource],
          _ completedResources: [any Resource]) -> Void)

    private let resources: [any Resource]
    private let completionHandler: PrefetcherCompletionHandler?

    public init(resources: [any Resource], options: KingfisherOptionsInfo? = nil,
                progressBlock: Any? = nil, completionHandler: PrefetcherCompletionHandler? = nil) {
        self.resources = resources
        self.completionHandler = completionHandler
    }

    public init(urls: [URL], options: KingfisherOptionsInfo? = nil,
                completionHandler: PrefetcherCompletionHandler? = nil) {
        self.resources = urls
        self.completionHandler = completionHandler
    }

    public func start() {
        let failed = resources
        let done = completionHandler
        DispatchQueue.main.async { done?([], failed, []) }
    }

    public func stop() {}
}

// MARK: - UIKit views

/// Kingfisher's GIF-capable image view. Without Kingfisher's decoder it is a
/// plain image view (it still shows any image assigned to it directly).
open class AnimatedImageView: UIImageView {}

// MARK: - SwiftUI views

/// Kingfisher's `KFImage`: shows its placeholder (or nothing) and never
/// loads, because the download fails closed.
public struct KFImage: View {
    let source: Source?
    var placeholderView: AnyView?
    var isResizable = false

    public init(source: Source?) { self.source = source }
    public init(_ url: URL?) { self.source = url.map { .network($0) } }

    public var body: some View {
        if let placeholderView { placeholderView } else { Color.clear }
    }

    public func placeholder<P: View>(@ViewBuilder _ content: () -> P) -> KFImage {
        var copy = self
        copy.placeholderView = AnyView(content())
        return copy
    }

    public func placeholder<P: View>(@ViewBuilder _ content: @escaping (Progress) -> P) -> KFImage {
        var copy = self
        copy.placeholderView = AnyView(content(Progress(totalUnitCount: 0)))
        return copy
    }

    /// Stored: applies to the loaded image, and none ever loads. (Upstream
    /// also takes `resizingMode: Image.ResizingMode`, which OpenUIKit's
    /// SwiftUI does not declare; the app calls `.resizable()` only.)
    public func resizable(capInsets: EdgeInsets = EdgeInsets()) -> KFImage {
        var copy = self
        copy.isResizable = true
        return copy
    }

    /// No image ever arrives, so there is nothing to fade in.
    public func fade(duration: TimeInterval) -> KFImage { self }
}

/// Kingfisher's animated-image SwiftUI view; same fail-closed rule.
public struct KFAnimatedImage: View {
    let source: Source?
    var placeholderView: AnyView?

    public init(source: Source?) { self.source = source }
    public init(_ url: URL?) { self.source = url.map { .network($0) } }

    public var body: some View {
        if let placeholderView { placeholderView } else { Color.clear }
    }

    public func placeholder<P: View>(@ViewBuilder _ content: @escaping (Progress) -> P) -> KFAnimatedImage {
        var copy = self
        copy.placeholderView = AnyView(content(Progress(totalUnitCount: 0)))
        return copy
    }

    public func placeholder<P: View>(@ViewBuilder _ content: () -> P) -> KFAnimatedImage {
        var copy = self
        copy.placeholderView = AnyView(content())
        return copy
    }
}
