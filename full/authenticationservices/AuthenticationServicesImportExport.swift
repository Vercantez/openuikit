import Foundation

/// Credential import/export value types. Codable keys follow the public
/// property names. Apple's on-the-wire format is an oracle question; tests
/// prove the Linux overlay round-trip only.

public struct ASImportableEditableField: Hashable, Codable, Sendable {
    public enum FieldType: String, Hashable, Codable, Sendable {
        case wifiNetworkSecurityType
        case countryCode
        case concealedString
        case subdivisionCode
        case date
        case email
        case number
        case string
        case boolean
        case yearMonth
    }

    public var id: Data?
    public var fieldType: FieldType
    public var value: String
    public var label: String?

    public init(
        id: Data?,
        fieldType: FieldType,
        value: String,
        label: String? = nil
    ) {
        self.id = id
        self.fieldType = fieldType
        self.value = value
        self.label = label
    }
}

public struct ASImportableLinkedItem: Hashable, Codable, Sendable {
    public var item: Data
    public var account: Data?

    public init(item: Data, account: Data? = nil) {
        self.item = item
        self.account = account
    }
}

public struct ASImportableCredentialScope: Hashable, Codable, Sendable {
    public struct AndroidAppCertificationFingerprint: Hashable, Codable, Sendable {
        public var fingerprint: Data
        public var hashAlgorithm: String

        public init(fingerprint: Data, hashAlgorithm: String) {
            self.fingerprint = fingerprint
            self.hashAlgorithm = hashAlgorithm
        }
    }

    public struct AndroidAppID: Hashable, Codable, Sendable {
        public var bundleID: String
        public var certificate: AndroidAppCertificationFingerprint?
        public var name: String?

        public init(
            bundleID: String,
            certificate: AndroidAppCertificationFingerprint?,
            name: String?
        ) {
            self.bundleID = bundleID
            self.certificate = certificate
            self.name = name
        }
    }

    public var urls: [URL]
    public var androidApps: [AndroidAppID]

    public init(urls: [URL], androidApps: [AndroidAppID] = []) {
        self.urls = urls
        self.androidApps = androidApps
    }
}

public enum ASImportableCredential: Hashable, Codable, Sendable {
    public struct BasicAuthentication: Hashable, Codable, Sendable {
        public var userName: ASImportableEditableField?
        public var password: ASImportableEditableField?

        public init(
            userName: ASImportableEditableField? = nil,
            password: ASImportableEditableField? = nil
        ) {
            self.userName = userName
            self.password = password
        }
    }

    public struct CreditCard: Hashable, Codable, Sendable {
        public var number: ASImportableEditableField?
        public var fullName: ASImportableEditableField?
        public var cardType: ASImportableEditableField?
        public var verificationNumber: ASImportableEditableField?
        public var pin: ASImportableEditableField?
        public var expiryDate: ASImportableEditableField?
        public var validFrom: ASImportableEditableField?

        public init(
            number: ASImportableEditableField?,
            fullName: ASImportableEditableField?,
            cardType: ASImportableEditableField?,
            verificationNumber: ASImportableEditableField?,
            pin: ASImportableEditableField?,
            expiryDate: ASImportableEditableField?,
            validFrom: ASImportableEditableField?
        ) {
            self.number = number
            self.fullName = fullName
            self.cardType = cardType
            self.verificationNumber = verificationNumber
            self.pin = pin
            self.expiryDate = expiryDate
            self.validFrom = validFrom
        }
    }

    public struct PersonName: Hashable, Codable, Sendable {
        public var title: ASImportableEditableField?
        public var given: ASImportableEditableField?
        public var givenInformal: ASImportableEditableField?
        public var given2: ASImportableEditableField?
        public var surnamePrefix: ASImportableEditableField?
        public var surname: ASImportableEditableField?
        public var surname2: ASImportableEditableField?
        public var credentials: ASImportableEditableField?
        public var generation: ASImportableEditableField?

        public init(
            title: ASImportableEditableField?,
            given: ASImportableEditableField?,
            givenInformal: ASImportableEditableField?,
            given2: ASImportableEditableField?,
            surnamePrefix: ASImportableEditableField?,
            surname: ASImportableEditableField?,
            surname2: ASImportableEditableField?,
            credentials: ASImportableEditableField?,
            generation: ASImportableEditableField?
        ) {
            self.title = title
            self.given = given
            self.givenInformal = givenInformal
            self.given2 = given2
            self.surnamePrefix = surnamePrefix
            self.surname = surname
            self.surname2 = surname2
            self.credentials = credentials
            self.generation = generation
        }
    }

    public struct CustomFields: Hashable, Codable, Sendable {
        public var id: Data?
        public var label: String?
        public var fields: [ASImportableEditableField]

        public init(
            id: Data? = nil,
            label: String? = nil,
            fields: [ASImportableEditableField]
        ) {
            self.id = id
            self.label = label
            self.fields = fields
        }
    }

    public struct ItemReference: Hashable, Codable, Sendable {
        public var reference: ASImportableLinkedItem

        public init(reference: ASImportableLinkedItem) {
            self.reference = reference
        }
    }

    public struct DriversLicense: Hashable, Codable, Sendable {
        public var fullName: ASImportableEditableField?
        public var birthDate: ASImportableEditableField?
        public var issueDate: ASImportableEditableField?
        public var expiryDate: ASImportableEditableField?
        public var issuingAuthority: ASImportableEditableField?
        public var territory: ASImportableEditableField?
        public var country: ASImportableEditableField?
        public var licenseNumber: ASImportableEditableField?
        public var licenseClass: ASImportableEditableField?

        public init(
            fullName: ASImportableEditableField?,
            birthDate: ASImportableEditableField?,
            issueDate: ASImportableEditableField?,
            expiryDate: ASImportableEditableField?,
            issuingAuthority: ASImportableEditableField?,
            territory: ASImportableEditableField?,
            country: ASImportableEditableField?,
            licenseNumber: ASImportableEditableField?,
            licenseClass: ASImportableEditableField?
        ) {
            self.fullName = fullName
            self.birthDate = birthDate
            self.issueDate = issueDate
            self.expiryDate = expiryDate
            self.issuingAuthority = issuingAuthority
            self.territory = territory
            self.country = country
            self.licenseNumber = licenseNumber
            self.licenseClass = licenseClass
        }
    }

    public struct IdentityDocument: Hashable, Codable, Sendable {
        public var issuingCountry: ASImportableEditableField?
        public var documentNumber: ASImportableEditableField?
        public var identificationNumber: ASImportableEditableField?
        public var nationality: ASImportableEditableField?
        public var fullName: ASImportableEditableField?
        public var birthDate: ASImportableEditableField?
        public var birthPlace: ASImportableEditableField?
        public var sex: ASImportableEditableField?
        public var issueDate: ASImportableEditableField?
        public var expiryDate: ASImportableEditableField?
        public var issuingAuthority: ASImportableEditableField?

        public init(
            issuingCountry: ASImportableEditableField?,
            documentNumber: ASImportableEditableField?,
            identificationNumber: ASImportableEditableField?,
            nationality: ASImportableEditableField?,
            fullName: ASImportableEditableField?,
            birthDate: ASImportableEditableField?,
            birthPlace: ASImportableEditableField?,
            sex: ASImportableEditableField?,
            issueDate: ASImportableEditableField?,
            expiryDate: ASImportableEditableField?,
            issuingAuthority: ASImportableEditableField?
        ) {
            self.issuingCountry = issuingCountry
            self.documentNumber = documentNumber
            self.identificationNumber = identificationNumber
            self.nationality = nationality
            self.fullName = fullName
            self.birthDate = birthDate
            self.birthPlace = birthPlace
            self.sex = sex
            self.issueDate = issueDate
            self.expiryDate = expiryDate
            self.issuingAuthority = issuingAuthority
        }
    }

    public struct GeneratedPassword: Hashable, Codable, Sendable {
        public var password: String

        public init(password: String) {
            self.password = password
        }
    }

    public struct Note: Hashable, Codable, Sendable {
        public var content: ASImportableEditableField

        public init(content: ASImportableEditableField) {
            self.content = content
        }
    }

    public struct TOTP: Hashable, Codable, Sendable {
        public enum Algorithm: String, Hashable, Codable, Sendable {
            case sha1
            case sha256
            case sha512
        }

        public var secret: Data
        public var period: UInt16
        public var digits: UInt16
        public var userName: String?
        public var algorithm: Algorithm
        public var issuer: String?

        public init(
            secret: Data,
            period: UInt16,
            digits: UInt16,
            userName: String?,
            algorithm: Algorithm,
            issuer: String? = nil
        ) {
            self.secret = secret
            self.period = period
            self.digits = digits
            self.userName = userName
            self.algorithm = algorithm
            self.issuer = issuer
        }
    }

    public struct WiFi: Hashable, Codable, Sendable {
        public var ssid: ASImportableEditableField?
        public var networkSecurityType: ASImportableEditableField?
        public var passphrase: ASImportableEditableField?
        public var hidden: ASImportableEditableField?

        public init(
            ssid: ASImportableEditableField?,
            networkSecurityType: ASImportableEditableField?,
            passphrase: ASImportableEditableField?,
            hidden: ASImportableEditableField? = nil
        ) {
            self.ssid = ssid
            self.networkSecurityType = networkSecurityType
            self.passphrase = passphrase
            self.hidden = hidden
        }
    }

    public struct APIKey: Hashable, Codable, Sendable {
        public var key: ASImportableEditableField?
        public var userName: ASImportableEditableField?
        public var keyType: ASImportableEditableField?
        public var url: ASImportableEditableField?
        public var validFrom: ASImportableEditableField?
        public var expiryDate: ASImportableEditableField?

        public init(
            key: ASImportableEditableField?,
            userName: ASImportableEditableField?,
            keyType: ASImportableEditableField?,
            url: ASImportableEditableField?,
            validFrom: ASImportableEditableField?,
            expiryDate: ASImportableEditableField?
        ) {
            self.key = key
            self.userName = userName
            self.keyType = keyType
            self.url = url
            self.validFrom = validFrom
            self.expiryDate = expiryDate
        }
    }

    public struct SSHKey: Hashable, Codable, Sendable {
        public var keyType: String
        public var privateKey: Data
        public var keyComment: String?
        public var creationDate: ASImportableEditableField?
        public var expiryDate: ASImportableEditableField?
        public var keyGenerationSource: ASImportableEditableField?

        public init(
            keyType: String,
            privateKey: Data,
            keyComment: String?,
            creationDate: ASImportableEditableField?,
            expiryDate: ASImportableEditableField?,
            keyGenerationSource: ASImportableEditableField?
        ) {
            self.keyType = keyType
            self.privateKey = privateKey
            self.keyComment = keyComment
            self.creationDate = creationDate
            self.expiryDate = expiryDate
            self.keyGenerationSource = keyGenerationSource
        }
    }

    public struct Address: Hashable, Codable, Sendable {
        public var streetAddress: ASImportableEditableField?
        public var postalCode: ASImportableEditableField?
        public var city: ASImportableEditableField?
        public var territory: ASImportableEditableField?
        public var country: ASImportableEditableField?
        public var telephone: ASImportableEditableField?

        public init(
            streetAddress: ASImportableEditableField?,
            postalCode: ASImportableEditableField?,
            city: ASImportableEditableField?,
            territory: ASImportableEditableField?,
            country: ASImportableEditableField?,
            telephone: ASImportableEditableField?
        ) {
            self.streetAddress = streetAddress
            self.postalCode = postalCode
            self.city = city
            self.territory = territory
            self.country = country
            self.telephone = telephone
        }
    }

    public struct Passkey: Hashable, Codable, Sendable {
        public var credentialID: Data
        public var relyingPartyIdentifier: String
        public var userName: String
        public var userDisplayName: String
        public var userHandle: Data
        public var key: Data

        public init(
            credentialID: Data,
            relyingPartyIdentifier: String,
            userName: String,
            userDisplayName: String,
            userHandle: Data,
            key: Data
        ) {
            self.credentialID = credentialID
            self.relyingPartyIdentifier = relyingPartyIdentifier
            self.userName = userName
            self.userDisplayName = userDisplayName
            self.userHandle = userHandle
            self.key = key
        }
    }

    public struct Passport: Hashable, Codable, Sendable {
        public var issuingCountry: ASImportableEditableField?
        public var passportType: ASImportableEditableField?
        public var passportNumber: ASImportableEditableField?
        public var nationalIdentificationNumber: ASImportableEditableField?
        public var nationality: ASImportableEditableField?
        public var fullName: ASImportableEditableField?
        public var birthDate: ASImportableEditableField?
        public var birthPlace: ASImportableEditableField?
        public var sex: ASImportableEditableField?
        public var issueDate: ASImportableEditableField?
        public var expiryDate: ASImportableEditableField?
        public var issuingAuthority: ASImportableEditableField?

        public init(
            issuingCountry: ASImportableEditableField?,
            passportType: ASImportableEditableField?,
            passportNumber: ASImportableEditableField?,
            nationalIdentificationNumber: ASImportableEditableField?,
            nationality: ASImportableEditableField?,
            fullName: ASImportableEditableField?,
            birthDate: ASImportableEditableField?,
            birthPlace: ASImportableEditableField?,
            sex: ASImportableEditableField?,
            issueDate: ASImportableEditableField?,
            expiryDate: ASImportableEditableField?,
            issuingAuthority: ASImportableEditableField?
        ) {
            self.issuingCountry = issuingCountry
            self.passportType = passportType
            self.passportNumber = passportNumber
            self.nationalIdentificationNumber = nationalIdentificationNumber
            self.nationality = nationality
            self.fullName = fullName
            self.birthDate = birthDate
            self.birthPlace = birthPlace
            self.sex = sex
            self.issueDate = issueDate
            self.expiryDate = expiryDate
            self.issuingAuthority = issuingAuthority
        }
    }

    case basicAuthentication(BasicAuthentication)
    case creditCard(CreditCard)
    case personName(PersonName)
    case customFields(CustomFields)
    case itemReference(ItemReference)
    case driversLicense(DriversLicense)
    case identityDocument(IdentityDocument)
    case generatedPassword(GeneratedPassword)
    case note(Note)
    case totp(TOTP)
    case wifi(WiFi)
    case apiKey(APIKey)
    case sshKey(SSHKey)
    case address(Address)
    case passkey(Passkey)
    case passport(Passport)
}

public struct ASImportableItem: Hashable, Codable, Sendable {
    public var id: Data
    public var created: Date?
    public var lastModified: Date?
    public var title: String
    public var subtitle: String?
    public var favorite: Bool
    public var scope: ASImportableCredentialScope?
    public var credentials: [ASImportableCredential]
    public var tags: [String]

    public init(
        id: Data,
        title: String,
        subtitle: String? = nil,
        favorite: Bool = false,
        scope: ASImportableCredentialScope? = nil,
        credentials: [ASImportableCredential],
        tags: [String] = []
    ) {
        self.id = id
        self.created = nil
        self.lastModified = nil
        self.title = title
        self.subtitle = subtitle
        self.favorite = favorite
        self.scope = scope
        self.credentials = credentials
        self.tags = tags
    }

    public init(
        id: Data,
        created: Date,
        lastModified: Date,
        title: String,
        subtitle: String? = nil,
        favorite: Bool = false,
        scope: ASImportableCredentialScope? = nil,
        credentials: [ASImportableCredential],
        tags: [String] = []
    ) {
        self.id = id
        self.created = created
        self.lastModified = lastModified
        self.title = title
        self.subtitle = subtitle
        self.favorite = favorite
        self.scope = scope
        self.credentials = credentials
        self.tags = tags
    }
}

public struct ASImportableCollection: Hashable, Codable, Sendable {
    public var id: Data
    public var created: Date?
    public var lastModified: Date?
    public var title: String
    public var subtitle: String?
    public var items: [ASImportableLinkedItem]
    public var subcollections: [ASImportableCollection]

    public init(
        id: Data,
        created: Date?,
        lastModified: Date?,
        title: String,
        subtitle: String? = nil,
        items: [ASImportableLinkedItem],
        subcollections: [ASImportableCollection] = []
    ) {
        self.id = id
        self.created = created
        self.lastModified = lastModified
        self.title = title
        self.subtitle = subtitle
        self.items = items
        self.subcollections = subcollections
    }
}

public struct ASImportableAccount: Hashable, Codable, Sendable {
    public var id: Data
    public var userName: String
    public var email: String
    public var fullName: String?
    public var collections: [ASImportableCollection]
    public var items: [ASImportableItem]

    public init(
        id: Data,
        userName: String,
        email: String,
        fullName: String? = nil,
        collections: [ASImportableCollection],
        items: [ASImportableItem]
    ) {
        self.id = id
        self.userName = userName
        self.email = email
        self.fullName = fullName
        self.collections = collections
        self.items = items
    }
}

public struct ASExportedCredentialData: Hashable, Codable, Sendable {
    public enum FormatVersion: String, Hashable, Codable, Sendable, CaseIterable {
        case v1
    }

    public var accounts: [ASImportableAccount]
    public let formatVersion: FormatVersion
    public let exporterRelyingPartyIdentifier: String
    public let exporterDisplayName: String
    public let timestamp: Date

    public init(
        accounts: [ASImportableAccount],
        formatVersion: FormatVersion,
        exporterRelyingPartyIdentifier: String,
        exporterDisplayName: String,
        timestamp: Date
    ) {
        self.accounts = accounts
        self.formatVersion = formatVersion
        self.exporterRelyingPartyIdentifier = exporterRelyingPartyIdentifier
        self.exporterDisplayName = exporterDisplayName
        self.timestamp = timestamp
    }
}

public struct ASEmailIdentifier: Hashable, Codable, Sendable {
    public var value: String

    public init(value: String) {
        self.value = value
    }
}

public struct ASPhoneNumberIdentifier: Hashable, Codable, Sendable {
    public var value: String

    public init(value: String) {
        self.value = value
    }
}

public enum ASContactIdentifier: Hashable, Codable, Sendable {
    case phoneNumber(ASPhoneNumberIdentifier)
    case email(ASEmailIdentifier)
}

public enum ASContactIdentifierRequest: Hashable, Codable, Sendable {
    case phoneNumber
    case email
}

public final class ASCredentialExportManager: NSObject, @unchecked Sendable {
    public struct ExportOptions: Hashable, Codable, Sendable {
        public let formatVersion: ASExportedCredentialData.FormatVersion

        public init(formatVersion: ASExportedCredentialData.FormatVersion) {
            self.formatVersion = formatVersion
        }
    }

    public override init() {
        super.init()
    }

    public func requestExport(for extensionBundleIdentifier: String? = nil) async throws -> ExportOptions {
        _ = extensionBundleIdentifier
        throw ASAuthorizationError(.credentialExport)
    }

    public func exportCredentials(_ credentialData: ASExportedCredentialData) async throws {
        _ = credentialData
        throw ASAuthorizationError(.credentialExport)
    }
}

public final class ASCredentialImportManager: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        _ = token
        throw ASAuthorizationError(.credentialImport)
    }
}
