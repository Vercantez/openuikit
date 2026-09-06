import Foundation

// MARK: - Account

/// An object that configures whether a user can modify their device's account settings.
public struct AccountSettings: ManagedSettingsGroup {
    /// A Boolean value that indicates whether to prevent the user from changing
    /// their account information. The default value is `nil`.
    public var lockAccounts: Bool?

    /// A description of the setting that controls whether a user can modify
    /// their account information.
    public static let lockAccounts = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Application

/// Constraints on the apps and categories of apps a user can run on their device.
public struct ApplicationSettings: ManagedSettingsGroup {
    /// A set of applications for the system to block. `nil` if unspecified.
    public var blockedApplications: Set<Application>?

    /// The metadata for `blockedApplications`. Default is an empty set.
    public static let blockedApplications = SettingMetadata<Set<Application>>(defaultValue: [])

    /// A Boolean value that indicates whether to prevent the user from installing applications.
    public var denyAppInstallation: Bool?

    /// The metadata for `denyAppInstallation`. Default is `false`.
    public static let denyAppInstallation = SettingMetadata<Bool>(defaultValue: false)

    /// A Boolean value that indicates whether to prevent the user from removing applications.
    public var denyAppRemoval: Bool?

    /// The metadata for `denyAppRemoval`. Default is `false`.
    public static let denyAppRemoval = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - App Store

/// Constraints on a user's App Store settings.
public struct AppStoreSettings: ManagedSettingsGroup {
    /// A Boolean value that indicates whether to deny in-app purchases.
    public var denyInAppPurchases: Bool?

    /// The metadata for `denyInAppPurchases`. Default is `false`.
    public static let denyInAppPurchases = SettingMetadata<Bool>(defaultValue: false)

    /// The maximum app rating the user can download.
    ///
    /// Documented U.S. levels include `1000` (All) and `600`. Bounds `0...2000`.
    public var maximumRating: Int?

    /// Default `1000`, bounds `0...2000`.
    public static let maximumRating = BoundedSettingMetadata<Int>(
        defaultValue: 1000,
        bounds: 0...2000
    )

    /// A Boolean value that indicates whether to require a password for purchases.
    public var requirePasswordForPurchases: Bool?

    /// The metadata for `requirePasswordForPurchases`. Default is `false`.
    public static let requirePasswordForPurchases = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Cellular

/// Constraints on the user's cellular networking settings.
public struct CellularSettings: ManagedSettingsGroup {
    /// Prevents changing which apps may use cellular data.
    public var lockAppCellularData: Bool?

    /// Default is `false`.
    public static let lockAppCellularData = SettingMetadata<Bool>(defaultValue: false)

    /// Prevents changing the cellular plan.
    public var lockCellularPlan: Bool?

    /// Default is `false`.
    public static let lockCellularPlan = SettingMetadata<Bool>(defaultValue: false)

    /// Prevents changing eSIM settings.
    public var lockESIM: Bool?

    /// Default is `false`.
    public static let lockESIM = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Date and time

/// Constraints on the device's date and time settings.
public struct DateAndTimeSettings: ManagedSettingsGroup {
    /// Prevents changing the device date and time.
    public var requireAutomaticDateAndTime: Bool?

    /// Default is `false`.
    public static let requireAutomaticDateAndTime = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Game Center

/// Constraints on the user's Game Center settings.
public struct GameCenterSettings: ManagedSettingsGroup {
    /// Prevents adding Game Center friends.
    public var denyAddingFriends: Bool?

    /// Default is `false`.
    public static let denyAddingFriends = SettingMetadata<Bool>(defaultValue: false)

    /// Prevents joining multiplayer games.
    public var denyMultiplayerGaming: Bool?

    /// Default is `false`.
    public static let denyMultiplayerGaming = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Media

/// Constraints on the media content the user can access.
public struct MediaSettings: ManagedSettingsGroup {
    /// Denies Books-store erotica.
    public var denyBookstoreErotica: Bool?

    /// Default is `false`.
    public static let denyBookstoreErotica = SettingMetadata<Bool>(defaultValue: false)

    /// Prevents access to explicit content.
    public var denyExplicitContent: Bool?

    /// Default is `false`.
    public static let denyExplicitContent = SettingMetadata<Bool>(defaultValue: false)

    /// Prevents access to Apple Music streaming. `true` reverts Music to classic mode.
    public var denyMusicService: Bool?

    /// Default is `false`.
    public static let denyMusicService = SettingMetadata<Bool>(defaultValue: false)

    /// Maximum movie rating. Documented U.S. values include `1000` (All) and `500` (NC-17).
    public var maximumMovieRating: Int?

    /// Default `1000`, bounds `0...1000`.
    public static let maximumMovieRating = BoundedSettingMetadata<Int>(
        defaultValue: 1000,
        bounds: 0...1000
    )

    /// Maximum TV-show rating. Documented U.S. values include `1000` (All) and `600`.
    public var maximumTVShowRating: Int?

    /// Default `1000`, bounds `0...1000`.
    public static let maximumTVShowRating = BoundedSettingMetadata<Int>(
        defaultValue: 1000,
        bounds: 0...1000
    )
}

// MARK: - Passcode

/// Constraints on a user's ability to change their device's passcode.
public struct PasscodeSettings: ManagedSettingsGroup {
    /// Prevents changing the device passcode.
    public var lockPasscode: Bool?

    /// Default is `false`.
    public static let lockPasscode = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Safari

/// Constraints on Safari's AutoFill and cookie behaviors.
public struct SafariSettings: ManagedSettingsGroup {
    /// The conditions under which Safari accepts cookies.
    public enum CookiePolicy: String, Comparable, Hashable, CustomStringConvertible {
        /// The device doesn't accept cookies from any website.
        case never
        /// The device only accepts cookies from the current website.
        case currentWebsite
        /// The device only accepts cookies from websites in browsing history.
        case visitedWebsites
        /// The device accepts cookies from all websites.
        case always

        public typealias RawValue = String

        private var rank: Int {
            switch self {
            case .never: return 0
            case .currentWebsite: return 1
            case .visitedWebsites: return 2
            case .always: return 3
            }
        }

        public static func < (lhs: CookiePolicy, rhs: CookiePolicy) -> Bool {
            lhs.rank < rhs.rank
        }

        public var description: String { rawValue }
    }

    /// Cookie policy. `nil` if not applied. Metadata default is `.always`.
    public var cookiePolicy: CookiePolicy?

    /// Default is ``CookiePolicy/always``.
    public static let cookiePolicy = SettingMetadata<CookiePolicy>(defaultValue: .always)

    /// `true` prevents Safari AutoFill.
    public var denyAutoFill: Bool?

    /// Default is `false`.
    public static let denyAutoFill = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Siri

/// Constraints on the device's Siri settings.
public struct SiriSettings: ManagedSettingsGroup {
    /// Prevents access to Siri.
    public var denySiri: Bool?

    /// Default is `false`.
    public static let denySiri = SettingMetadata<Bool>(defaultValue: false)
}

// MARK: - Web content

/// An object that configures which websites a user can access.
public struct WebContentSettings: ManagedSettingsGroup {
    /// Policies for filtering web content based on specific web domains.
    public enum FilterPolicy: Equatable {
        /// The policy doesn't affect any domains.
        case none
        /// Blocks the specified domains (up to 50).
        case specific(Set<WebDomain>)
        /// Blocks adult content plus `domains`, allowing `except`.
        case auto(Set<WebDomain> = [], except: Set<WebDomain> = [])
        /// Blocks all websites except the ones specified (up to 50 exceptions).
        case all(except: Set<WebDomain> = [])

        public static func == (lhs: FilterPolicy, rhs: FilterPolicy) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case let (.specific(a), .specific(b)):
                return a == b
            case let (.auto(aDomains, aExcept), .auto(bDomains, bExcept)):
                return aDomains == bDomains && aExcept == bExcept
            case let (.all(aExcept), .all(bExcept)):
                return aExcept == bExcept
            default:
                return false
            }
        }
    }

    /// Current web filter policy. `nil` unless specified. Setting any policy
    /// besides `.none` disables Safari private browsing on Apple; Linux does
    /// not host Safari.
    public var blockedByFilter: FilterPolicy?

    /// Default is ``FilterPolicy/none``.
    public static let blockedByFilter = SettingMetadata<FilterPolicy>(defaultValue: .none)
}

// MARK: - Shield settings

/// Constraints that indicate what apps and websites to cover with a shielding view.
public struct ShieldSettings: ManagedSettingsGroup {
    /// Policies available for shielding activities based on their category.
    public enum ActivityCategoryPolicy<Activity>: Equatable {
        /// The device doesn't shield any content.
        case none
        /// Shields all apps and websites except the listed tokens (up to 50).
        case all(except: Set<Token<Activity>> = [])
        /// Shields specific categories, with optional exceptions.
        case specific(Set<ActivityCategoryToken>, except: Set<Token<Activity>> = [])

        public static func == (
            lhs: ActivityCategoryPolicy<Activity>,
            rhs: ActivityCategoryPolicy<Activity>
        ) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case let (.all(aExcept), .all(bExcept)):
                return aExcept == bExcept
            case let (.specific(aCats, aExcept), .specific(bCats, bExcept)):
                return aCats == bCats && aExcept == bExcept
            default:
                return false
            }
        }
    }

    /// Applications to cover with a shielding view.
    public var applications: Set<ApplicationToken>?

    /// Default is an empty set.
    public static let applications = SettingMetadata<Set<ApplicationToken>>(defaultValue: [])

    /// Categories of apps to cover with a shielding view.
    public var applicationCategories: ActivityCategoryPolicy<Application>?

    /// Default is ``ActivityCategoryPolicy/none``.
    public static let applicationCategories = SettingMetadata<ActivityCategoryPolicy<Application>>(
        defaultValue: .none
    )

    /// Websites to cover with a shielding view.
    public var webDomains: Set<WebDomainToken>?

    /// Default is an empty set.
    public static let webDomains = SettingMetadata<Set<WebDomainToken>>(defaultValue: [])

    /// Categories of websites to cover with a shielding view.
    public var webDomainCategories: ActivityCategoryPolicy<WebDomain>?

    /// Default is ``ActivityCategoryPolicy/none``.
    public static let webDomainCategories = SettingMetadata<ActivityCategoryPolicy<WebDomain>>(
        defaultValue: .none
    )
}
