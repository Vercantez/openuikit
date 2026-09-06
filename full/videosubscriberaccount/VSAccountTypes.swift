import Foundation

/// Application-defined account provider shown in the TV-provider picker.
open class VSAccountApplicationProvider: NSObject {
    public let localizedDisplayName: String
    public let identifier: String

    public init(localizedDisplayName: String, identifier: String) {
        self.localizedDisplayName = localizedDisplayName
        self.identifier = identifier
        super.init()
    }
}

/// Result of a metadata request. Properties are get-only on Darwin; Linux
/// constructs instances only for local tests. Apple services never populate
/// these fields.
open class VSAccountMetadata: NSObject {
    public let accountProviderIdentifier: String?
    public let authenticationExpirationDate: Date?
    public let verificationData: Data?
    public let samlAttributeQueryResponse: String?
    public let accountProviderResponse: VSAccountProviderResponse?

    public init(
        accountProviderIdentifier: String? = nil,
        authenticationExpirationDate: Date? = nil,
        verificationData: Data? = nil,
        samlAttributeQueryResponse: String? = nil,
        accountProviderResponse: VSAccountProviderResponse? = nil
    ) {
        self.accountProviderIdentifier = accountProviderIdentifier
        self.authenticationExpirationDate = authenticationExpirationDate
        self.verificationData = verificationData
        self.samlAttributeQueryResponse = samlAttributeQueryResponse
        self.accountProviderResponse = accountProviderResponse
        super.init()
    }
}

/// Request describing the account metadata an app wants from a TV provider.
/// Arrays default to empty; booleans default to `false`. Darwin defaults are
/// otherwise unobserved.
open class VSAccountMetadataRequest: NSObject {
    public var channelIdentifier: String?
    public var supportedAccountProviderIdentifiers: [String] = []
    public var featuredAccountProviderIdentifiers: [String] = []
    public var verificationToken: String?
    public var includeAccountProviderIdentifier: Bool = false
    public var includeAuthenticationExpirationDate: Bool = false
    public var localizedVideoTitle: String?
    public var isInterruptionAllowed: Bool = false
    public var forceAuthentication: Bool = false
    public var attributeNames: [String] = []
    public var supportedAuthenticationSchemes: [VSAccountProviderAuthenticationScheme] = []
    public var accountProviderAuthenticationToken: String?
    public var applicationAccountProviders: [VSAccountApplicationProvider]?
}

/// Provider authentication payload. Get-only on Darwin; Linux supplies an
/// explicit initializer because there is no provider process to produce one.
open class VSAccountProviderResponse: NSObject {
    public let authenticationScheme: VSAccountProviderAuthenticationScheme
    public let body: String?
    public let status: String?

    public init(
        authenticationScheme: VSAccountProviderAuthenticationScheme,
        body: String? = nil,
        status: String? = nil
    ) {
        self.authenticationScheme = authenticationScheme
        self.body = body
        self.status = status
        super.init()
    }
}
