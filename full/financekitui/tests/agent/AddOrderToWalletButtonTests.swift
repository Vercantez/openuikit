import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testAddOrderToWalletButtonStruct() {
    FinanceKitUIHostControl.reset()
    let button = AddOrderToWalletButton(signedArchive: Data([0x01]), onCompletion: { _ in })
    let asView: any View = button
    _ = asView
    precondition(button.hostArchive == Data([0x01]))
}

func testAddOrderToWalletButtonInitSignedArchive() {
    FinanceKitUIHostControl.reset()
    var invoked = false
    let archive = Data([0x0A, 0x0B, 0x0C])
    let button = AddOrderToWalletButton(signedArchive: archive) { result in
        invoked = true
        _ = result
    }
    precondition(button.hostArchive == archive)
    precondition(FinanceKitUIHostControl.lastWalletArchive() == archive)
    precondition(FinanceKitUIHostControl.pendingWalletCompletions() == 1)
    precondition(invoked == false)
}

func testAddOrderToWalletButtonBodyTypealias() {
    precondition(AddOrderToWalletButton.Body.self == EmptyView.self)
}

func testAddOrderToWalletButtonBody() {
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    precondition(type(of: button.body) == EmptyView.self)
}

func testAddOrderToWalletButtonStyleStruct() {
    let black: AddOrderToWalletButtonStyle = .black
    let outline: AddOrderToWalletButtonStyle = .blackOutline
    precondition(black == AddOrderToWalletButtonStyle.black)
    precondition(outline == AddOrderToWalletButtonStyle.blackOutline)
    precondition(black != outline)
}

func testAddOrderToWalletButtonStyleBlack() {
    let style = AddOrderToWalletButtonStyle.black
    precondition(style == .black)
    precondition(style != .blackOutline)
}

func testAddOrderToWalletButtonStyleBlackOutline() {
    let style = AddOrderToWalletButtonStyle.blackOutline
    precondition(style == .blackOutline)
    precondition(style != .black)
}

func testAddOrderToWalletButtonFailClosedNeverSucceeds() {
    FinanceKitUIHostControl.reset()
    var delivered: Result<FinanceStore.SaveOrderResult, any Error>?
    _ = AddOrderToWalletButton(signedArchive: Data([0xFF])) { result in
        delivered = result
    }
    let count = FinanceKitUIHostControl.failClosedPendingWalletButtons()
    precondition(count == 1)
    precondition(FinanceKitUIHostControl.pendingWalletCompletions() == 0)
    switch delivered {
    case .failure(let error as FinanceKitUIUnavailable):
        precondition(error == .linuxHost(operation: "AddOrderToWalletButton"))
    default:
        precondition(false, "Wallet button must fail closed on Linux")
    }
}
