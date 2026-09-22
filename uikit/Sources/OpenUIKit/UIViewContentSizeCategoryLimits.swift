// UIView.minimumContentSizeCategory / maximumContentSizeCategory (iOS 15).
// Owner: dynamic type.
//
// iOS 26.1 (Tools/oracle2/iososslibraryprobe `view.*ContentSizeCategory`):
// both are nil on a fresh view and read back what is assigned. ios-oss
// PagedContainerViewController.swift:35 caps its tab bar at `.medium`.
//
// Stored only: OpenUIKit never changes the content size category on its own
// (UIFontMetrics.swift), so a limit has nothing to clamp until a host does;
// the clamping of the view's trait collection is not implemented
// (docs/KNOWN_GAPS.md). Storage is a side table keyed by object identity
// with a weak owner (the NSObjectAccessibility.swift pattern), so the
// UIView class body — being converted by another pass — is not touched.

private final class _ContentSizeLimits {
    weak var owner: UIView?
    var minimum: UIContentSizeCategory?
    var maximum: UIContentSizeCategory?
    init(owner: UIView) { self.owner = owner }
}

@MainActor
private var _contentSizeLimitTable: [ObjectIdentifier: _ContentSizeLimits] = [:]

extension UIView {
    private var _contentSizeLimits: _ContentSizeLimits? {
        guard let entry = _contentSizeLimitTable[ObjectIdentifier(self)], entry.owner === self else { return nil }
        return entry
    }

    private func _contentSizeLimitsForWriting() -> _ContentSizeLimits {
        if let entry = _contentSizeLimits { return entry }
        _contentSizeLimitTable = _contentSizeLimitTable.filter { $0.value.owner != nil }
        let entry = _ContentSizeLimits(owner: self)
        _contentSizeLimitTable[ObjectIdentifier(self)] = entry
        return entry
    }

    public var minimumContentSizeCategory: UIContentSizeCategory? {
        get { _contentSizeLimits?.minimum }
        set { _contentSizeLimitsForWriting().minimum = newValue }
    }

    public var maximumContentSizeCategory: UIContentSizeCategory? {
        get { _contentSizeLimits?.maximum }
        set { _contentSizeLimitsForWriting().maximum = newValue }
    }
}
