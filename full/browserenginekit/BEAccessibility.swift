import Foundation
#if canImport(Glibc)
import Glibc
#endif

public final class BEAccessibilityTextMarker: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return BEAccessibilityTextMarker()
    }

    public final class Range: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public static var supportsSecureCoding: Bool { true }

        public var startMarker: BEAccessibilityTextMarker
        public var endMarker: BEAccessibilityTextMarker

        public override init() {
            startMarker = BEAccessibilityTextMarker()
            endMarker = BEAccessibilityTextMarker()
            super.init()
        }

        public required init?(coder: NSCoder) {
            startMarker = BEAccessibilityTextMarker()
            endMarker = BEAccessibilityTextMarker()
            super.init()
            _ = coder
        }

        public func encode(with coder: NSCoder) {
            _ = coder
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            let copy = Range()
            copy.startMarker = startMarker
            copy.endMarker = endMarker
            return copy
        }
    }
}

public protocol BEAccessibilityTextMarkerSupport: NSObjectProtocol {
    func accessibilityBounds(for range: BEAccessibilityTextMarker.Range) -> CGRect
    func accessibilityContent(for range: BEAccessibilityTextMarker.Range) -> String?
    func accessibilityLineEndMarker(for marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker?
    func accessibilityLineStartMarker(for marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker?
    func accessibilityMarker(for point: CGPoint) -> BEAccessibilityTextMarker?
    func accessibilityNextTextMarker(_ marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker?
    func accessibilityPreviousTextMarker(_ marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker?
    func accessibilityRange(for range: BEAccessibilityTextMarker.Range) -> NSRange
    func accessibilityTextMarker(forPosition position: Int) -> BEAccessibilityTextMarker?
    func accessibilityTextMarkerRange() -> BEAccessibilityTextMarker.Range
    func accessibilityTextMarkerRangeForCurrentSelection() -> BEAccessibilityTextMarker.Range?
    func accessibilityTextMarkerRange(for range: NSRange) -> BEAccessibilityTextMarker.Range?
}

public final class BEAccessibilityRemoteElement: NSObject, @unchecked Sendable {
    public let identifier: String
    public let hostPid: pid_t

    public init(identifier: String, hostPid: pid_t) {
        self.identifier = identifier
        self.hostPid = hostPid
        super.init()
    }
}

public final class BEAccessibilityRemoteHostElement: NSObject, @unchecked Sendable {
    public let identifier: String
    public let remotePid: pid_t
    public weak var accessibilityContainer: AnyObject?

    public init(identifier: String, remotePid: pid_t) {
        self.identifier = identifier
        self.remotePid = remotePid
        super.init()
    }
}

private final class BrowserAccessibilityState {
    var currentStatus: String?
    var sortDirection: String?
    var roleDescription: String?
    var isRequired = false
    var pressedState: BEAccessibilityPressedState = .undefined
    var hasDOMFocus = false
    var containerType = BEAccessibilityContainerType()
    var selectedTextRange = NSRange(location: 0, length: 0)
    var backingValue = ""
}

private let accessibilityLock = NSLock()
private var accessibilityState: [ObjectIdentifier: BrowserAccessibilityState] = [:]

extension NSObject {
    private func bek_axState() -> BrowserAccessibilityState {
        accessibilityLock.lock()
        defer { accessibilityLock.unlock() }
        let key = ObjectIdentifier(self)
        if let existing = accessibilityState[key] {
            return existing
        }
        let created = BrowserAccessibilityState()
        accessibilityState[key] = created
        return created
    }

    public var browserAccessibilityContainerType: BEAccessibilityContainerType {
        get { bek_axState().containerType }
        set { bek_axState().containerType = newValue }
    }

    public var browserAccessibilityCurrentStatus: String? {
        get { bek_axState().currentStatus }
        set { bek_axState().currentStatus = newValue }
    }

    public var browserAccessibilityHasDOMFocus: Bool {
        get { bek_axState().hasDOMFocus }
        set { bek_axState().hasDOMFocus = newValue }
    }

    public var browserAccessibilityIsRequired: Bool {
        get { bek_axState().isRequired }
        set { bek_axState().isRequired = newValue }
    }

    public var browserAccessibilityPressedState: BEAccessibilityPressedState {
        get { bek_axState().pressedState }
        set { bek_axState().pressedState = newValue }
    }

    public var browserAccessibilityRoleDescription: String? {
        get { bek_axState().roleDescription }
        set { bek_axState().roleDescription = newValue }
    }

    public var browserAccessibilitySortDirection: String? {
        get { bek_axState().sortDirection }
        set { bek_axState().sortDirection = newValue }
    }

    public func browserAccessibilitySelectedTextRange() -> NSRange {
        bek_axState().selectedTextRange
    }

    public func browserAccessibilitySetSelectedTextRange(_ range: NSRange) {
        bek_axState().selectedTextRange = range
    }

    public func browserAccessibilityValue(in range: NSRange) -> String {
        let value = bek_axState().backingValue as NSString
        let length = value.length
        guard range.location != NSNotFound, range.location >= 0 else { return "" }
        let loc = min(range.location, length)
        let len = max(0, min(range.length, length - loc))
        return value.substring(with: NSRange(location: loc, length: len))
    }

    public func browserAccessibilityAttributedValue(in range: NSRange) -> NSAttributedString {
        NSAttributedString(string: browserAccessibilityValue(in: range))
    }

    public func browserAccessibilityInsertTextAtCursor(text: String) {
        bek_axState().backingValue += text
    }

    public func browserAccessibilityDeleteTextAtCursor(numberOfCharacters: Int) {
        let state = bek_axState()
        let count = max(0, numberOfCharacters)
        if state.backingValue.count <= count {
            state.backingValue = ""
        } else {
            state.backingValue = String(state.backingValue.dropLast(count))
        }
    }

    public func accessibilityLineEndPositionFromCurrentSelection() -> Int {
        NSNotFound
    }

    public func accessibilityLineStartPositionFromCurrentSelection() -> Int {
        NSNotFound
    }

    public func accessibilityLineRange(forPosition position: Int) -> NSRange {
        _ = position
        return NSRange(location: NSNotFound, length: 0)
    }
}
