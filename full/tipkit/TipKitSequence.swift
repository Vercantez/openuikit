import Foundation

extension Sequence {
    public func donatedWithin<DonationInfo: Codable & Sendable>(
        _ timeRange: Tips.DonationTimeRange
    ) -> [Self.Element]
    where Self.Element == Tips.Event<DonationInfo>.Donation {
        let cutoff = Date().addingTimeInterval(-timeRange.seconds)
        return filter { $0.date >= cutoff }
    }

    public func largestSubset<DonationInfo: Codable & Sendable, Value: Hashable>(
        groupedBy keyPath: KeyPath<DonationInfo, Value>
    ) -> [Self.Element]
    where Self.Element == Tips.Event<DonationInfo>.Donation {
        groupedSubset(groupedBy: keyPath, pickLargest: true)
    }

    public func smallestSubset<DonationInfo: Codable & Sendable, Value: Hashable>(
        groupedBy keyPath: KeyPath<DonationInfo, Value>
    ) -> [Self.Element]
    where Self.Element == Tips.Event<DonationInfo>.Donation {
        groupedSubset(groupedBy: keyPath, pickLargest: false)
    }

    private func groupedSubset<DonationInfo: Codable & Sendable, Value: Hashable>(
        groupedBy keyPath: KeyPath<DonationInfo, Value>,
        pickLargest: Bool
    ) -> [Self.Element]
    where Self.Element == Tips.Event<DonationInfo>.Donation {
        let groups = Dictionary(grouping: Array(self)) { donation in
            donation[dynamicMember: keyPath]
        }
        guard let selected = groups.max(by: { lhs, rhs in
            if pickLargest {
                return lhs.value.count < rhs.value.count
            }
            return lhs.value.count > rhs.value.count
        }) else {
            return []
        }
        return selected.value
    }
}
