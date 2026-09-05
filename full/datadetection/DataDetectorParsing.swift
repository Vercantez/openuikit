import Foundation

extension StringProtocol {
    /// Apple overlay: async sequence of detector matches. Linux yields a
    /// precomputed snapshot; the iterator does not hop queues or wait on a
    /// run loop.
    public func dataDetectorMatches(
        _ types: DataDetector.MatchType = .all,
        options: DataDetector.Options = DataDetector.Options()
    ) -> some AsyncSequence<DataDetector.Match, Never> {
        DataDetector.MatchSequence(
            matches: DataDetector.collectMatches(
                in: String(self),
                types: types,
                options: options
            )
        )
    }
}

extension DataDetector {
    struct MatchSequence: AsyncSequence, Sendable {
        typealias Element = Match

        let matches: [Match]

        struct AsyncIterator: AsyncIteratorProtocol, Sendable {
            var index = 0
            let matches: [Match]

            mutating func next() async -> Match? {
                guard index < matches.count else { return nil }
                let match = matches[index]
                index += 1
                return match
            }
        }

        func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(matches: matches)
        }
    }
}

enum DataDetectionScanner {
    private struct Candidate {
        let range: Range<String.Index>
        let match: DataDetector.Match
    }

    static func scan(
        text: String,
        types: DataDetector.MatchType,
        options: DataDetector.Options
    ) -> [DataDetector.Match] {
        guard !types.isEmpty, !text.isEmpty else { return [] }

        var candidates: [Candidate] = []
        if types.contains(.link) {
            candidates.append(contentsOf: links(in: text))
        }
        if types.contains(.emailAddress) {
            candidates.append(contentsOf: emails(in: text))
        }
        if types.contains(.paymentIdentifier) {
            candidates.append(contentsOf: payments(in: text))
        }
        if types.contains(.phoneNumber) {
            candidates.append(contentsOf: phones(in: text))
        }
        if types.contains(.moneyAmount) {
            candidates.append(contentsOf: money(in: text))
        }
        if types.contains(.measurement) {
            candidates.append(contentsOf: measurements(in: text))
        }
        if types.contains(.flightNumber) {
            candidates.append(contentsOf: flights(in: text))
        }
        if types.contains(.shipmentTrackingNumber) {
            candidates.append(contentsOf: tracking(in: text))
        }
        if types.contains(.calendarEvent) {
            candidates.append(contentsOf: calendarEvents(in: text, options: options))
        }
        if types.contains(.postalAddress) {
            candidates.append(contentsOf: postalAddresses(in: text, options: options))
        }

        candidates.sort { lhs, rhs in
            if lhs.range.lowerBound != rhs.range.lowerBound {
                return lhs.range.lowerBound < rhs.range.lowerBound
            }
            return lhs.range.upperBound > rhs.range.upperBound
        }

        var accepted: [DataDetector.Match] = []
        var occupied: [Range<String.Index>] = []
        for candidate in candidates {
            if occupied.contains(where: { $0.overlaps(candidate.range) }) {
                continue
            }
            occupied.append(candidate.range)
            accepted.append(candidate.match)
        }
        return accepted
    }

    private static func matches(
        in text: String,
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> [(Range<String.Index>, NSTextCheckingResult)] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }
        let full = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: full).compactMap { result in
            guard let range = Range(result.range, in: text) else { return nil }
            return (range, result)
        }
    }

    private static func group(_ result: NSTextCheckingResult, _ index: Int, in text: String) -> String? {
        guard result.numberOfRanges > index, result.range(at: index).location != NSNotFound else {
            return nil
        }
        guard let range = Range(result.range(at: index), in: text) else { return nil }
        return String(text[range])
    }

    private static func links(in text: String) -> [Candidate] {
        let pattern = #"((?:https?|ftp)://[^\s<>"]+|www\.[^\s<>"]+)"#
        return matches(in: text, pattern: pattern, options: [.caseInsensitive]).compactMap { range, _ in
            var raw = String(text[range])
            if raw.lowercased().hasPrefix("www.") {
                raw = "https://" + raw
            }
            guard let url = URL(string: raw) else { return nil }
            return Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .url,
                    range: range,
                    details: .link(.init(url: url))
                )
            )
        }
    }

    private static func emails(in text: String) -> [Candidate] {
        let pattern = #"\b([A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,})\b"#
        return matches(in: text, pattern: pattern, options: [.caseInsensitive]).map { range, _ in
            let value = String(text[range])
            return Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .regular,
                    range: range,
                    details: .emailAddress(.init(emailAddress: value, label: nil))
                )
            )
        }
    }

    private static func payments(in text: String) -> [Candidate] {
        // Fail-closed: only explicit UPI URIs. VPA-vs-email overlap is an oracle question.
        let pattern = #"upi://[^\s<>"]+"#
        return matches(in: text, pattern: pattern, options: [.caseInsensitive]).map { range, _ in
            Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .regular,
                    range: range,
                    details: .paymentIdentifier(
                        .init(
                            identifier: String(text[range]),
                            type: .unifiedPaymentsInterface
                        )
                    )
                )
            )
        }
    }

    private static func phones(in text: String) -> [Candidate] {
        let pattern = #"(?:\+\d{1,3}[\s.\-]?)?(?:\(?\d{3}\)?[\s.\-]?)\d{3}[\s.\-]?\d{4}"#
        return matches(in: text, pattern: pattern).compactMap { range, _ in
            let digits = text[range].filter(\.isNumber)
            guard digits.count >= 10 else { return nil }
            return Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .regular,
                    range: range,
                    details: .phoneNumber(
                        .init(phoneNumber: String(text[range]), label: nil)
                    )
                )
            )
        }
    }

    private static func money(in text: String) -> [Candidate] {
        var found: [Candidate] = []
        let symbolPattern = #"([$€£¥])\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)"#
        for (range, result) in matches(in: text, pattern: symbolPattern) {
            guard let symbol = group(result, 1, in: text),
                  let amountText = group(result, 2, in: text),
                  let amount = decimal(from: amountText)
            else { continue }
            let code: String
            switch symbol {
            case "$": code = "USD"
            case "€": code = "EUR"
            case "£": code = "GBP"
            case "¥": code = "JPY"
            default: continue
            }
            found.append(
                Candidate(
                    range: range,
                    match: DataDetector.Match(
                        preferredHighlightStyle: .regular,
                        range: range,
                        details: .moneyAmount(
                            .init(amount: amount, currency: Locale.Currency(code))
                        )
                    )
                )
            )
        }

        let codePattern = #"\b([A-Z]{3})\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)\b"#
        for (range, result) in matches(in: text, pattern: codePattern) {
            guard let code = group(result, 1, in: text),
                  let amountText = group(result, 2, in: text),
                  let amount = decimal(from: amountText),
                  isCurrencyCode(code)
            else { continue }
            found.append(
                Candidate(
                    range: range,
                    match: DataDetector.Match(
                        preferredHighlightStyle: .regular,
                        range: range,
                        details: .moneyAmount(
                            .init(amount: amount, currency: Locale.Currency(code))
                        )
                    )
                )
            )
        }

        let suffixPattern = #"\b(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)\s*([A-Z]{3})\b"#
        for (range, result) in matches(in: text, pattern: suffixPattern) {
            guard let amountText = group(result, 1, in: text),
                  let code = group(result, 2, in: text),
                  let amount = decimal(from: amountText),
                  isCurrencyCode(code)
            else { continue }
            found.append(
                Candidate(
                    range: range,
                    match: DataDetector.Match(
                        preferredHighlightStyle: .regular,
                        range: range,
                        details: .moneyAmount(
                            .init(amount: amount, currency: Locale.Currency(code))
                        )
                    )
                )
            )
        }
        return found
    }

    private static func measurements(in text: String) -> [Candidate] {
        let pattern = #"\b(\d+(?:\.\d+)?)\s*(km/h|mph|km|cm|mm|mi|ft|in|kg|mg|lb|oz|ml|°C|°F|C|F|m|g|L)\b"#
        return matches(in: text, pattern: pattern).compactMap { range, result in
            guard let valueText = group(result, 1, in: text),
                  let unitText = group(result, 2, in: text),
                  let value = Double(valueText),
                  let unit = dimension(for: unitText)
            else { return nil }
            return Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .regular,
                    range: range,
                    details: .measurement(
                        .init(value: value, possibleDimensions: [unit])
                    )
                )
            )
        }
    }

    private static func flights(in text: String) -> [Candidate] {
        let pattern = #"\b([A-Z]{2})\s?(\d{3,4})\b"#
        return matches(in: text, pattern: pattern).compactMap { range, result in
            guard let airline = group(result, 1, in: text),
                  let numberText = group(result, 2, in: text),
                  let number = Int(numberText),
                  !deniedAirlineCodes.contains(airline)
            else { return nil }
            return Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .regular,
                    range: range,
                    details: .flightNumber(
                        .init(airlineCode: airline, flightNumber: number)
                    )
                )
            )
        }
    }

    private static func tracking(in text: String) -> [Candidate] {
        var found: [Candidate] = []
        for (range, _) in matches(in: text, pattern: #"\b(1Z[A-Z0-9]{16})\b"#, options: [.caseInsensitive]) {
            found.append(
                Candidate(
                    range: range,
                    match: DataDetector.Match(
                        preferredHighlightStyle: .regular,
                        range: range,
                        details: .shipmentTrackingNumber(
                            .init(
                                carrier: "UPS",
                                trackingNumber: String(text[range]).uppercased(),
                                trackingURL: nil
                            )
                        )
                    )
                )
            )
        }
        return found
    }

    private static func calendarEvents(
        in text: String,
        options: DataDetector.Options
    ) -> [Candidate] {
        var found: [Candidate] = []
        let timeZone = options.documentTimeZone ?? TimeZone(secondsFromGMT: 0) ?? .gmt

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        iso.timeZone = timeZone
        for (range, _) in matches(
            in: text,
            pattern: #"\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:\d{2})?\b"#
        ) {
            let raw = String(text[range])
            guard let date = iso.date(from: raw) ?? parseFlexibleISO(raw, timeZone: timeZone) else {
                continue
            }
            found.append(
                Candidate(
                    range: range,
                    match: DataDetector.Match(
                        preferredHighlightStyle: .regular,
                        range: range,
                        details: .calendarEvent(
                            .init(
                                allDay: false,
                                startDate: date,
                                startTimeZone: timeZone,
                                endDate: nil,
                                endTimeZone: nil
                            )
                        )
                    )
                )
            )
        }

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = timeZone
        dayFormatter.dateFormat = "yyyy-MM-dd"
        for (range, _) in matches(in: text, pattern: #"\b\d{4}-\d{2}-\d{2}\b"#) {
            let raw = String(text[range])
            guard let date = dayFormatter.date(from: raw) else { continue }
            found.append(
                Candidate(
                    range: range,
                    match: DataDetector.Match(
                        preferredHighlightStyle: .regular,
                        range: range,
                        details: .calendarEvent(
                            .init(
                                allDay: true,
                                startDate: date,
                                startTimeZone: timeZone,
                                endDate: nil,
                                endTimeZone: nil
                            )
                        )
                    )
                )
            )
        }
        return found
    }

    private static func postalAddresses(
        in text: String,
        options: DataDetector.Options
    ) -> [Candidate] {
        let pattern = #"(\d{1,5}\s+[^,\n]+),\s*([^,\n]+),\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)"#
        let region = options.documentRegion ?? Locale.Region("US")
        return matches(in: text, pattern: pattern).compactMap { range, result in
            guard let street = group(result, 1, in: text),
                  let city = group(result, 2, in: text),
                  let state = group(result, 3, in: text),
                  let postal = group(result, 4, in: text)
            else { return nil }
            let full = String(text[range])
            return Candidate(
                range: range,
                match: DataDetector.Match(
                    preferredHighlightStyle: .regular,
                    range: range,
                    details: .postalAddress(
                        .init(
                            fullAddress: full,
                            street: street,
                            city: city,
                            state: state,
                            postalCode: postal,
                            region: nil,
                            regionCode: region,
                            label: nil
                        )
                    )
                )
            )
        }
    }

    private static func decimal(from text: String) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: ""))
    }

    private static func isCurrencyCode(_ code: String) -> Bool {
        ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR"].contains(code)
    }

    private static let deniedAirlineCodes: Set<String> = [
        "TO", "IN", "ON", "AT", "OF", "OR", "IS", "BE", "AS", "BY", "IF",
        "NO", "SO", "AN", "AM", "PM", "THE",
    ]

    private static func dimension(for unit: String) -> Dimension? {
        switch unit {
        case "km": return UnitLength.kilometers
        case "m": return UnitLength.meters
        case "cm": return UnitLength.centimeters
        case "mm": return UnitLength.millimeters
        case "mi": return UnitLength.miles
        case "ft": return UnitLength.feet
        case "in": return UnitLength.inches
        case "kg": return UnitMass.kilograms
        case "g": return UnitMass.grams
        case "mg": return UnitMass.milligrams
        case "lb": return UnitMass.pounds
        case "oz": return UnitMass.ounces
        case "L": return UnitVolume.liters
        case "ml": return UnitVolume.milliliters
        case "°C", "C": return UnitTemperature.celsius
        case "°F", "F": return UnitTemperature.fahrenheit
        case "mph": return UnitSpeed.milesPerHour
        case "km/h": return UnitSpeed.kilometersPerHour
        default: return nil
        }
    }

    private static func parseFlexibleISO(_ raw: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: raw) { return date }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: raw)
    }
}
