import Foundation
#if canImport(Glibc)
import Glibc
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif

#if !canImport(CoreGraphics)

public struct CGVector: Equatable, Hashable, Sendable {
    public var dx: CGFloat
    public var dy: CGFloat

    public init() {
        dx = 0
        dy = 0
    }

    public init(dx: CGFloat, dy: CGFloat) {
        self.dx = dx
        self.dy = dy
    }
}

public enum CGLineCap: Int, Sendable, Hashable {
    case butt = 0
    case round = 1
    case square = 2
}

public enum CGLineJoin: Int, Sendable, Hashable {
    case miter = 0
    case round = 1
    case bevel = 2
}

public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]? = nil) {
        self.width = max(0, width)
        self.height = max(0, height)
        let count = self.width * self.height * 4
        if let pixels, pixels.count >= count {
            self.pixels = Array(pixels.prefix(count))
        } else {
            self.pixels = [UInt8](repeating: 0, count: count)
        }
    }
}

/// Linux path token. Stores polyline / rect / ellipse commands for CPU queries.
public final class CGPath: @unchecked Sendable {
    public enum Command {
        case move(CGPoint)
        case line(CGPoint)
        case close
    }

    public private(set) var commands: [Command]
    public private(set) var boundingBox: CGRect

    public init() {
        commands = []
        boundingBox = .zero
    }

    public init(rect: CGRect) {
        let p0 = CGPoint(x: rect.minX, y: rect.minY)
        let p1 = CGPoint(x: rect.maxX, y: rect.minY)
        let p2 = CGPoint(x: rect.maxX, y: rect.maxY)
        let p3 = CGPoint(x: rect.minX, y: rect.maxY)
        commands = [.move(p0), .line(p1), .line(p2), .line(p3), .close]
        boundingBox = rect
    }

    public init(ellipseIn rect: CGRect) {
        commands = [.move(CGPoint(x: rect.midX, y: rect.minY))]
        boundingBox = rect
    }

    public init(points: [CGPoint], close: Bool = false) {
        var cmds: [Command] = []
        if let first = points.first {
            cmds.append(.move(first))
            for point in points.dropFirst() {
                cmds.append(.line(point))
            }
            if close { cmds.append(.close) }
        }
        commands = cmds
        boundingBox = SKPathMath.bounds(points)
    }

    public var isEmpty: Bool { commands.isEmpty }

    public func contains(_ point: CGPoint) -> Bool {
        boundingBox.contains(point)
    }
}

enum SKPathMath {
    static func bounds(_ points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func length(_ commands: [CGPath.Command]) -> CGFloat {
        var total: CGFloat = 0
        var current = CGPoint.zero
        var started = false
        for command in commands {
            switch command {
            case .move(let p):
                current = p
                started = true
            case .line(let p):
                if started {
                    total += sk_hypot(p.x - current.x, p.y - current.y)
                }
                current = p
                started = true
            case .close:
                break
            }
        }
        return total
    }
}

#endif

#if !canImport(UIKit)

public enum NSLineBreakMode: Int, Sendable, Hashable {
    case byWordWrapping = 0
    case byCharWrapping = 1
    case byClipping = 2
    case byTruncatingHead = 3
    case byTruncatingTail = 4
    case byTruncatingMiddle = 5
}

open class SKColor: NSObject, NSCopying, @unchecked Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        super.init()
    }

    public convenience init(white: CGFloat, alpha: CGFloat) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        SKColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static let white = SKColor(white: 1, alpha: 1)
    public static let black = SKColor(white: 0, alpha: 1)
    public static let clear = SKColor(white: 0, alpha: 0)
    public static let red = SKColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = SKColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = SKColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let gray = SKColor(white: 0.5, alpha: 1)
}

#else
public typealias SKColor = UIColor
#endif
