import Foundation

/// Assigned-work scoring overlay.
public protocol AssignedWorkDocumentConfiguration: Hashable {
    var manualScore: Double? { get set }
}

struct AssignedWorkDocumentConfigurationStorage: AssignedWorkDocumentConfiguration, Sendable {
    var manualScore: Double? = nil
}

/// Student copy of an `AssignableDocument` plus scores and assignees.
public struct AssignedWorkDocument: MergeableDocument, Hashable, Sendable {
    public typealias ID = String
    public typealias Configuration = AssignedWorkDocumentConfiguration
    public typealias PartID = MergeablePartsContainerPartID

    public enum Error: Swift.Error, Hashable, Sendable {
        case otherDocumentIsNotAVariant
        case exportFailed(partIDs: [AssignedWorkDocument.PartID])
    }

    public enum PartIDs {
        public typealias Document = AssignedWorkDocument

        public static let assignableDocumentBase = MergeablePartsContainerPartID("assignableDocumentBase")
        public static let assignableDocumentInstructionMarkup = MergeablePartsContainerPartID("assignableDocumentInstructionMarkup")
        public static let assignableDocumentQuestionBoxes = MergeablePartsContainerPartID("assignableDocumentQuestionBoxes")
        public static let assignableDocumentAuthors = MergeablePartsContainerPartID("assignableDocumentAuthors")
        public static let takerMarkup = MergeablePartsContainerPartID("takerMarkup")
        public static let scorerMarkup = MergeablePartsContainerPartID("scorerMarkup")
        public static let scoreAnnotations = MergeablePartsContainerPartID("scoreAnnotations")
        public static let assignees = MergeablePartsContainerPartID("assignees")
        public static let scorers = MergeablePartsContainerPartID("scorers")
        public static let all: [MergeablePartsContainerPartID] = [
            assignableDocumentBase,
            assignableDocumentInstructionMarkup,
            assignableDocumentQuestionBoxes,
            assignableDocumentAuthors,
            takerMarkup,
            scorerMarkup,
            scoreAnnotations,
            assignees,
            scorers,
        ]
    }

    public struct ScoreAnnotation: AssignedWorkDocumentElement, Hashable, Sendable {
        public typealias Document = AssignedWorkDocument
        public typealias ID = String

        /// API-digester child order: `unknown`, `incorrect`, `correct`, `bonus`.
        public enum Kind: Int, Hashable, CaseIterable, Sendable, CustomDebugStringConvertible {
            case unknown = 0
            case incorrect = 1
            case correct = 2
            case bonus = 3

            public typealias AllCases = [AssignedWorkDocument.ScoreAnnotation.Kind]
            public typealias RawValue = Int

            public var debugDescription: String {
                switch self {
                case .unknown: return "unknown"
                case .incorrect: return "incorrect"
                case .correct: return "correct"
                case .bonus: return "bonus"
                }
            }
        }

        public var id: AssignedWorkDocument.ScoreAnnotation.ID
        public var pageID: AssignedWorkDocument.Page.ID?
        public var location: CGPoint
        public var kind: AssignedWorkDocument.ScoreAnnotation.Kind

        public init(
            id: AssignedWorkDocument.ScoreAnnotation.ID,
            pageID: AssignedWorkDocument.Page.ID?,
            location: CGPoint,
            kind: AssignedWorkDocument.ScoreAnnotation.Kind
        ) {
            self.id = id
            self.pageID = pageID
            self.location = location
            self.kind = kind
        }
    }

    public struct Page: MergeableDocumentPage, AssignedWorkDocumentElement, Hashable, Sendable, CustomDebugStringConvertible {
        public typealias Document = AssignedWorkDocument

        public struct ID: DocumentElementID, Sendable {
            public typealias Element = AssignedWorkDocument.Page

            public var assignableDocumentPageID: AssignableDocument.Page.ID

            init(assignableDocumentPageID: AssignableDocument.Page.ID) {
                self.assignableDocumentPageID = assignableDocumentPageID
            }

            public static func == (a: AssignedWorkDocument.Page.ID, b: AssignedWorkDocument.Page.ID) -> Bool {
                a.assignableDocumentPageID == b.assignableDocumentPageID
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(assignableDocumentPageID)
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                self.assignableDocumentPageID = AssignableDocument.Page.ID(
                    try container.decode(String.self)
                )
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(assignableDocumentPageID.raw)
            }
        }

        public var id: AssignedWorkDocument.Page.ID
        public var assignableDocumentPageID: AssignableDocument.Page.ID { id.assignableDocumentPageID }
        public var rotation: Measurement<UnitAngle>

        public var debugDescription: String {
            "AssignedPage(\(assignableDocumentPageID.debugDescription))"
        }

        init(assignablePage: AssignableDocument.Page) {
            self.id = ID(assignableDocumentPageID: assignablePage.id)
            self.rotation = assignablePage.rotation
        }
    }

    public var id: AssignedWorkDocument.ID
    public var assignableDocument: AssignableDocument {
        didSet { rebuildPages() }
    }
    public var assignees: [AnyUserIdentity]
    public var scorers: [AnyUserIdentity]
    public var scoreAnnotations: [AssignedWorkDocument.ScoreAnnotation]
    public private(set) var pages: [AssignedWorkDocument.Page]
    var storedParts: [MergeablePartsContainerPartID: MergeablePartData]
    var configurationStorage: AssignedWorkDocumentConfigurationStorage

    public var configuration: any AssignedWorkDocumentConfiguration {
        get { configurationStorage }
        set { configurationStorage.manualScore = newValue.manualScore }
    }

    public var isMultiPageDocument: Bool { pages.count > 1 }

    public var pagesDebugDescription: String {
        pages.map(\.debugDescription).joined(separator: "\n")
    }

    public var partIDs: [MergeablePartsContainerPartID] { PartIDs.all }

    public var isPartial: Bool {
        PartIDs.all.contains { storedParts[$0] == nil }
    }

    init(hostAssignable: AssignableDocument, id: String, assignees: [AnyUserIdentity]) {
        self.id = id
        self.assignableDocument = hostAssignable
        self.assignees = assignees
        self.scorers = []
        self.scoreAnnotations = []
        self.pages = hostAssignable.pages.map(Page.init(assignablePage:))
        self.storedParts = [:]
        self.configurationStorage = AssignedWorkDocumentConfigurationStorage()
    }

    public init(
        id: AssignedWorkDocument.ID,
        assignableDocument: AssignableDocument,
        partData: [AssignedWorkDocument.PartID: URL]
    ) throws {
        self.id = id
        self.assignableDocument = assignableDocument
        self.assignees = []
        self.scorers = []
        self.scoreAnnotations = []
        self.pages = assignableDocument.pages.map(Page.init(assignablePage:))
        self.storedParts = [:]
        self.configurationStorage = AssignedWorkDocumentConfigurationStorage()
        for (partID, url) in partData {
            guard url.scheme != nil else { throw Error.exportFailed(partIDs: [partID]) }
            storedParts[partID] = .fileURL(url)
            if partID == PartIDs.scoreAnnotations, let data = try? Data(contentsOf: url) {
                try? applyScoreAnnotationsData(data)
            }
            if partID == PartIDs.assignees, let data = try? Data(contentsOf: url) {
                assignees = (try? JSONDecoder().decode([AnyUserIdentity].self, from: data)) ?? assignees
            }
            if partID == PartIDs.scorers, let data = try? Data(contentsOf: url) {
                scorers = (try? JSONDecoder().decode([AnyUserIdentity].self, from: data)) ?? scorers
            }
        }
    }

    public init(
        id: AssignedWorkDocument.ID,
        assignableDocument: AssignableDocument,
        partData: [AssignedWorkDocument.PartID: MergeablePartData]
    ) async throws {
        self.id = id
        self.assignableDocument = assignableDocument
        self.assignees = []
        self.scorers = []
        self.scoreAnnotations = []
        self.pages = assignableDocument.pages.map(Page.init(assignablePage:))
        self.storedParts = partData
        self.configurationStorage = AssignedWorkDocumentConfigurationStorage()
        if let part = partData[PartIDs.scoreAnnotations],
           let data = try? AssignablesPartCodec.data(from: part) {
            try? applyScoreAnnotationsData(data)
        }
        if let part = partData[PartIDs.assignees],
           let data = try? AssignablesPartCodec.data(from: part) {
            assignees = (try? JSONDecoder().decode([AnyUserIdentity].self, from: data)) ?? []
        }
        if let part = partData[PartIDs.scorers],
           let data = try? AssignablesPartCodec.data(from: part) {
            scorers = (try? JSONDecoder().decode([AnyUserIdentity].self, from: data)) ?? []
        }
    }

    /// Uses `manualScore` when set; otherwise sums annotation kinds using the
    /// assignable document's points-per-mark configuration.
    public func computeScore() -> Double {
        if let manual = configurationStorage.manualScore {
            return manual
        }
        let config = assignableDocument.configurationStorage
        var total: Double = 0
        for annotation in scoreAnnotations {
            switch annotation.kind {
            case .correct:
                total += config.pointsPerCorrectScoreMark
            case .incorrect:
                total += config.pointsPerIncorrectScoreMark
            case .bonus:
                total += config.pointsPerBonusScoreMark
            case .unknown:
                break
            }
        }
        return total
    }

    public subscript(
        scoreAnnotationID: AssignedWorkDocument.ScoreAnnotation.ID
    ) -> AssignedWorkDocument.ScoreAnnotation? {
        get { scoreAnnotations.first { $0.id == scoreAnnotationID } }
        set {
            if let index = scoreAnnotations.firstIndex(where: { $0.id == scoreAnnotationID }) {
                if let newValue {
                    scoreAnnotations[index] = newValue
                } else {
                    scoreAnnotations.remove(at: index)
                }
            } else if let newValue {
                scoreAnnotations.append(newValue)
            }
        }
    }

    public subscript(pageID: AssignedWorkDocument.Page.ID) -> AssignedWorkDocument.Page? {
        pages.first { $0.id == pageID }
    }

    public static func == (lhs: AssignedWorkDocument, rhs: AssignedWorkDocument) -> Bool {
        lhs.id == rhs.id
            && lhs.assignableDocument == rhs.assignableDocument
            && lhs.assignees == rhs.assignees
            && lhs.scorers == rhs.scorers
            && lhs.scoreAnnotations == rhs.scoreAnnotations
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(assignableDocument)
        hasher.combine(assignees)
        hasher.combine(scorers)
        hasher.combine(scoreAnnotations)
    }

    @discardableResult
    public mutating func merge(other: AssignedWorkDocument) throws -> Bool {
        guard other.id == id else { throw Error.otherDocumentIsNotAVariant }
        var changed = false
        if other.scoreAnnotations != scoreAnnotations {
            scoreAnnotations = other.scoreAnnotations
            changed = true
        }
        if other.assignees != assignees {
            assignees = other.assignees
            changed = true
        }
        if other.scorers != scorers {
            scorers = other.scorers
            changed = true
        }
        if try assignableDocument.merge(other: other.assignableDocument) {
            changed = true
        }
        rebuildPages()
        return changed
    }

    @discardableResult
    public mutating func merge(
        partID: AssignedWorkDocument.PartID,
        partDataURL: URL
    ) throws -> Bool {
        guard let data = try? Data(contentsOf: partDataURL) else {
            throw Error.exportFailed(partIDs: [partID])
        }
        storedParts[partID] = .fileURL(partDataURL)
        try applyPart(partID: partID, data: data)
        return true
    }

    @discardableResult
    public mutating func merge(
        partData: MergeablePartData,
        into partID: AssignedWorkDocument.PartID
    ) async throws -> Bool {
        let data = try AssignablesPartCodec.data(from: partData)
        storedParts[partID] = partData
        try applyPart(partID: partID, data: data)
        return true
    }

    @discardableResult
    public mutating func merge(_ other: AssignedWorkDocument) async throws -> Bool {
        try merge(other: other)
    }

    public func export(
        partIDs: [AssignedWorkDocument.PartID]
    ) async throws -> [AssignedWorkDocument.PartID: URL] {
        var result: [AssignedWorkDocument.PartID: URL] = [:]
        var missing: [AssignedWorkDocument.PartID] = []
        for partID in partIDs {
            if case .fileURL(let url) = storedParts[partID] {
                result[partID] = url
                continue
            }
            guard let part = try makePart(for: partID), case .data(let data) = part else {
                missing.append(partID)
                continue
            }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(
                "assignables-work-\(id)-\(partID.rawValue).part"
            )
            try data.write(to: url)
            result[partID] = url
        }
        if !missing.isEmpty {
            throw Error.exportFailed(partIDs: missing)
        }
        return result
    }

    public func exportParts(
        identifiedBy partIDs: [AssignedWorkDocument.PartID]
    ) async throws -> [AssignedWorkDocument.PartID: MergeablePartData] {
        var result: [AssignedWorkDocument.PartID: MergeablePartData] = [:]
        var missing: [AssignedWorkDocument.PartID] = []
        for partID in partIDs {
            if let stored = storedParts[partID] {
                result[partID] = stored
            } else if let made = try makePart(for: partID) {
                result[partID] = made
            } else {
                missing.append(partID)
            }
        }
        if !missing.isEmpty {
            throw Error.exportFailed(partIDs: missing)
        }
        return result
    }

    public func makePart(for partID: AssignedWorkDocument.PartID) throws -> MergeablePartData? {
        if let stored = storedParts[partID] {
            return stored
        }
        switch partID {
        case PartIDs.scoreAnnotations:
            return .data(try JSONEncoder().encode(ScoreAnnotationsPayload(from: scoreAnnotations)))
        case PartIDs.assignees:
            return .data(try JSONEncoder().encode(assignees))
        case PartIDs.scorers:
            return .data(try JSONEncoder().encode(scorers))
        case PartIDs.assignableDocumentQuestionBoxes,
             PartIDs.assignableDocumentAuthors,
             PartIDs.assignableDocumentBase,
             PartIDs.assignableDocumentInstructionMarkup:
            let mapped = mapAssignablePart(partID)
            return try assignableDocument.makePart(for: mapped)
        case PartIDs.takerMarkup, PartIDs.scorerMarkup:
            return storedParts[partID] ?? .data(Data())
        default:
            return storedParts[partID]
        }
    }

    public func exportToPDF(visibleParts: [MergeablePartsContainerPartID]) async -> PDFDocument {
        _ = visibleParts
        return PDFDocument()
    }

    public func pageThumbnails(
        visibleParts: [Self.PartID]
    ) async -> [Self.Page.ID: Self.Page.Thumbnail] {
        _ = visibleParts
        return [:]
    }

    public func questionThumbnails(
        visibleParts: [AssignedWorkDocument.PartID]
    ) async -> [AssignableDocument.Question.ID: [AssignableDocument.Question.Thumbnail]] {
        _ = visibleParts
        return [:]
    }

    private mutating func rebuildPages() {
        pages = assignableDocument.pages.map(Page.init(assignablePage:))
    }

    private func mapAssignablePart(_ partID: AssignedWorkDocument.PartID) -> AssignableDocument.PartID {
        switch partID {
        case PartIDs.assignableDocumentBase:
            return AssignableDocument.PartIDs.base
        case PartIDs.assignableDocumentInstructionMarkup:
            return AssignableDocument.PartIDs.instructionMarkup
        case PartIDs.assignableDocumentQuestionBoxes:
            return AssignableDocument.PartIDs.questionBoxes
        case PartIDs.assignableDocumentAuthors:
            return AssignableDocument.PartIDs.authors
        default:
            return partID
        }
    }

    private mutating func applyPart(partID: AssignedWorkDocument.PartID, data: Data) throws {
        switch partID {
        case PartIDs.scoreAnnotations:
            try applyScoreAnnotationsData(data)
        case PartIDs.assignees:
            assignees = try JSONDecoder().decode([AnyUserIdentity].self, from: data)
        case PartIDs.scorers:
            scorers = try JSONDecoder().decode([AnyUserIdentity].self, from: data)
        default:
            break
        }
    }

    private mutating func applyScoreAnnotationsData(_ data: Data) throws {
        let payload = try JSONDecoder().decode(ScoreAnnotationsPayload.self, from: data)
        scoreAnnotations = payload.annotations()
    }
}

private struct ScoreAnnotationsPayload: Codable {
    struct Item: Codable {
        var id: String
        var pageID: String?
        var x: Double
        var y: Double
        var kind: Int
    }

    var items: [Item]

    init(from annotations: [AssignedWorkDocument.ScoreAnnotation]) {
        items = annotations.map { annotation in
            Item(
                id: annotation.id,
                pageID: annotation.pageID?.assignableDocumentPageID.raw,
                x: annotation.location.x,
                y: annotation.location.y,
                kind: annotation.kind.rawValue
            )
        }
    }

    func annotations() -> [AssignedWorkDocument.ScoreAnnotation] {
        items.map { item in
            AssignedWorkDocument.ScoreAnnotation(
                id: item.id,
                pageID: item.pageID.map { AssignedWorkDocument.Page.ID(assignableDocumentPageID: AssignableDocument.Page.ID($0)) },
                location: CGPoint(x: item.x, y: item.y),
                kind: AssignedWorkDocument.ScoreAnnotation.Kind(rawValue: item.kind) ?? .unknown
            )
        }
    }
}
