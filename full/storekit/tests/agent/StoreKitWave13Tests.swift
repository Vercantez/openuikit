import Foundation
import StoreKit

// Wave 13: in-process async coverage for the leftover async surface.
// Every test is a top-level no-argument `func test*() async` (non-throwing so
// the sealed `@main async` runner can `await` it without `try`). Only
// immediate-returning async calls appear here: no main-queue hops, no run
// loops, and no blocking waits. Each async API under test
// returns immediately with a fail-closed value or error backed by the local
// testing store or a constant; live `Transaction.updates` (which suspends on
// a continuation) is never touched. Snapshot-backed sequences terminate
// immediately, including when empty.

private func expectWave13(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private let wave13StoreJSON = """
{
  "identifier": "WAVE13",
  "products": [
    {
      "displayPrice": "0.99",
      "familyShareable": true,
      "localizations": [
        { "description": "Coins", "displayName": "Coins", "locale": "en_US" }
      ],
      "productID": "coins",
      "referenceName": "Coins",
      "type": "Consumable"
    },
    {
      "displayPrice": "4.99",
      "familyShareable": true,
      "localizations": [
        { "description": "Pro", "displayName": "Pro", "locale": "en_US" }
      ],
      "productID": "pro",
      "referenceName": "Pro",
      "type": "NonConsumable"
    }
  ],
  "settings": { "_locale": "en_US" },
  "nonRenewingSubscriptions": [],
  "subscriptionGroups": [
    {
      "id": "group1",
      "localizations": [],
      "name": "Plus",
      "subscriptions": [
        {
          "displayPrice": "1.99",
          "familyShareable": false,
          "groupNumber": 1,
          "localizations": [
            { "description": "Monthly", "displayName": "Plus Monthly", "locale": "en_US" }
          ],
          "productID": "plus.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Plus Monthly",
          "subscriptionGroupID": "group1",
          "type": "RecurringSubscription"
        }
      ]
    }
  ]
}
"""

private func wave13Storefronts() -> Storefront.Storefronts {
    Storefront.Storefronts(snapshot: [])
}

private func wave13Transactions() -> Transaction.Transactions {
    Transaction.Transactions(snapshot: [])
}

private func wave13Statuses() -> Product.SubscriptionInfo.Status.Statuses {
    Product.SubscriptionInfo.Status.Statuses(snapshot: [])
}

func testWave13ExternalPurchaseAsync() async {
    let presentable = await ExternalPurchase.canPresent
    expectWave13(presentable == false, "ExternalPurchase.canPresent is fail-closed false")
    do {
        _ = try await ExternalPurchase.presentNoticeSheet()
        expectWave13(false, "presentNoticeSheet must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no App Store on Linux.
    } catch {
        expectWave13(false, "wrong presentNoticeSheet error \(error)")
    }
}

func testWave13ExternalLinkAccountAsync() async {
    let openable = await ExternalLinkAccount.canOpen
    expectWave13(openable == false, "ExternalLinkAccount.canOpen is fail-closed false")
    do {
        try await ExternalLinkAccount.open()
        expectWave13(false, "ExternalLinkAccount.open must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no App Store on Linux.
    } catch {
        expectWave13(false, "wrong ExternalLinkAccount.open error \(error)")
    }
}

func testWave13ExternalPurchaseLinkAsync() async {
    let openable = await ExternalPurchaseLink.canOpen
    expectWave13(openable == false, "ExternalPurchaseLink.canOpen is fail-closed false")
    do {
        try await ExternalPurchaseLink.open()
        expectWave13(false, "ExternalPurchaseLink.open must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no App Store on Linux.
    } catch {
        expectWave13(false, "wrong ExternalPurchaseLink.open error \(error)")
    }
    do {
        try await ExternalPurchaseLink.open(url: URL(string: "https://example.com")!)
        expectWave13(false, "ExternalPurchaseLink.open(url:) must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no App Store on Linux.
    } catch {
        expectWave13(false, "wrong ExternalPurchaseLink.open(url:) error \(error)")
    }
}

func testWave13ExternalPurchaseCustomLinkAsync() async {
    let eligible = await ExternalPurchaseCustomLink.isEligible
    expectWave13(eligible == false, "ExternalPurchaseCustomLink.isEligible is fail-closed false")
    do {
        _ = try await ExternalPurchaseCustomLink.token(for: "notice")
        expectWave13(false, "token(for:) must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no token minting on Linux.
    } catch {
        expectWave13(false, "wrong token(for:) error \(error)")
    }
    do {
        _ = try await ExternalPurchaseCustomLink.showNotice(type: .browser)
        expectWave13(false, "showNotice must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no notice sheet on Linux.
    } catch {
        expectWave13(false, "wrong showNotice error \(error)")
    }
}

func testWave13PaymentMethodBindingAsync() async {
    do {
        _ = try await PaymentMethodBinding(id: "pin-1")
        expectWave13(false, "PaymentMethodBinding.init(id:) must throw")
    } catch PaymentMethodBinding.PaymentMethodBindingError.notEligible {
        // Expected: binding is fail-closed on Linux.
    } catch {
        expectWave13(false, "wrong PaymentMethodBinding.init error \(error)")
    }
    let binding = PaymentMethodBinding(portableID: "pin-1")
    expectWave13(binding.id == "pin-1", "portable binding id")
    do {
        try await binding.bind()
        expectWave13(false, "PaymentMethodBinding.bind must throw")
    } catch PaymentMethodBinding.PaymentMethodBindingError.failed {
        // Expected: binding is fail-closed on Linux.
    } catch {
        expectWave13(false, "wrong PaymentMethodBinding.bind error \(error)")
    }
}

func testWave13AdvancedCommerceProductAsync() async {
    StoreKitTesting.reset()
    do {
        _ = try await AdvancedCommerceProduct(id: "coins")
        expectWave13(false, "AdvancedCommerceProduct.init(id:) must throw without a store")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: no configuration loaded.
    } catch {
        expectWave13(false, "wrong AdvancedCommerceProduct.init error \(error)")
    }
    try! StoreKitTesting.loadConfiguration(json: wave13StoreJSON)
    let made = try! await AdvancedCommerceProduct(id: "coins")
    expectWave13(made.id == "coins", "async init resolves after load")
    let portable = AdvancedCommerceProduct(portableID: "coins")
    do {
        _ = try await portable.purchase(compactJWS: "aaa.bbb.ccc", confirmIn: UIViewController())
        expectWave13(false, "AdvancedCommerceProduct.purchase must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Expected: compact-JWS purchase is fail-closed on Linux.
    } catch {
        expectWave13(false, "wrong AdvancedCommerceProduct.purchase error \(error)")
    }
}

func testWave13AdvancedCommerceLatestTransactionAsync() async {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: wave13StoreJSON)
    let missing = await Transaction.latest(for: "no-such-product")
    expectWave13(missing == nil, "latest(for:) is nil without transactions")
    let product = try! StoreKitTesting.products(for: ["coins"])[0]
    let bought = try! StoreKitTesting.purchase(product)
    guard case .success(_) = bought else {
        expectWave13(false, "coins purchase")
        return
    }
    let commerce = try! AdvancedCommerceProduct.make(id: "coins")
    let latest = await commerce.latestTransaction
    expectWave13(latest != nil, "latestTransaction is non-nil after purchase")
    expectWave13(latest?.unsafePayloadValue.productID == "coins", "latestTransaction product")
}

func testWave13PurchaseIntentIntentsNextAsync() async {
    StoreKitTesting.reset()
    var iterator = PurchaseIntent.intents.makeAsyncIterator()
    let empty = await iterator.next()
    expectWave13(empty == nil, "Intents iterator is nil when empty")
    try! StoreKitTesting.loadConfiguration(json: wave13StoreJSON)
    try! StoreKitTesting.enqueuePurchaseIntent(productID: "coins")
    var pending = PurchaseIntent.intents.makeAsyncIterator()
    let first = await pending.next()
    expectWave13(first?.id == "coins", "Intents iterator yields enqueued intent")
    let done = await pending.next()
    expectWave13(done == nil, "Intents iterator terminates")
}

func testWave13MessageMessagesNextAsync() async {
    StoreKitTesting.reset()
    var iterator = Message.messages.makeAsyncIterator()
    let empty = await iterator.next()
    expectWave13(empty == nil, "Messages iterator is nil when empty")
    StoreKitTesting.enqueueMessage(reason: .billingIssue)
    var pending = Message.messages.makeAsyncIterator()
    let first = await pending.next()
    expectWave13(first?.reason == .billingIssue, "Messages iterator yields enqueued message")
    let done = await pending.next()
    expectWave13(done == nil, "Messages iterator terminates")
}

func testWave13AsyncIteratorNextSnapshotAsync() async {
    var storefronts = wave13Storefronts().makeAsyncIterator()
    let noStorefront = await storefronts.next()
    expectWave13(noStorefront == nil, "Storefronts iterator is nil when empty")
    var transactions = wave13Transactions().makeAsyncIterator()
    let noTransaction = await transactions.next()
    expectWave13(noTransaction == nil, "Transactions snapshot iterator is nil when empty")
    var statuses = wave13Statuses().makeAsyncIterator()
    let noStatus = await statuses.next()
    expectWave13(noStatus == nil, "Statuses iterator is nil when empty")
}

func testWave13AsyncIteratorIsolationAsync() async {
    StoreKitTesting.reset()
    var storefronts = wave13Storefronts().makeAsyncIterator()
    let noStorefront = await storefronts.next(isolation: nil)
    expectWave13(noStorefront == nil, "Storefronts isolation-next is nil when empty")
    var transactions = wave13Transactions().makeAsyncIterator()
    let noTransaction = await transactions.next(isolation: nil)
    expectWave13(noTransaction == nil, "Transactions isolation-next is nil when empty")
    var intents = PurchaseIntent.intents.makeAsyncIterator()
    let noIntent = await intents.next(isolation: nil)
    expectWave13(noIntent == nil, "Intents isolation-next is nil when empty")
    var messages = Message.messages.makeAsyncIterator()
    let noMessage = await messages.next(isolation: nil)
    expectWave13(noMessage == nil, "Messages isolation-next is nil when empty")
    var statuses = wave13Statuses().makeAsyncIterator()
    let noStatus = await statuses.next(isolation: nil)
    expectWave13(noStatus == nil, "Statuses isolation-next is nil when empty")
}

func testWave13AsyncSequenceFirstWhereAsync() async {
    StoreKitTesting.reset()
    let storefront = await wave13Storefronts().first { _ in true }
    expectWave13(storefront == nil, "Storefronts.first is nil when empty")
    let transaction = await wave13Transactions().first { _ in true }
    expectWave13(transaction == nil, "Transactions.first is nil when empty")
    let intent = await PurchaseIntent.intents.first { _ in true }
    expectWave13(intent == nil, "Intents.first is nil when empty")
    let message = await Message.messages.first { _ in true }
    expectWave13(message == nil, "Messages.first is nil when empty")
    let status = await wave13Statuses().first { _ in true }
    expectWave13(status == nil, "Statuses.first is nil when empty")
}

func testWave13AsyncSequenceContainsWhereAsync() async {
    StoreKitTesting.reset()
    let storefront = await wave13Storefronts().contains { _ in true }
    expectWave13(storefront == false, "Storefronts.contains is false when empty")
    let transaction = await wave13Transactions().contains { _ in true }
    expectWave13(transaction == false, "Transactions.contains is false when empty")
    let intent = await PurchaseIntent.intents.contains { _ in true }
    expectWave13(intent == false, "Intents.contains is false when empty")
    let message = await Message.messages.contains { _ in true }
    expectWave13(message == false, "Messages.contains is false when empty")
    let status = await wave13Statuses().contains { _ in true }
    expectWave13(status == false, "Statuses.contains is false when empty")
}

func testWave13AsyncSequenceContainsElementAsync() async {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: wave13StoreJSON)
    let probe = PurchaseIntent(product: Product(id: "probe"), offer: nil)
    let noIntent = await PurchaseIntent.intents.contains(probe)
    expectWave13(noIntent == false, "Intents.contains(probe) is false when empty")
    let sample = Message(reason: .generic)
    let noMessage = await Message.messages.contains(sample)
    expectWave13(noMessage == false, "Messages.contains(sample) is false when empty")
    let coins = try! StoreKitTesting.products(for: ["coins"])[0]
    let coinsBought = try! StoreKitTesting.purchase(coins)
    guard case .success(_) = coinsBought else {
        expectWave13(false, "coins purchase")
        return
    }
    let all = StoreKitTesting.allTransactions()
    expectWave13(all.isEmpty == false, "allTransactions is non-empty after purchase")
    let found = await Transaction.Transactions(snapshot: all).contains(all[0])
    expectWave13(found == true, "Transactions.contains finds the recorded element")
    let sub = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    let subBought = try! StoreKitTesting.purchase(sub)
    guard case .success(_) = subBought else {
        expectWave13(false, "subscription purchase")
        return
    }
    let statuses = StoreKitTesting.subscriptionStatuses()
    expectWave13(statuses.isEmpty == false, "subscriptionStatuses is non-empty after purchase")
    let statusFound = await Product.SubscriptionInfo.Status.Statuses(snapshot: statuses).contains(statuses[0])
    expectWave13(statusFound == true, "Statuses.contains finds the recorded element")
}

func testWave13AsyncSequenceMinMaxAsync() async {
    StoreKitTesting.reset()
    let maxStorefront = await wave13Storefronts().max { _, _ in true }
    expectWave13(maxStorefront == nil, "Storefronts.max is nil when empty")
    let minStorefront = await wave13Storefronts().min { _, _ in true }
    expectWave13(minStorefront == nil, "Storefronts.min is nil when empty")
    let maxTransaction = await wave13Transactions().max { _, _ in true }
    expectWave13(maxTransaction == nil, "Transactions.max is nil when empty")
    let minTransaction = await wave13Transactions().min { _, _ in true }
    expectWave13(minTransaction == nil, "Transactions.min is nil when empty")
    let maxIntent = await PurchaseIntent.intents.max { _, _ in true }
    expectWave13(maxIntent == nil, "Intents.max is nil when empty")
    let minIntent = await PurchaseIntent.intents.min { _, _ in true }
    expectWave13(minIntent == nil, "Intents.min is nil when empty")
    let maxMessage = await Message.messages.max { _, _ in true }
    expectWave13(maxMessage == nil, "Messages.max is nil when empty")
    let minMessage = await Message.messages.min { _, _ in true }
    expectWave13(minMessage == nil, "Messages.min is nil when empty")
    let maxStatus = await wave13Statuses().max { _, _ in true }
    expectWave13(maxStatus == nil, "Statuses.max is nil when empty")
    let minStatus = await wave13Statuses().min { _, _ in true }
    expectWave13(minStatus == nil, "Statuses.min is nil when empty")
}

func testWave13AsyncSequenceAllSatisfyAsync() async {
    StoreKitTesting.reset()
    let storefronts = await wave13Storefronts().allSatisfy { _ in true }
    expectWave13(storefronts == true, "empty Storefronts allSatisfy is true")
    let transactions = await wave13Transactions().allSatisfy { _ in true }
    expectWave13(transactions == true, "empty Transactions allSatisfy is true")
    let intents = await PurchaseIntent.intents.allSatisfy { _ in true }
    expectWave13(intents == true, "empty Intents allSatisfy is true")
    let messages = await Message.messages.allSatisfy { _ in true }
    expectWave13(messages == true, "empty Messages allSatisfy is true")
    let statuses = await wave13Statuses().allSatisfy { _ in true }
    expectWave13(statuses == true, "empty Statuses allSatisfy is true")
}

func testWave13AsyncSequenceMapAsync() async {
    StoreKitTesting.reset()
    var count = 0
    for await _ in wave13Storefronts().map({ $0 }) { count += 1 }
    expectWave13(count == 0, "mapped Storefronts is empty")
    for await _ in wave13Transactions().map({ $0 }) { count += 1 }
    expectWave13(count == 0, "mapped Transactions is empty")
    for await _ in PurchaseIntent.intents.map({ $0 }) { count += 1 }
    expectWave13(count == 0, "mapped Intents is empty")
    for await _ in Message.messages.map({ $0 }) { count += 1 }
    expectWave13(count == 0, "mapped Messages is empty")
    for await _ in wave13Statuses().map({ $0 }) { count += 1 }
    expectWave13(count == 0, "mapped Statuses is empty")
    let throwingStorefronts = wave13Storefronts().map({ (element: Storefront) throws -> Storefront in element })
    let throwingTransactions = wave13Transactions().map({ (element: VerificationResult<Transaction>) throws -> VerificationResult<Transaction> in element })
    let throwingIntents = PurchaseIntent.intents.map({ (element: PurchaseIntent) throws -> PurchaseIntent in element })
    let throwingMessages = Message.messages.map({ (element: Message) throws -> Message in element })
    let throwingStatuses = wave13Statuses().map({ (element: Product.SubscriptionInfo.Status) throws -> Product.SubscriptionInfo.Status in element })
    do {
        for try await _ in throwingStorefronts { count += 1 }
        for try await _ in throwingTransactions { count += 1 }
        for try await _ in throwingIntents { count += 1 }
        for try await _ in throwingMessages { count += 1 }
        for try await _ in throwingStatuses { count += 1 }
        expectWave13(count == 0, "throwing-mapped sequences are empty")
    } catch {
        expectWave13(false, "throwing map iteration threw \(error)")
    }
}

func testWave13AsyncSequenceCompactMapAsync() async {
    StoreKitTesting.reset()
    var count = 0
    for await _ in wave13Storefronts().compactMap({ $0 as Storefront? }) { count += 1 }
    expectWave13(count == 0, "compactMapped Storefronts is empty")
    for await _ in wave13Transactions().compactMap({ $0 as VerificationResult<Transaction>? }) { count += 1 }
    expectWave13(count == 0, "compactMapped Transactions is empty")
    for await _ in PurchaseIntent.intents.compactMap({ $0 as PurchaseIntent? }) { count += 1 }
    expectWave13(count == 0, "compactMapped Intents is empty")
    for await _ in Message.messages.compactMap({ $0 as Message? }) { count += 1 }
    expectWave13(count == 0, "compactMapped Messages is empty")
    for await _ in wave13Statuses().compactMap({ $0 as Product.SubscriptionInfo.Status? }) { count += 1 }
    expectWave13(count == 0, "compactMapped Statuses is empty")
    let throwingStorefronts = wave13Storefronts().compactMap({ (element: Storefront) throws -> Storefront? in element })
    let throwingTransactions = wave13Transactions().compactMap({ (element: VerificationResult<Transaction>) throws -> VerificationResult<Transaction>? in element })
    let throwingIntents = PurchaseIntent.intents.compactMap({ (element: PurchaseIntent) throws -> PurchaseIntent? in element })
    let throwingMessages = Message.messages.compactMap({ (element: Message) throws -> Message? in element })
    let throwingStatuses = wave13Statuses().compactMap({ (element: Product.SubscriptionInfo.Status) throws -> Product.SubscriptionInfo.Status? in element })
    do {
        for try await _ in throwingStorefronts { count += 1 }
        for try await _ in throwingTransactions { count += 1 }
        for try await _ in throwingIntents { count += 1 }
        for try await _ in throwingMessages { count += 1 }
        for try await _ in throwingStatuses { count += 1 }
        expectWave13(count == 0, "throwing-compactMapped sequences are empty")
    } catch {
        expectWave13(false, "throwing compactMap iteration threw \(error)")
    }
}

func testWave13AsyncSequenceFilterAsync() async {
    StoreKitTesting.reset()
    var count = 0
    for await _ in wave13Storefronts().filter({ _ in true }) { count += 1 }
    expectWave13(count == 0, "filtered Storefronts is empty")
    for await _ in wave13Transactions().filter({ _ in true }) { count += 1 }
    expectWave13(count == 0, "filtered Transactions is empty")
    for await _ in PurchaseIntent.intents.filter({ _ in true }) { count += 1 }
    expectWave13(count == 0, "filtered Intents is empty")
    for await _ in Message.messages.filter({ _ in true }) { count += 1 }
    expectWave13(count == 0, "filtered Messages is empty")
    for await _ in wave13Statuses().filter({ _ in true }) { count += 1 }
    expectWave13(count == 0, "filtered Statuses is empty")
}

func testWave13AsyncSequenceWhileAsync() async {
    StoreKitTesting.reset()
    var count = 0
    for await _ in wave13Storefronts().drop(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "drop-while Storefronts is empty")
    for await _ in wave13Storefronts().prefix(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "prefix-while Storefronts is empty")
    for await _ in wave13Transactions().drop(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "drop-while Transactions is empty")
    for await _ in wave13Transactions().prefix(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "prefix-while Transactions is empty")
    for await _ in PurchaseIntent.intents.drop(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "drop-while Intents is empty")
    for await _ in PurchaseIntent.intents.prefix(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "prefix-while Intents is empty")
    for await _ in Message.messages.drop(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "drop-while Messages is empty")
    for await _ in Message.messages.prefix(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "prefix-while Messages is empty")
    for await _ in wave13Statuses().drop(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "drop-while Statuses is empty")
    for await _ in wave13Statuses().prefix(while: { _ in true }) { count += 1 }
    expectWave13(count == 0, "prefix-while Statuses is empty")
}

func testWave13AsyncSequencePrefixDropFirstAsync() async {
    StoreKitTesting.reset()
    var count = 0
    for await _ in wave13Storefronts().prefix(2) { count += 1 }
    expectWave13(count == 0, "prefixed Storefronts is empty")
    for await _ in wave13Storefronts().dropFirst(2) { count += 1 }
    expectWave13(count == 0, "dropFirst Storefronts is empty")
    for await _ in wave13Transactions().prefix(2) { count += 1 }
    expectWave13(count == 0, "prefixed Transactions is empty")
    for await _ in wave13Transactions().dropFirst(2) { count += 1 }
    expectWave13(count == 0, "dropFirst Transactions is empty")
    for await _ in PurchaseIntent.intents.prefix(2) { count += 1 }
    expectWave13(count == 0, "prefixed Intents is empty")
    for await _ in PurchaseIntent.intents.dropFirst(2) { count += 1 }
    expectWave13(count == 0, "dropFirst Intents is empty")
    for await _ in Message.messages.prefix(2) { count += 1 }
    expectWave13(count == 0, "prefixed Messages is empty")
    for await _ in Message.messages.dropFirst(2) { count += 1 }
    expectWave13(count == 0, "dropFirst Messages is empty")
    for await _ in wave13Statuses().prefix(2) { count += 1 }
    expectWave13(count == 0, "prefixed Statuses is empty")
    for await _ in wave13Statuses().dropFirst(2) { count += 1 }
    expectWave13(count == 0, "dropFirst Statuses is empty")
}

func testWave13AsyncSequenceReduceAsync() async {
    StoreKitTesting.reset()
    let storefronts = await wave13Storefronts().reduce(0) { count, _ in count + 1 }
    expectWave13(storefronts == 0, "empty Storefronts reduce is zero")
    let storefrontsInto = await wave13Storefronts().reduce(into: 0) { count, _ in count += 1 }
    expectWave13(storefrontsInto == 0, "empty Storefronts reduce(into:) is zero")
    let transactions = await wave13Transactions().reduce(0) { count, _ in count + 1 }
    expectWave13(transactions == 0, "empty Transactions reduce is zero")
    let transactionsInto = await wave13Transactions().reduce(into: 0) { count, _ in count += 1 }
    expectWave13(transactionsInto == 0, "empty Transactions reduce(into:) is zero")
    let intents = await PurchaseIntent.intents.reduce(0) { count, _ in count + 1 }
    expectWave13(intents == 0, "empty Intents reduce is zero")
    let intentsInto = await PurchaseIntent.intents.reduce(into: 0) { count, _ in count += 1 }
    expectWave13(intentsInto == 0, "empty Intents reduce(into:) is zero")
    let messages = await Message.messages.reduce(0) { count, _ in count + 1 }
    expectWave13(messages == 0, "empty Messages reduce is zero")
    let messagesInto = await Message.messages.reduce(into: 0) { count, _ in count += 1 }
    expectWave13(messagesInto == 0, "empty Messages reduce(into:) is zero")
    let statuses = await wave13Statuses().reduce(0) { count, _ in count + 1 }
    expectWave13(statuses == 0, "empty Statuses reduce is zero")
    let statusesInto = await wave13Statuses().reduce(into: 0) { count, _ in count += 1 }
    expectWave13(statusesInto == 0, "empty Statuses reduce(into:) is zero")
}

func testWave13AsyncSequenceFlatMapAsync() async {
    StoreKitTesting.reset()
    var count = 0
    for await _ in wave13Storefronts().flatMap({ _ in wave13Storefronts() }) { count += 1 }
    expectWave13(count == 0, "flatMapped Storefronts is empty")
    for await _ in wave13Transactions().flatMap({ _ in wave13Transactions() }) { count += 1 }
    expectWave13(count == 0, "flatMapped Transactions is empty")
    for await _ in PurchaseIntent.intents.flatMap({ _ in PurchaseIntent.intents }) { count += 1 }
    expectWave13(count == 0, "flatMapped Intents is empty")
    for await _ in Message.messages.flatMap({ _ in Message.messages }) { count += 1 }
    expectWave13(count == 0, "flatMapped Messages is empty")
    for await _ in wave13Statuses().flatMap({ _ in wave13Statuses() }) { count += 1 }
    expectWave13(count == 0, "flatMapped Statuses is empty")
    let throwingStorefronts = wave13Storefronts().flatMap({ _ throws in wave13Storefronts() })
    let throwingTransactions = wave13Transactions().flatMap({ _ throws in wave13Transactions() })
    let throwingIntents = PurchaseIntent.intents.flatMap({ _ throws in PurchaseIntent.intents })
    let throwingMessages = Message.messages.flatMap({ _ throws in Message.messages })
    let throwingStatuses = wave13Statuses().flatMap({ _ throws in wave13Statuses() })
    do {
        for try await _ in throwingStorefronts { count += 1 }
        for try await _ in throwingTransactions { count += 1 }
        for try await _ in throwingIntents { count += 1 }
        for try await _ in throwingMessages { count += 1 }
        for try await _ in throwingStatuses { count += 1 }
        expectWave13(count == 0, "throwing-flatMapped sequences are empty")
    } catch {
        expectWave13(false, "throwing flatMap iteration threw \(error)")
    }
}
