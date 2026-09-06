import Foundation
import FinanceKit

func testFullyQualifiedOrderIdentifierInit() {
    let identifier = FullyQualifiedOrderIdentifier(
        orderTypeIdentifier: "order.com.example.store",
        orderIdentifier: "ABC-100"
    )
    financeKitExpect(identifier.orderTypeIdentifier == "order.com.example.store")
    financeKitExpect(identifier.orderIdentifier == "ABC-100")
}

func testFullyQualifiedOrderIdentifierDescription() {
    let identifier = FullyQualifiedOrderIdentifier(
        orderTypeIdentifier: "order.com.example.store",
        orderIdentifier: "ABC-100"
    )
    financeKitExpect(identifier.description == "order.com.example.store/ABC-100")
}

func testFullyQualifiedOrderIdentifierEquality() {
    let lhs = FullyQualifiedOrderIdentifier(orderTypeIdentifier: "a", orderIdentifier: "1")
    let rhs = FullyQualifiedOrderIdentifier(orderTypeIdentifier: "a", orderIdentifier: "1")
    financeKitExpect(lhs == rhs)
}
