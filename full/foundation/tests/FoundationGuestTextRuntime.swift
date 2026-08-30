import Foundation

private enum PlainRuntimeError: Error {
    case sample(Int)
}

private struct Payload: Decodable {
    let value: Int
}

@main
struct FoundationGuestTextRuntime {
    static func main() {
        let boundary = "\u{200B}\u{00A0}Reminder\u{2028}\u{2029}"
        precondition(
            boundary.trimmingCharacters(in: .whitespacesAndNewlines)
                == "Reminder"
        )

        var value: UInt64 = 0
        let scanner = Scanner(string: "\t0x10000000000000000")
        precondition(scanner.scanHexInt64(&value))
        precondition(value == UInt64.max)
        precondition(scanner.isAtEnd)

        var unchanged: UInt64 = 42
        let failure = Scanner(string: "not-hex")
        precondition(!failure.scanHexInt64(&unchanged))
        precondition(unchanged == 42)
        precondition(failure.currentIndex == failure.string.startIndex)

        let plain: any Error = PlainRuntimeError.sample(7)
        precondition(
            plain.localizedDescription.hasPrefix(
                "The operation couldn’t be completed. ("
            )
        )

        precondition(
            "Focus Linux".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                == "Focus%20Linux"
        )
        precondition("caf%C3%A9".removingPercentEncoding == "café")
        precondition("%GG".removingPercentEncoding == nil)
        let regexInput = "www.example"
        let regexUpper = regexInput.index(regexInput.startIndex, offsetBy: 4)
        precondition(
            regexInput.range(of: "^(www|m)\\.", options: .regularExpression)
                == regexInput.startIndex..<regexUpper
        )
        precondition(
            "abc".range(of: "^", options: .regularExpression) == nil,
            "the bounded overlay must reject zero-width regular-expression matches"
        )
        precondition(
            "abc".replacingOccurrences(
                of: "^", with: "X", options: .regularExpression
            ) == "abc",
            "a zero-width regular expression must not stall replacement"
        )
        precondition(String(format: "%2$@/%1$@", "one", "two") == "two/one")
        precondition(NSString(string: "/tmp/file.txt").lastPathComponent == "file.txt")

        do {
            _ = try JSONDecoder().decode(
                Payload.self,
                from: Data("{\"value\":\"wrong\"}".utf8)
            )
            preconditionFailure("malformed payload unexpectedly decoded")
        } catch {
            precondition(!error.localizedDescription.isEmpty)
        }

        print(
            "FOUNDATION_GUEST_TEXT_RUNTIME_OK "
                + "characters=26 trimming=unicode scanner=hex error=descriptive compatibility=focus"
        )
    }
}
