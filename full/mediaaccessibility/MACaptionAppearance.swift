import CoreFoundation
import Foundation

/// Process-local caption appearance. Linux has no Accessibility Settings
/// daemon and does not read Apple's system caption profile.
final class _MACaptionStore: @unchecked Sendable {
    static let shared = _MACaptionStore()

    static let defaultProfileID = "default"
    static let defaultProfileName = "Default"

    struct Color {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
    }

    struct DomainState {
        var selectedLanguages: [String] = []
        var displayType: MACaptionAppearanceDisplayType = .forcedOnly
        var customized = false
        var foreground = Color(red: 1, green: 1, blue: 1, alpha: 1)
        var background = Color(red: 0, green: 0, blue: 0, alpha: 1)
        var window = Color(red: 0, green: 0, blue: 0, alpha: 1)
        var foregroundOpacity: CGFloat = 1
        var backgroundOpacity: CGFloat = 0
        var windowOpacity: CGFloat = 0
        var relativeCharacterSize: CGFloat = 1
        var textEdgeStyle: MACaptionAppearanceTextEdgeStyle = .undefined
        var windowRoundedCornerRadius: CGFloat = 0
    }

    let lock = NSLock()
    var domains: [MACaptionAppearanceDomain: DomainState] = [
        .default: DomainState(),
        .user: DomainState(),
    ]
    var profileNames: [String: String] = [defaultProfileID: defaultProfileName]
    var profileOrder: [String] = [defaultProfileID]
    var activeProfileID = defaultProfileID
    var lastDisplayedCaptions: [String] = []

    func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    func state(for domain: MACaptionAppearanceDomain) -> DomainState {
        domains[domain] ?? DomainState()
    }

    func update(_ domain: MACaptionAppearanceDomain, _ mutate: (inout DomainState) -> Void) {
        var current = state(for: domain)
        mutate(&current)
        domains[domain] = current
    }
}

func _maWriteBehavior(_ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?) {
    behavior?.pointee = .useValue
}

/// Restores process-local caption state. Not an Apple API; used by focused tests
/// so sequential sealed-runner invocations do not leak prior mutations.
public func MAResetProcessLocalStateForTesting() {
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.domains = [
            .default: _MACaptionStore.DomainState(),
            .user: _MACaptionStore.DomainState(),
        ]
        _MACaptionStore.shared.profileNames = [
            _MACaptionStore.defaultProfileID: _MACaptionStore.defaultProfileName
        ]
        _MACaptionStore.shared.profileOrder = [_MACaptionStore.defaultProfileID]
        _MACaptionStore.shared.activeProfileID = _MACaptionStore.defaultProfileID
        _MACaptionStore.shared.lastDisplayedCaptions = []
    }
}

public func MACaptionAppearanceAddSelectedLanguage(
    _ domain: MACaptionAppearanceDomain,
    _ language: CFString
) -> Bool {
    let tag = _maString(language)
    guard !tag.isEmpty else { return false }
    let added = _MACaptionStore.shared.withLock { () -> Bool in
        _MACaptionStore.shared.update(domain) { state in
            if !state.selectedLanguages.contains(tag) {
                state.selectedLanguages.append(tag)
            }
            state.customized = true
        }
        return true
    }
    if added {
        _maPost(kMACaptionAppearanceSettingsChangedNotification)
    }
    return added
}

public func MACaptionAppearanceCopySelectedLanguages(
    _ domain: MACaptionAppearanceDomain
) -> Unmanaged<CFArray> {
    let languages = _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).selectedLanguages
    }
    return _maPassArray(languages)
}

public func MACaptionAppearanceGetDisplayType(
    _ domain: MACaptionAppearanceDomain
) -> MACaptionAppearanceDisplayType {
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).displayType
    }
}

public func MACaptionAppearanceSetDisplayType(
    _ domain: MACaptionAppearanceDomain,
    _ displayType: MACaptionAppearanceDisplayType
) {
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.update(domain) { state in
            state.displayType = displayType
            state.customized = true
        }
    }
    _maPost(kMACaptionAppearanceSettingsChangedNotification)
}

public func MACaptionAppearanceIsCustomized(
    _ domain: MACaptionAppearanceDomain
) -> Bool {
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).customized
    }
}

public func MACaptionAppearanceCopyPreferredCaptioningMediaCharacteristics(
    _ domain: MACaptionAppearanceDomain
) -> Unmanaged<CFArray> {
    let displayType = MACaptionAppearanceGetDisplayType(domain)
    let values: [String]
    switch displayType {
    case .forcedOnly:
        values = []
    case .automatic, .alwaysOn:
        values = [_maString(MAMediaCharacteristicTranscribesSpokenDialogForAccessibility)]
    }
    return _maPassArray(values)
}

public func MACaptionAppearanceCopyForegroundColor(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> Unmanaged<CGColor> {
    _maWriteBehavior(behavior)
    let color = _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).foreground
    }
    return Unmanaged.passRetained(_maMakeColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha))
}

public func MACaptionAppearanceCopyBackgroundColor(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> Unmanaged<CGColor> {
    _maWriteBehavior(behavior)
    let color = _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).background
    }
    return Unmanaged.passRetained(_maMakeColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha))
}

public func MACaptionAppearanceCopyWindowColor(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> Unmanaged<CGColor> {
    _maWriteBehavior(behavior)
    let color = _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).window
    }
    return Unmanaged.passRetained(_maMakeColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha))
}

public func MACaptionAppearanceGetForegroundOpacity(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> CGFloat {
    _maWriteBehavior(behavior)
    return _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).foregroundOpacity
    }
}

public func MACaptionAppearanceGetBackgroundOpacity(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> CGFloat {
    _maWriteBehavior(behavior)
    return _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).backgroundOpacity
    }
}

public func MACaptionAppearanceGetWindowOpacity(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> CGFloat {
    _maWriteBehavior(behavior)
    return _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).windowOpacity
    }
}

public func MACaptionAppearanceGetWindowRoundedCornerRadius(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> CGFloat {
    _maWriteBehavior(behavior)
    return _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).windowRoundedCornerRadius
    }
}

public func MACaptionAppearanceGetRelativeCharacterSize(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> CGFloat {
    _maWriteBehavior(behavior)
    return _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).relativeCharacterSize
    }
}

public func MACaptionAppearanceGetTextEdgeStyle(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?
) -> MACaptionAppearanceTextEdgeStyle {
    _maWriteBehavior(behavior)
    return _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.state(for: domain).textEdgeStyle
    }
}

public func MACaptionAppearanceCopyFontDescriptorForStyle(
    _ domain: MACaptionAppearanceDomain,
    _ behavior: UnsafeMutablePointer<MACaptionAppearanceBehavior>?,
    _ fontStyle: MACaptionAppearanceFontStyle
) -> Unmanaged<CTFontDescriptor> {
    _maWriteBehavior(behavior)
    _ = domain
    return Unmanaged.passRetained(CTFontDescriptor(fontStyle: fontStyle))
}

public func MACaptionAppearanceCopyProfileIDs() -> CFArray {
    _MACaptionStore.shared.withLock {
        _maPassCFArray(_MACaptionStore.shared.profileOrder as NSArray)
    }
}

public func MACaptionAppearanceCopyActiveProfileID() -> CFString {
    _MACaptionStore.shared.withLock {
        _maCFString(_MACaptionStore.shared.activeProfileID)
    }
}

public func MACaptionAppearanceSetActiveProfileID(_ profileID: CFString) {
    let identifier = _maString(profileID)
    guard !identifier.isEmpty else { return }
    _MACaptionStore.shared.withLock {
        if !_MACaptionStore.shared.profileOrder.contains(identifier) {
            _MACaptionStore.shared.profileOrder.append(identifier)
            _MACaptionStore.shared.profileNames[identifier] = identifier
        }
        _MACaptionStore.shared.activeProfileID = identifier
    }
    _maPost(kMACaptionAppearanceSettingsChangedNotification)
}

public func MACaptionAppearanceCopyProfileName(_ profileID: CFString) -> CFString {
    let identifier = _maString(profileID)
    return _MACaptionStore.shared.withLock {
        _maCFString(_MACaptionStore.shared.profileNames[identifier] ?? identifier)
    }
}

public func MACaptionAppearanceExecuteBlockForProfileID(
    _ profileID: CFString,
    _ aBlock: @escaping () -> Void
) {
    let identifier = _maString(profileID)
    let previous = _MACaptionStore.shared.withLock { () -> String in
        let prior = _MACaptionStore.shared.activeProfileID
        if !_MACaptionStore.shared.profileOrder.contains(identifier) {
            _MACaptionStore.shared.profileOrder.append(identifier)
            _MACaptionStore.shared.profileNames[identifier] = identifier
        }
        _MACaptionStore.shared.activeProfileID = identifier
        return prior
    }
    aBlock()
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.activeProfileID = previous
    }
}

public func MACaptionAppearanceDidDisplayCaptions(_ strings: CFArray) {
    let values = _maNSArray(strings).compactMap { value -> String? in
        if let string = value as? String {
            return string
        }
        if let ns = value as? NSString {
            return ns as String
        }
        return nil
    }
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.lastDisplayedCaptions = values
    }
}

public func MALastDisplayedCaptionsForTesting() -> [String] {
    _MACaptionStore.shared.withLock {
        _MACaptionStore.shared.lastDisplayedCaptions
    }
}
