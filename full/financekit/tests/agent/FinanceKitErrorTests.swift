import Foundation
import FinanceKit

func testFinanceErrorCases() {
    let restrictedOrders = FinanceError.dataRestricted(.orders)
    let restrictedFinancial = FinanceError.dataRestricted(.financialData)
    let unknown = FinanceError.unknown
    let invalid = FinanceError.historyTokenInvalid
    financeKitExpect(restrictedOrders != unknown)
    financeKitExpect(restrictedOrders != restrictedFinancial)
    financeKitSink(restrictedOrders)
    financeKitSink(unknown)
    financeKitSink(invalid)
}

func testFinanceErrorErrorDomain() {
    financeKitExpect(FinanceError.errorDomain == "FinanceKit.FinanceError")
}

func testFinanceErrorErrorCode() {
    financeKitExpect(FinanceError.dataRestricted(.orders).errorCode == 0)
    financeKitExpect(FinanceError.dataRestricted(.financialData).errorCode == 0)
    financeKitExpect(FinanceError.unknown.errorCode == 1)
    financeKitExpect(FinanceError.historyTokenInvalid.errorCode == 2)
}

func testFinanceErrorErrorUserInfo() {
    let info = FinanceError.dataRestricted(.financialData).errorUserInfo
    financeKitExpect(info[NSLocalizedDescriptionKey] as? String != nil)
    financeKitExpect(info["FinanceStoreDataType"] as? String == "financialData")
    let unknownInfo = FinanceError.unknown.errorUserInfo
    financeKitExpect(unknownInfo[NSLocalizedDescriptionKey] as? String != nil)
}

func testFinanceErrorErrorDescription() {
    financeKitExpect(FinanceError.unknown.errorDescription != nil)
    financeKitExpect(FinanceError.dataRestricted(.orders).errorDescription?.contains("orders") == true)
    financeKitExpect(FinanceError.historyTokenInvalid.errorDescription != nil)
}

func testFinanceErrorFailureReason() {
    financeKitExpect(FinanceError.dataRestricted(.orders).failureReason != nil)
    financeKitExpect(FinanceError.unknown.failureReason != nil)
    financeKitExpect(FinanceError.historyTokenInvalid.failureReason != nil)
}

func testFinanceErrorEquality() {
    financeKitExpect(FinanceError.unknown == FinanceError.unknown)
    financeKitExpect(FinanceError.dataRestricted(.orders) == FinanceError.dataRestricted(.orders))
    financeKitExpect(FinanceError.dataRestricted(.orders) != FinanceError.dataRestricted(.financialData))
}

func testFinanceErrorInequality() {
    financeKitExpect(FinanceError.unknown != FinanceError.historyTokenInvalid)
}

func testFinanceErrorHelpAnchor() {
    let error: any LocalizedError = FinanceError.unknown
    financeKitExpect(error.helpAnchor == nil)
}

func testFinanceErrorRecoverySuggestion() {
    let error: any LocalizedError = FinanceError.unknown
    financeKitExpect(error.recoverySuggestion == nil)
}

func testFinanceErrorLocalizedDescription() {
    let error: any Error = FinanceError.unknown
    financeKitExpect(!error.localizedDescription.isEmpty)
}
