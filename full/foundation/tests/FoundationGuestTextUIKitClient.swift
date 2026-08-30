import UIKit

private struct UIKitOnlyLocalizedError: LocalizedError {
    var errorDescription: String? { "visible through UIKit" }
}

@main
struct FoundationGuestTextUIKitClient {
    static func main() {
        precondition(
            " \tunchanged app\n".trimmingCharacters(
                in: .whitespacesAndNewlines
            ) == "unchanged app"
        )

        var value: UInt64 = 0
        let scanner = Scanner(string: "  0xC0FFEE")
        precondition(scanner.scanHexInt64(&value))
        precondition(value == 0xC0FFEE)
        precondition(scanner.isAtEnd)

        let error: any Error = UIKitOnlyLocalizedError()
        precondition(error.localizedDescription == "visible through UIKit")
        print("FOUNDATION_GUEST_TEXT_UIKIT_REEXPORT_OK")
    }
}
