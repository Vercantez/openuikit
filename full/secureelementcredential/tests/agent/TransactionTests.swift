import Foundation
import SecureElementCredential

func testCredentialTransactionClass() {
    let transaction = CredentialTransaction()
    _ = transaction
}

func testConfigurationInit() {
    let configuration = CredentialTransaction.Configuration()
    _ = configuration
}

func testConfigurationEquality() {
    let a = CredentialTransaction.Configuration()
    let b = a
    let c = CredentialTransaction.Configuration()
    precondition(a == b)
    precondition(a != c)
}

func testConfigurationInequality() {
    let a = CredentialTransaction.Configuration()
    let b = CredentialTransaction.Configuration()
    precondition(a != b)
    precondition(!(a != a))
}
