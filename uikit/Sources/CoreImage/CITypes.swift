import Foundation
import OpenCoreGraphics

public let kCIInputImageKey = "inputImage"
public let kCIInputRadiusKey = "inputRadius"
public let kCIInputColorKey = "inputColor"
public let kCIOutputImageKey = "outputImage"
public let kCIInputBackgroundImageKey = "inputBackgroundImage"
public let kCIInputAmountKey = "inputAmount"

public struct CIFormat: RawRepresentable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public static let RGBA8 = CIFormat(rawValue: 24)
}

public struct CIContextOption: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let workingColorSpace = CIContextOption(rawValue: "kCIContextWorkingColorSpace")
    public static let workingFormat = CIContextOption(rawValue: "kCIContextWorkingFormat")
}

public struct CIImageOption: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let colorSpace = CIImageOption(rawValue: "kCIImageColorSpace")
}

public struct CIImageRepresentationOption: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public class CIColor: NSObject, @unchecked Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public static let black = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let clear = CIColor(red: 0, green: 0, blue: 0, alpha: 0)

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        super.init()
    }

    public convenience init(color: CGColor) {
        self.init(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }

    public convenience init(cgColor color: CGColor) {
        self.init(color: color)
    }
}
