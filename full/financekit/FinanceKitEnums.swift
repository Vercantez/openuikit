import Foundation

/// ISO 18245 merchant category code. `init(_:)` parses a decimal integer string.
public struct MerchantCategoryCode: RawRepresentable, Hashable, Sendable, Codable {
    public typealias RawValue = Int16
    public let rawValue: Int16

    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    public init?(_ description: String) {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Int16(trimmed) else {
            return nil
        }
        self.init(rawValue: value)
    }

    public var description: String { String(rawValue) }
}

extension MerchantCategoryCode: CustomStringConvertible, LosslessStringConvertible {}

public enum CreditDebitIndicator: Int16, Codable, Hashable, Sendable, CaseIterable {
    case credit = 0
    case debit = 1
}

public enum TransactionType: Int16, Codable, Hashable, Sendable, CaseIterable {
    case unknown = 0
    case adjustment = 1
    case atm = 2
    case billPayment = 3
    case check = 4
    case deposit = 5
    case directDeposit = 6
    case dividend = 7
    case fee = 8
    case interest = 9
    case pointOfSale = 10
    case transfer = 11
    case withdrawal = 12
    case standingOrder = 13
    case directDebit = 14
    case loan = 15
    case refund = 16
}

public enum TransactionStatus: Int16, Codable, Hashable, Sendable, CaseIterable {
    case authorized = 0
    case memo = 1
    case pending = 2
    case booked = 3
    case rejected = 4
}

public enum AuthorizationStatus: Codable, Hashable, Sendable {
    case notDetermined
    case denied
    case authorized
}
