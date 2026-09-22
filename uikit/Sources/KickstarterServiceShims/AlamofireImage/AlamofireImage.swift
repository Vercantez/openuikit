// Fail-closed stand-in for AlamofireImage 4.3.0 (1eaf3b6c), the UIImageView
// surface ios-oss uses through `.af` (32 call sites in Kickstarter-Framework):
//   imageView.af.cancelImageRequest()                         — 26 sites
//   imageView.af.setImage(withURL:)                           — 6 sites
//   imageView.af.setImage(withURL:placeholderImage:filter:progress:
//     progressQueue:imageTransition:runImageTransitionIfCached:completion:)
//     with `.crossDissolve(0.3)` and `CircleFilter()`  — UIImageView+URL.swift
//
// Why a shim and not the pinned library: upstream's UIImageView extension is
// inside `#if os(iOS) || os(tvOS)`, so on the Darwin host (os(macOS)) the
// real module has none of this surface — the same platform-branch wall as
// Kingfisher. The real `.af` namespace comes from Alamofire's
// AlamofireExtension/AlamofireExtended; the app never imports Alamofire, so
// the shim declares the two itself.
//
// Behaviour: there is no image download. `setImage` does exactly the local
// part the library does before a download (UIImageView+AlamofireImage.swift:
// 283 and 330 at the pin): cancel any active request, then set the
// placeholder if one was given. The download then fails: the image is never
// replaced, filters and transitions never run, and `completion` (if any) is
// called once on the main queue with `.failure`. `cancelImageRequest` has no
// active request to cancel.
//
// Divergences, stated: `completion` receives `Result<UIImage, Error>`, not
// Alamofire's `AFIDataResponse<UIImage>` (every app call passes nil);
// `serializer:` is omitted (never passed); and the UIImage transforms
// (`af.imageRoundedIntoCircle()`, `af.imageAspectScaled(toFit:)`,
// `af.inflate()`, used once in RootTabBarViewController.swift:427-430) are
// NOT provided — they are pixel operations that need an oracle measurement,
// not a service boundary. `CircleFilter.filter` is therefore unimplemented
// and unreachable: the shim never delivers an image to a filter.
import Foundation
import UIKit

public struct AlamofireExtension<ExtendedType> {
    public private(set) var type: ExtendedType
    public init(_ type: ExtendedType) { self.type = type }
}

public protocol AlamofireExtended {
    associatedtype ExtendedType
    var af: AlamofireExtension<ExtendedType> { get set }
}

extension AlamofireExtended {
    public var af: AlamofireExtension<Self> {
        get { AlamofireExtension(self) }
        set {}
    }
}

public typealias Image = UIImage

public protocol ImageFilter {
    var filter: (Image) -> Image { get }
    var identifier: String { get }
}

extension ImageFilter {
    public var identifier: String { String(describing: type(of: self)) }
}

public struct CircleFilter: ImageFilter {
    public init() {}
    public var filter: (Image) -> Image {
        { _ in preconditionFailure("CircleFilter is not implemented by the OpenUIKit AlamofireImage shim") }
    }
}

public enum AFIError: Error {
    case requestCancelled
    /// Not upstream: the shim's download failure.
    case downloadUnavailable
}

extension UIImageView: AlamofireExtended {}

extension UIImageView {
    public enum ImageTransition {
        case noTransition
        case crossDissolve(TimeInterval)
        case curlDown(TimeInterval)
        case curlUp(TimeInterval)
        case flipFromBottom(TimeInterval)
        case flipFromLeft(TimeInterval)
        case flipFromRight(TimeInterval)
        case flipFromTop(TimeInterval)

        public var duration: TimeInterval {
            switch self {
            case .noTransition: return 0
            case let .crossDissolve(d), let .curlDown(d), let .curlUp(d), let .flipFromBottom(d),
                 let .flipFromLeft(d), let .flipFromRight(d), let .flipFromTop(d):
                return d
            }
        }
    }
}

extension AlamofireExtension where ExtendedType: UIImageView {
    public func setImage(
        withURL url: URL,
        cacheKey: String? = nil,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ((Progress) -> Void)? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        imageTransition: UIImageView.ImageTransition = .noTransition,
        runImageTransitionIfCached: Bool = false,
        completion: ((Result<UIImage, Error>) -> Void)? = nil
    ) {
        cancelImageRequest()
        if let placeholderImage { type.image = placeholderImage }
        guard let completion else { return }
        DispatchQueue.main.async { completion(.failure(AFIError.downloadUnavailable)) }
    }

    /// No request is ever active.
    public func cancelImageRequest() {}
}
