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

open class HKAttachment: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var identifier: UUID
    public private(set) var name: String
    public private(set) var size: Int
    public private(set) var creationDate: Date
    public private(set) var metadata: [String: Any]?

    public override init() {
        self.identifier = UUID()
        self.name = ""
        self.size = 0
        self.creationDate = Date()
        self.metadata = nil
        super.init()
    }

    public init(
        identifier: UUID = UUID(),
        name: String,
        size: Int,
        creationDate: Date = Date(),
        metadata: [String: Any]? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.size = size
        self.creationDate = creationDate
        self.metadata = metadata
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.identifier = UUID(uuidString: (coder.decodeObject(of: NSString.self, forKey: "identifier") as String?) ?? "") ?? UUID()
        self.name = (coder.decodeObject(of: NSString.self, forKey: "name") as String?) ?? ""
        self.size = coder.decodeInteger(forKey: "size")
        self.creationDate = (coder.decodeObject(of: NSDate.self, forKey: "creationDate") as Date?) ?? Date()
        self.metadata = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier.uuidString as NSString, forKey: "identifier")
        coder.encode(name as NSString, forKey: "name")
        coder.encode(size, forKey: "size")
        coder.encode(creationDate as NSDate, forKey: "creationDate")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKAttachment(identifier: identifier, name: name, size: size, creationDate: creationDate, metadata: metadata)
    }

    public struct AsyncBytes: AsyncSequence {
        public typealias Element = UInt8
        public struct Iterator: AsyncIteratorProtocol {
            var bytes: [UInt8]
            var index = 0
            public mutating func next() async throws -> UInt8? {
                guard index < bytes.count else { return nil }
                let value = bytes[index]
                index += 1
                return value
            }
        }
        let bytes: [UInt8]
        public func makeAsyncIterator() -> Iterator { Iterator(bytes: bytes) }
    }
}

open class HKAttachmentStore: NSObject, @unchecked Sendable {
    private let healthStore: HKHealthStore

    public override init() {
        self.healthStore = HKHealthStore()
        super.init()
    }

    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        super.init()
    }

    /// Linux local attachment: stores bytes in-process. Apple attachment daemons / iCloud
    /// Health sharing are not invented; `UTType` overloads stay unavailable.
    public func addAttachment(
        to object: HKObject,
        name: String,
        data: Data,
        metadata: [String: Any]? = nil
    ) throws -> HKAttachment {
        _ = healthStore
        let attachment = HKAttachment(name: name, size: data.count, metadata: metadata)
        HKHealthStorePortable._addAttachment(attachment, data: data, to: object.uuid)
        return attachment
    }

    public func getAttachments(for object: HKObject, completion: @escaping ([HKAttachment]?, (any Error)?) -> Void) {
        completion(HKHealthStorePortable.attachments(for: object.uuid), nil)
    }

    public func attachments(for object: HKObject) async throws -> [HKAttachment] {
        HKHealthStorePortable.attachments(for: object.uuid)
    }

    public func getAttachments(for object: HKObject) async throws -> [HKAttachment] {
        try await attachments(for: object)
    }

    public func removeAttachment(
        _ attachment: HKAttachment,
        from object: HKObject,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        let removed = HKHealthStorePortable._removeAttachment(attachment.identifier, from: object.uuid)
        if removed {
            completion(true, nil)
        } else {
            completion(false, hkError(.errorInvalidArgument, reason: "attachment is not on this object"))
        }
    }

    public func removeAttachment(_ attachment: HKAttachment, from object: HKObject) async throws {
        let removed = HKHealthStorePortable._removeAttachment(attachment.identifier, from: object.uuid)
        if !removed {
            throw hkError(.errorInvalidArgument, reason: "attachment is not on this object")
        }
    }

    public func getData(
        for attachment: HKAttachment,
        completion: @escaping (Data?, (any Error)?) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        if let data = HKHealthStorePortable.attachmentData(for: attachment.identifier) {
            progress.completedUnitCount = 1
            completion(data, nil)
        } else {
            progress.completedUnitCount = 1
            completion(nil, hkError(.errorNoData, reason: "attachment bytes are not in the local store"))
        }
        return progress
    }

    public func streamData(
        for attachment: HKAttachment,
        dataHandler: @escaping (Data?, (any Error)?, Bool) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        if let data = HKHealthStorePortable.attachmentData(for: attachment.identifier) {
            progress.completedUnitCount = 1
            dataHandler(data, nil, true)
        } else {
            progress.completedUnitCount = 1
            dataHandler(nil, hkError(.errorNoData, reason: "attachment bytes are not in the local store"), true)
        }
        return progress
    }

    public func dataReader(for attachment: HKAttachment) -> HKAttachmentDataReader {
        HKAttachmentDataReader(attachment: attachment)
    }
}

open class HKAttachmentDataReader: NSObject, @unchecked Sendable {
    public let attachment: HKAttachment
    public let progress: Progress

    public override init() {
        self.attachment = HKAttachment()
        self.progress = Progress(totalUnitCount: 1)
        super.init()
    }

    public init(attachment: HKAttachment) {
        self.attachment = attachment
        self.progress = Progress(totalUnitCount: 1)
        super.init()
    }

    public var bytes: HKAttachment.AsyncBytes {
        let data = HKHealthStorePortable.attachmentData(for: attachment.identifier) ?? Data()
        return HKAttachment.AsyncBytes(bytes: [UInt8](data))
    }

    public func makeAsyncIterator() -> HKAttachment.AsyncBytes.Iterator {
        bytes.makeAsyncIterator()
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
        self.init(sensitivityPoints: sensitivityPoints, start: startDate, end: endDate, device: nil, metadata: metadata)
    }

    public convenience init(
        sensitivityPoints: [HKAudiogramSensitivityPoint],
        startDate: Date,
        endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(sensitivityPoints: sensitivityPoints, start: startDate, end: endDate, metadata: metadata)
    }

    public convenience init(
        sensitivityPoints: [HKAudiogramSensitivityPoint],
        start startDate: Date,
        end endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(type: HKObjectType.audiogramSampleType(), start: startDate, end: endDate, device: device, metadata: metadata)
        self.sensitivityPoints = sensitivityPoints
    }

    public convenience init(
        sensitivityPoints: [HKAudiogramSensitivityPoint],
        startDate: Date,
        endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(sensitivityPoints: sensitivityPoints, start: startDate, end: endDate, device: device, metadata: metadata)
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKAudiogramSensitivityPoint: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var frequency: HKQuantity
    public private(set) var leftEarSensitivity: HKQuantity?
    public private(set) var rightEarSensitivity: HKQuantity?
    public private(set) var tests: [HKAudiogramSensitivityTest]

    public override init() {
        self.frequency = HKQuantity(unit: .hertz(), doubleValue: 0)
        self.leftEarSensitivity = nil
        self.rightEarSensitivity = nil
        self.tests = []
        super.init()
    }

    public init(frequency: HKQuantity, leftEarSensitivity: HKQuantity?, rightEarSensitivity: HKQuantity?) throws {
        try Self.validateFrequency(frequency)
        if let leftEarSensitivity { try Self.validateSensitivity(leftEarSensitivity) }
        if let rightEarSensitivity { try Self.validateSensitivity(rightEarSensitivity) }
        self.frequency = frequency
        self.leftEarSensitivity = leftEarSensitivity
        self.rightEarSensitivity = rightEarSensitivity
        var built: [HKAudiogramSensitivityTest] = []
        if let leftEarSensitivity {
            built.append(try HKAudiogramSensitivityTest(
                sensitivity: leftEarSensitivity,
                type: .air,
                masked: false,
                side: .left,
                clampingRange: nil
            ))
        }
        if let rightEarSensitivity {
            built.append(try HKAudiogramSensitivityTest(
                sensitivity: rightEarSensitivity,
                type: .air,
                masked: false,
                side: .right,
                clampingRange: nil
            ))
        }
        self.tests = built
        super.init()
    }

    public init(frequency: HKQuantity, tests: [HKAudiogramSensitivityTest]) throws {
        try Self.validateFrequency(frequency)
        self.frequency = frequency
        self.tests = tests
        self.leftEarSensitivity = tests.first(where: { $0.side == .left })?.sensitivity
        self.rightEarSensitivity = tests.first(where: { $0.side == .right })?.sensitivity
        super.init()
    }

    public required init?(coder: NSCoder) {
        let hz = coder.decodeDouble(forKey: "frequency")
        self.frequency = HKQuantity(unit: .hertz(), doubleValue: hz)
        if coder.containsValue(forKey: "left") {
            self.leftEarSensitivity = HKQuantity(unit: .decibelHearingLevel(), doubleValue: coder.decodeDouble(forKey: "left"))
        } else {
            self.leftEarSensitivity = nil
        }
        if coder.containsValue(forKey: "right") {
            self.rightEarSensitivity = HKQuantity(unit: .decibelHearingLevel(), doubleValue: coder.decodeDouble(forKey: "right"))
        } else {
            self.rightEarSensitivity = nil
        }
        self.tests = []
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(frequency.doubleValue(for: .hertz()), forKey: "frequency")
        if let leftEarSensitivity {
            coder.encode(leftEarSensitivity.doubleValue(for: .decibelHearingLevel()), forKey: "left")
        }
        if let rightEarSensitivity {
            coder.encode(rightEarSensitivity.doubleValue(for: .decibelHearingLevel()), forKey: "right")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        (try? HKAudiogramSensitivityPoint(
            frequency: frequency,
            leftEarSensitivity: leftEarSensitivity,
            rightEarSensitivity: rightEarSensitivity
        )) ?? HKAudiogramSensitivityPoint()
    }

    static func validateFrequency(_ quantity: HKQuantity) throws {
        guard quantity.unit.`is`(compatibleWith: .hertz()) else {
            throw hkError(.errorInvalidArgument, reason: "audiogram frequency must be in hertz")
        }
        let hz = quantity.doubleValue(for: .hertz())
        guard hz > 0 else {
            throw hkError(.errorInvalidArgument, reason: "audiogram frequency must be positive")
        }
    }

    static func validateSensitivity(_ quantity: HKQuantity) throws {
        guard quantity.unit.`is`(compatibleWith: .decibelHearingLevel()) else {
            throw hkError(.errorInvalidArgument, reason: "audiogram sensitivity must be in dB HL")
        }
    }
}

open class HKAudiogramSensitivityPointClampingRange: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var lowerBound: HKQuantity?
    public private(set) var upperBound: HKQuantity?

    public override init() {
        self.lowerBound = nil
        self.upperBound = nil
        super.init()
    }

    public init(lowerBound: NSNumber?, upperBound: NSNumber?) throws {
        if let lowerBound, let upperBound, lowerBound.doubleValue > upperBound.doubleValue {
            throw hkError(.errorInvalidArgument, reason: "clamping range lowerBound must be <= upperBound")
        }
        self.lowerBound = lowerBound.map { HKQuantity(unit: .decibelHearingLevel(), doubleValue: $0.doubleValue) }
        self.upperBound = upperBound.map { HKQuantity(unit: .decibelHearingLevel(), doubleValue: $0.doubleValue) }
        super.init()
    }

    public required init?(coder: NSCoder) {
        if coder.containsValue(forKey: "lower") {
            self.lowerBound = HKQuantity(unit: .decibelHearingLevel(), doubleValue: coder.decodeDouble(forKey: "lower"))
        }
        if coder.containsValue(forKey: "upper") {
            self.upperBound = HKQuantity(unit: .decibelHearingLevel(), doubleValue: coder.decodeDouble(forKey: "upper"))
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let lowerBound {
            coder.encode(lowerBound.doubleValue(for: .decibelHearingLevel()), forKey: "lower")
        }
        if let upperBound {
            coder.encode(upperBound.doubleValue(for: .decibelHearingLevel()), forKey: "upper")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        (try? HKAudiogramSensitivityPointClampingRange(
            lowerBound: lowerBound.map { NSNumber(value: $0.doubleValue(for: .decibelHearingLevel())) },
            upperBound: upperBound.map { NSNumber(value: $0.doubleValue(for: .decibelHearingLevel())) }
        )) ?? HKAudiogramSensitivityPointClampingRange()
    }
}

open class HKAudiogramSensitivityTest: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var type: HKAudiogramConductionType
    public private(set) var side: HKAudiogramSensitivityTestSide
    public private(set) var sensitivity: HKQuantity
    public private(set) var masked: Bool
    public private(set) var clampingRange: HKAudiogramSensitivityPointClampingRange?

    public override init() {
        self.type = .air
        self.side = .left
        self.sensitivity = HKQuantity(unit: .decibelHearingLevel(), doubleValue: 0)
        self.masked = false
        self.clampingRange = nil
        super.init()
    }

    public init(
        sensitivity: HKQuantity,
        type: HKAudiogramConductionType,
        masked: Bool,
        side: HKAudiogramSensitivityTestSide,
        clampingRange: HKAudiogramSensitivityPointClampingRange?
    ) throws {
        try HKAudiogramSensitivityPoint.validateSensitivity(sensitivity)
        if let clampingRange {
            let value = sensitivity.doubleValue(for: .decibelHearingLevel())
            if let lower = clampingRange.lowerBound?.doubleValue(for: .decibelHearingLevel()), value < lower {
                throw hkError(.errorInvalidArgument, reason: "sensitivity is below clamping lowerBound")
            }
            if let upper = clampingRange.upperBound?.doubleValue(for: .decibelHearingLevel()), value > upper {
                throw hkError(.errorInvalidArgument, reason: "sensitivity is above clamping upperBound")
            }
        }
        self.sensitivity = sensitivity
        self.type = type
        self.masked = masked
        self.side = side
        self.clampingRange = clampingRange
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.type = HKAudiogramConductionType(rawValue: coder.decodeInteger(forKey: "type")) ?? .air
        self.side = HKAudiogramSensitivityTestSide(rawValue: coder.decodeInteger(forKey: "side")) ?? .left
        self.sensitivity = HKQuantity(unit: .decibelHearingLevel(), doubleValue: coder.decodeDouble(forKey: "sensitivity"))
        self.masked = coder.decodeBool(forKey: "masked")
        self.clampingRange = coder.decodeObject(of: HKAudiogramSensitivityPointClampingRange.self, forKey: "clamping")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(side.rawValue, forKey: "side")
        coder.encode(sensitivity.doubleValue(for: .decibelHearingLevel()), forKey: "sensitivity")
        coder.encode(masked, forKey: "masked")
        if let clampingRange {
            coder.encode(clampingRange, forKey: "clamping")
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        (try? HKAudiogramSensitivityTest(
            sensitivity: sensitivity,
            type: type,
            masked: masked,
            side: side,
            clampingRange: clampingRange
        )) ?? HKAudiogramSensitivityTest()
    }
}

open class HKCDADocument: NSObject, @unchecked Sendable {
    public private(set) var title: String
    public private(set) var patientName: String
    public private(set) var authorName: String
    public private(set) var custodianName: String
    public var documentData: Data?

    public override init() {
        self.title = ""
        self.patientName = ""
        self.authorName = ""
        self.custodianName = ""
        self.documentData = nil
        super.init()
    }

    public init(title: String, patientName: String, authorName: String, custodianName: String, documentData: Data?) {
        self.title = title
        self.patientName = patientName
        self.authorName = authorName
        self.custodianName = custodianName
        self.documentData = documentData
        super.init()
    }

    /// Local XML field extraction. This is not Apple CDA schema validation.
    public static func parse(_ data: Data) throws -> HKCDADocument {
        guard let xml = String(data: data, encoding: .utf8),
              xml.range(of: "ClinicalDocument", options: .caseInsensitive) != nil else {
            throw hkError(.errorInvalidArgument, reason: "CDA payload is missing ClinicalDocument")
        }
        func firstTag(_ names: [String]) -> String {
            for name in names {
                let pattern = "<\(name)[^>]*>([^<]*)</\(name)>"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
                    if let match = regex.firstMatch(in: xml, options: [], range: range),
                       match.numberOfRanges > 1,
                       let inner = Range(match.range(at: 1), in: xml) {
                        let text = xml[inner].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty { return text }
                    }
                }
            }
            return ""
        }
        let given = firstTag(["given"])
        let family = firstTag(["family"])
        let patient: String
        if given.isEmpty && family.isEmpty {
            patient = firstTag(["patientName", "name"])
        } else {
            patient = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return HKCDADocument(
            title: firstTag(["title"]),
            patientName: patient,
            authorName: firstTag(["authorName", "assignedPerson"]),
            custodianName: firstTag(["custodianName", "representedCustodianOrganization"]),
            documentData: data
        )
    }
}

open class HKCDADocumentSample: HKDocumentSample, @unchecked Sendable {
    public var document: HKCDADocument?

    public override init(
        type: HKSampleType,
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

    public convenience init(data documentData: Data, start startDate: Date, end endDate: Date, metadata: [String: Any]?) throws {
        let parsed = try HKCDADocument.parse(documentData)
        self.init(
            type: HKObjectType.documentType(forIdentifier: .CDA) ?? HKDocumentType(identifier: HKDocumentTypeIdentifier.CDA.rawValue),
            start: startDate,
            end: endDate,
            metadata: metadata
        )
        self.document = parsed
    }

    public convenience init(data documentData: Data, startDate: Date, endDate: Date, metadata: [String: Any]?) throws {
        try self.init(data: documentData, start: startDate, end: endDate, metadata: metadata)
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKClinicalCoding: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var system: String
    public private(set) var code: String
    public private(set) var version: String?

    public override convenience init() { self.init(system: "", version: nil, code: "") }
    public init(system: String, version: String?, code: String) {
        self.system = system
        self.version = version
        self.code = code
        super.init()
    }
    public required init?(coder: NSCoder) {
        guard let system = coder.decodeObject(of: NSString.self, forKey: "system") as String?,
              let code = coder.decodeObject(of: NSString.self, forKey: "code") as String? else { return nil }
        self.system = system
        self.code = code
        self.version = coder.decodeObject(of: NSString.self, forKey: "version") as String?
        super.init()
    }
    public func encode(with coder: NSCoder) {
        coder.encode(system as NSString, forKey: "system")
        coder.encode(code as NSString, forKey: "code")
        if let version { coder.encode(version as NSString, forKey: "version") }
    }
    public func copy(with zone: NSZone? = nil) -> Any { HKClinicalCoding(system: system, version: version, code: code) }
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKClinicalCoding else { return false }
        return system == other.system && version == other.version && code == other.code
    }
    public override var hash: Int { var h = Hasher(); h.combine(system); h.combine(version); h.combine(code); return h.finalize() }
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
    public private(set) var sphere: HKQuantity?
    public private(set) var cylinder: HKQuantity?
    public private(set) var axis: HKQuantity?
    public private(set) var addPower: HKQuantity?
    public private(set) var baseCurve: HKQuantity?
    public private(set) var diameter: HKQuantity?

    public override init() { super.init() }
    public init(sphere: HKQuantity, cylinder: HKQuantity?, axis: HKQuantity?, addPower: HKQuantity?, baseCurve: HKQuantity?, diameter: HKQuantity?) {
        self.sphere = sphere; self.cylinder = cylinder; self.axis = axis
        self.addPower = addPower; self.baseCurve = baseCurve; self.diameter = diameter
        super.init()
    }
}

open class HKContactsPrescription: HKVisionPrescription, @unchecked Sendable {
    public var rightEye: HKContactsLensSpecification?
    public var leftEye: HKContactsLensSpecification?
    public private(set) var brand: String = ""

    public override init(type: HKSampleType, start startDate: Date, end endDate: Date, uuid: UUID = UUID(), sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil), device: HKDevice? = nil, metadata: [String: Any]? = nil) {
        super.init(type: type, start: startDate, end: endDate, uuid: uuid, sourceRevision: sourceRevision, device: device, metadata: metadata)
        prescriptionType = .contacts
        dateIssued = startDate
        expirationDate = endDate == startDate ? nil : endDate
    }

    public convenience init(rightEyeSpecification: HKContactsLensSpecification?, leftEyeSpecification: HKContactsLensSpecification?, brand: String, dateIssued: Date, expirationDate: Date?, device: HKDevice?, metadata: [String: Any]?) {
        self.init(type: HKObjectType.visionPrescriptionType(), start: dateIssued, end: expirationDate ?? dateIssued, device: device, metadata: metadata)
        self.rightEye = rightEyeSpecification; self.leftEye = leftEyeSpecification
        self.brand = brand; self.dateIssued = dateIssued; self.expirationDate = expirationDate
        self.prescriptionType = .contacts
    }

    public convenience init() {
        self.init(rightEyeSpecification: nil, leftEyeSpecification: nil, brand: "", dateIssued: .distantPast, expirationDate: nil, device: nil, metadata: nil)
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
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
    public var data: Data = Data()
    public var fhirVersion: HKFHIRVersion = HKFHIRVersion.primaryR4()
}

open class HKFHIRVersion: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let majorVersion: Int
    public let minorVersion: Int
    public let patchVersion: Int
    public let fhirRelease: HKFHIRRelease
    public var stringRepresentation: String { "\(majorVersion).\(minorVersion).\(patchVersion)" }

    public override convenience init() {
        self.init(majorVersion: 0, minorVersion: 0, patchVersion: 0, fhirRelease: .unknown)
    }

    public required init(majorVersion: Int, minorVersion: Int, patchVersion: Int, fhirRelease: HKFHIRRelease) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
        self.fhirRelease = fhirRelease
        super.init()
    }

    public convenience init(fromVersionString versionString: String) throws {
        let parts = versionString.split(separator: ".").map(String.init)
        guard (1...3).contains(parts.count), let major = Int(parts[0]) else {
            throw hkError(.errorInvalidArgument, reason: "FHIR version string must be major[.minor[.patch]]")
        }
        let minor = parts.count > 1 ? (Int(parts[1]) ?? -1) : 0
        let patch = parts.count > 2 ? (Int(parts[2]) ?? -1) : 0
        guard minor >= 0, patch >= 0 else {
            throw hkError(.errorInvalidArgument, reason: "FHIR version components must be integers")
        }
        let release: HKFHIRRelease
        if major == 1 {
            release = .dstu2
        } else if major == 4 {
            release = .r4
        } else {
            release = .unknown
        }
        self.init(majorVersion: major, minorVersion: minor, patchVersion: patch, fhirRelease: release)
    }

    public class func primaryDSTU2() -> Self {
        Self.init(majorVersion: 1, minorVersion: 0, patchVersion: 2, fhirRelease: .dstu2)
    }

    public class func primaryR4() -> Self {
        Self.init(majorVersion: 4, minorVersion: 0, patchVersion: 1, fhirRelease: .r4)
    }

    public required init?(coder: NSCoder) {
        self.majorVersion = coder.decodeInteger(forKey: "major")
        self.minorVersion = coder.decodeInteger(forKey: "minor")
        self.patchVersion = coder.decodeInteger(forKey: "patch")
        let raw = (coder.decodeObject(of: NSString.self, forKey: "release") as String?) ?? HKFHIRRelease.unknown.rawValue
        self.fhirRelease = HKFHIRRelease(rawValue: raw)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(majorVersion, forKey: "major")
        coder.encode(minorVersion, forKey: "minor")
        coder.encode(patchVersion, forKey: "patch")
        coder.encode(fhirRelease.rawValue as NSString, forKey: "release")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKFHIRVersion(
            majorVersion: majorVersion,
            minorVersion: minorVersion,
            patchVersion: patchVersion,
            fhirRelease: fhirRelease
        )
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKFHIRVersion else { return false }
        return majorVersion == other.majorVersion
            && minorVersion == other.minorVersion
            && patchVersion == other.patchVersion
            && fhirRelease == other.fhirRelease
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(majorVersion)
        hasher.combine(minorVersion)
        hasher.combine(patchVersion)
        hasher.combine(fhirRelease)
        return hasher.finalize()
    }
}

open class HKGAD7Assessment: HKScoredAssessment, @unchecked Sendable {
    public var answers: [Answer] = []
    public var risk: Risk = .noneToMinimal
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKGlassesLensSpecification: HKLensSpecification, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var vertexDistance: HKQuantity?
    public private(set) var prism: HKVisionPrism?
    public private(set) var farPupillaryDistance: HKQuantity?
    public private(set) var nearPupillaryDistance: HKQuantity?

    public override init() {
        super.init()
    }

    public init(
        sphere: HKQuantity,
        cylinder: HKQuantity?,
        axis: HKQuantity?,
        addPower: HKQuantity?,
        vertexDistance: HKQuantity?,
        prism: HKVisionPrism?,
        farPupillaryDistance: HKQuantity?,
        nearPupillaryDistance: HKQuantity?
    ) {
        self.vertexDistance = vertexDistance
        self.prism = prism
        self.farPupillaryDistance = farPupillaryDistance
        self.nearPupillaryDistance = nearPupillaryDistance
        super.init()
        self.sphere = sphere
        self.cylinder = cylinder
        self.axis = axis
        self.add = addPower
        self.addPower = addPower
    }

    public required init?(coder: NSCoder) {
        if coder.containsValue(forKey: "vertex") {
            self.vertexDistance = HKQuantity(unit: .meterUnit(with: .milli), doubleValue: coder.decodeDouble(forKey: "vertex"))
        }
        if coder.containsValue(forKey: "farPD") {
            self.farPupillaryDistance = HKQuantity(unit: .meterUnit(with: .milli), doubleValue: coder.decodeDouble(forKey: "farPD"))
        }
        if coder.containsValue(forKey: "nearPD") {
            self.nearPupillaryDistance = HKQuantity(unit: .meterUnit(with: .milli), doubleValue: coder.decodeDouble(forKey: "nearPD"))
        }
        if coder.containsValue(forKey: "prism") {
            self.prism = coder.decodeObject(of: HKVisionPrism.self, forKey: "prism")
        }
        super.init()
        self.sphere = HKQuantity(unit: .diopter(), doubleValue: coder.decodeDouble(forKey: "sphere"))
        if coder.containsValue(forKey: "cylinder") {
            self.cylinder = HKQuantity(unit: .diopter(), doubleValue: coder.decodeDouble(forKey: "cylinder"))
        }
        if coder.containsValue(forKey: "axis") {
            self.axis = HKQuantity(unit: .degreeAngle(), doubleValue: coder.decodeDouble(forKey: "axis"))
        }
        if coder.containsValue(forKey: "add") {
            let add = HKQuantity(unit: .diopter(), doubleValue: coder.decodeDouble(forKey: "add"))
            self.add = add
            self.addPower = add
        }
    }

    public func encode(with coder: NSCoder) {
        coder.encode(sphere?.doubleValue(for: .diopter()) ?? 0, forKey: "sphere")
        if let cylinder { coder.encode(cylinder.doubleValue(for: .diopter()), forKey: "cylinder") }
        if let axis { coder.encode(axis.doubleValue(for: .degreeAngle()), forKey: "axis") }
        if let addPower { coder.encode(addPower.doubleValue(for: .diopter()), forKey: "add") }
        if let vertexDistance { coder.encode(vertexDistance.doubleValue(for: .meterUnit(with: .milli)), forKey: "vertex") }
        if let farPupillaryDistance { coder.encode(farPupillaryDistance.doubleValue(for: .meterUnit(with: .milli)), forKey: "farPD") }
        if let nearPupillaryDistance { coder.encode(nearPupillaryDistance.doubleValue(for: .meterUnit(with: .milli)), forKey: "nearPD") }
        if let prism { coder.encode(prism, forKey: "prism") }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKGlassesLensSpecification(
            sphere: sphere ?? HKQuantity(unit: .diopter(), doubleValue: 0),
            cylinder: cylinder,
            axis: axis,
            addPower: addPower,
            vertexDistance: vertexDistance,
            prism: prism,
            farPupillaryDistance: farPupillaryDistance,
            nearPupillaryDistance: nearPupillaryDistance
        )
    }
}

open class HKGlassesPrescription: HKVisionPrescription, @unchecked Sendable {
    public var rightEye: HKGlassesLensSpecification?
    public var leftEye: HKGlassesLensSpecification?

    public init() {
        super.init(
            type: HKObjectType.visionPrescriptionType(),
            start: Date(),
            end: Date()
        )
        self.prescriptionType = .glasses
    }

    public convenience init(
        rightEyeSpecification: HKGlassesLensSpecification?,
        leftEyeSpecification: HKGlassesLensSpecification?,
        dateIssued: Date,
        expirationDate: Date?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init()
        self.rightEye = rightEyeSpecification
        self.leftEye = leftEyeSpecification
        self.dateIssued = dateIssued
        self.expirationDate = expirationDate
        self.prescriptionType = .glasses
        _ = (device, metadata)
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKHealthConceptIdentifier: NSObject, @unchecked Sendable {
    public var domain: HKHealthConceptDomain = .medication
    public var identifier: String = ""

    public override init() { super.init() }

    public init(domain: HKHealthConceptDomain = .medication, identifier: String) {
        self.domain = domain
        self.identifier = identifier
        super.init()
    }

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
    public var add: HKQuantity?
    public var addPower: HKQuantity? {
        get { add }
        set { add = newValue }
    }
}

open class HKMedicationConcept: NSObject, @unchecked Sendable {
    public var identifier: HKHealthConceptIdentifier = HKHealthConceptIdentifier()
    public var displayText: String = ""
    public var generalForm: HKMedicationGeneralForm = .unknown
    public var relatedCodings: Set<HKClinicalCoding> = []

    public convenience init(identifier: HKHealthConceptIdentifier, displayText: String, generalForm: HKMedicationGeneralForm, relatedCodings: Set<HKClinicalCoding> = []) {
        self.init(); self.identifier = identifier; self.displayText = displayText
        self.generalForm = generalForm; self.relatedCodings = relatedCodings
    }
}

open class HKMedicationDoseEvent: HKSample, @unchecked Sendable {
    public var medicationConceptIdentifier = HKHealthConceptIdentifier()
    public var scheduledDate: Date?
    public var logStatus: LogStatus = .notLogged
    public var scheduleType: ScheduleType = .asNeeded
    public var unit: HKUnit = .count()
    public var doseQuantity: Double?
    public var scheduledDoseQuantity: Double?
    public var medicationDoseEventType: HKMedicationDoseEventType {
        HKObjectType.medicationDoseEventType()
    }

    public override init(
        type: HKSampleType,
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

    public convenience init(
        medicationConceptIdentifier: HKHealthConceptIdentifier,
        logStatus: LogStatus,
        scheduleType: ScheduleType,
        scheduledDate: Date?,
        scheduledDoseQuantity: Double?,
        doseQuantity: Double?,
        unit: HKUnit,
        start: Date,
        end: Date
    ) {
        self.init(type: HKObjectType.medicationDoseEventType(), start: start, end: end)
        self.medicationConceptIdentifier = medicationConceptIdentifier
        self.logStatus = logStatus
        self.scheduleType = scheduleType
        self.scheduledDate = scheduledDate
        self.scheduledDoseQuantity = scheduledDoseQuantity
        self.doseQuantity = doseQuantity
        self.unit = unit
    }

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

    public convenience init(medication: HKMedicationConcept, nickname: String?, hasSchedule: Bool, isArchived: Bool) {
        self.init(); self.medication = medication; self.nickname = nickname
        self.hasSchedule = hasSchedule; self.isArchived = isArchived
    }
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

    public override init(
        type: HKSampleType,
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

    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public convenience init(type: HKVisionPrescriptionType, dateIssued: Date, expirationDate: Date?, device: HKDevice?, metadata: [String: Any]?) {
        self.init(type: HKObjectType.visionPrescriptionType(), start: dateIssued, end: expirationDate ?? dateIssued, device: device, metadata: metadata)
        self.prescriptionType = type; self.dateIssued = dateIssued; self.expirationDate = expirationDate
    }
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

extension HKAppleWalkingSteadinessClassification: CaseIterable {
    public static var allCases: [HKAppleWalkingSteadinessClassification] { [.ok, .low, .veryLow] }

    /// Linux host ranges: veryLow [0, 0.50), low [0.50, 0.75), ok [0.75, 1.0].
    /// Quantity must be percent-compatible. Apple Watch classification firmware is not used.
    public init(for appleWalkingSteadiness: HKQuantity) throws {
        guard appleWalkingSteadiness.is(compatibleWith: .percent()) else {
            throw hkError(.errorInvalidArgument, reason: "walking steadiness must be a percent quantity")
        }
        let percent = appleWalkingSteadiness.doubleValue(for: .percent())
        guard percent >= 0, percent <= 1 else {
            throw hkError(.errorInvalidArgument, reason: "walking steadiness percent must be between 0 and 1")
        }
        self = Self.classification(for: appleWalkingSteadiness)
    }

    public var minimum: HKQuantity {
        switch self {
        case .veryLow: return HKQuantity(unit: .percent(), doubleValue: 0)
        case .low: return HKQuantity(unit: .percent(), doubleValue: 0.50)
        case .ok: return HKQuantity(unit: .percent(), doubleValue: 0.75)
        }
    }

    public var maximum: HKQuantity {
        switch self {
        case .veryLow: return HKQuantity(unit: .percent(), doubleValue: 0.50)
        case .low: return HKQuantity(unit: .percent(), doubleValue: 0.75)
        case .ok: return HKQuantity(unit: .percent(), doubleValue: 1.0)
        }
    }

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
