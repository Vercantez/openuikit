import Foundation

public class CIColor: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let componentBuffer: UnsafeMutablePointer<CGFloat>
    public let numberOfComponents: Int
    public let colorSpace: CGColorSpace

    public var red: CGFloat { componentBuffer[0] }
    public var green: CGFloat { numberOfComponents > 1 ? componentBuffer[1] : 0 }
    public var blue: CGFloat { numberOfComponents > 2 ? componentBuffer[2] : 0 }
    public var alpha: CGFloat { numberOfComponents > 3 ? componentBuffer[3] : 1 }

    public var components: UnsafePointer<CGFloat> {
        UnsafePointer(componentBuffer)
    }

    public var stringRepresentation: String {
        (0..<numberOfComponents).map {
            String(format: "%.6g", Double(componentBuffer[$0]))
        }.joined(separator: " ")
    }

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.numberOfComponents = 4
        self.colorSpace = .sRGB
        let buffer = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
        buffer[0] = red
        buffer[1] = green
        buffer[2] = blue
        buffer[3] = alpha
        self.componentBuffer = buffer
        super.init()
    }

    deinit {
        componentBuffer.deallocate()
    }

    public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    public convenience init?(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat,
        colorSpace: CGColorSpace
    ) {
        self.init(red: red, green: green, blue: blue, alpha: alpha)
        _ = colorSpace
    }

    public convenience init?(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        colorSpace: CGColorSpace
    ) {
        self.init(red: red, green: green, blue: blue, alpha: 1, colorSpace: colorSpace)
    }

    public init(cgColor color: CGColor) {
        self.numberOfComponents = 4
        self.colorSpace = color.colorSpace
        let buffer = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
        buffer[0] = color.red
        buffer[1] = color.green
        buffer[2] = color.blue
        buffer[3] = color.alpha
        self.componentBuffer = buffer
        super.init()
    }

    public convenience init(CGColor color: CGColor) {
        self.init(cgColor: color)
    }

    public convenience init(string representation: String) {
        let parts = representation.split(whereSeparator: { $0 == " " || $0 == "," })
            .compactMap { CGFloat(Double($0) ?? 0) }
        let r = parts.count > 0 ? parts[0] : 0
        let g = parts.count > 1 ? parts[1] : 0
        let b = parts.count > 2 ? parts[2] : 0
        let a = parts.count > 3 ? parts[3] : 1
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public static let black = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let gray = CIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    public static let red = CIColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = CIColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = CIColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let cyan = CIColor(red: 0, green: 1, blue: 1, alpha: 1)
    public static let magenta = CIColor(red: 1, green: 0, blue: 1, alpha: 1)
    public static let yellow = CIColor(red: 1, green: 1, blue: 0, alpha: 1)
    public static let clear = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
}
