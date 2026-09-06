// FOCUS SHIMS — everything in this file is NOT focus-ios source.
//
// The vendored Settings screen (Sources/RealAppProbe/Vendored/Focus/) is
// mozilla-mobile/focus-ios at a2832521, unmodified. This file is the app's
// own infrastructure collapsed to the smallest stand-in that type-checks
// and paints the one configuration the harness captures
// (`realapp_focus_settings_light` on the iPhone 16 @3x).
//
// Rules, same as Shims.swift:
//   * every shim states what it replaces;
//   * colours are the exact sRGB components from
//     BlockzillaPackage/Sources/DesignSystem/Colors.xcassets;
//   * strings are the exact `value:` of UIConstants.strings;
//   * NOTHING here stands in for a UIKit symbol.

import OpenUIKit
import Foundation
import Onboarding
import Combine
import DesignSystem

// DesignSystem colours/fonts live in the DesignSystem product
// (FocusUIColor.swift / FocusUIFont.swift), measured from
// BlockzillaPackage Colors.xcassets at a2832521.

// MARK: - UIConstants
//
// Replaces Blockzilla/UIComponents/UIConstants.swift. Only the strings and
// layout numbers the Settings screen and its cells/footers read.

struct UIConstants {
    struct layout {
        static let settingsVerticalOffset: CGFloat = 8
        static let settingsHorizontalOffset: CGFloat = 20
        static let settingsCellLeftInset: CGFloat = 20
        static let browserToolbarHeight: CGFloat = 44
        static let urlBarMargin: CGFloat = 10
        static let textLogoOffset: CGFloat = -10 - browserToolbarHeight / 2
        static let textLogoOffsetSmallDevice: CGFloat = 10 - browserToolbarHeight / 4
        static let textLogoMargin: CGFloat = 44
        static let tipViewHeight: CGFloat = 148
        static let tipViewBottomOffset: CGFloat = 6
        static let iPhoneSEHeight: CGFloat = 568
    }

    struct strings {
        static let done = "Done"
        static let general = "General"
        static let theme = "Theme"
        static let systemTheme = "System Theme"
        static let light = "Light"
        static let dark = "Dark"
        static let licenses = "Licenses"
        static let settingsSearchTitle = "SEARCH"
        static let settingsSearchLabel = "Search Engine"
        static let settingsSearchSuggestions = "Get Search Suggestions"
        static let detailTextSearchSuggestion = "%@ will send what you type in the address bar to your search engine."
        static let settingsAutocompleteSection = "URL Autocomplete"
        static let settingsTitle = "Settings"
        static let settingsTrackingProtectionOn = "On"
        static let settingsTrackingProtectionOff = "Off"
        static let setAsDefaultBrowserLabel = "Set as Default Browser"
        static let setAsDefaultBrowserDescriptionLabel = "Set links from websites, emails and messages to open automatically in %@."
        static let learnMore = "Learn more."
        static let toggleHomeScreenTips = "Show home screen tips"
        static let toggleSectionSafari = "SAFARI INTEGRATION"
        static let toggleSectionMozilla = "MOZILLA"
        static let toggleSectionPrivacy = "PRIVACY"
        static let toggleSafari = "Safari"
        static let labelBlockFonts = "Block web fonts"
        static let labelSendAnonymousUsageData = "Send usage data"
        static let detailTextSendUsageData = "Mozilla strives to collect only what we need to provide and improve %@ for everyone."
        static let labelStudies = "Studies"
        static let detailTextStudies = "%@ may install and run studies from time to time."
        static let labelFaceIDLogin = "Use Face ID to unlock app"
        static let labelFaceIDLoginDescription = "Face ID can unlock %@ if a URL is already open in the app"
        static let labelTouchIDLogin = "Use Touch ID to unlock app"
        static let labelTouchIDLoginDescription = "Touch ID can unlock %@ if a URL is already open in the app"
        static let trackingProtectionLabel = "Tracking Protection"
        static let ratingSetting = "Rate %@"
        static let aboutTitle = "About %@"
        static let autocompleteCustomEnabled = "Enabled"
        static let autocompleteCustomDisabled = "Disabled"
        static let siriShortcutsTitle = "SIRI SHORTCUTS"
        static let eraseSiri = "Erase"
        static let eraseAndOpenSiri = "Erase & Open"
        static let openUrlSiri = "Open Favorite Site"
        static let addToSiri = "Add to Siri"
        static let Edit = "Edit"
        static let add = "Add"
        static let share = "Share"
    }
}

// MARK: - Settings store
//
// Replaces Shared/Settings.swift. Pocket Casts already owns `enum Settings`
// in Shims.swift; Focus methods are added as an extension so the vendored
// `Settings.getToggle` / `Settings.set` call sites stay unmodified.
// Defaults are the real `defaultForToggle` values for Focus (not Klar).

enum SettingsToggle: String, Equatable {
    case trackingProtection = "TrackingProtection"
    case biometricLogin = "BiometricLogin"
    case blockAds = "BlockAds"
    case blockAnalytics = "BlockAnalytics"
    case blockSocial = "BlockSocial"
    case blockOther = "BlockOther"
    case blockFonts = "BlockFonts"
    case showHomeScreenTips = "HomeScreenTips"
    case safari = "Safari"
    case sendAnonymousUsageData = "SendAnonymousUsageData"
    case studies = "Studies"
    case enableDomainAutocomplete = "enableDomainAutocomplete"
    case enableCustomDomainAutocomplete = "enableCustomDomainAutocomplete"
    case enableSearchSuggestions = "enableSearchSuggestions"
    case displaySecretMenu = "displaySecretMenu"
}

extension Settings {
    static func getToggle(_ toggle: SettingsToggle) -> Bool {
        switch toggle {
        case .trackingProtection: return true
        case .biometricLogin: return false
        case .blockAds: return true
        case .blockAnalytics: return true
        case .blockSocial: return true
        case .blockOther: return false
        case .blockFonts: return false
        case .showHomeScreenTips: return true
        case .safari: return true
        case .sendAnonymousUsageData: return true
        case .studies: return true
        case .enableDomainAutocomplete: return true
        case .enableCustomDomainAutocomplete: return true
        case .enableSearchSuggestions: return false
        case .displaySecretMenu: return false
        }
    }

    static func set(_ value: Bool, forToggle toggle: SettingsToggle) {
        _ = (value, toggle)
    }
}

// MARK: - AppInfo
//
// Replaces Shared/AppInfo.swift. `productName` is the user-facing Focus
// name the Settings rows interpolate; `isKlar` is false so usage-data /
// studies default on. No Bundle / String.contains (guest Foundation has
// neither a product plist nor _StringProcessing).

enum AppInfo {
    static let productName = "Focus"
    static let isKlar = false
    static let contentBlockerBundleIdentifier = "org.mozilla.ios.Focus.ContentBlocker"
    static let config = FocusAppConfig()
}

struct FocusAppConfig {
    let appId = "1059793120"
}

// MARK: - Theme / auth / search
//
// ThemeManager replaces Blockzilla/Theme/Theme.swift without @Published or
// UserDefaults. The light Settings capture pins `.light` so the Theme row
// accessory is "Light".

class ThemeManager {
    enum Theme {
        case device, light, dark
        var userInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .device: return .unspecified
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    var selectedTheme: UIUserInterfaceStyle = .light
    func set(_ theme: Theme) { selectedTheme = theme.userInterfaceStyle }
}

// Replaces Blockzilla/Utilities/AuthenticationManager.swift. Face ID /
// Touch ID is pinned off so the Privacy section is the 2-row configuration
// (Tracking Protection + Block web fonts) on every oracle.
enum LABiometryType { case none, faceID, touchID }

class AuthenticationManager {
    var canEvaluatePolicy = false
    var biometricType = LABiometryType.none
}

class SearchEngine {
    let name: String
    init(name: String) { self.name = name }
}

class SearchEngineManager {
    var activeEngine = SearchEngine(name: "Google")
}

final class HarnessOnboardingEventsHandler: OnboardingEventsHandling {
    @Published var route: ToolTipRoute?
    var routePublisher: Published<ToolTipRoute?>.Publisher { $route }
    func send(_ action: Action) { _ = action }
}

// MARK: - Cells' neighbours

// Replaces Blockzilla/UIComponents/SmartLabel.swift without importing
// UIHelpers. SettingsTableViewToggleCell constructs one and never adds it
// to the hierarchy; the visible label is `textLabel`.
class SmartLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsFontSizeToFitWidth = true
        minimumScaleFactor = 0.6
    }
    required init?(coder: NSCoder) { fatalError() }
}

// Replaces Blockzilla/Settings/Helpers/BlockerEnabledDetector.swift
// (SafariServices). Calls back synchronously so openrender (no run loop)
// and the 1.5 s sim capture see the same Safari toggle: on, enabled.
class BlockerEnabledDetector {
    func detectEnabled(_ parentView: UIView, callback: @escaping (Bool) -> Void) {
        _ = parentView
        callback(true)
    }
}

// Replaces Blockzilla/Siri/SiriShortcuts.swift. Completes synchronously
// with false so the three Siri rows show "Add to Siri" / "Add".
class SiriShortcuts {
    enum activityType {
        case erase, eraseAndOpen, openURL
    }
    func hasAddedActivity(type: SiriShortcuts.activityType,
                          _ completion: @escaping (Bool) -> Void) {
        _ = type
        completion(false)
    }
    func manageSiri(for type: SiriShortcuts.activityType, in viewController: UIViewController) {
        _ = (type, viewController)
    }
}

// MARK: - Telemetry / blockers / tips (no-ops)

class ContentBlockerHelper {
    static let shared = ContentBlockerHelper()
    func reload() {}
}

enum Utils {
    static func reloadSafariContentBlocker() {}
}

class NimbusWrapper {
    static let shared = NimbusWrapper()
    let nimbus = NimbusInterface()
}

class NimbusInterface {
    var globalUserParticipation = true
    func resetTelemetryIdentifiers() {}
}

class TipManager {
    static var siriEraseTip = true
    static var biometricTip = true

    struct Tip: Equatable {
        let identifier: String
        static func == (lhs: Tip, rhs: Tip) -> Bool {
            lhs.identifier == rhs.identifier
        }
    }

    init() {}

    func shareTrackersDescription() -> String {
        // TipManager.shareTrackersTipDescription at a2832521 with 0 blocked.
        "0 trackers blocked so far"
    }
}

enum SearchSuggestionsPromptView {
    static let respondedToSearchSuggestionsPrompt = "SearchSuggestionPrompt"
}

class HomeViewToolbar: UIView {
    // Replaces Blockzilla/UIComponents/HomeViewToolbar.swift. Upstream pins
    // a UIStackView with SnapKit (urlBarMargin 10, height browserToolbarHeight
    // 44, bottom to safeArea). SnapKit is a listed ingest blocker; Auto Layout
    // here uses those same UIConstants.layout numbers.
    private let stackView = UIStackView()

    init() {
        super.init(frame: .zero)
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(UIView())
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.layout.urlBarMargin),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.layout.urlBarMargin),
            stackView.heightAnchor.constraint(equalToConstant: UIConstants.layout.browserToolbarHeight),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

class TipsPageViewController: UIViewController {
    // Replaces Blockzilla/Pro Tips/TipsPageViewController.swift for the home
    // capture. HomeViewController.refreshTipsDisplay always installs
    // `.showEmpty(ShareTrackersViewController)`; the UIPageViewController
    // `.showTips` branch is not driven.
    enum State {
        case showTips
        case showEmpty(controller: UIViewController)
    }

    init(tipManager: TipManager,
         tipTapped: @escaping (TipManager.Tip) -> Void,
         tapOutsideAction: @escaping () -> Void) {
        _ = (tipManager, tipTapped, tapOutsideAction)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setupPageController(with state: State) {
        switch state {
        case .showTips:
            break
        case .showEmpty(let controller):
            install(controller, on: view)
        }
    }
}

class ShareTrackersViewController: UIViewController {
    // Replaces Blockzilla/Pro Tips/ShareTrackersViewController.swift. The
    // upstream file uses DesignSystem fonts/images, `#selector(shareTapped)`,
    // and contentEdgeInsets. The home capture shows the tracker title string
    // HomeViewController passes through; Share itself is not driven.
    private let trackerTitle: String
    private let shareTap: (UIButton) -> Void

    init(trackerTitle: String, shareTap: @escaping (UIButton) -> Void) {
        self.trackerTitle = trackerTitle
        self.shareTap = shareTap
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = trackerTitle
        label.font = .footnote12
        label.textColor = .secondaryText
        label.numberOfLines = 2
        label.textAlignment = .center
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
        ])
        _ = shareTap
    }
}

class BrowserViewController: UIViewController {
    func refreshTipsDisplay() {}
}

// MARK: - Pushed screens (constructed only on row tap)

enum TrackingProtectionState { case settings }

class TrackingProtectionViewController: UIViewController {
    weak var delegate: BrowserViewController?
    init(state: TrackingProtectionState, onboardingEventsHandler: OnboardingEventsHandling) {
        _ = (state, onboardingEventsHandler)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
}

class ThemeViewController: UIViewController {
    init(themeManager: ThemeManager) {
        _ = themeManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
}

class SearchSettingsViewController: UIViewController {
    weak var delegate: SearchSettingsViewControllerDelegate?
    init(searchEngineManager: SearchEngineManager) {
        _ = searchEngineManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
}

class AutocompleteSettingViewController: UIViewController {}
class SiriFavoriteViewController: UIViewController {}
class AboutViewController: UIViewController {}
class SafariInstructionsViewController: UIViewController {}
class SettingsContentViewController: UIViewController {
    init(url: URL?) {
        _ = url
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
}

protocol SearchSettingsViewControllerDelegate: AnyObject {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController,
                                      didSelectEngine engine: SearchEngine)
}

enum SupportTopic {
    case usageData, searchSuggestions, studies
}

extension URL {
    init(forSupportTopic topic: SupportTopic) {
        self = URL(string: "https://support.mozilla.org")!
        _ = topic
    }

    /// Focus a2832521 spells the iOS 17 URL parser flag `invalidCharacters`.
    /// The capture never calls this (didSelectRowAt only). Guest Foundation
    /// has no encoding-invalid-characters flag; Darwin's overlay is macOS 14+.
    init?(string: String, invalidCharacters: Bool) {
        _ = invalidCharacters
        self.init(string: string)
    }
}
