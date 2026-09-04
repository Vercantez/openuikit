import Foundation

public typealias CGImageSourceAnimationBlock = (
    Int, CGImage, UnsafeMutablePointer<Bool>
) -> Void

public func CGAnimateImageDataWithBlock(
    _ data: CFData,
    _ options: CFDictionary?,
    _ block: @escaping CGImageSourceAnimationBlock
) -> OSStatus {
    _ = options
    guard let source = CGImageSourceCreateWithData(data, options),
          let image = CGImageSourceCreateImageAtIndex(source, 0, options) else {
        return CGImageAnimationStatus.unsupportedFormat.rawValue
    }
    var stop = false
    block(0, image, &stop)
    return 0
}

public func CGAnimateImageAtURLWithBlock(
    _ url: CFURL,
    _ options: CFDictionary?,
    _ block: @escaping CGImageSourceAnimationBlock
) -> OSStatus {
    guard let data = try? Data(contentsOf: url) else {
        return CGImageAnimationStatus.parameterError.rawValue
    }
    return CGAnimateImageDataWithBlock(data, options, block)
}
