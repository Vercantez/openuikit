import Foundation

#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// A set of applications, categories, and web domains chosen in a
/// `FamilyActivityPicker`.
///
/// Linux stores opaque tokens and `includeEntireCategory`. Resolved
/// `applications`, `categories`, and `webDomains` stay empty: there is no
/// Screen Time catalog. Codable keys are Linux-local (`includeEntireCategory`
/// plus token arrays); Apple's encoding is unobserved.
public struct FamilyActivitySelection: Equatable, Codable, Sendable {
    public var applicationTokens: Set<ApplicationToken>
    public var categoryTokens: Set<ActivityCategoryToken>
    public var webDomainTokens: Set<WebDomainToken>
    public let includeEntireCategory: Bool

    /// Darwin `init()` is equivalent to `includeEntireCategory: false`.
    public init() {
        self.init(includeEntireCategory: false)
    }

    public init(includeEntireCategory: Bool) {
        self.applicationTokens = []
        self.categoryTokens = []
        self.webDomainTokens = []
        self.includeEntireCategory = includeEntireCategory
    }

    /// Linux cannot resolve tokens to ManagedSettings records.
    public var applications: Set<Application> { [] }

    /// Linux cannot resolve tokens to ManagedSettings records.
    public var categories: Set<ActivityCategory> { [] }

    /// Linux cannot resolve tokens to ManagedSettings records.
    public var webDomains: Set<WebDomain> { [] }

    public static func == (
        a: FamilyActivitySelection,
        b: FamilyActivitySelection
    ) -> Bool {
        a.includeEntireCategory == b.includeEntireCategory
            && a.applicationTokens == b.applicationTokens
            && a.categoryTokens == b.categoryTokens
            && a.webDomainTokens == b.webDomainTokens
    }

    private enum CodingKeys: String, CodingKey {
        case applicationTokens
        case categoryTokens
        case webDomainTokens
        case includeEntireCategory
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        includeEntireCategory = try container.decode(Bool.self, forKey: .includeEntireCategory)
        applicationTokens = try container.decode(Set<ApplicationToken>.self, forKey: .applicationTokens)
        categoryTokens = try container.decode(Set<ActivityCategoryToken>.self, forKey: .categoryTokens)
        webDomainTokens = try container.decode(Set<WebDomainToken>.self, forKey: .webDomainTokens)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(includeEntireCategory, forKey: .includeEntireCategory)
        try container.encode(applicationTokens, forKey: .applicationTokens)
        try container.encode(categoryTokens, forKey: .categoryTokens)
        try container.encode(webDomainTokens, forKey: .webDomainTokens)
    }
}
