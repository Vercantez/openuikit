// Which modules does Apple's `import UIKit` make visible? (NetNewsWire
// RSCore/RSImage.swift imports only Foundation, UniformTypeIdentifiers, os
// and UIKit, then uses CGContext, CGBitmapInfo and CGImageSource*/
// CGImageDestination* from ImageIO.)
//
// swiftc -typecheck -target arm64-apple-ios26.1-simulator \
//   -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" probe.swift
import Foundation
import UIKit

func probe(_ data: Data, _ image: UIImage) {
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)
    _ = context
    _ = image.cgImage
    let source = CGImageSourceCreateWithData(data as CFData, nil)
    _ = source.map { CGImageSourceGetCount($0) }
    _ = kCGImagePropertyPixelWidth
    _ = kCGImageSourceThumbnailMaxPixelSize
    let out = NSMutableData()
    _ = CGImageDestinationCreateWithData(out as CFMutableData, "public.png" as CFString, 1, nil)
    _ = "abc".boundingRect(with: CGSize(width: 10, height: 10), options: [.usesLineFragmentOrigin, .usesFontLeading],
                           attributes: [.font: UIFont.systemFont(ofSize: 12)], context: nil)
    _ = CALayer()               // QuartzCore
}
