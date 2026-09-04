import Foundation

public protocol HistoryToken: Comparable, Codable, Hashable, Identifiable, Sendable {
    associatedtype TokenType: Codable, Hashable, Sendable
    var tokenValue: TokenType? { get }
}

public protocol HistoryTransaction: Hashable, Identifiable, Sendable {
    associatedtype TokenType: Comparable, Hashable, Identifiable, Sendable
    associatedtype TransactionIdentifier: Comparable, Hashable, Sendable
    var author: String? { get }
    var changes: [HistoryChange] { get }
    var storeIdentifier: String { get }
    var timestamp: Date { get }
    var token: TokenType { get }
    var transactionIdentifier: TransactionIdentifier { get }
}

public protocol HistoryInsert<Model>: Sendable {
    associatedtype Model: PersistentModel
    associatedtype ChangeIdentifier: Comparable, Hashable, Sendable
    associatedtype TransactionIdentifier: Comparable, Hashable, Sendable
    var changeIdentifier: ChangeIdentifier { get }
    var changedPersistentIdentifier: PersistentIdentifier { get }
    var transactionIdentifier: TransactionIdentifier { get }
}

public protocol HistoryUpdate<Model>: Sendable {
    associatedtype Model: PersistentModel
    associatedtype ChangeIdentifier: Comparable, Hashable, Sendable
    associatedtype TransactionIdentifier: Comparable, Hashable, Sendable
    typealias PropertyUpdate = PartialKeyPath<Model> & Sendable
    var changeIdentifier: ChangeIdentifier { get }
    var changedPersistentIdentifier: PersistentIdentifier { get }
    var transactionIdentifier: TransactionIdentifier { get }
    var updatedAttributes: [any PartialKeyPath<Model> & Sendable] { get }
}

public protocol HistoryDelete<Model>: Sendable {
    associatedtype Model: PersistentModel
    associatedtype ChangeIdentifier: Comparable, Hashable, Sendable
    associatedtype TransactionIdentifier: Comparable, Hashable, Sendable
    var changeIdentifier: ChangeIdentifier { get }
    var changedPersistentIdentifier: PersistentIdentifier { get }
    var transactionIdentifier: TransactionIdentifier { get }
    var tombstone: HistoryTombstone<Model> { get }
}

public protocol HistoryProviding {
    associatedtype HistoryType: HistoryTransaction
    static var historyType: HistoryType.Type { get }
    func fetchHistory(_ descriptor: HistoryDescriptor<HistoryType>) throws -> [HistoryType]
    func deleteHistory(_ descriptor: HistoryDescriptor<HistoryType>) throws
}

public enum HistoryChange: Sendable {
    case insert(any HistoryInsert)
    case update(any HistoryUpdate)
    case delete(any HistoryDelete)

    public var changedPersistentIdentifier: PersistentIdentifier {
        switch self {
        case .insert(let change): return change.changedPersistentIdentifier
        case .update(let change): return change.changedPersistentIdentifier
        case .delete(let change): return change.changedPersistentIdentifier
        }
    }
}

public struct HistoryDescriptor<TransactionType: HistoryTransaction> {
    public var predicate: Predicate<TransactionType>?
    public var sortBy: [SortDescriptor<TransactionType>]
    public var fetchLimit: UInt64

    public init(predicate: Predicate<TransactionType>? = nil) {
        self.predicate = predicate
        self.sortBy = []
        self.fetchLimit = .max
    }

    public init(
        predicate: Predicate<TransactionType>? = nil,
        sortBy: [SortDescriptor<TransactionType>] = []
    ) {
        self.predicate = predicate
        self.sortBy = sortBy
        self.fetchLimit = .max
    }
}

public struct HistoryTombstone<Model: PersistentModel>: Sequence, @unchecked Sendable {
    public typealias Element = Any
    private let values: [Any]

    public init(_ values: [Any] = []) {
        self.values = values
    }

    public struct Iterator: IteratorProtocol {
        public typealias Element = Any
        private var inner: IndexingIterator<[Any]>
        fileprivate init(_ values: [Any]) { inner = values.makeIterator() }
        public mutating func next() -> Any? { inner.next() }
    }

    public func makeIterator() -> Iterator {
        Iterator(values)
    }

    public subscript(keyPath: PartialKeyPath<Model>) -> (any Sendable)? {
        _ = keyPath
        return nil
    }
}

public struct DefaultHistoryToken: HistoryToken, Sendable {
    public typealias ID = Int
    public typealias TokenType = [String: Int64]
    public let id: Int
    public let tokenValue: TokenType?

    public init(id: Int = 0, tokenValue: TokenType? = nil) {
        self.id = id
        self.tokenValue = tokenValue
    }

    public static func < (lhs: DefaultHistoryToken, rhs: DefaultHistoryToken) -> Bool {
        lhs.id < rhs.id
    }
}

public struct DefaultHistoryTransaction: HistoryTransaction, Hashable, Sendable {
    public typealias ID = Int64
    public typealias TokenType = DefaultHistoryToken
    public typealias TransactionIdentifier = Int64

    public let author: String?
    public let bundleIdentifier: String
    public let processIdentifier: String
    public let storeIdentifier: String
    public let timestamp: Date
    public let token: DefaultHistoryToken
    public let transactionIdentifier: Int64
    public let changes: [HistoryChange]
    public var id: Int64 { transactionIdentifier }

    public init(
        author: String? = nil,
        bundleIdentifier: String = "",
        processIdentifier: String = "",
        storeIdentifier: String,
        timestamp: Date = Date(timeIntervalSince1970: 0),
        token: DefaultHistoryToken = DefaultHistoryToken(),
        transactionIdentifier: Int64,
        changes: [HistoryChange] = []
    ) {
        self.author = author
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.storeIdentifier = storeIdentifier
        self.timestamp = timestamp
        self.token = token
        self.transactionIdentifier = transactionIdentifier
        self.changes = changes
    }

    public static func == (lhs: DefaultHistoryTransaction, rhs: DefaultHistoryTransaction) -> Bool {
        lhs.transactionIdentifier == rhs.transactionIdentifier
            && lhs.storeIdentifier == rhs.storeIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionIdentifier)
        hasher.combine(storeIdentifier)
    }
}

public struct DefaultHistoryInsert<Model: PersistentModel>: HistoryInsert, Hashable, Sendable {
    public typealias ChangeIdentifier = Int64
    public typealias TransactionIdentifier = Int64
    public let changeIdentifier: Int64
    public let changedPersistentIdentifier: PersistentIdentifier
    public let transactionIdentifier: Int64
}

public struct DefaultHistoryUpdate<Model: PersistentModel>: HistoryUpdate, Sendable {
    public typealias ChangeIdentifier = Int64
    public typealias TransactionIdentifier = Int64
    public typealias PropertyUpdate = PartialKeyPath<Model> & Sendable
    public let changeIdentifier: Int64
    public let changedPersistentIdentifier: PersistentIdentifier
    public let transactionIdentifier: Int64
    public let updatedAttributes: [any PartialKeyPath<Model> & Sendable]

    public static func == (lhs: DefaultHistoryUpdate<Model>, rhs: DefaultHistoryUpdate<Model>) -> Bool {
        lhs.changeIdentifier == rhs.changeIdentifier
            && lhs.transactionIdentifier == rhs.transactionIdentifier
            && lhs.changedPersistentIdentifier == rhs.changedPersistentIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(changeIdentifier)
        hasher.combine(transactionIdentifier)
        hasher.combine(changedPersistentIdentifier)
    }
}

public struct DefaultHistoryDelete<Model: PersistentModel>: HistoryDelete, Hashable, Sendable {
    public typealias ChangeIdentifier = Int64
    public typealias TransactionIdentifier = Int64
    public let changeIdentifier: Int64
    public let changedPersistentIdentifier: PersistentIdentifier
    public let transactionIdentifier: Int64
    public let tombstone: HistoryTombstone<Model>
}

extension HistoryTombstone: Equatable {
    public static func == (lhs: HistoryTombstone<Model>, rhs: HistoryTombstone<Model>) -> Bool {
        lhs.values.count == rhs.values.count
    }
}

extension HistoryTombstone: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(values.count)
    }
}
