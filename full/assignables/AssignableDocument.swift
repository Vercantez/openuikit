import Foundation

/// Scoring and mark configuration for an assignable document.
public protocol AssignableDocumentConfiguration: Hashable {
    var correctScoreMarkType: AssignableDocument.CorrectMarkType { get set }
    var pointsPerBonusScoreMark: Double { get set }
    var pointsPerCorrectScoreMark: Double { get set }
    var pointsPerIncorrectScoreMark: Double { get set }
    var maxScore: Double? { get set }
}

struct AssignableDocumentConfigurationStorage: AssignableDocumentConfiguration, Sendable {
    var correctScoreMarkType: AssignableDocument.CorrectMarkType = .checkmark
    var pointsPerBonusScoreMark: Double = 0
    var pointsPerCorrectScoreMark: Double = 1
    var pointsPerIncorrectScoreMark: Double = 0
    var maxScore: Double? = nil
}

/// Something that can produce an `AssignedWorkDocument` for a user.
public protocol Assignable {
    func makeAssignedWorkDocument(id: String) throws -> AssignedWorkDocument
    func makeAssignedWorkDocument() throws -> AssignedWorkDocument
    func assign(to userIdentity: AnyUserIdentity) throws -> AssignedWorkDocument
    func assign(to userIdentity: some UserIdentity) throws -> AssignedWorkDocument
}

extension Assignable {
    public func assign(to userIdentity: some UserIdentity) throws -> AssignedWorkDocument {
        try assign(to: AnyUserIdentity(userIdentity))
    }

    public func makeAssignedWorkDocument() throws -> AssignedWorkDocument {
        try makeAssignedWorkDocument(id: UUID().uuidString)
    }
}

/// Teacher-authored assignment document. PDF bytes are not decoded on Linux.
public struct AssignableDocument: Assignable, MergeableDocument, Hashable, Sendable {
    public typealias ID = String
    public typealias Configuration = AssignableDocumentConfiguration
    public typealias Element = AssignableDocumentElement
    public typealias PartID = MergeablePartsContainerPartID

    public enum Error: Swift.Error, Hashable, Sendable {
        case otherDocumentIsNotAVariant
        case invalidURL
        case exportFailed(partIDs: [AssignableDocument.PartID])
    }

    public enum CorrectMarkType: Hashable, CaseIterable, Identifiable, Sendable, CustomDebugStringConvertible {
        case checkmark
        case star
        case numeric
        case unknown

        public typealias ID = AssignableDocument.CorrectMarkType
        public typealias AllCases = [AssignableDocument.CorrectMarkType]

        public var id: AssignableDocument.CorrectMarkType { self }

        public var debugDescription: String {
            switch self {
            case .checkmark: return "checkmark"
            case .star: return "star"
            case .numeric: return "numeric"
            case .unknown: return "unknown"
            }
        }

        public static var allCases: [AssignableDocument.CorrectMarkType] {
            [.checkmark, .star, .numeric, .unknown]
        }
    }

    public enum PartIDs {
        public typealias Document = AssignableDocument

        public static let base = MergeablePartsContainerPartID("base")
        public static let instructionMarkup = MergeablePartsContainerPartID("instructionMarkup")
        public static let questionBoxes = MergeablePartsContainerPartID("questionBoxes")
        public static let authors = MergeablePartsContainerPartID("authors")
        public static let all: [MergeablePartsContainerPartID] = [
            base, instructionMarkup, questionBoxes, authors,
        ]
    }

    public struct Page: MergeableDocumentPage, AssignableDocumentElement, Hashable, Sendable, CustomDebugStringConvertible {
        public typealias Document = AssignableDocument

        public struct ID: DocumentElementID, Sendable, CustomDebugStringConvertible {
            public typealias Element = AssignableDocument.Page

            var raw: String

            init(_ raw: String) {
                self.raw = raw
            }

            public var debugDescription: String { raw }

            public static func == (a: AssignableDocument.Page.ID, b: AssignableDocument.Page.ID) -> Bool {
                a.raw == b.raw
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(raw)
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                self.raw = try container.decode(String.self)
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(raw)
            }
        }

        public var id: AssignableDocument.Page.ID
        public var size: CGSize
        public var rotation: Measurement<UnitAngle>

        public var debugDescription: String {
            "Page(\(id.debugDescription) \(size.width)x\(size.height))"
        }

        init(
            id: AssignableDocument.Page.ID,
            size: CGSize = .zero,
            rotation: Measurement<UnitAngle> = Measurement(value: 0, unit: UnitAngle.degrees)
        ) {
            self.id = id
            self.size = size
            self.rotation = rotation
        }
    }

    public struct QuestionBox: AssignableDocumentElement, Hashable, Sendable {
        public typealias Document = AssignableDocument
        public typealias ID = String

        public var id: AssignableDocument.QuestionBox.ID
        public var bounds: CGRect
        private var storedPageID: AssignableDocument.Page.ID

        public var pageID: AssignableDocument.Page.ID? { storedPageID }

        public init(
            id: AssignableDocument.QuestionBox.ID,
            pageID: AssignableDocument.Page.ID,
            bounds: CGRect
        ) {
            self.id = id
            self.storedPageID = pageID
            self.bounds = bounds
        }
    }

    public struct Question: AssignableDocumentElement, Hashable, Sendable {
        public typealias Document = AssignableDocument
        public typealias ID = BasicDocumentElementID<AssignableDocument.Question>

        public struct Thumbnail: Hashable {
            public struct Data: Hashable {
                public var box: AssignableDocument.QuestionBox
                public var image: UIImage
                public var pageID: AssignableDocument.Page.ID

                init(box: AssignableDocument.QuestionBox, image: UIImage, pageID: AssignableDocument.Page.ID) {
                    self.box = box
                    self.image = image
                    self.pageID = pageID
                }
            }

            public var questionID: AssignableDocument.Question.ID
            public var data: AssignableDocument.Question.Thumbnail.Data?

            init(questionID: AssignableDocument.Question.ID, data: AssignableDocument.Question.Thumbnail.Data? = nil) {
                self.questionID = questionID
                self.data = data
            }
        }

        public private(set) var id: AssignableDocument.Question.ID
        public var boxes: [AssignableDocument.QuestionBox]
        public var maxScore: Double?

        public init(boxes: [AssignableDocument.QuestionBox], maxScore: Double? = nil) {
            self.id = BasicDocumentElementID()
            self.boxes = boxes
            self.maxScore = maxScore
        }

        public init(
            pageID: AssignableDocument.Page.ID,
            boxes: [AssignableDocument.QuestionBox],
            maxScore: Double? = nil
        ) {
            _ = pageID
            self.id = BasicDocumentElementID()
            self.boxes = boxes
            self.maxScore = maxScore
        }

        init(
            id: AssignableDocument.Question.ID,
            boxes: [AssignableDocument.QuestionBox],
            maxScore: Double?
        ) {
            self.id = id
            self.boxes = boxes
            self.maxScore = maxScore
        }
    }

    public var id: AssignableDocument.ID
    public var authors: [AnyUserIdentity]
    public var questions: [AssignableDocument.Question]
    public private(set) var pages: [AssignableDocument.Page]
    var storedParts: [MergeablePartsContainerPartID: MergeablePartData]
    var configurationStorage: AssignableDocumentConfigurationStorage

    public var configuration: some AssignableDocumentConfiguration {
        get { configurationStorage }
        set {
            configurationStorage.correctScoreMarkType = newValue.correctScoreMarkType
            configurationStorage.pointsPerBonusScoreMark = newValue.pointsPerBonusScoreMark
            configurationStorage.pointsPerCorrectScoreMark = newValue.pointsPerCorrectScoreMark
            configurationStorage.pointsPerIncorrectScoreMark = newValue.pointsPerIncorrectScoreMark
            configurationStorage.maxScore = newValue.maxScore
        }
    }

    public var isMultiPageDocument: Bool { pages.count > 1 }

    public var pagesDebugDescription: String {
        pages.map(\.debugDescription).joined(separator: "\n")
    }

    public var partIDs: [AssignableDocument.PartID] { PartIDs.all }

    public var isPartial: Bool {
        PartIDs.all.contains { storedParts[$0] == nil }
    }

    public init(id: AssignableDocument.ID, partData: [AssignableDocument.PartID: URL]) throws {
        self.id = id
        self.authors = []
        self.questions = []
        self.pages = []
        self.storedParts = [:]
        self.configurationStorage = AssignableDocumentConfigurationStorage()
        for (partID, url) in partData {
            guard url.isFileURL || url.scheme != nil else {
                throw Error.invalidURL
            }
            storedParts[partID] = .fileURL(url)
            if partID == PartIDs.questionBoxes, let data = try? Data(contentsOf: url) {
                try? applyQuestionBoxesData(data)
            }
            if partID == PartIDs.authors, let data = try? Data(contentsOf: url) {
                try? applyAuthorsData(data)
            }
        }
        if pages.isEmpty {
            pages = [Page(id: Page.ID("0"))]
        }
    }

    public init(
        id: AssignableDocument.ID,
        partData: [AssignableDocument.PartID: MergeablePartData]
    ) async throws {
        self.id = id
        self.authors = []
        self.questions = []
        self.pages = []
        self.storedParts = partData
        self.configurationStorage = AssignableDocumentConfigurationStorage()
        if let part = partData[PartIDs.questionBoxes],
           let data = try? AssignablesPartCodec.data(from: part) {
            try? applyQuestionBoxesData(data)
        }
        if let part = partData[PartIDs.authors],
           let data = try? AssignablesPartCodec.data(from: part) {
            try? applyAuthorsData(data)
        }
        if pages.isEmpty {
            pages = [Page(id: Page.ID("0"))]
        }
    }

    /// Linux cannot decode PDFKit documents. Always throws `invalidURL`.
    public init(pdfURL: URL, id: String? = nil) throws {
        _ = pdfURL
        _ = id
        throw Error.invalidURL
    }

    /// Linux cannot decode PDFKit documents. Always throws `invalidURL`.
    public init(pdfURL: URL, authors: [some UserIdentity], id: String? = nil) throws {
        _ = pdfURL
        _ = authors
        _ = id
        throw Error.invalidURL
    }

    public func makeAssignedWorkDocument(id: String) throws -> AssignedWorkDocument {
        AssignedWorkDocument(hostAssignable: self, id: id, assignees: [])
    }

    public func makeAssignedWorkDocument() throws -> AssignedWorkDocument {
        try makeAssignedWorkDocument(id: UUID().uuidString)
    }

    public func assign(to userIdentity: AnyUserIdentity) throws -> AssignedWorkDocument {
        AssignedWorkDocument(hostAssignable: self, id: UUID().uuidString, assignees: [userIdentity])
    }

    public func assign(to userIdentity: some UserIdentity) throws -> AssignedWorkDocument {
        try assign(to: AnyUserIdentity(userIdentity))
    }

    @discardableResult
    public mutating func appendQuestion(
        pageID: AssignableDocument.Page.ID,
        rect: CGRect,
        maxScore: Double? = nil
    ) -> AssignableDocument.Question.ID {
        if pages.contains(where: { $0.id == pageID }) == false {
            pages.append(Page(id: pageID, size: rect.size))
        }
        let box = QuestionBox(
            id: UUID().uuidString,
            pageID: pageID,
            bounds: rect
        )
        let question = Question(pageID: pageID, boxes: [box], maxScore: maxScore)
        questions.append(question)
        return questions[questions.count - 1].id
    }

    @discardableResult
    public mutating func removeQuestion(
        _ questionID: AssignableDocument.Question.ID
    ) -> AssignableDocument.Question? {
        guard let index = questions.firstIndex(where: { $0.id == questionID }) else {
            return nil
        }
        return questions.remove(at: index)
    }

    public func questions(on pageID: AssignableDocument.Page.ID) -> [AssignableDocument.Question] {
        questions.filter { question in
            question.boxes.contains { $0.pageID == pageID }
        }
    }

    public func computeMaxScore(defaultQuestionMaxScore: Double? = Double.zero) -> Double? {
        if questions.isEmpty {
            return configurationStorage.maxScore
        }
        var total: Double = 0
        var sawValue = false
        for question in questions {
            if let value = question.maxScore ?? defaultQuestionMaxScore {
                total += value
                sawValue = true
            }
        }
        if sawValue {
            if let cap = configurationStorage.maxScore {
                return min(total, cap)
            }
            return total
        }
        return configurationStorage.maxScore
    }

    public subscript(questionBoxID: AssignableDocument.QuestionBox.ID) -> AssignableDocument.QuestionBox? {
        get {
            for question in questions {
                if let box = question.boxes.first(where: { $0.id == questionBoxID }) {
                    return box
                }
            }
            return nil
        }
        set {
            guard let newValue else {
                for index in questions.indices {
                    questions[index].boxes.removeAll { $0.id == questionBoxID }
                }
                questions.removeAll { $0.boxes.isEmpty }
                return
            }
            for index in questions.indices {
                if let boxIndex = questions[index].boxes.firstIndex(where: { $0.id == questionBoxID }) {
                    questions[index].boxes[boxIndex] = newValue
                    return
                }
            }
            if questions.isEmpty {
                questions.append(Question(boxes: [newValue], maxScore: nil))
            } else {
                questions[0].boxes.append(newValue)
            }
        }
    }

    public subscript(pageID: AssignableDocument.Page.ID) -> AssignableDocument.Page? {
        pages.first { $0.id == pageID }
    }

    public subscript(questionID: AssignableDocument.Question.ID) -> AssignableDocument.Question? {
        get { questions.first { $0.id == questionID } }
        set {
            if let index = questions.firstIndex(where: { $0.id == questionID }) {
                if let newValue {
                    questions[index] = newValue
                } else {
                    questions.remove(at: index)
                }
            } else if let newValue {
                questions.append(newValue)
            }
        }
    }

    public static func == (lhs: AssignableDocument, rhs: AssignableDocument) -> Bool {
        lhs.id == rhs.id
            && lhs.authors == rhs.authors
            && lhs.questions == rhs.questions
            && lhs.pages == rhs.pages
            && lhs.configurationStorage == rhs.configurationStorage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(authors)
        hasher.combine(questions)
        hasher.combine(pages)
        hasher.combine(configurationStorage)
    }

    @discardableResult
    public mutating func merge(other: AssignableDocument) throws -> Bool {
        guard other.id == id else { throw Error.otherDocumentIsNotAVariant }
        var changed = false
        if other.questions != questions {
            questions = other.questions
            changed = true
        }
        if other.authors != authors {
            authors = other.authors
            changed = true
        }
        if other.pages != pages {
            pages = other.pages
            changed = true
        }
        for (partID, part) in other.storedParts {
            storedParts[partID] = part
            changed = true
        }
        return changed
    }

    @discardableResult
    public mutating func merge(
        partID: AssignableDocument.PartID,
        partDataURL: URL
    ) throws -> Bool {
        guard let data = try? Data(contentsOf: partDataURL) else {
            throw Error.invalidURL
        }
        return try mergePart(partID: partID, data: data, stored: .fileURL(partDataURL))
    }

    @discardableResult
    public mutating func merge(
        partData: MergeablePartData,
        into partID: AssignableDocument.PartID
    ) async throws -> Bool {
        let data = try AssignablesPartCodec.data(from: partData)
        return try mergePart(partID: partID, data: data, stored: partData)
    }

    @discardableResult
    public mutating func merge(_ other: AssignableDocument) async throws -> Bool {
        try merge(other: other)
    }

    public func export(partIDs: [AssignableDocument.PartID]) async throws -> [AssignableDocument.PartID: URL] {
        var result: [AssignableDocument.PartID: URL] = [:]
        let missing = partIDs.filter { storedParts[$0] == nil && makePartIgnoringErrors($0) == nil }
        if !missing.isEmpty {
            throw Error.exportFailed(partIDs: missing)
        }
        for partID in partIDs {
            if case .fileURL(let url) = storedParts[partID] {
                result[partID] = url
                continue
            }
            let part = try makePart(for: partID)
            guard case .data(let data) = part else { continue }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(
                "assignables-\(id)-\(partID.rawValue).part"
            )
            try data.write(to: url)
            result[partID] = url
        }
        return result
    }

    public func exportParts(
        identifiedBy partIDs: [AssignableDocument.PartID]
    ) async throws -> [AssignableDocument.PartID: MergeablePartData] {
        var result: [AssignableDocument.PartID: MergeablePartData] = [:]
        var missing: [AssignableDocument.PartID] = []
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

    public func makePart(for partID: AssignableDocument.PartID) throws -> MergeablePartData? {
        if let stored = storedParts[partID] {
            return stored
        }
        switch partID {
        case PartIDs.questionBoxes:
            let encoder = JSONEncoder()
            let payload = try encoder.encode(QuestionBoxesPayload(from: questions))
            return .data(payload)
        case PartIDs.authors:
            let encoder = JSONEncoder()
            let payload = try encoder.encode(authors)
            return .data(payload)
        case PartIDs.base, PartIDs.instructionMarkup:
            return storedParts[partID] ?? .data(Data())
        default:
            return storedParts[partID]
        }
    }

    /// Linux has no PDFKit. Returns an empty document and never claims pages.
    public func exportToPDF(visibleParts: [MergeablePartsContainerPartID]) async -> PDFDocument {
        _ = visibleParts
        return PDFDocument()
    }

    public func exportBaseAsPDF() async -> PDFDocument {
        PDFDocument()
    }

    public func pageThumbnails(
        visibleParts: [Self.PartID]
    ) async -> [Self.Page.ID: Self.Page.Thumbnail] {
        _ = visibleParts
        return [:]
    }

    public func questionThumbnails(
        visibleParts: [AssignableDocument.PartID]
    ) async -> [AssignableDocument.Question.ID: [AssignableDocument.Question.Thumbnail]] {
        _ = visibleParts
        return [:]
    }

    private func makePartIgnoringErrors(_ partID: AssignableDocument.PartID) -> MergeablePartData? {
        try? makePart(for: partID)
    }

    private mutating func mergePart(
        partID: AssignableDocument.PartID,
        data: Data,
        stored: MergeablePartData
    ) throws -> Bool {
        storedParts[partID] = stored
        if partID == PartIDs.questionBoxes {
            try applyQuestionBoxesData(data)
        }
        if partID == PartIDs.authors {
            try applyAuthorsData(data)
        }
        return true
    }

    private mutating func applyQuestionBoxesData(_ data: Data) throws {
        let payload = try JSONDecoder().decode(QuestionBoxesPayload.self, from: data)
        questions = payload.questions()
        for question in questions {
            for box in question.boxes {
                if let pageID = box.pageID, pages.contains(where: { $0.id == pageID }) == false {
                    pages.append(Page(id: pageID))
                }
            }
        }
    }

    private mutating func applyAuthorsData(_ data: Data) throws {
        authors = try JSONDecoder().decode([AnyUserIdentity].self, from: data)
    }
}

private struct QuestionBoxesPayload: Codable {
    struct Box: Codable {
        var id: String
        var pageID: String
        var x: Double
        var y: Double
        var width: Double
        var height: Double
    }

    struct Item: Codable {
        var id: UUID
        var maxScore: Double?
        var boxes: [Box]
    }

    var items: [Item]

    init(from questions: [AssignableDocument.Question]) {
        items = questions.map { question in
            Item(
                id: question.id.raw,
                maxScore: question.maxScore,
                boxes: question.boxes.map { box in
                    Box(
                        id: box.id,
                        pageID: box.pageID?.raw ?? "0",
                        x: box.bounds.origin.x,
                        y: box.bounds.origin.y,
                        width: box.bounds.size.width,
                        height: box.bounds.size.height
                    )
                }
            )
        }
    }

    func questions() -> [AssignableDocument.Question] {
        items.map { item in
            return AssignableDocument.Question(
                id: BasicDocumentElementID(item.id),
                boxes: item.boxes.map { box in
                    AssignableDocument.QuestionBox(
                        id: box.id,
                        pageID: AssignableDocument.Page.ID(box.pageID),
                        bounds: CGRect(x: box.x, y: box.y, width: box.width, height: box.height)
                    )
                },
                maxScore: item.maxScore
            )
        }
    }
}
