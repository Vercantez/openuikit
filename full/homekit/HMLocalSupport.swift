import Foundation

/// Host-local HomeKit helpers: name checks, time-of-day arithmetic, and
/// completion-to-async bridges. None of this talks to Apple Home or HAP.
enum HMLocalName {
    static func errorIfInvalid(_ name: String) -> HMError? {
        if name.isEmpty {
            return HMMakeError(
                .stringShorterThanMinimum,
                reason: "HomeKit object names must be nonempty"
            )
        }
        return nil
    }

    static func folded(_ name: String) -> String {
        name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    static func collides(_ name: String, with existing: [String]) -> Bool {
        let key = folded(name)
        return existing.contains { folded($0) == key }
    }
}

public enum HMLocalClock {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    static func minutesOfDay(from components: DateComponents) -> Int? {
        guard let hour = components.hour else { return nil }
        return hour * 60 + (components.minute ?? 0)
    }

    static func minutesOfDay(from date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    public static func date(hour: Int, minute: Int) -> Date {
        var parts = DateComponents()
        parts.year = 2024
        parts.month = 1
        parts.day = 15
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}

func hmFinishAsync<T: AnyObject>(
    _ body: (@escaping (T?, (any Error)?) -> Void) -> Void
) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        body { value, error in
            if let error {
                continuation.resume(throwing: error)
            } else if let value {
                continuation.resume(returning: value)
            } else {
                continuation.resume(throwing: HMFailClosed())
            }
        }
    }
}

func hmFinishAsync(_ body: (@escaping ((any Error)?) -> Void) -> Void) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        body { error in
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
            }
        }
    }
}

func hmNotifyHome(_ home: HMHome?, _ body: (HMHome) -> Void) {
    if let home { body(home) }
}

func hmNotifyAccessory(_ accessory: HMAccessory?, _ body: (HMAccessory) -> Void) {
    if let accessory { body(accessory) }
}

public func hmNSErrorCode(_ error: (any Error)?) -> Int? {
    (error as NSError?)?.code
}
