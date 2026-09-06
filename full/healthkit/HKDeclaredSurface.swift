import Foundation

open class HKActivitySummary: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public var dateComponents: DateComponents = DateComponents()
    public var activeEnergyBurned: HKQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: 0)
    public var activeEnergyBurnedGoal: HKQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: 0)
    public var activityMoveMode: HKActivityMoveMode = .activeEnergy
    public var appleExerciseTime: HKQuantity = HKQuantity(unit: .minute(), doubleValue: 0)
    public var appleExerciseTimeGoal: HKQuantity = HKQuantity(unit: .minute(), doubleValue: 0)
    public var appleMoveTime: HKQuantity = HKQuantity(unit: .minute(), doubleValue: 0)
    public var appleMoveTimeGoal: HKQuantity = HKQuantity(unit: .minute(), doubleValue: 0)
    public var appleStandHours: HKQuantity = HKQuantity(unit: .count(), doubleValue: 0)
    public var appleStandHoursGoal: HKQuantity = HKQuantity(unit: .count(), doubleValue: 0)
    public var exerciseTimeGoal: HKQuantity?
    public var standHoursGoal: HKQuantity?
    public var isPaused: Bool = false

    public override init() { super.init() }

    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any { HKActivitySummary() }

    public func dateComponents(for calendar: Calendar) -> DateComponents {
        var components = dateComponents
        components.calendar = calendar
        return components
    }

    convenience init(stored: HKStoredSummary) {
        self.init()
        dateComponents.year = stored.year
        dateComponents.month = stored.month
        dateComponents.day = stored.day
        activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: stored.activeEnergy)
        appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: stored.exerciseMinutes)
        appleStandHours = HKQuantity(unit: .count(), doubleValue: stored.standHours)
        appleMoveTime = HKQuantity(unit: .minute(), doubleValue: stored.moveTimeMinutes)
        activityMoveMode = HKActivityMoveMode(rawValue: stored.moveMode) ?? .activeEnergy
        isPaused = stored.paused
    }
}

open class HKAttachment: NSObject, @unchecked Sendable {
    public var identifier: UUID = UUID()
    public var name: String = ""
    public var size: Int = 0
    public var creationDate: Date = Date()
    public struct AsyncBytes: AsyncSequence {
        public typealias Element = UInt8
        public struct Iterator: AsyncIteratorProtocol {
            public mutating func next() async throws -> UInt8? { nil }
        }
        public func makeAsyncIterator() -> Iterator { Iterator() }
    }
}

open class HKAttachmentStore: NSObject, @unchecked Sendable {
    public func getAttachments(for object: HKObject) async throws -> [HKAttachment] {
        _ = object
        return []
    }

    public func removeAttachment(_ attachment: HKAttachment, from object: HKObject) async throws {
        _ = (attachment, object)
        throw hkError(.errorHealthDataUnavailable, reason: "attachments are fail-closed")
    }
}

open class HKAttachmentDataReader: NSObject, @unchecked Sendable {
    public func makeAsyncIterator() -> HKAttachment.AsyncBytes.Iterator {
        HKAttachment.AsyncBytes.Iterator()
    }
}

open class HKAudiogramSample: HKSample, @unchecked Sendable {
    public var sensitivityPoints: [HKAudiogramSensitivityPoint] = []

    public override init(
        type: HKSampleType,
        start startDate: Date,
        end endDate: Date,
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        super.init(type: type, start: startDate, end: endDate, uuid: uuid, sourceRevision: sourceRevision, device: device, metadata: metadata)
    }

    public convenience init(sensitivityPoints: [HKAudiogramSensitivityPoint], start startDate: Date, end endDate: Date, metadata: [String: Any]?) {
        self.init(type: HKObjectType.audiogramSampleType(), start: startDate, end: endDate, metadata: metadata)
        self.sensitivityPoints = sensitivityPoints
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKAudiogramSensitivityPoint: NSObject, @unchecked Sendable {
    public var frequency: HKQuantity = HKQuantity(unit: .hertz(), doubleValue: 0)
    public var leftEarSensitivity: HKQuantity?
    public var rightEarSensitivity: HKQuantity?
}

open class HKAudiogramSensitivityPointClampingRange: NSObject, @unchecked Sendable {
    public var lowerBound: HKQuantity?
    public var upperBound: HKQuantity?
}

open class HKAudiogramSensitivityTest: NSObject, @unchecked Sendable {
    public var type: HKAudiogramConductionType = .air
    public var side: HKAudiogramSensitivityTestSide = .left
}

open class HKCDADocument: NSObject, @unchecked Sendable {
    public var title: String?
    public var patientName: String?
    public var authorName: String?
    public var custodianName: String?
    public var documentData: Data?
}

open class HKCDADocumentSample: HKDocumentSample, @unchecked Sendable {
    public var document: HKCDADocument?
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKClinicalCoding: NSObject, @unchecked Sendable {
    public var system: String = ""
    public var code: String = ""
    public var version: String?
}

open class HKClinicalRecord: HKSample, @unchecked Sendable {
    public var fhirResourceType: HKFHIRResourceType = .observation
    public var fhirIdentifier: String = ""
    public var fhirSourceURL: URL?
    public var displayName: String?
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKContactsLensSpecification: NSObject, @unchecked Sendable {
    public var eye: HKVisionEye = .left
    public var sphere: HKQuantity?
    public var cylinder: HKQuantity?
}

open class HKContactsPrescription: NSObject, @unchecked Sendable {
    public var rightEye: HKContactsLensSpecification?
    public var leftEye: HKContactsLensSpecification?
}

open class HKElectrocardiogram: HKSeriesSample, @unchecked Sendable {
    public var classification: Classification = .notSet
    public var symptomsStatus: SymptomsStatus = .notSet
    public var samplingFrequency: HKQuantity?
    public var averageHeartRate: HKQuantity?
    public var numberOfVoltageMeasurements: Int {
        HKHealthStorePortable.voltageMeasurements(for: uuid).count
    }
    public override init(
        type: HKSampleType = HKObjectType.electrocardiogramType(),
        start startDate: Date,
        end endDate: Date,
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        super.init(
            type: type,
            start: startDate,
            end: endDate,
            uuid: uuid,
            sourceRevision: sourceRevision,
            device: device,
            metadata: metadata
        )
    }
    public convenience init(start startDate: Date, end endDate: Date) {
        self.init(type: HKObjectType.electrocardiogramType(), start: startDate, end: endDate)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKFHIRResource: NSObject, @unchecked Sendable {
    public var resourceType: HKFHIRResourceType = .observation
    public var identifier: String = ""
    public var sourceURL: URL?
    public var data: Data?
}

open class HKFHIRVersion: NSObject, @unchecked Sendable {
    public var majorVersion: Int = 0
    public var minorVersion: Int = 0
    public var patchVersion: Int = 0
    public var fhirRelease: HKFHIRRelease = .unknown
    public var stringRepresentation: String { "\(majorVersion).\(minorVersion).\(patchVersion)" }
}

open class HKGAD7Assessment: HKScoredAssessment, @unchecked Sendable {
    public var answers: [Answer] = []
    public var risk: Risk = .noneToMinimal
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKGlassesLensSpecification: NSObject, @unchecked Sendable {
    public var eye: HKVisionEye = .left
    public var sphere: HKQuantity?
    public var cylinder: HKQuantity?
    public var axis: HKQuantity?
    public var add: HKQuantity?
}

open class HKGlassesPrescription: NSObject, @unchecked Sendable {
    public var rightEye: HKGlassesLensSpecification?
    public var leftEye: HKGlassesLensSpecification?
}

open class HKHealthConceptIdentifier: NSObject, @unchecked Sendable {
    public var domain: HKHealthConceptDomain = .medication
    public var identifier: String = ""
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKHealthConceptIdentifier else { return false }
        return identifier == other.identifier && domain == other.domain
    }
    public override var hash: Int { identifier.hashValue }
}

open class HKHeartbeatSeriesSample: HKSeriesSample, @unchecked Sendable {
    public convenience init(start startDate: Date, end endDate: Date) {
        self.init(type: HKSeriesType.heartbeat(), start: startDate, end: endDate)
    }
}

open class HKLensSpecification: NSObject, @unchecked Sendable {
    public var sphere: HKQuantity?
    public var cylinder: HKQuantity?
    public var axis: HKQuantity?
}

open class HKMedicationConcept: NSObject, @unchecked Sendable {
    public var identifier: HKHealthConceptIdentifier = HKHealthConceptIdentifier()
    public var displayText: String = ""
    public var generalForm: HKMedicationGeneralForm = .unknown
}

open class HKMedicationDoseEvent: HKSample, @unchecked Sendable {
    public var medicationConceptIdentifier = HKHealthConceptIdentifier()
    public var scheduledDate: Date?
    public var logStatus: LogStatus = .notLogged
    public var scheduleType: ScheduleType = .asNeeded
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKPHQ9Assessment: HKScoredAssessment, @unchecked Sendable {
    public var answers: [Answer] = []
    public var risk: Risk = .noneToMinimal
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKScoredAssessment: HKSample, @unchecked Sendable {
    public override init(
        type: HKSampleType,
        start startDate: Date,
        end endDate: Date,
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        super.init(type: type, start: startDate, end: endDate, uuid: uuid, sourceRevision: sourceRevision, device: device, metadata: metadata)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKStateOfMind: HKSample, @unchecked Sendable {
    public var kind: Kind = .momentaryEmotion
    public var valence: Double = 0
    public var valenceClassification: ValenceClassification = .neutral
    public var labels: [Label] = []
    public var associations: [Association] = []
    public convenience init(
        type: HKStateOfMindType = HKStateOfMindType(identifier: HKDataTypeIdentifierStateOfMind),
        date: Date,
        kind: Kind,
        valence: Double,
        labels: [Label],
        associations: [Association]
    ) {
        self.init(type: type, start: date, end: date, uuid: UUID(), metadata: nil)
        self.kind = kind
        self.valence = valence
        self.labels = labels
        self.associations = associations
    }

    public init(type: HKSampleType, start startDate: Date, end endDate: Date, uuid: UUID = UUID(), metadata: [String: Any]? = nil) {
        super.init(type: type, start: startDate, end: endDate, uuid: uuid, metadata: metadata)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKUserAnnotatedMedication: NSObject, @unchecked Sendable {
    public var medication: HKMedicationConcept = HKMedicationConcept()
    public var hasSchedule: Bool = false
    public var isArchived: Bool = false
    public var nickname: String?
}

open class HKVerifiableClinicalRecord: HKSample, @unchecked Sendable {
    public private(set) var recordTypes: [String]
    public var issuer: String? { issuerIdentifier }
    public private(set) var issuerIdentifier: String
    public private(set) var issuedDate: Date
    public private(set) var relevantDate: Date
    public private(set) var expirationDate: Date?
    public private(set) var itemNames: [String]
    public private(set) var sourceType: HKVerifiableClinicalRecordSourceType?
    public private(set) var subject: HKVerifiableClinicalRecordSubject
    public private(set) var jwsRepresentation: Data
    public var dataRepresentation: Data { jwsRepresentation }

    public init(
        recordTypes: [String],
        issuerIdentifier: String,
        issuedDate: Date,
        relevantDate: Date,
        expirationDate: Date?,
        itemNames: [String],
        sourceType: HKVerifiableClinicalRecordSourceType?,
        subject: HKVerifiableClinicalRecordSubject,
        jwsRepresentation: Data,
        start startDate: Date? = nil,
        end endDate: Date? = nil
    ) {
        self.recordTypes = recordTypes
        self.issuerIdentifier = issuerIdentifier
        self.issuedDate = issuedDate
        self.relevantDate = relevantDate
        self.expirationDate = expirationDate
        self.itemNames = itemNames
        self.sourceType = sourceType
        self.subject = subject
        self.jwsRepresentation = jwsRepresentation
        super.init(
            type: HKSampleType(identifier: "HKVerifiableClinicalRecordTypeIdentifier"),
            start: startDate ?? relevantDate,
            end: endDate ?? expirationDate ?? relevantDate
        )
    }

    public required init?(coder: NSCoder) {
        self.recordTypes = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "recordTypes") as? [String]) ?? []
        self.issuerIdentifier = (coder.decodeObject(of: NSString.self, forKey: "issuerIdentifier") as String?) ?? ""
        self.issuedDate = (coder.decodeObject(of: NSDate.self, forKey: "issuedDate") as Date?) ?? Date()
        self.relevantDate = (coder.decodeObject(of: NSDate.self, forKey: "relevantDate") as Date?) ?? Date()
        self.expirationDate = coder.decodeObject(of: NSDate.self, forKey: "expirationDate") as Date?
        self.itemNames = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "itemNames") as? [String]) ?? []
        if let raw = coder.decodeObject(of: NSString.self, forKey: "sourceType") as String? {
            self.sourceType = HKVerifiableClinicalRecordSourceType(rawValue: raw)
        } else {
            self.sourceType = nil
        }
        self.subject = coder.decodeObject(of: HKVerifiableClinicalRecordSubject.self, forKey: "subject")
            ?? HKVerifiableClinicalRecordSubject(fullName: "", dateOfBirthComponents: nil)
        self.jwsRepresentation = (coder.decodeObject(of: NSData.self, forKey: "jwsRepresentation") as Data?) ?? Data()
        super.init(coder: coder)
    }
}

open class HKVerifiableClinicalRecordSubject: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var fullName: String
    public private(set) var dateOfBirthComponents: DateComponents?
    public var name: String { fullName }
    public var dateOfBirth: DateComponents? { dateOfBirthComponents }

    public init(fullName: String, dateOfBirthComponents: DateComponents?) {
        self.fullName = fullName
        self.dateOfBirthComponents = dateOfBirthComponents
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.fullName = (coder.decodeObject(of: NSString.self, forKey: "fullName") as String?) ?? ""
        self.dateOfBirthComponents = coder.decodeObject(of: NSDateComponents.self, forKey: "dateOfBirthComponents") as DateComponents?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(fullName as NSString, forKey: "fullName")
        if let dateOfBirthComponents {
            coder.encode(dateOfBirthComponents as NSDateComponents, forKey: "dateOfBirthComponents")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKVerifiableClinicalRecordSubject(fullName: fullName, dateOfBirthComponents: dateOfBirthComponents)
    }
}

open class HKVisionPrescription: HKSample, @unchecked Sendable {
    public var prescriptionType: HKVisionPrescriptionType = .glasses
    public var dateIssued: Date = Date()
    public var expirationDate: Date?
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKVisionPrism: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var amount: HKQuantity
    public private(set) var angle: HKQuantity
    public private(set) var eye: HKVisionEye
    public private(set) var verticalAmount: HKQuantity
    public private(set) var verticalBase: HKPrismBase
    public private(set) var horizontalAmount: HKQuantity
    public private(set) var horizontalBase: HKPrismBase
    public var base: HKPrismBase { verticalBase }

    public override init() {
        let zeroPrism = HKQuantity(unit: .prismDiopter(), doubleValue: 0)
        let zeroAngle = HKQuantity(unit: .degreeAngle(), doubleValue: 0)
        self.amount = zeroPrism
        self.angle = zeroAngle
        self.eye = .left
        self.verticalAmount = zeroPrism
        self.verticalBase = .none
        self.horizontalAmount = zeroPrism
        self.horizontalBase = .none
        super.init()
    }

    public init(amount: HKQuantity, angle: HKQuantity, eye: HKVisionEye) {
        self.amount = amount
        self.angle = angle
        self.eye = eye
        let magnitude = amount.doubleValue(for: .prismDiopter())
        let degrees = angle.doubleValue(for: .degreeAngle())
        let radians = degrees * .pi / 180
        let horizontal = magnitude * cos(radians)
        let vertical = magnitude * sin(radians)
        self.horizontalAmount = HKQuantity(unit: .prismDiopter(), doubleValue: abs(horizontal))
        self.verticalAmount = HKQuantity(unit: .prismDiopter(), doubleValue: abs(vertical))
        self.horizontalBase = Self.horizontalBase(for: horizontal)
        self.verticalBase = Self.verticalBase(for: vertical)
        super.init()
    }

    public init(
        verticalAmount: HKQuantity,
        verticalBase: HKPrismBase,
        horizontalAmount: HKQuantity,
        horizontalBase: HKPrismBase,
        eye: HKVisionEye
    ) {
        self.verticalAmount = verticalAmount
        self.verticalBase = verticalBase
        self.horizontalAmount = horizontalAmount
        self.horizontalBase = horizontalBase
        self.eye = eye
        let v = verticalAmount.doubleValue(for: .prismDiopter()) * (verticalBase == .down ? -1 : 1)
        let h = horizontalAmount.doubleValue(for: .prismDiopter()) * (horizontalBase == .in ? -1 : 1)
        let magnitude = (h * h + v * v).squareRoot()
        var degrees = atan2(v, h) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        self.amount = HKQuantity(unit: .prismDiopter(), doubleValue: magnitude)
        self.angle = HKQuantity(unit: .degreeAngle(), doubleValue: degrees)
        super.init()
    }

    public required init?(coder: NSCoder) {
        let amountValue = coder.decodeDouble(forKey: "amount")
        let angleValue = coder.decodeDouble(forKey: "angle")
        self.amount = HKQuantity(unit: .prismDiopter(), doubleValue: amountValue)
        self.angle = HKQuantity(unit: .degreeAngle(), doubleValue: angleValue)
        self.eye = HKVisionEye(rawValue: coder.decodeInteger(forKey: "eye")) ?? .left
        self.verticalAmount = HKQuantity(unit: .prismDiopter(), doubleValue: coder.decodeDouble(forKey: "verticalAmount"))
        self.horizontalAmount = HKQuantity(unit: .prismDiopter(), doubleValue: coder.decodeDouble(forKey: "horizontalAmount"))
        self.verticalBase = HKPrismBase(rawValue: coder.decodeInteger(forKey: "verticalBase")) ?? .none
        self.horizontalBase = HKPrismBase(rawValue: coder.decodeInteger(forKey: "horizontalBase")) ?? .none
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(amount.doubleValue(for: .prismDiopter()), forKey: "amount")
        coder.encode(angle.doubleValue(for: .degreeAngle()), forKey: "angle")
        coder.encode(eye.rawValue, forKey: "eye")
        coder.encode(verticalAmount.doubleValue(for: .prismDiopter()), forKey: "verticalAmount")
        coder.encode(horizontalAmount.doubleValue(for: .prismDiopter()), forKey: "horizontalAmount")
        coder.encode(verticalBase.rawValue, forKey: "verticalBase")
        coder.encode(horizontalBase.rawValue, forKey: "horizontalBase")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKVisionPrism(
            verticalAmount: verticalAmount,
            verticalBase: verticalBase,
            horizontalAmount: horizontalAmount,
            horizontalBase: horizontalBase,
            eye: eye
        )
    }

    private static func horizontalBase(for value: Double) -> HKPrismBase {
        if abs(value) < 1e-12 { return .none }
        return value >= 0 ? .out : .in
    }

    private static func verticalBase(for value: Double) -> HKPrismBase {
        if abs(value) < 1e-12 { return .none }
        return value >= 0 ? .up : .down
    }
}

open class HKWorkoutRoute: HKSeriesSample, @unchecked Sendable {
    public convenience init(start startDate: Date, end endDate: Date, metadata: [String: Any]? = nil) {
        self.init(type: HKSeriesType.workoutRoute(), start: startDate, end: endDate, uuid: UUID(), metadata: metadata)
    }
}

open class HKWorkoutEffortRelationship: NSObject, @unchecked Sendable {
    public var workout: HKWorkout?
    public var activity: HKWorkoutActivity?
    public var sample: HKSample?
    public var samples: [HKSample]? { sample.map { [$0] } }
}

extension HKElectrocardiogram {
    public class VoltageMeasurement: NSObject, @unchecked Sendable {
        public private(set) var timeSinceSampleStart: TimeInterval
        public private(set) var voltage: HKQuantity?

        public init(timeSinceSampleStart: TimeInterval, voltage: HKQuantity?) {
            self.timeSinceSampleStart = timeSinceSampleStart
            self.voltage = voltage
            super.init()
        }

        public func quantity(for lead: HKElectrocardiogram.Lead) -> HKQuantity? {
            _ = lead
            return voltage
        }
    }
}

public protocol HKCategoryValuePredicateProviding: Hashable, RawRepresentable {}

extension HKCategoryValuePredicateProviding where RawValue == Int {
    public static func predicateForSamples(equalTo values: Set<Self>) -> NSPredicate {
        HKQuery.predicateForCategorySamplesEqualToValues(Set(values.map { NSNumber(value: $0.rawValue) }))
    }

    public static func predicateForSamples(_ operatorType: HKPredicateOperator, value: Self) -> NSPredicate {
        HKQuery.predicateForCategorySamples(with: operatorType, value: value.rawValue)
    }
}

extension HKCategoryValue: HKCategoryValuePredicateProviding {}
extension HKCategoryValueAppetiteChanges: HKCategoryValuePredicateProviding {}
extension HKCategoryValueAppleStandHour: HKCategoryValuePredicateProviding {}
extension HKCategoryValueAppleWalkingSteadinessEvent: HKCategoryValuePredicateProviding {}
extension HKCategoryValueCervicalMucusQuality: HKCategoryValuePredicateProviding {}
extension HKCategoryValueContraceptive: HKCategoryValuePredicateProviding {}
extension HKCategoryValueEnvironmentalAudioExposureEvent: HKCategoryValuePredicateProviding {}
extension HKCategoryValueHeadphoneAudioExposureEvent: HKCategoryValuePredicateProviding {}
extension HKCategoryValueLowCardioFitnessEvent: HKCategoryValuePredicateProviding {}
extension HKCategoryValueMenstrualFlow: HKCategoryValuePredicateProviding {}
extension HKCategoryValueOvulationTestResult: HKCategoryValuePredicateProviding {}
extension HKCategoryValuePregnancyTestResult: HKCategoryValuePredicateProviding {}
extension HKCategoryValuePresence: HKCategoryValuePredicateProviding {}
extension HKCategoryValueProgesteroneTestResult: HKCategoryValuePredicateProviding {}
extension HKCategoryValueSeverity: HKCategoryValuePredicateProviding {}
extension HKCategoryValueSleepAnalysis: HKCategoryValuePredicateProviding {}
extension HKCategoryValueVaginalBleeding: HKCategoryValuePredicateProviding {}

extension HKAppleWalkingSteadinessClassification {
    public static func classification(for quantity: HKQuantity) -> HKAppleWalkingSteadinessClassification {
        let percent = quantity.doubleValue(for: .percent())
        if percent < 0.5 { return .veryLow }
        if percent < 0.75 { return .low }
        return .ok
    }
}

extension HKAppleSleepingBreathingDisturbancesClassification {
    public var minimum: HKQuantity {
        HKQuantity(unit: .count(), doubleValue: self == .elevated ? 1 : 0)
    }

    public static func classification(for quantity: HKQuantity) -> HKAppleSleepingBreathingDisturbancesClassification {
        quantity.doubleValue(for: .count()) >= 1 ? .elevated : .notElevated
    }

    public static func minimumQuantity(for classification: HKAppleSleepingBreathingDisturbancesClassification) -> HKQuantity {
        classification.minimum
    }
}
