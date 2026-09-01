@_exported import Foundation

/// The bounded AppKit application surface used by portable macOS-targeted
/// packages.  Linux has no WindowServer, Finder, or native AppKit event loop;
/// APIs that require those services therefore fail closed below.
open class NSApplication: NSObject, @unchecked Sendable {
    public struct ModalResponse: RawRepresentable, Equatable, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let stop = ModalResponse(rawValue: -1000)
        public static let abort = ModalResponse(rawValue: -1001)
        public static let `continue` = ModalResponse(rawValue: -1002)
        public static let alertFirstButtonReturn = ModalResponse(rawValue: 1000)
        public static let alertSecondButtonReturn = ModalResponse(rawValue: 1001)
        public static let alertThirdButtonReturn = ModalResponse(rawValue: 1002)
    }

    public static let shared = NSApplication()

    public static let willBecomeActiveNotification = Notification.Name(
        "NSApplicationWillBecomeActiveNotification"
    )
    public static let willResignActiveNotification = Notification.Name(
        "NSApplicationWillResignActiveNotification"
    )
    public static let didResignActiveNotification = Notification.Name(
        "NSApplicationDidResignActiveNotification"
    )
    public static let didBecomeActiveNotification = Notification.Name(
        "NSApplicationDidBecomeActiveNotification"
    )

    public override init() {
        super.init()
    }
}

open class NSWindow: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class NSButton: NSObject, @unchecked Sendable {
    public let title: String

    public init(title: String) {
        self.title = title
        super.init()
    }
}

/// A headless alert model.  It retains the user-visible strings and button
/// order so callers can inspect their configuration, but never claims that a
/// graphical alert was presented.  If an explicit Cancel button exists,
/// `runModal()` returns that button's Apple-compatible response; otherwise it
/// returns `.abort`.
open class NSAlert: NSObject, @unchecked Sendable {
    public struct Style: RawRepresentable, Equatable, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let warning = Style(rawValue: 0)
        public static let informational = Style(rawValue: 1)
        public static let critical = Style(rawValue: 2)
    }

    public var messageText = ""
    public var informativeText = ""
    public var alertStyle: Style = .warning

    private var storedButtons: [NSButton] = []
    public var buttons: [NSButton] { storedButtons }

    public override init() {
        super.init()
    }

    @discardableResult
    open func addButton(withTitle title: String) -> NSButton {
        let button = NSButton(title: title)
        storedButtons.append(button)
        return button
    }

    open func runModal() -> NSApplication.ModalResponse {
        guard let cancelIndex = storedButtons.firstIndex(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare("cancel") == .orderedSame
        }) else {
            return .abort
        }
        return .init(rawValue: 1000 + cancelIndex)
    }
}

/// Finder/application launching cannot be represented without a desktop
/// integration host.  The shared workspace consequently reports failure and
/// performs no external side effect.
open class NSWorkspace: NSObject, @unchecked Sendable {
    public static let shared = NSWorkspace()

    public override init() {
        super.init()
    }

    open func open(_ url: URL) -> Bool {
        _ = url
        return false
    }

    open func selectFile(
        _ fullPath: String?,
        inFileViewerRootedAtPath rootFullPath: String
    ) -> Bool {
        _ = fullPath
        _ = rootFullPath
        return false
    }
}

/// AppKit font lookup is deliberately unavailable until the portable
/// CoreText registry can vend a stable NSFont identity.  Returning `nil` and
/// an empty inventory lets callers use their existing download/registration
/// fallback without inventing installed fonts.
open class NSFont: NSObject, @unchecked Sendable {
    public let fontName: String
    public let familyName: String?
    public let pointSize: CGFloat

    public init?(name fontName: String, size fontSize: CGFloat) {
        _ = fontName
        _ = fontSize
        return nil
    }

    private init(
        resolvedName: String,
        familyName: String?,
        pointSize: CGFloat
    ) {
        self.fontName = resolvedName
        self.familyName = familyName
        self.pointSize = pointSize
        super.init()
    }
}

open class NSFontManager: NSObject, @unchecked Sendable {
    public static let shared = NSFontManager()

    public var availableFonts: [String] { [] }
    public var availableFontFamilies: [String] { [] }

    public override init() {
        super.init()
    }

    open func availableMembers(ofFontFamily family: String) -> [[Any]]? {
        _ = family
        return nil
    }
}

/// A deterministic extended-sRGB color value.  Unlike window-server APIs,
/// component colors are fully representable on Linux and preserve their
/// values through the SwiftUI compatibility extension.
open class NSColor: NSObject, @unchecked Sendable {
    public let redComponent: CGFloat
    public let greenComponent: CGFloat
    public let blueComponent: CGFloat
    public let alphaComponent: CGFloat

    public override convenience init() {
        self.init(red: 0, green: 0, blue: 0, alpha: 0)
    }

    public init(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat
    ) {
        redComponent = red
        greenComponent = green
        blueComponent = blue
        alphaComponent = alpha
        super.init()
    }

    open func getRed(
        _ red: UnsafeMutablePointer<CGFloat>?,
        green: UnsafeMutablePointer<CGFloat>?,
        blue: UnsafeMutablePointer<CGFloat>?,
        alpha: UnsafeMutablePointer<CGFloat>?
    ) {
        red?.pointee = redComponent
        green?.pointee = greenComponent
        blue?.pointee = blueComponent
        alpha?.pointee = alphaComponent
    }
}
