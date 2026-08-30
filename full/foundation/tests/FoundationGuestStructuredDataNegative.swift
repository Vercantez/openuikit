import Foundation

@main
enum FoundationGuestStructuredDataNegative {
    static func main() throws {
        for option in [
            NSRegularExpression.Options.useUnixLineSeparators,
            NSRegularExpression.Options.useUnicodeWordBoundaries,
            NSRegularExpression.Options(rawValue: 1 << 20),
        ] {
            do {
                _ = try NSRegularExpression(pattern: "a", options: option)
                fatalError("unsupported regex option unexpectedly succeeded")
            } catch let error as NSError {
                precondition(error.domain == NSCocoaErrorDomain)
                precondition(error.code == 2048)
            }
        }

        do {
            _ = try JSONSerialization.data(
                withJSONObject: ["nonfinite": Double.infinity]
            )
            fatalError("nonfinite JSON number unexpectedly succeeded")
        } catch let error as NSError {
            precondition(error.domain == NSCocoaErrorDomain)
            precondition(error.code == NSPropertyListReadCorruptError)
        }

        print(
            "FOUNDATION_GUEST_STRUCTURED_NEGATIVE_OK " +
            "regex-options=3 json-nonfinite=1"
        )
    }
}
