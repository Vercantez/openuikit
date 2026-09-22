// Fail-closed stand-in for KingfisherWebP 1.7.0 (dccea7e9). The only call
// site is Kickstarter-Framework/Library/UIImageView+URL.swift:46-48:
//   .processor(WebPProcessor.default), .cacheSerializer(WebPSerializer.default)
//
// Why a shim: the real module decodes WebP through libwebp (a C target the
// chain does not build) and encodes through `image.kf.webpRepresentation`.
// This file keeps upstream's non-WebP path verbatim in shape — anything that
// is not RIFF/WEBP data goes to Kingfisher's DefaultImageProcessor /
// DefaultCacheSerializer, exactly as WebPProcessor.swift / WebPSerializer.swift
// do at the pin — and FAILS CLOSED on WebP itself: WebP data decodes to nil
// (no image, the caller's failure path runs) and no WebP data is ever
// produced. Nothing is fabricated.
//
// Kingfisher symbols required (from whatever `Kingfisher` module the chain
// provides): ImageProcessor, CacheSerializer, ImageProcessItem (.image/.data),
// KingfisherParsedOptionsInfo, KFCrossPlatformImage, DefaultImageProcessor
// .default, DefaultCacheSerializer.default.
import Foundation
import Kingfisher

extension Data {
    /// Upstream's check (Image+WebP.swift:173 at the pin).
    public var isWebPFormat: Bool {
        guard count >= 12 else { return false }
        let riff = subdata(in: startIndex..<index(startIndex, offsetBy: 4))
        let webp = subdata(in: index(startIndex, offsetBy: 8)..<index(startIndex, offsetBy: 12))
        return String(data: riff, encoding: .ascii) == "RIFF" && String(data: webp, encoding: .ascii) == "WEBP"
    }
}

public struct WebPProcessor: ImageProcessor {
    public static let `default` = WebPProcessor()
    public let identifier = "com.yeatse.WebPProcessor"
    public init() {}

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            if data.isWebPFormat {
                return nil // no WebP decoder on OpenUIKit
            }
            return DefaultImageProcessor.default.process(item: item, options: options)
        }
    }
}

public struct WebPSerializer: CacheSerializer {
    public static let `default` = WebPSerializer()
    public var originalDataUsed: Bool = true
    private init() {}

    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        if originalDataUsed, let original { return original }
        if let original, !original.isWebPFormat {
            return DefaultCacheSerializer.default.data(with: image, original: original)
        }
        return nil // no WebP encoder on OpenUIKit
    }

    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        WebPProcessor.default.process(item: .data(data), options: options)
    }
}
