import AppKit
import StoreKit

@main
@available(macOS 15.2, *)
private enum StoreKitAppKitRuntime {
    static func main() async {
        let product = Product(
            id: "portable.appkit.product",
            displayName: "Portable AppKit Product"
        )
        do {
            _ = try await product.purchase(confirmIn: NSWindow())
            preconditionFailure("headless StoreKit purchase unexpectedly succeeded")
        } catch let error as StoreKitPortableError {
            switch error.code {
            case .paymentsUnavailable:
                break
            default:
                preconditionFailure("wrong fail-closed StoreKit error: \(error)")
            }
        } catch {
            preconditionFailure("wrong StoreKit error type: \(error)")
        }

        print(
            "APPKIT_STOREKIT_MACHO_OK confirm-in=NSWindow " +
            "purchase=fail-closed,payments-unavailable"
        )
    }
}
