import Foundation

extension Tips {
    public struct Event<DonationInfo: Codable & Sendable>: Sendable {
        public typealias ID = String
        public typealias Value = Tips.Event<DonationInfo>

        public let id: String
        let donationLimit: Tips.DonationLimit

        public init(id: String, donationLimit: Tips.DonationLimit) {
            self.id = id
            self.donationLimit = donationLimit
        }

        public init(id: String) {
            self.init(
                id: id,
                donationLimit: Tips.DonationLimit(maximumCount: Int.max)
            )
        }

        @dynamicMemberLookup
        public struct Donation: Decodable, Encodable, Sendable {
            public let date: Date
            let info: DonationInfo

            init(date: Date, info: DonationInfo) {
                self.date = date
                self.info = info
            }

            public subscript<Value>(dynamicMember keyPath: KeyPath<DonationInfo, Value>) -> Value {
                info[keyPath: keyPath]
            }

            enum CodingKeys: String, CodingKey {
                case date
                case info
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                date = try container.decode(Date.self, forKey: .date)
                info = try container.decode(DonationInfo.self, forKey: .info)
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(date, forKey: .date)
                try container.encode(info, forKey: .info)
            }
        }

        public var donations: [Tips.Event<DonationInfo>.Donation] {
            let stored = TipsStore.shared.loadDonations(eventID: id)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return stored.compactMap { row in
                guard let info = try? decoder.decode(DonationInfo.self, from: row.payload) else {
                    return nil
                }
                return Donation(date: row.date, info: info)
            }
        }

        public func sendDonation(
            _ donation: DonationInfo,
            _ completion: (() -> Void)? = nil
        ) {
            sendDonation(donation, date: TipsTime.now, completion)
        }

        @_spi(OpenUIKitHost)
        public func sendDonation(
            _ donation: DonationInfo,
            date: Date,
            _ completion: (() -> Void)? = nil
        ) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let payload = (try? encoder.encode(donation)) ?? Data()
            TipsStore.shared.appendDonation(
                eventID: id,
                date: date,
                payload: payload,
                limit: donationLimit
            )
            if let completion {
                TipsStore.shared.completionQueue.async {
                    completion()
                }
            }
        }

        public func donate(_ donation: DonationInfo) async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                sendDonation(donation) {
                    continuation.resume()
                }
            }
        }

        public func deleteDonations() async throws {
            TipsStore.shared.deleteDonations(eventID: id)
        }
    }
}

extension Tips.Event where DonationInfo == Tips.EmptyDonation {
    public func sendDonation(_ completion: (() -> Void)? = nil) {
        sendDonation(Tips.EmptyDonation(), completion)
    }

    public func donate() async {
        await donate(Tips.EmptyDonation())
    }
}

extension Sequence {
    public func donatedWithin<DonationInfo>(
        _ timeRange: Tips.DonationTimeRange
    ) -> [Self.Element]
    where
        DonationInfo: Decodable,
        DonationInfo: Encodable,
        DonationInfo: Sendable,
        Self.Element == Tips.Event<DonationInfo>.Donation
    {
        let cutoff = TipsTime.now.addingTimeInterval(-timeRange.hostSeconds)
        return filter { $0.date >= cutoff }
    }

    public func largestSubset<DonationInfo, Value>(
        groupedBy keyPath: KeyPath<DonationInfo, Value>
    ) -> [Self.Element]
    where
        DonationInfo: Decodable,
        DonationInfo: Encodable,
        DonationInfo: Sendable,
        Value: Hashable,
        Self.Element == Tips.Event<DonationInfo>.Donation
    {
        grouped(by: keyPath).max(by: { $0.value.count < $1.value.count })?.value ?? []
    }

    public func smallestSubset<DonationInfo, Value>(
        groupedBy keyPath: KeyPath<DonationInfo, Value>
    ) -> [Self.Element]
    where
        DonationInfo: Decodable,
        DonationInfo: Encodable,
        DonationInfo: Sendable,
        Value: Hashable,
        Self.Element == Tips.Event<DonationInfo>.Donation
    {
        grouped(by: keyPath).min(by: { $0.value.count < $1.value.count })?.value ?? []
    }

    private func grouped<DonationInfo, Value>(
        by keyPath: KeyPath<DonationInfo, Value>
    ) -> [Value: [Self.Element]]
    where
        DonationInfo: Decodable,
        DonationInfo: Encodable,
        DonationInfo: Sendable,
        Value: Hashable,
        Self.Element == Tips.Event<DonationInfo>.Donation
    {
        var result: [Value: [Self.Element]] = [:]
        for element in self {
            let key = element.info[keyPath: keyPath]
            result[key, default: []].append(element)
        }
        return result
    }
}
