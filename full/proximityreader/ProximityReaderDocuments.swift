import Foundation

public final class MobileDocumentReader: @unchecked Sendable {
    public static var isSupported: Bool { false }

    public init() {}

    public final var configuration: MobileDocumentReader.Configuration {
        get async throws {
            throw MobileDocumentReaderError.notSupported
        }
    }

    public final func prepare(using token: MobileDocumentReader.Token? = nil) async throws -> MobileDocumentReaderSession {
        _ = token
        throw MobileDocumentReaderError.notSupported
    }

    public struct Configuration: Hashable, Sendable {
        public let readerInstanceIdentifier: String

        public init(readerInstanceIdentifier: String) {
            self.readerInstanceIdentifier = readerInstanceIdentifier
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(readerInstanceIdentifier)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public struct Token: Hashable, Sendable {
        public let tokenString: String

        public init(_ tokenString: String) {
            self.tokenString = tokenString
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(tokenString)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

public enum MobileDocumentReaderError: Error, Hashable, LocalizedError, Sendable {
    case notAllowed
    case systemBusy
    case invalidToken
    case notSupported
    case invalidRequest
    case sessionExpired
    case invalidResponse
    case networkUnavailable
    case serviceUnavailable
    case unknown
    case cancelled

    public var errorDescription: String? {
        "MobileDocumentReaderError.\(String(describing: self))"
    }

    public var failureReason: String? { nil }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
    public var localizedDescription: String { errorDescription ?? "MobileDocumentReaderError" }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: self))
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

public final class MobileDocumentReaderSession: @unchecked Sendable {
    public init() {}

    @discardableResult
    public final func requestDocument<Request>(_ request: Request) async throws -> Request.Response
        where Request: MobileDocumentRequest
    {
        _ = request
        throw MobileDocumentReaderError.notSupported
    }
}

public struct MobilePhotoIDDataRequest: Hashable, Sendable, MobileDocumentDataRequest {
    public var retainedElements: [Element]
    public var nonRetainedElements: [Element]

    public init(
        retainedElements: [MobilePhotoIDDataRequest.Element] = [],
        nonRetainedElements: [MobilePhotoIDDataRequest.Element] = []
    ) {
        self.retainedElements = retainedElements
        self.nonRetainedElements = nonRetainedElements
    }

    public static func photoIDData(
        retaining retainedElements: [MobilePhotoIDDataRequest.Element],
        notRetaining nonRetainedElements: [MobilePhotoIDDataRequest.Element]
    ) -> Self {
        Self(retainedElements: retainedElements, nonRetainedElements: nonRetainedElements)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(retainedElements)
        hasher.combine(nonRetainedElements)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobilePhotoIDDataRequest.Element {
            MobilePhotoIDDataRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobilePhotoIDDataRequest.Element(identifier: "familyName")
        public static let dateOfBirth = MobilePhotoIDDataRequest.Element(identifier: "dateOfBirth")
        public static let documentNumber = MobilePhotoIDDataRequest.Element(identifier: "documentNumber")
        public static let issuingAuthority = MobilePhotoIDDataRequest.Element(identifier: "issuingAuthority")
        public static let documentIssueDate = MobilePhotoIDDataRequest.Element(identifier: "documentIssueDate")
        public static let documentExpirationDate = MobilePhotoIDDataRequest.Element(identifier: "documentExpirationDate")
        public static let age = MobilePhotoIDDataRequest.Element(identifier: "age")
        public static let sex = MobilePhotoIDDataRequest.Element(identifier: "sex")
        public static let address = MobilePhotoIDDataRequest.Element(identifier: "address")
        public static let portrait = MobilePhotoIDDataRequest.Element(identifier: "portrait")
        public static let givenName = MobilePhotoIDDataRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Response: Hashable, Sendable, MobileDocumentDataResponse {
        public let documentElements: DocumentElements

        public init(documentElements: DocumentElements) {
            self.documentElements = documentElements
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(documentElements)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public struct DocumentElements: Hashable, Sendable {
            public let ageAtLeastElements: [Int: Bool]
            public let dateOfBirth: DateComponents?
            public let portraitData: Data?
            public let documentNumber: String?
            public let nameComponents: PersonNameComponents?
            public let issuingAuthority: IssuingAuthority?
            public let documentIssueDate: DateComponents?
            public let documentExpirationDate: DateComponents?
            public let age: Int?
            public let sex: Sex?
            public var address: CNPostalAddress?

            public init(
                ageAtLeastElements: [Int: Bool] = [:],
                dateOfBirth: DateComponents? = nil,
                portraitData: Data? = nil,
                documentNumber: String? = nil,
                nameComponents: PersonNameComponents? = nil,
                issuingAuthority: IssuingAuthority? = nil,
                documentIssueDate: DateComponents? = nil,
                documentExpirationDate: DateComponents? = nil,
                age: Int? = nil,
                sex: Sex? = nil,
                address: CNPostalAddress? = nil
            ) {
                self.ageAtLeastElements = ageAtLeastElements
                self.dateOfBirth = dateOfBirth
                self.portraitData = portraitData
                self.documentNumber = documentNumber
                self.nameComponents = nameComponents
                self.issuingAuthority = issuingAuthority
                self.documentIssueDate = documentIssueDate
                self.documentExpirationDate = documentExpirationDate
                self.age = age
                self.sex = sex
                self.address = address
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(ageAtLeastElements)
                hasher.combine(dateOfBirth)
                hasher.combine(portraitData)
                hasher.combine(documentNumber)
                hasher.combine(nameComponents)
                hasher.combine(issuingAuthority)
                hasher.combine(documentIssueDate)
                hasher.combine(documentExpirationDate)
                hasher.combine(age)
                hasher.combine(sex)
                hasher.combine(address)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }

            public struct IssuingAuthority: Hashable, Sendable {
                public let jurisdiction: String?
                public let isoCountryCode: String?
                public let name: String?

                public init(jurisdiction: String? = nil, isoCountryCode: String? = nil, name: String? = nil) {
                    self.jurisdiction = jurisdiction
                    self.isoCountryCode = isoCountryCode
                    self.name = name
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(jurisdiction)
                    hasher.combine(isoCountryCode)
                    hasher.combine(name)
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }

            public enum Sex: Hashable, Sendable {
                case notApplicable
                case male
                case female
                case unknown

                public var localizedName: String {
                    switch self {
                    case .notApplicable: return "Not Applicable"
                    case .male: return "Male"
                    case .female: return "Female"
                    case .unknown: return "Unknown"
                    }
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(String(describing: self))
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }
        }
    }
}

extension MobileDocumentRequest where Self == MobilePhotoIDDataRequest {
    public static func photoIDData(
        retaining retainedElements: [MobilePhotoIDDataRequest.Element],
        notRetaining nonRetainedElements: [MobilePhotoIDDataRequest.Element]
    ) -> Self {
        Self.photoIDData(retaining: retainedElements, notRetaining: nonRetainedElements)
    }
}

public struct MobilePhotoIDRawDataRequest: Hashable, Sendable, MobileDocumentRawDataRequest {
    public var retainedElements: [Element]
    public var nonRetainedElements: [Element]

    public init(
        retainedElements: [MobilePhotoIDRawDataRequest.Element] = [],
        nonRetainedElements: [MobilePhotoIDRawDataRequest.Element] = []
    ) {
        self.retainedElements = retainedElements
        self.nonRetainedElements = nonRetainedElements
    }

    public static func photoIDRawData(
        retaining retainedElements: [MobilePhotoIDRawDataRequest.Element],
        notRetaining nonRetainedElements: [MobilePhotoIDRawDataRequest.Element]
    ) -> Self {
        Self(retainedElements: retainedElements, nonRetainedElements: nonRetainedElements)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(retainedElements)
        hasher.combine(nonRetainedElements)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobilePhotoIDRawDataRequest.Element {
            MobilePhotoIDRawDataRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobilePhotoIDRawDataRequest.Element(identifier: "familyName")
        public static let dateOfBirth = MobilePhotoIDRawDataRequest.Element(identifier: "dateOfBirth")
        public static let documentNumber = MobilePhotoIDRawDataRequest.Element(identifier: "documentNumber")
        public static let issuingAuthority = MobilePhotoIDRawDataRequest.Element(identifier: "issuingAuthority")
        public static let documentIssueDate = MobilePhotoIDRawDataRequest.Element(identifier: "documentIssueDate")
        public static let documentExpirationDate = MobilePhotoIDRawDataRequest.Element(identifier: "documentExpirationDate")
        public static let age = MobilePhotoIDRawDataRequest.Element(identifier: "age")
        public static let sex = MobilePhotoIDRawDataRequest.Element(identifier: "sex")
        public static let address = MobilePhotoIDRawDataRequest.Element(identifier: "address")
        public static let portrait = MobilePhotoIDRawDataRequest.Element(identifier: "portrait")
        public static let givenName = MobilePhotoIDRawDataRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Response: Hashable, Sendable {
        public let responseData: Data
        public let sessionTranscript: Data

        public init(responseData: Data, sessionTranscript: Data) {
            self.responseData = responseData
            self.sessionTranscript = sessionTranscript
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(responseData)
            hasher.combine(sessionTranscript)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

extension MobileDocumentRequest where Self == MobilePhotoIDRawDataRequest {
    public static func photoIDRawData(
        retaining retainedElements: [MobilePhotoIDRawDataRequest.Element],
        notRetaining nonRetainedElements: [MobilePhotoIDRawDataRequest.Element]
    ) -> Self {
        Self.photoIDRawData(retaining: retainedElements, notRetaining: nonRetainedElements)
    }
}

public struct MobileDocumentDisplayRequest: Hashable, Sendable, MobileDocumentRequest {
    public var elements: [Element]
    public var options: Options

    public init(
        elements: [MobileDocumentDisplayRequest.Element] = [],
        options: MobileDocumentDisplayRequest.Options = .init()
    ) {
        self.elements = elements
        self.options = options
    }

    public static func displayDocument(
        _ elements: [MobileDocumentDisplayRequest.Element],
        options: MobileDocumentDisplayRequest.Options
    ) -> Self {
        Self(elements: elements, options: options)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
        hasher.combine(options)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileDocumentDisplayRequest.Element {
            MobileDocumentDisplayRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileDocumentDisplayRequest.Element(identifier: "familyName")
        public static let age = MobileDocumentDisplayRequest.Element(identifier: "age")
        public static let givenName = MobileDocumentDisplayRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Options: Hashable, Sendable {
        public var allowedDocumentTypes: [DocumentType]
        public var validationMode: ValidationMode

        public init(
            allowedDocumentTypes: [MobileDocumentDisplayRequest.Options.DocumentType] = [],
            validationMode: MobileDocumentDisplayRequest.Options.ValidationMode = .check
        ) {
            self.allowedDocumentTypes = allowedDocumentTypes
            self.validationMode = validationMode
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(allowedDocumentTypes)
            hasher.combine(validationMode)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public struct DocumentType: Hashable, Sendable {
            internal let identifier: String
            internal let region: Locale.Region?

            public static let driversLicense = DocumentType(identifier: "driversLicense", region: nil)
            public static let photoID = DocumentType(identifier: "photoID", region: nil)

            public static func nationalIDCard(region: Locale.Region) -> MobileDocumentDisplayRequest.Options.DocumentType {
                DocumentType(identifier: "nationalIDCard", region: region)
            }

            internal init(identifier: String, region: Locale.Region?) {
                self.identifier = identifier
                self.region = region
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
                hasher.combine(region)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }

        public struct ValidationMode: Hashable, Sendable {
            internal let identifier: String
            public static let checkMultiple = ValidationMode(identifier: "checkMultiple")
            public static let check = ValidationMode(identifier: "check")
            public static let confirm = ValidationMode(identifier: "confirm")

            internal init(identifier: String) {
                self.identifier = identifier
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }

    public struct Response: Hashable, Sendable {
        public let validationOutcome: ValidationOutcome

        public init(validationOutcome: ValidationOutcome) {
            self.validationOutcome = validationOutcome
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(validationOutcome)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public enum ValidationOutcome: Hashable, Sendable {
            case approved
            case rejected
            case dismissed

            public func hash(into hasher: inout Hasher) {
                hasher.combine(String(describing: self))
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }
}

extension MobileDocumentRequest where Self == MobileDocumentDisplayRequest {
    public static func displayDocument(
        _ elements: [MobileDocumentDisplayRequest.Element],
        options: MobileDocumentDisplayRequest.Options
    ) -> Self {
        Self.displayDocument(elements, options: options)
    }
}

public struct MobileDocumentAnyOfDataRequest: Hashable, Sendable, MobileDocumentRequest {
    internal var stored: [MobilePhotoIDDataRequest]

    public init() {
        stored = []
    }

    public mutating func addRequest(_ request: any MobileDocumentDataRequest) {
        if let photo = request as? MobilePhotoIDDataRequest {
            stored.append(photo)
        } else if let boxed = request as? MobileDriversLicenseDataRequest {
            stored.append(
                MobilePhotoIDDataRequest(
                    retainedElements: [],
                    nonRetainedElements: []
                )
            )
            _ = boxed
            stored[stored.count - 1] = MobilePhotoIDDataRequest(
                retainedElements: [MobilePhotoIDDataRequest.Element.familyName],
                nonRetainedElements: []
            )
        } else if let boxed = request as? MobileNationalIDCardDataRequest {
            _ = boxed
            stored.append(
                MobilePhotoIDDataRequest(
                    retainedElements: [MobilePhotoIDDataRequest.Element.givenName],
                    nonRetainedElements: []
                )
            )
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stored)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Response: Hashable, Sendable {
        internal let boxed: MobilePhotoIDDataRequest.Response

        public var documentResponse: any MobileDocumentDataResponse { boxed }

        public init(documentResponse: MobilePhotoIDDataRequest.Response) {
            self.boxed = documentResponse
        }

        public static func == (lhs: Response, rhs: Response) -> Bool {
            lhs.boxed == rhs.boxed
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(boxed)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

public struct MobileDriversLicenseDataRequest: Hashable, Sendable, MobileDocumentDataRequest {
    public var retainedElements: [Element]
    public var nonRetainedElements: [Element]

    public init(
        retainedElements: [MobileDriversLicenseDataRequest.Element] = [],
        nonRetainedElements: [MobileDriversLicenseDataRequest.Element] = []
    ) {
        self.retainedElements = retainedElements
        self.nonRetainedElements = nonRetainedElements
    }

    public static func driversLicenseData(
        retaining retainedElements: [MobileDriversLicenseDataRequest.Element],
        notRetaining nonRetainedElements: [MobileDriversLicenseDataRequest.Element]
    ) -> Self {
        Self(retainedElements: retainedElements, nonRetainedElements: nonRetainedElements)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(retainedElements)
        hasher.combine(nonRetainedElements)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileDriversLicenseDataRequest.Element {
            MobileDriversLicenseDataRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileDriversLicenseDataRequest.Element(identifier: "familyName")
        public static let dateOfBirth = MobileDriversLicenseDataRequest.Element(identifier: "dateOfBirth")
        public static let veteranStatus = MobileDriversLicenseDataRequest.Element(identifier: "veteranStatus")
        public static let documentNumber = MobileDriversLicenseDataRequest.Element(identifier: "documentNumber")
        public static let issuingAuthority = MobileDriversLicenseDataRequest.Element(identifier: "issuingAuthority")
        public static let organDonorStatus = MobileDriversLicenseDataRequest.Element(identifier: "organDonorStatus")
        public static let documentIssueDate = MobileDriversLicenseDataRequest.Element(identifier: "documentIssueDate")
        public static let drivingPrivileges = MobileDriversLicenseDataRequest.Element(identifier: "drivingPrivileges")
        public static let documentExpirationDate = MobileDriversLicenseDataRequest.Element(identifier: "documentExpirationDate")
        public static let documentDHSComplianceStatus = MobileDriversLicenseDataRequest.Element(identifier: "documentDHSComplianceStatus")
        public static let age = MobileDriversLicenseDataRequest.Element(identifier: "age")
        public static let sex = MobileDriversLicenseDataRequest.Element(identifier: "sex")
        public static let height = MobileDriversLicenseDataRequest.Element(identifier: "height")
        public static let weight = MobileDriversLicenseDataRequest.Element(identifier: "weight")
        public static let address = MobileDriversLicenseDataRequest.Element(identifier: "address")
        public static let eyeColor = MobileDriversLicenseDataRequest.Element(identifier: "eyeColor")
        public static let portrait = MobileDriversLicenseDataRequest.Element(identifier: "portrait")
        public static let givenName = MobileDriversLicenseDataRequest.Element(identifier: "givenName")
        public static let hairColor = MobileDriversLicenseDataRequest.Element(identifier: "hairColor")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Response: Hashable, Sendable, MobileDocumentDataResponse {
        public let documentElements: DocumentElements

        public init(documentElements: DocumentElements) {
            self.documentElements = documentElements
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(documentElements)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public struct DocumentElements: Hashable, Sendable {
            public let ageAtLeastElements: [Int: Bool]
            public let portraitData: Data?
            public let dateOfBirth: DateComponents?
            public let isOrganDonor: Bool?
            public let documentNumber: String?
            public let nameComponents: PersonNameComponents?
            public let issuingAuthority: IssuingAuthority?
            public let documentIssueDate: DateComponents?
            public let drivingPrivileges: [DrivingPrivilege]
            public let aamvaDrivingPrivileges: [AAMVADrivingPrivilege]
            public let documentExpirationDate: DateComponents?
            public let documentDHSComplianceStatus: DHSComplianceStatus?
            public let age: Int?
            public let sex: Sex?
            public let height: Measurement<UnitLength>?
            public let weight: Measurement<UnitMass>?
            public var address: CNPostalAddress?
            public let eyeColor: EyeColor?
            public let hairColor: HairColor?
            public let isVeteran: Bool?

            public init(
                ageAtLeastElements: [Int: Bool] = [:],
                portraitData: Data? = nil,
                dateOfBirth: DateComponents? = nil,
                isOrganDonor: Bool? = nil,
                documentNumber: String? = nil,
                nameComponents: PersonNameComponents? = nil,
                issuingAuthority: IssuingAuthority? = nil,
                documentIssueDate: DateComponents? = nil,
                drivingPrivileges: [DrivingPrivilege] = [],
                aamvaDrivingPrivileges: [AAMVADrivingPrivilege] = [],
                documentExpirationDate: DateComponents? = nil,
                documentDHSComplianceStatus: DHSComplianceStatus? = nil,
                age: Int? = nil,
                sex: Sex? = nil,
                height: Measurement<UnitLength>? = nil,
                weight: Measurement<UnitMass>? = nil,
                address: CNPostalAddress? = nil,
                eyeColor: EyeColor? = nil,
                hairColor: HairColor? = nil,
                isVeteran: Bool? = nil
            ) {
                self.ageAtLeastElements = ageAtLeastElements
                self.portraitData = portraitData
                self.dateOfBirth = dateOfBirth
                self.isOrganDonor = isOrganDonor
                self.documentNumber = documentNumber
                self.nameComponents = nameComponents
                self.issuingAuthority = issuingAuthority
                self.documentIssueDate = documentIssueDate
                self.drivingPrivileges = drivingPrivileges
                self.aamvaDrivingPrivileges = aamvaDrivingPrivileges
                self.documentExpirationDate = documentExpirationDate
                self.documentDHSComplianceStatus = documentDHSComplianceStatus
                self.age = age
                self.sex = sex
                self.height = height
                self.weight = weight
                self.address = address
                self.eyeColor = eyeColor
                self.hairColor = hairColor
                self.isVeteran = isVeteran
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(ageAtLeastElements)
                hasher.combine(portraitData)
                hasher.combine(dateOfBirth)
                hasher.combine(isOrganDonor)
                hasher.combine(documentNumber)
                hasher.combine(nameComponents)
                hasher.combine(issuingAuthority)
                hasher.combine(documentIssueDate)
                hasher.combine(drivingPrivileges)
                hasher.combine(aamvaDrivingPrivileges)
                hasher.combine(documentExpirationDate)
                hasher.combine(documentDHSComplianceStatus)
                hasher.combine(age)
                hasher.combine(sex)
                hasher.combine(height)
                hasher.combine(weight)
                hasher.combine(address)
                hasher.combine(eyeColor)
                hasher.combine(hairColor)
                hasher.combine(isVeteran)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }

            public struct DrivingPrivilege: Hashable, Sendable {
                public let expirationDate: DateComponents?
                public let vehicleCategoryCode: String
                public let codes: [Code]
                public let issueDate: DateComponents?

                public init(
                    vehicleCategoryCode: String,
                    codes: [Code] = [],
                    issueDate: DateComponents? = nil,
                    expirationDate: DateComponents? = nil
                ) {
                    self.vehicleCategoryCode = vehicleCategoryCode
                    self.codes = codes
                    self.issueDate = issueDate
                    self.expirationDate = expirationDate
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(expirationDate)
                    hasher.combine(vehicleCategoryCode)
                    hasher.combine(codes)
                    hasher.combine(issueDate)
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }

                public struct Code: Hashable, Sendable {
                    public let code: String
                    public let sign: String?
                    public let value: String?

                    public init(code: String, sign: String? = nil, value: String? = nil) {
                        self.code = code
                        self.sign = sign
                        self.value = value
                    }

                    public func hash(into hasher: inout Hasher) {
                        hasher.combine(code)
                        hasher.combine(sign)
                        hasher.combine(value)
                    }

                    public var hashValue: Int {
                        var hasher = Hasher()
                        hash(into: &hasher)
                        return hasher.finalize()
                    }
                }
            }

            public struct IssuingAuthority: Hashable, Sendable {
                public let jurisdiction: String?
                public let isoCountryCode: String?
                public let name: String?

                public init(jurisdiction: String? = nil, isoCountryCode: String? = nil, name: String? = nil) {
                    self.jurisdiction = jurisdiction
                    self.isoCountryCode = isoCountryCode
                    self.name = name
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(jurisdiction)
                    hasher.combine(isoCountryCode)
                    hasher.combine(name)
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }

            public enum DHSComplianceStatus: Hashable, Sendable {
                case noncompliant
                case compliant

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(String(describing: self))
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }

            public struct AAMVADrivingPrivilege: Hashable, Sendable {
                public let vehicleClass: VehicleClass?
                public let vehicleEndorsements: [VehicleEndorsement]
                public let vehicleRestrictions: [VehicleRestriction]

                public init(
                    vehicleClass: VehicleClass? = nil,
                    vehicleEndorsements: [VehicleEndorsement] = [],
                    vehicleRestrictions: [VehicleRestriction] = []
                ) {
                    self.vehicleClass = vehicleClass
                    self.vehicleEndorsements = vehicleEndorsements
                    self.vehicleRestrictions = vehicleRestrictions
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(vehicleClass)
                    hasher.combine(vehicleEndorsements)
                    hasher.combine(vehicleRestrictions)
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }

                public struct VehicleClass: Hashable, Sendable {
                    public let description: String
                    public let expirationDate: DateComponents?
                    public let code: String
                    public let issueDate: DateComponents?

                    public init(
                        code: String,
                        description: String,
                        issueDate: DateComponents? = nil,
                        expirationDate: DateComponents? = nil
                    ) {
                        self.code = code
                        self.description = description
                        self.issueDate = issueDate
                        self.expirationDate = expirationDate
                    }

                    public func hash(into hasher: inout Hasher) {
                        hasher.combine(description)
                        hasher.combine(expirationDate)
                        hasher.combine(code)
                        hasher.combine(issueDate)
                    }

                    public var hashValue: Int {
                        var hasher = Hasher()
                        hash(into: &hasher)
                        return hasher.finalize()
                    }
                }

                public struct VehicleEndorsement: Hashable, Sendable {
                    public let description: String
                    public let code: String?

                    public init(code: String? = nil, description: String) {
                        self.code = code
                        self.description = description
                    }

                    public func hash(into hasher: inout Hasher) {
                        hasher.combine(description)
                        hasher.combine(code)
                    }

                    public var hashValue: Int {
                        var hasher = Hasher()
                        hash(into: &hasher)
                        return hasher.finalize()
                    }
                }

                public struct VehicleRestriction: Hashable, Sendable {
                    public let description: String
                    public let code: String?

                    public init(code: String? = nil, description: String) {
                        self.code = code
                        self.description = description
                    }

                    public func hash(into hasher: inout Hasher) {
                        hasher.combine(description)
                        hasher.combine(code)
                    }

                    public var hashValue: Int {
                        var hasher = Hasher()
                        hash(into: &hasher)
                        return hasher.finalize()
                    }
                }
            }

            public enum Sex: Hashable, Sendable {
                case notSpecified
                case notApplicable
                case male
                case female
                case unknown

                public var localizedName: String {
                    switch self {
                    case .notSpecified: return "Not Specified"
                    case .notApplicable: return "Not Applicable"
                    case .male: return "Male"
                    case .female: return "Female"
                    case .unknown: return "Unknown"
                    }
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(String(describing: self))
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }

            public enum EyeColor: Hashable, Sendable {
                case dichromatic, blue, grey, pink, black, brown, green, hazel, maroon, unknown

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(String(describing: self))
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }

            public enum HairColor: Hashable, Sendable {
                case red, bald, grey, black, blond, brown, sandy, white, auburn, unknown

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(String(describing: self))
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }
        }
    }
}

extension MobileDocumentRequest where Self == MobileDriversLicenseDataRequest {
    public static func driversLicenseData(
        retaining retainedElements: [MobileDriversLicenseDataRequest.Element],
        notRetaining nonRetainedElements: [MobileDriversLicenseDataRequest.Element]
    ) -> Self {
        Self.driversLicenseData(retaining: retainedElements, notRetaining: nonRetainedElements)
    }
}

public struct MobileNationalIDCardDataRequest: Hashable, Sendable, MobileDocumentDataRequest {
    public var region: Locale.Region
    public var retainedElements: [Element]
    public var nonRetainedElements: [Element]

    public init(
        region: Locale.Region,
        retainedElements: [MobileNationalIDCardDataRequest.Element] = [],
        nonRetainedElements: [MobileNationalIDCardDataRequest.Element] = []
    ) {
        self.region = region
        self.retainedElements = retainedElements
        self.nonRetainedElements = nonRetainedElements
    }

    public static func isSupportedRegion(_ region: Locale.Region) -> Bool {
        _ = region
        return false
    }

    public static func nationalIDCardData(
        region: Locale.Region,
        retaining retainedElements: [MobileNationalIDCardDataRequest.Element] = [],
        notRetaining nonRetainedElements: [MobileNationalIDCardDataRequest.Element] = []
    ) -> Self {
        Self(region: region, retainedElements: retainedElements, nonRetainedElements: nonRetainedElements)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(region)
        hasher.combine(retainedElements)
        hasher.combine(nonRetainedElements)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileNationalIDCardDataRequest.Element {
            MobileNationalIDCardDataRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileNationalIDCardDataRequest.Element(identifier: "familyName")
        public static let dateOfBirth = MobileNationalIDCardDataRequest.Element(identifier: "dateOfBirth")
        public static let documentNumber = MobileNationalIDCardDataRequest.Element(identifier: "documentNumber")
        public static let age = MobileNationalIDCardDataRequest.Element(identifier: "age")
        public static let sex = MobileNationalIDCardDataRequest.Element(identifier: "sex")
        public static let portrait = MobileNationalIDCardDataRequest.Element(identifier: "portrait")
        public static let givenName = MobileNationalIDCardDataRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Response: Hashable, Sendable, MobileDocumentDataResponse {
        public let documentElements: DocumentElements
        public let region: Locale.Region

        public init(documentElements: DocumentElements, region: Locale.Region) {
            self.documentElements = documentElements
            self.region = region
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(documentElements)
            hasher.combine(region)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public struct DocumentElements: Hashable, Sendable {
            public let ageAtLeastElements: [Int: Bool]
            public let portraitData: Data?
            public let dateOfBirth: DateComponents?
            public let documentNumber: String?
            public let nameComponents: PersonNameComponents?
            public let age: Int?
            public let sex: Sex?

            public init(
                ageAtLeastElements: [Int: Bool] = [:],
                portraitData: Data? = nil,
                dateOfBirth: DateComponents? = nil,
                documentNumber: String? = nil,
                nameComponents: PersonNameComponents? = nil,
                age: Int? = nil,
                sex: Sex? = nil
            ) {
                self.ageAtLeastElements = ageAtLeastElements
                self.portraitData = portraitData
                self.dateOfBirth = dateOfBirth
                self.documentNumber = documentNumber
                self.nameComponents = nameComponents
                self.age = age
                self.sex = sex
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(ageAtLeastElements)
                hasher.combine(portraitData)
                hasher.combine(dateOfBirth)
                hasher.combine(documentNumber)
                hasher.combine(nameComponents)
                hasher.combine(age)
                hasher.combine(sex)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }

            public enum Sex: Hashable, Sendable {
                case notApplicable
                case male
                case female
                case unknown

                public var localizedName: String {
                    switch self {
                    case .notApplicable: return "Not Applicable"
                    case .male: return "Male"
                    case .female: return "Female"
                    case .unknown: return "Unknown"
                    }
                }

                public func hash(into hasher: inout Hasher) {
                    hasher.combine(String(describing: self))
                }

                public var hashValue: Int {
                    var hasher = Hasher()
                    hash(into: &hasher)
                    return hasher.finalize()
                }
            }
        }
    }
}

extension MobileDocumentRequest where Self == MobileNationalIDCardDataRequest {
    public static func nationalIDCardData(
        region: Locale.Region,
        retaining retainedElements: [MobileNationalIDCardDataRequest.Element] = [],
        notRetaining nonRetainedElements: [MobileNationalIDCardDataRequest.Element] = []
    ) -> Self {
        Self.nationalIDCardData(
            region: region,
            retaining: retainedElements,
            notRetaining: nonRetainedElements
        )
    }
}

public struct MobileDocumentAnyOfRawDataRequest: Hashable, Sendable, MobileDocumentRequest {
    internal var stored: [MobilePhotoIDRawDataRequest]

    public init() {
        stored = []
    }

    public mutating func addRequest(_ request: any MobileDocumentRawDataRequest) {
        if let photo = request as? MobilePhotoIDRawDataRequest {
            stored.append(photo)
        } else {
            stored.append(MobilePhotoIDRawDataRequest())
            _ = request
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stored)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Response: Hashable, Sendable {
        public let responseData: Data
        public let sessionTranscript: Data

        public init(responseData: Data, sessionTranscript: Data) {
            self.responseData = responseData
            self.sessionTranscript = sessionTranscript
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(responseData)
            hasher.combine(sessionTranscript)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

public struct MobileDriversLicenseDisplayRequest: Hashable, Sendable, MobileDocumentRequest {
    public var elements: [Element]
    public var options: Options

    public init(
        elements: [MobileDriversLicenseDisplayRequest.Element] = [],
        options: MobileDriversLicenseDisplayRequest.Options = .init()
    ) {
        self.elements = elements
        self.options = options
    }

    public static func displayDriversLicense(
        _ elements: [MobileDriversLicenseDisplayRequest.Element],
        options: MobileDriversLicenseDisplayRequest.Options = .init()
    ) -> Self {
        Self(elements: elements, options: options)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
        hasher.combine(options)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileDriversLicenseDisplayRequest.Element {
            MobileDriversLicenseDisplayRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileDriversLicenseDisplayRequest.Element(identifier: "familyName")
        public static let age = MobileDriversLicenseDisplayRequest.Element(identifier: "age")
        public static let givenName = MobileDriversLicenseDisplayRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Options: Hashable, Sendable {
        public var validationMode: ValidationMode

        public init(validationMode: MobileDriversLicenseDisplayRequest.Options.ValidationMode = .check) {
            self.validationMode = validationMode
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(validationMode)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public struct ValidationMode: Hashable, Sendable {
            internal let identifier: String
            public static let checkMultiple = ValidationMode(identifier: "checkMultiple")
            public static let check = ValidationMode(identifier: "check")
            public static let confirm = ValidationMode(identifier: "confirm")

            internal init(identifier: String) {
                self.identifier = identifier
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }

    public struct Response: Hashable, Sendable {
        public let validationOutcome: ValidationOutcome

        public init(validationOutcome: ValidationOutcome) {
            self.validationOutcome = validationOutcome
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(validationOutcome)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public enum ValidationOutcome: Hashable, Sendable {
            case approved
            case rejected
            case dismissed

            public func hash(into hasher: inout Hasher) {
                hasher.combine(String(describing: self))
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }
}

extension MobileDocumentRequest where Self == MobileDriversLicenseDisplayRequest {
    public static func displayDriversLicense(
        _ elements: [MobileDriversLicenseDisplayRequest.Element],
        options: MobileDriversLicenseDisplayRequest.Options = .init()
    ) -> Self {
        Self.displayDriversLicense(elements, options: options)
    }
}

public struct MobileDriversLicenseRawDataRequest: Hashable, Sendable, MobileDocumentRawDataRequest {
    public var retainedElements: [Element]
    public var nonRetainedElements: [Element]

    public init(
        retainedElements: [MobileDriversLicenseRawDataRequest.Element] = [],
        nonRetainedElements: [MobileDriversLicenseRawDataRequest.Element] = []
    ) {
        self.retainedElements = retainedElements
        self.nonRetainedElements = nonRetainedElements
    }

    public static func driversLicenseRawData(
        retaining retainedElements: [MobileDriversLicenseRawDataRequest.Element],
        notRetaining nonRetainedElements: [MobileDriversLicenseRawDataRequest.Element]
    ) -> Self {
        Self(retainedElements: retainedElements, nonRetainedElements: nonRetainedElements)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(retainedElements)
        hasher.combine(nonRetainedElements)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileDriversLicenseRawDataRequest.Element {
            MobileDriversLicenseRawDataRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileDriversLicenseRawDataRequest.Element(identifier: "familyName")
        public static let dateOfBirth = MobileDriversLicenseRawDataRequest.Element(identifier: "dateOfBirth")
        public static let veteranStatus = MobileDriversLicenseRawDataRequest.Element(identifier: "veteranStatus")
        public static let documentNumber = MobileDriversLicenseRawDataRequest.Element(identifier: "documentNumber")
        public static let issuingAuthority = MobileDriversLicenseRawDataRequest.Element(identifier: "issuingAuthority")
        public static let organDonorStatus = MobileDriversLicenseRawDataRequest.Element(identifier: "organDonorStatus")
        public static let documentIssueDate = MobileDriversLicenseRawDataRequest.Element(identifier: "documentIssueDate")
        public static let drivingPrivileges = MobileDriversLicenseRawDataRequest.Element(identifier: "drivingPrivileges")
        public static let documentExpirationDate = MobileDriversLicenseRawDataRequest.Element(identifier: "documentExpirationDate")
        public static let documentDHSComplianceStatus = MobileDriversLicenseRawDataRequest.Element(identifier: "documentDHSComplianceStatus")
        public static let age = MobileDriversLicenseRawDataRequest.Element(identifier: "age")
        public static let sex = MobileDriversLicenseRawDataRequest.Element(identifier: "sex")
        public static let height = MobileDriversLicenseRawDataRequest.Element(identifier: "height")
        public static let weight = MobileDriversLicenseRawDataRequest.Element(identifier: "weight")
        public static let address = MobileDriversLicenseRawDataRequest.Element(identifier: "address")
        public static let eyeColor = MobileDriversLicenseRawDataRequest.Element(identifier: "eyeColor")
        public static let portrait = MobileDriversLicenseRawDataRequest.Element(identifier: "portrait")
        public static let givenName = MobileDriversLicenseRawDataRequest.Element(identifier: "givenName")
        public static let hairColor = MobileDriversLicenseRawDataRequest.Element(identifier: "hairColor")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Response: Hashable, Sendable {
        public let responseData: Data
        public let sessionTranscript: Data

        public init(responseData: Data, sessionTranscript: Data) {
            self.responseData = responseData
            self.sessionTranscript = sessionTranscript
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(responseData)
            hasher.combine(sessionTranscript)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

extension MobileDocumentRequest where Self == MobileDriversLicenseRawDataRequest {
    public static func driversLicenseRawData(
        retaining retainedElements: [MobileDriversLicenseRawDataRequest.Element],
        notRetaining nonRetainedElements: [MobileDriversLicenseRawDataRequest.Element]
    ) -> Self {
        Self.driversLicenseRawData(retaining: retainedElements, notRetaining: nonRetainedElements)
    }
}

public struct MobileNationalIDCardDisplayRequest: Hashable, Sendable, MobileDocumentRequest {
    public var region: Locale.Region
    public var elements: [Element]
    public var options: Options

    public init(
        region: Locale.Region,
        elements: [MobileNationalIDCardDisplayRequest.Element] = [],
        options: MobileNationalIDCardDisplayRequest.Options = .init()
    ) {
        self.region = region
        self.elements = elements
        self.options = options
    }

    public static func isSupportedRegion(_ region: Locale.Region) -> Bool {
        _ = region
        return false
    }

    public static func nationalIDCard(
        region: Locale.Region,
        _ elements: [MobileNationalIDCardDisplayRequest.Element],
        options: MobileNationalIDCardDisplayRequest.Options = .init()
    ) -> Self {
        Self(region: region, elements: elements, options: options)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(region)
        hasher.combine(elements)
        hasher.combine(options)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileNationalIDCardDisplayRequest.Element {
            MobileNationalIDCardDisplayRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileNationalIDCardDisplayRequest.Element(identifier: "familyName")
        public static let age = MobileNationalIDCardDisplayRequest.Element(identifier: "age")
        public static let givenName = MobileNationalIDCardDisplayRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Options: Hashable, Sendable {
        public var validationMode: ValidationMode

        public init(validationMode: MobileNationalIDCardDisplayRequest.Options.ValidationMode = .check) {
            self.validationMode = validationMode
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(validationMode)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public struct ValidationMode: Hashable, Sendable {
            internal let identifier: String
            public static let checkMultiple = ValidationMode(identifier: "checkMultiple")
            public static let check = ValidationMode(identifier: "check")
            public static let confirm = ValidationMode(identifier: "confirm")

            internal init(identifier: String) {
                self.identifier = identifier
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }

    public struct Response: Hashable, Sendable {
        public let validationOutcome: ValidationOutcome

        public init(validationOutcome: ValidationOutcome) {
            self.validationOutcome = validationOutcome
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(validationOutcome)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }

        public enum ValidationOutcome: Hashable, Sendable {
            case approved
            case rejected
            case dismissed

            public func hash(into hasher: inout Hasher) {
                hasher.combine(String(describing: self))
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }
    }
}

extension MobileDocumentRequest where Self == MobileNationalIDCardDisplayRequest {
    public static func nationalIDCard(
        region: Locale.Region,
        _ elements: [MobileNationalIDCardDisplayRequest.Element],
        options: MobileNationalIDCardDisplayRequest.Options = .init()
    ) -> Self {
        Self.nationalIDCard(region: region, elements, options: options)
    }
}

public struct MobileNationalIDCardRawDataRequest: Hashable, Sendable, MobileDocumentRawDataRequest {
    public var region: Locale.Region
    public var retainedElements: [Element]
    public var nonRetainedElements: [Element]

    public init(
        region: Locale.Region,
        retainedElements: [MobileNationalIDCardRawDataRequest.Element] = [],
        nonRetainedElements: [MobileNationalIDCardRawDataRequest.Element] = []
    ) {
        self.region = region
        self.retainedElements = retainedElements
        self.nonRetainedElements = nonRetainedElements
    }

    public static func isSupportedRegion(_ region: Locale.Region) -> Bool {
        _ = region
        return false
    }

    public static func nationalIDCardRawData(
        region: Locale.Region,
        retaining retainedElements: [MobileNationalIDCardRawDataRequest.Element] = [],
        notRetaining nonRetainedElements: [MobileNationalIDCardRawDataRequest.Element] = []
    ) -> Self {
        Self(region: region, retainedElements: retainedElements, nonRetainedElements: nonRetainedElements)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(region)
        hasher.combine(retainedElements)
        hasher.combine(nonRetainedElements)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    public struct Element: Hashable, Sendable {
        internal let identifier: String
        internal let minimumAge: Int?

        public static func ageAtLeast(_ age: Int) -> MobileNationalIDCardRawDataRequest.Element {
            MobileNationalIDCardRawDataRequest.Element(identifier: "ageAtLeast", minimumAge: age)
        }

        public static let familyName = MobileNationalIDCardRawDataRequest.Element(identifier: "familyName")
        public static let dateOfBirth = MobileNationalIDCardRawDataRequest.Element(identifier: "dateOfBirth")
        public static let documentNumber = MobileNationalIDCardRawDataRequest.Element(identifier: "documentNumber")
        public static let age = MobileNationalIDCardRawDataRequest.Element(identifier: "age")
        public static let sex = MobileNationalIDCardRawDataRequest.Element(identifier: "sex")
        public static let address = MobileNationalIDCardRawDataRequest.Element(identifier: "address")
        public static let portrait = MobileNationalIDCardRawDataRequest.Element(identifier: "portrait")
        public static let givenName = MobileNationalIDCardRawDataRequest.Element(identifier: "givenName")

        internal init(identifier: String, minimumAge: Int? = nil) {
            self.identifier = identifier
            self.minimumAge = minimumAge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(minimumAge)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }


    public struct Response: Hashable, Sendable {
        public let responseData: Data
        public let sessionTranscript: Data

        public init(responseData: Data, sessionTranscript: Data) {
            self.responseData = responseData
            self.sessionTranscript = sessionTranscript
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(responseData)
            hasher.combine(sessionTranscript)
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}

extension MobileDocumentRequest where Self == MobileNationalIDCardRawDataRequest {
    public static func nationalIDCardRawData(
        region: Locale.Region,
        retaining retainedElements: [MobileNationalIDCardRawDataRequest.Element] = [],
        notRetaining nonRetainedElements: [MobileNationalIDCardRawDataRequest.Element] = []
    ) -> Self {
        Self.nationalIDCardRawData(
            region: region,
            retaining: retainedElements,
            notRetaining: nonRetainedElements
        )
    }
}
