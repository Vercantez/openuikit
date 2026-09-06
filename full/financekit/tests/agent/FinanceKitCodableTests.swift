import Foundation
import FinanceKit

func testTransactionTypeCodable() {
    financeKitExpect(financeKitRoundTrip(TransactionType.pointOfSale) == .pointOfSale)
}

func testTransactionStatusCodable() {
    financeKitExpect(financeKitRoundTrip(TransactionStatus.booked) == .booked)
}

func testCreditDebitIndicatorCodable() {
    financeKitExpect(financeKitRoundTrip(CreditDebitIndicator.debit) == .debit)
}

func testMerchantCategoryCodeCodable() {
    financeKitExpect(financeKitRoundTrip(MerchantCategoryCode(rawValue: 5411)).rawValue == 5411)
}

func testUpdateFrequencyCodable() {
    financeKitExpect(financeKitRoundTrip(FinanceStore.UpdateFrequency.weekly) == .weekly)
}

func testBackgroundDataTypeCodable() {
    financeKitExpect(financeKitRoundTrip(FinanceStore.BackgroundDataType.accounts) == .accounts)
}

func testAuthorizationStatusCodable() {
    financeKitExpect(financeKitRoundTrip(AuthorizationStatus.denied) == .denied)
}

func testTransactionCodable() {
    financeKitExpect(financeKitRoundTrip(sampleTransaction()) == sampleTransaction())
}

func testAssetAccountCodable() {
    financeKitExpect(financeKitRoundTrip(sampleAssetAccount()) == sampleAssetAccount())
}

func testLiabilityAccountCodable() {
    financeKitExpect(financeKitRoundTrip(sampleLiabilityAccount()) == sampleLiabilityAccount())
}

func testAccountCodable() {
    financeKitExpect(financeKitRoundTrip(Account.asset(sampleAssetAccount())) == Account.asset(sampleAssetAccount()))
    financeKitExpect(
        financeKitRoundTrip(Account.liability(sampleLiabilityAccount())) == Account.liability(sampleLiabilityAccount())
    )
}

func testAccountBalanceCodable() {
    let id = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    let balance = AccountBalance(
        id: id,
        accountID: accountID,
        currentBalance: .availableAndBooked(available: sampleBalance(indicator: .credit), booked: sampleBalance(indicator: .debit))
    )
    financeKitExpect(financeKitRoundTrip(balance) == balance)
}

func testCurrentBalanceCodable() {
    financeKitExpect(financeKitRoundTrip(CurrentBalance.available(sampleBalance())) == .available(sampleBalance()))
}

func testBalanceCodable() {
    financeKitExpect(financeKitRoundTrip(sampleBalance()) == sampleBalance())
}

func testAccountCreditInformationCodable() {
    let info = sampleLiabilityAccount().creditInformation
    financeKitExpect(financeKitRoundTrip(info) == info)
}

func testFullyQualifiedOrderIdentifierCodable() {
    let identifier = FullyQualifiedOrderIdentifier(
        orderTypeIdentifier: "order.com.example",
        orderIdentifier: "A-1"
    )
    financeKitExpect(financeKitRoundTrip(identifier) == identifier)
}

func testHistoryTokenCodable() {
    let encoded = try! JSONEncoder().encode(Data([0x0A, 0x0B]))
    let token = try! JSONDecoder().decode(FinanceStore.HistoryToken.self, from: encoded)
    let roundTrip = try! JSONDecoder().decode(
        FinanceStore.HistoryToken.self,
        from: try! JSONEncoder().encode(token)
    )
    let again = try! JSONDecoder().decode(FinanceStore.HistoryToken.self, from: encoded)
    financeKitSink(roundTrip)
    financeKitSink(again)
}
