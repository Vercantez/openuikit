import Foundation
@_spi(OpenIntentsHost) import Intents

private func wave9ArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
            preconditionFailure("expected restored \(T.self)")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

private func wave9Person(_ name: String = "Ada") -> INPerson {
    INPerson(
        personHandle: INPersonHandle(value: "ada@example.com", type: .emailAddress),
        nameComponents: nil,
        displayName: name,
        image: nil,
        contactIdentifier: "c-ada",
        customIdentifier: "custom-ada"
    )
}

private func wave9Account(_ nick: String) -> INPaymentAccount {
    INPaymentAccount(
        nickname: INSpeakableString(spokenPhrase: nick),
        number: "42",
        accountType: .checking,
        organizationName: INSpeakableString(spokenPhrase: "OpenBank"),
        balance: nil,
        secondaryBalance: nil
    )
}

private final class Wave9AddTasksHandler: NSObject, INAddTasksIntentHandling {
    func handle(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void) {
        let response = INAddTasksIntentResponse(code: .success, userActivity: nil)
        response.addedTasks = []
        completion(response)
    }
}

private final class Wave9PayBillHandler: NSObject, INPayBillIntentHandling {
    func handle(intent: INPayBillIntent, completion: @escaping (INPayBillIntentResponse) -> Void) {
        completion(INPayBillIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave9TransferHandler: NSObject, INTransferMoneyIntentHandling {
    func handle(intent: INTransferMoneyIntent, completion: @escaping (INTransferMoneyIntentResponse) -> Void) {
        completion(INTransferMoneyIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave9NotebookHandler: NSObject, INSearchForNotebookItemsIntentHandling {
    func handle(intent: INSearchForNotebookItemsIntent, completion: @escaping (INSearchForNotebookItemsIntentResponse) -> Void) {
        let response = INSearchForNotebookItemsIntentResponse(code: .success, userActivity: nil)
        response.notes = []
        response.tasks = []
        response.taskLists = []
        completion(response)
    }
}

private final class Wave9SetTaskHandler: NSObject, INSetTaskAttributeIntentHandling {
    func handle(intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeIntentResponse) -> Void) {
        completion(INSetTaskAttributeIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave9CallHistoryHandler: NSObject, INSearchCallHistoryIntentHandling {
    func handle(intent: INSearchCallHistoryIntent, completion: @escaping (INSearchCallHistoryIntentResponse) -> Void) {
        let response = INSearchCallHistoryIntentResponse(code: .success, userActivity: nil)
        response.callRecords = []
        completion(response)
    }
}

private final class Wave9BookRestaurantHandler: NSObject, INBookRestaurantReservationIntentHandling {
    func handle(
        bookRestaurantReservation intent: INBookRestaurantReservationIntent,
        completion: @escaping (INBookRestaurantReservationIntentResponse) -> Void
    ) {
        completion(INBookRestaurantReservationIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave9PhotosHandler: NSObject, INSearchForPhotosIntentHandling {
    func handle(intent: INSearchForPhotosIntent, completion: @escaping (INSearchForPhotosIntentResponse) -> Void) {
        completion(INSearchForPhotosIntentResponse(code: .continueInApp, userActivity: nil))
    }
}

private final class Wave9PlaybackHandler: NSObject, INStartPhotoPlaybackIntentHandling {
    func handle(intent: INStartPhotoPlaybackIntent, completion: @escaping (INStartPhotoPlaybackIntentResponse) -> Void) {
        completion(INStartPhotoPlaybackIntentResponse(code: .continueInApp, userActivity: nil))
    }
}

private final class Wave9ClimateHandler: NSObject, INSetClimateSettingsInCarIntentHandling {
    func handle(intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSetClimateSettingsInCarIntentResponse) -> Void) {
        completion(INSetClimateSettingsInCarIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave9AccountsHandler: NSObject, INSearchForAccountsIntentHandling {
    func handle(intent: INSearchForAccountsIntent, completion: @escaping (INSearchForAccountsIntentResponse) -> Void) {
        let response = INSearchForAccountsIntentResponse(code: .success, userActivity: nil)
        response.accounts = []
        completion(response)
    }
}

private final class Wave9BillsHandler: NSObject, INSearchForBillsIntentHandling {
    func handle(intent: INSearchForBillsIntent, completion: @escaping (INSearchForBillsIntentResponse) -> Void) {
        let response = INSearchForBillsIntentResponse(code: .success, userActivity: nil)
        response.bills = []
        completion(response)
    }
}

func testAddTasksIntentPropertiesAndResponse() {
    let title = INSpeakableString(spokenPhrase: "Buy milk")
    let list = INTaskList(
        title: INSpeakableString(spokenPhrase: "Groceries"),
        tasks: [],
        groupName: INSpeakableString(spokenPhrase: "Home"),
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "list-1"
    )
    let spatial = INSpatialEventTrigger()
    let temporal = INTemporalEventTrigger()
    let intent = INAddTasksIntent(
        targetTaskList: list,
        taskTitles: [title],
        spatialEventTrigger: spatial,
        temporalEventTrigger: temporal,
        priority: .flagged
    )
    precondition(intent.targetTaskList?.identifier == "list-1")
    precondition(intent.taskTitles?.first?.spokenPhrase == "Buy milk")
    precondition(intent.spatialEventTrigger === spatial)
    precondition(intent.temporalEventTrigger === temporal)
    precondition(intent.priority == .flagged)
    let shorter = INAddTasksIntent(
        targetTaskList: list,
        taskTitles: [title],
        spatialEventTrigger: nil,
        temporalEventTrigger: nil
    )
    precondition(shorter.targetTaskList?.title?.spokenPhrase == "Groceries")
    let activity = NSUserActivity(activityType: "com.openuikit.intents.addtasks")
    let response = INAddTasksIntentResponse(code: .success, userActivity: activity)
    let task = INTask(
        title: title,
        status: .notCompleted,
        taskType: .completable,
        spatialEventTrigger: nil,
        temporalEventTrigger: nil,
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "task-1"
    )
    response.addedTasks = [task]
    response.modifiedTaskList = list
    precondition(response.code == .success)
    precondition(response.addedTasks?.count == 1)
    precondition(response.modifiedTaskList?.identifier == "list-1")
    precondition(response.userActivity?.activityType == "com.openuikit.intents.addtasks")
}

func testPayBillIntentPropertiesAndResponse() {
    let payee = INBillPayee()
    payee.accountNumber = "payee-1"
    let from = wave9Account("Bills")
    let amount = INPaymentAmount(
        amountType: .amountDue,
        amount: INCurrencyAmount(amount: NSDecimalNumber(value: 12), currencyCode: "USD")
    )
    var due = DateComponents()
    due.year = 2026
    let dueRange = INDateComponentsRange(start: due, end: due)
    let intent = INPayBillIntent(
        billPayee: payee,
        fromAccount: from,
        transactionAmount: amount,
        transactionScheduledDate: dueRange,
        transactionNote: "rent",
        billType: .rent,
        dueDate: dueRange
    )
    precondition(intent.billPayee?.accountNumber == "payee-1")
    precondition(intent.fromAccount?.accountNumber == "42")
    precondition(intent.transactionAmount?.amountType == .amountDue)
    precondition(intent.transactionNote == "rent")
    precondition(intent.billType == .rent)
    precondition(intent.dueDate?.startDateComponents?.year == 2026)
    precondition(intent.transactionScheduledDate?.startDateComponents?.year == 2026)
    let labeled = INPayBillIntent(
        billPayee: payee,
        from: from,
        transactionAmount: amount,
        transactionScheduledDate: dueRange,
        transactionNote: "labeled",
        billType: .phone,
        dueDate: dueRange
    )
    precondition(labeled.transactionNote == "labeled")
    let response = INPayBillIntentResponse(code: .success, userActivity: nil)
    response.billDetails = INBillDetails(
        billType: .rent,
        paymentStatus: .pending,
        billPayee: payee,
        amountDue: INCurrencyAmount(amount: NSDecimalNumber(value: 12), currencyCode: "USD"),
        minimumDue: nil,
        lateFee: nil,
        dueDate: due,
        paymentDate: nil
    )
    response.fromAccount = from
    response.transactionAmount = amount
    response.transactionNote = "rent"
    response.transactionScheduledDate = dueRange
    precondition(response.code == .success)
    precondition(response.billDetails?.billType == .rent)
    precondition(response.fromAccount?.nickname?.spokenPhrase == "Bills")
    precondition(response.transactionAmount?.amount?.currencyCode == "USD")
    precondition(response.transactionNote == "rent")
    precondition(response.transactionScheduledDate?.startDateComponents?.year == 2026)
}

func testTransferMoneyIntentPropertiesAndResponse() {
    let from = wave9Account("From")
    let to = wave9Account("To")
    let amount = INPaymentAmount(
        amountType: .unknown,
        amount: INCurrencyAmount(amount: NSDecimalNumber(value: 5), currencyCode: "USD")
    )
    var day = DateComponents()
    day.year = 2026
    let range = INDateComponentsRange(start: day, end: day)
    let intent = INTransferMoneyIntent(
        fromAccount: from,
        toAccount: to,
        transactionAmount: amount,
        transactionScheduledDate: range,
        transactionNote: "gift"
    )
    precondition(intent.fromAccount?.accountNumber == "42")
    precondition(intent.toAccount?.nickname?.spokenPhrase == "To")
    precondition(intent.transactionAmount?.amountType == .unknown)
    precondition(intent.transactionNote == "gift")
    precondition(intent.transactionScheduledDate?.startDateComponents?.year == 2026)
    let labeled = INTransferMoneyIntent(
        from: from,
        to: to,
        transactionAmount: amount,
        transactionScheduledDate: range,
        transactionNote: "labeled"
    )
    precondition(labeled.transactionNote == "labeled")
    let response = INTransferMoneyIntentResponse(code: .success, userActivity: nil)
    response.fromAccount = from
    response.toAccount = to
    response.transactionAmount = amount
    response.transactionNote = "gift"
    response.transactionScheduledDate = range
    response.transferFee = INCurrencyAmount(amount: NSDecimalNumber(value: 1), currencyCode: "USD")
    precondition(response.code == .success)
    precondition(response.fromAccount?.nickname?.spokenPhrase == "From")
    precondition(response.toAccount?.nickname?.spokenPhrase == "To")
    precondition(response.transactionAmount?.amount?.currencyCode == "USD")
    precondition(response.transactionNote == "gift")
    precondition(response.transactionScheduledDate?.startDateComponents?.year == 2026)
    precondition(response.transferFee?.currencyCode == "USD")
}

func testSearchForNotebookItemsIntentAndResponse() {
    var start = DateComponents()
    start.year = 2026
    let range = INDateComponentsRange(start: start, end: start)
    let intent = INSearchForNotebookItemsIntent()
    intent.title = INSpeakableString(spokenPhrase: "milk")
    intent.content = "shopping"
    intent.itemType = .task
    intent.status = .notCompleted
    intent.dateTime = range
    intent.dateSearchType = .byDueDate
    intent.locationSearchType = .byLocationTrigger
    intent.notebookItemIdentifier = "nb-1"
    intent.taskPriority = .flagged
    intent.temporalEventTriggerTypes = []
    precondition(intent.title?.spokenPhrase == "milk")
    precondition(intent.content == "shopping")
    precondition(intent.itemType == .task)
    precondition(intent.status == .notCompleted)
    precondition(intent.dateTime?.startDateComponents?.year == 2026)
    precondition(intent.dateSearchType == .byDueDate)
    precondition(intent.locationSearchType == .byLocationTrigger)
    precondition(intent.notebookItemIdentifier == "nb-1")
    precondition(intent.taskPriority == .flagged)
    let response = INSearchForNotebookItemsIntentResponse(code: .success, userActivity: nil)
    response.notes = []
    response.tasks = []
    response.taskLists = []
    response.sortType = nil
    precondition(response.code == .success)
    precondition(response.notes?.isEmpty == true)
    precondition(response.tasks?.isEmpty == true)
    precondition(response.taskLists?.isEmpty == true)
}

func testSetTaskAttributeIntentAndResponse() {
    let task = INTask(
        title: INSpeakableString(spokenPhrase: "Call"),
        status: .notCompleted,
        taskType: .completable,
        spatialEventTrigger: nil,
        temporalEventTrigger: nil,
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "t-1",
        priority: .notFlagged
    )
    let intent = INSetTaskAttributeIntent(
        targetTask: task,
        taskTitle: INSpeakableString(spokenPhrase: "Call Ada"),
        status: .completed,
        priority: .flagged,
        spatialEventTrigger: INSpatialEventTrigger(),
        temporalEventTrigger: INTemporalEventTrigger()
    )
    precondition(intent.targetTask?.identifier == "t-1")
    precondition(intent.taskTitle?.spokenPhrase == "Call Ada")
    precondition(intent.status == .completed)
    precondition(intent.priority == .flagged)
    precondition(intent.spatialEventTrigger != nil)
    precondition(intent.temporalEventTrigger != nil)
    let shorter = INSetTaskAttributeIntent(
        targetTask: task,
        status: .notCompleted,
        spatialEventTrigger: nil,
        temporalEventTrigger: nil
    )
    precondition(shorter.targetTask?.title?.spokenPhrase == "Call")
    let response = INSetTaskAttributeIntentResponse(code: .success, userActivity: nil)
    response.modifiedTask = task
    precondition(response.code == .success)
    precondition(response.modifiedTask?.identifier == "t-1")
}

func testSearchCallHistoryIntentAndResponse() {
    var day = DateComponents()
    day.year = 2026
    let range = INDateComponentsRange(start: day, end: day)
    let person = wave9Person()
    let intent = INSearchCallHistoryIntent(
        call: .missed,
        dateCreated: range,
        recipient: person,
        callCapabilities: [.audioCall]
    )
    intent.callTypes = [.missed]
    precondition(intent.callType == .missed)
    precondition(intent.dateCreated?.startDateComponents?.year == 2026)
    precondition(intent.recipient?.displayName == "Ada")
    precondition(intent.callCapabilities.contains(.audioCall))
    precondition(intent.callTypes.contains(.missed))
    let response = INSearchCallHistoryIntentResponse(code: .success, userActivity: nil)
    response.callRecords = []
    precondition(response.code == .success)
    precondition(response.callRecords?.isEmpty == true)
}

func testBookRestaurantReservationIntentAndResponse() {
    let restaurant = INRestaurant()
    restaurant.name = "Cafe"
    restaurant.restaurantIdentifier = "cafe-1"
    let guest = INRestaurantGuest(
        nameComponents: nil,
        phoneNumber: "555-0100",
        emailAddress: "ada@example.com"
    )
    var booking = DateComponents()
    booking.year = 2026
    booking.month = 9
    booking.day = 6
    let offer = INRestaurantOffer()
    offer.offerTitleText = "Prix fixe"
    let intent = INBookRestaurantReservationIntent(
        restaurant: restaurant,
        bookingDateComponents: booking,
        partySize: 2,
        bookingIdentifier: "b-1",
        guest: guest,
        selectedOffer: offer,
        guestProvidedSpecialRequestText: "window"
    )
    precondition(intent.restaurant?.name == "Cafe")
    precondition(intent.bookingDateComponents?.year == 2026)
    precondition(intent.partySize == 2)
    precondition(intent.bookingIdentifier == "b-1")
    precondition(intent.guest?.phoneNumber == "555-0100")
    precondition(intent.selectedOffer?.offerTitleText == "Prix fixe")
    precondition(intent.guestProvidedSpecialRequestText == "window")
    let labeled = INBookRestaurantReservationIntent(
        restaurant: restaurant,
        booking: booking,
        partySize: 3,
        bookingIdentifier: "b-2",
        guest: guest,
        selectedOffer: nil,
        guestProvidedSpecialRequestText: nil
    )
    precondition(labeled.partySize == 3)
    let response = INBookRestaurantReservationIntentResponse(code: .success, userActivity: nil)
    let userBooking = INRestaurantReservationUserBooking(
        restaurant: restaurant,
        bookingDate: Date(timeIntervalSince1970: 0),
        partySize: 2,
        bookingIdentifier: "b-1",
        guest: guest,
        status: .pending,
        dateStatusModified: Date(timeIntervalSince1970: 1)
    )
    userBooking.advisementText = "arrive early"
    userBooking.guestProvidedSpecialRequestText = "window"
    userBooking.selectedOffer = offer
    response.userBooking = userBooking
    precondition(response.code == .success)
    precondition(response.userBooking?.guest?.emailAddress == "ada@example.com")
    precondition(response.userBooking?.status == .pending)
    precondition(response.userBooking?.dateStatusModified == Date(timeIntervalSince1970: 1))
}

func testSearchForPhotosIntentAndResponse() {
    var day = DateComponents()
    day.year = 2025
    let range = INDateComponentsRange(start: day, end: day)
    let people = [wave9Person()]
    let search = INSearchForPhotosIntent()
    search.albumName = "Trip"
    search.dateCreated = range
    search.searchTerms = ["sunset"]
    search.searchTermsOperator = .all
    search.includedAttributes = [.favorite]
    search.excludedAttributes = [.flash]
    search.peopleInPhoto = people
    search.peopleInPhotoOperator = .any
    precondition(search.albumName == "Trip")
    precondition(search.dateCreated?.startDateComponents?.year == 2025)
    precondition(search.searchTerms == ["sunset"])
    precondition(search.searchTermsOperator == .all)
    precondition(search.includedAttributes.contains(.favorite))
    precondition(search.excludedAttributes.contains(.flash))
    precondition(search.peopleInPhoto?.count == 1)
    precondition(search.peopleInPhotoOperator == .any)
    let searchResponse = INSearchForPhotosIntentResponse(code: .continueInApp, userActivity: nil)
    precondition(searchResponse.code == .continueInApp)
}

func testStartPhotoPlaybackIntentAndResponse() {
    var day = DateComponents()
    day.year = 2025
    let range = INDateComponentsRange(start: day, end: day)
    let playback = INStartPhotoPlaybackIntent()
    playback.albumName = "Trip"
    playback.dateCreated = range
    playback.searchTerms = ["sunset"]
    playback.searchTermsOperator = .all
    playback.includedAttributes = [.livePhoto]
    playback.excludedAttributes = [.hdrPhoto]
    playback.peopleInPhoto = [wave9Person()]
    playback.peopleInPhotoOperator = INConditionalOperator.none
    precondition(playback.albumName == "Trip")
    precondition(playback.dateCreated?.startDateComponents?.year == 2025)
    precondition(playback.searchTerms == ["sunset"])
    precondition(playback.searchTermsOperator == .all)
    precondition(playback.includedAttributes.contains(.livePhoto))
    precondition(playback.excludedAttributes.contains(.hdrPhoto))
    precondition(playback.peopleInPhoto?.count == 1)
    precondition(playback.peopleInPhotoOperator == INConditionalOperator.none)
    let playbackResponse = INStartPhotoPlaybackIntentResponse(code: .continueInApp, userActivity: nil)
    precondition(playbackResponse.code == .continueInApp)
}

func testSetClimateSettingsInCarIntentOverlay() {
    let carName = INSpeakableString(spokenPhrase: "Red")
    let temperature = Measurement(value: 21, unit: UnitTemperature.celsius)
    let intent = INSetClimateSettingsInCarIntent(
        enableFan: true,
        enableAirConditioner: true,
        enableClimateControl: true,
        enableAutoMode: false,
        airCirculationMode: .freshAir,
        fanSpeedIndex: 3,
        fanSpeedPercentage: 40,
        relativeFanSpeedSetting: .higher,
        temperature: temperature,
        relativeTemperatureSetting: .unknown,
        climateZone: .driver,
        carName: carName
    )
    precondition(intent.enableFan == true)
    precondition(intent.enableAirConditioner == true)
    precondition(intent.enableClimateControl == true)
    precondition(intent.enableAutoMode == false)
    precondition(intent.airCirculationMode == .freshAir)
    precondition(intent.fanSpeedIndex == 3)
    precondition(intent.fanSpeedPercentage == 40)
    precondition(intent.relativeFanSpeedSetting == .higher)
    precondition(intent.temperature?.value == 21)
    precondition(intent.relativeTemperatureSetting == .unknown)
    precondition(intent.climateZone == .driver)
    precondition(intent.carName?.spokenPhrase == "Red")
    let response = INSetClimateSettingsInCarIntentResponse(code: .success, userActivity: nil)
    precondition(response.code == .success)
}

func testSearchForAccountsIntentAndResponse() {
    let accounts = INSearchForAccountsIntent(
        accountNickname: INSpeakableString(spokenPhrase: "Checking"),
        accountType: .checking,
        organizationName: INSpeakableString(spokenPhrase: "OpenBank"),
        requestedBalanceType: .money
    )
    precondition(accounts.accountNickname?.spokenPhrase == "Checking")
    precondition(accounts.accountType == .checking)
    precondition(accounts.organizationName?.spokenPhrase == "OpenBank")
    precondition(accounts.requestedBalanceType == .money)
    let accountResponse = INSearchForAccountsIntentResponse(code: .success, userActivity: nil)
    accountResponse.accounts = [wave9Account("Checking")]
    precondition(accountResponse.code == .success)
    precondition(accountResponse.accounts?.count == 1)
}

func testSearchForBillsIntentAndResponse() {
    var day = DateComponents()
    day.year = 2026
    let range = INDateComponentsRange(start: day, end: day)
    let payee = INBillPayee()
    payee.accountNumber = "util-1"
    let bills = INSearchForBillsIntent(
        billPayee: payee,
        paymentDateRange: range,
        billType: .electricity,
        status: .unpaid,
        dueDateRange: range
    )
    precondition(bills.billPayee?.accountNumber == "util-1")
    precondition(bills.paymentDateRange?.startDateComponents?.year == 2026)
    precondition(bills.billType == .electricity)
    precondition(bills.status == .unpaid)
    precondition(bills.dueDateRange?.startDateComponents?.year == 2026)
    let billResponse = INSearchForBillsIntentResponse(code: .success, userActivity: nil)
    billResponse.bills = []
    precondition(billResponse.code == .success)
    precondition(billResponse.bills?.isEmpty == true)
}

func testTaskConstructionAndCoding() {
    var created = DateComponents()
    created.year = 2026
    var modified = DateComponents()
    modified.year = 2027
    let task = INTask(
        title: INSpeakableString(spokenPhrase: "Pack"),
        status: .notCompleted,
        taskType: .completable,
        spatialEventTrigger: INSpatialEventTrigger(),
        temporalEventTrigger: INTemporalEventTrigger(),
        createdDateComponents: created,
        modifiedDateComponents: modified,
        identifier: "task-pack",
        priority: .flagged
    )
    precondition(task.title?.spokenPhrase == "Pack")
    precondition(task.status == .notCompleted)
    precondition(task.taskType == .completable)
    precondition(task.spatialEventTrigger != nil)
    precondition(task.temporalEventTrigger != nil)
    precondition(task.createdDateComponents?.year == 2026)
    precondition(task.modifiedDateComponents?.year == 2027)
    precondition(task.identifier == "task-pack")
    precondition(task.priority == .flagged)
    precondition(wave9ArchiveRoundTrip(task).identifier == "task-pack")
    let shorter = INTask(
        title: INSpeakableString(spokenPhrase: "Short"),
        status: .completed,
        taskType: .notCompletable,
        spatialEventTrigger: nil,
        temporalEventTrigger: nil,
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "task-short"
    )
    precondition(shorter.identifier == "task-short")
}

func testTaskListConstructionAndCoding() {
    var created = DateComponents()
    created.year = 2026
    var modified = DateComponents()
    modified.year = 2027
    let task = INTask(
        title: INSpeakableString(spokenPhrase: "Pack"),
        status: .notCompleted,
        taskType: .completable,
        spatialEventTrigger: nil,
        temporalEventTrigger: nil,
        createdDateComponents: created,
        modifiedDateComponents: modified,
        identifier: "task-pack"
    )
    let list = INTaskList(
        title: INSpeakableString(spokenPhrase: "Trip"),
        tasks: [task],
        groupName: INSpeakableString(spokenPhrase: "Travel"),
        createdDateComponents: created,
        modifiedDateComponents: modified,
        identifier: "list-trip"
    )
    precondition(list.title?.spokenPhrase == "Trip")
    precondition(list.tasks.count == 1)
    precondition(list.groupName?.spokenPhrase == "Travel")
    precondition(list.createdDateComponents?.year == 2026)
    precondition(list.modifiedDateComponents?.year == 2027)
    precondition(list.identifier == "list-trip")
    precondition(wave9ArchiveRoundTrip(list).identifier == "list-trip")
}

func testPaymentAccountConstructionAndCoding() {
    let nick = INSpeakableString(spokenPhrase: "Savings")
    let org = INSpeakableString(spokenPhrase: "OpenBank")
    let failable = INPaymentAccount(nickname: nick, number: "99", accountType: .saving, organizationName: org)
    precondition(failable?.accountNumber == "99")
    precondition(failable?.nickname?.spokenPhrase == "Savings")
    precondition(failable?.accountType == .saving)
    precondition(failable?.organizationName?.spokenPhrase == "OpenBank")
    let full = INPaymentAccount(
        nickname: nick,
        number: "100",
        accountType: .checking,
        organizationName: org,
        balance: INBalanceAmount(),
        secondaryBalance: INBalanceAmount()
    )
    precondition(full.accountNumber == "100")
    precondition(full.balance != nil)
    precondition(full.secondaryBalance != nil)
    precondition(wave9ArchiveRoundTrip(full).accountNumber == "100")
}

func testBillDetailsProperties() {
    var due = DateComponents()
    due.year = 2026
    let details = INBillDetails(
        billType: .electricity,
        paymentStatus: .unpaid,
        billPayee: INBillPayee(),
        amountDue: INCurrencyAmount(amount: NSDecimalNumber(value: 30), currencyCode: "USD"),
        minimumDue: INCurrencyAmount(amount: NSDecimalNumber(value: 10), currencyCode: "USD"),
        lateFee: INCurrencyAmount(amount: NSDecimalNumber(value: 2), currencyCode: "USD"),
        dueDate: due,
        paymentDate: due
    )
    precondition(details?.billType == .electricity)
    precondition(details?.paymentStatus == .unpaid)
    precondition(details?.billPayee != nil)
    precondition(details?.amountDue?.currencyCode == "USD")
    precondition(details?.minimumDue?.currencyCode == "USD")
    precondition(details?.lateFee?.currencyCode == "USD")
    precondition(details?.dueDate?.year == 2026)
    precondition(details?.paymentDate?.year == 2026)
}

func testRideDriverInitsAndCoding() {
    let driver = INRideDriver(
        handle: "driver@example.com",
        displayName: "Lin",
        image: nil,
        rating: "4.9",
        phoneNumber: "555-0110"
    )
    precondition(driver.rating == "4.9")
    precondition(driver.phoneNumber == "555-0110")
    let named = INRideDriver(
        handle: "driver@example.com",
        nameComponents: PersonNameComponents(),
        image: nil,
        rating: "5.0",
        phoneNumber: "555-0111"
    )
    precondition(named.rating == "5.0")
    let handle = INPersonHandle(value: "driver@example.com", type: .emailAddress)
    let handled = INRideDriver(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Lin",
        image: nil,
        rating: "4.8",
        phoneNumber: "555-0112"
    )
    precondition(handled.phoneNumber == "555-0112")
    let phone = INRideDriver(
        phoneNumber: "555-0113",
        nameComponents: nil,
        displayName: "Lin",
        image: nil,
        rating: "4.7"
    )
    precondition(phone.phoneNumber == "555-0113")
    precondition(wave9ArchiveRoundTrip(driver).rating == "4.9")
}

func testRideOptionRemainingProperties() {
    let option = INRideOption(name: "Pool", estimatedPickupDate: Date(timeIntervalSince1970: 20))
    option.availablePartySizeOptions = []
    option.availablePartySizeOptionsSelectionPrompt = "How many?"
    option.disclaimerMessage = "shared"
    option.fareLineItems = []
    option.identifier = "opt-1"
    option.priceRange = INPriceRange()
    option.specialPricing = "off-peak"
    option.specialPricingBadgeImage = INImage(named: "badge")
    option.userActivityForBookingInApplication = NSUserActivity(activityType: "book")
    precondition(option.availablePartySizeOptions?.isEmpty == true)
    precondition(option.availablePartySizeOptionsSelectionPrompt == "How many?")
    precondition(option.disclaimerMessage == "shared")
    precondition(option.estimatedPickupDate == Date(timeIntervalSince1970: 20))
    precondition(option.fareLineItems?.isEmpty == true)
    precondition(option.identifier == "opt-1")
    precondition(option.priceRange != nil)
    precondition(option.specialPricing == "off-peak")
    precondition(option.specialPricingBadgeImage != nil)
    precondition(option.userActivityForBookingInApplication?.activityType == "book")
}

func testRideStatusRemainingProperties() {
    let driver = INRideDriver(
        handle: "driver@example.com",
        displayName: "Lin",
        image: nil,
        rating: "4.9",
        phoneNumber: "555-0110"
    )
    let option = INRideOption(name: "Pool", estimatedPickupDate: Date(timeIntervalSince1970: 20))
    let status = INRideStatus()
    status.driver = driver
    status.rideOption = option
    status.vehicle = INRideVehicle()
    status.completionStatus = INRideCompletionStatus.completed()
    status.estimatedPickupDate = Date(timeIntervalSince1970: 30)
    status.estimatedDropOffDate = Date(timeIntervalSince1970: 40)
    status.estimatedPickupEndDate = Date(timeIntervalSince1970: 35)
    status.scheduledPickupTime = INDateComponentsRange()
    status.userActivityForCancelingInApplication = NSUserActivity(activityType: "cancel")
    status.additionalActionActivities = []
    precondition(status.driver?.rating == "4.9")
    precondition(status.rideOption?.name == "Pool")
    precondition(status.vehicle != nil)
    precondition(status.completionStatus?.isCompleted == true)
    precondition(status.estimatedPickupDate == Date(timeIntervalSince1970: 30))
    precondition(status.estimatedDropOffDate == Date(timeIntervalSince1970: 40))
    precondition(status.estimatedPickupEndDate == Date(timeIntervalSince1970: 35))
    precondition(status.scheduledPickupTime != nil)
    precondition(status.userActivityForCancelingInApplication?.activityType == "cancel")
    precondition(status.additionalActionActivities?.isEmpty == true)
}

func testPersonConvenienceInits() {
    let handle = INPersonHandle(value: "ada@example.com", type: .emailAddress)
    precondition(handle.value == "ada@example.com")
    precondition(handle.type == .emailAddress)
    let image = INImage(named: "ada")
    let byHandle = INPerson(handle: "ada@example.com", displayName: "Ada", contactIdentifier: "c1")
    precondition(byHandle.displayName == "Ada")
    precondition(byHandle.contactIdentifier == "c1")
    precondition(byHandle.personHandle?.value == "ada@example.com")
    var components = PersonNameComponents()
    components.givenName = "Ada"
    let byName = INPerson(handle: "ada@example.com", nameComponents: components, contactIdentifier: "c2")
    precondition(byName.nameComponents?.givenName == "Ada")
    let byImage = INPerson(
        handle: "ada@example.com",
        nameComponents: components,
        displayName: "Ada Lovelace",
        image: image,
        contactIdentifier: "c3"
    )
    precondition(byImage.image != nil)
    precondition(byImage.displayName == "Ada Lovelace")
    let aliases = INPerson(
        personHandle: handle,
        nameComponents: components,
        displayName: "Ada",
        image: image,
        contactIdentifier: "c4",
        customIdentifier: "x4",
        aliases: [handle],
        suggestionType: .socialProfile
    )
    precondition(aliases.aliases?.count == 1)
    precondition(aliases.suggestionType == .socialProfile)
    precondition(aliases.customIdentifier == "x4")
    let contactSuggestion = INPerson(
        personHandle: handle,
        nameComponents: components,
        displayName: "Ada",
        image: image,
        contactIdentifier: "c5",
        customIdentifier: "x5",
        isContactSuggestion: true,
        suggestionType: .none
    )
    precondition(contactSuggestion.isContactSuggestion)
    let me = INPerson(
        personHandle: handle,
        nameComponents: components,
        displayName: "Me",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil,
        isMe: true
    )
    precondition(me.isMe)
    let meSuggested = INPerson(
        personHandle: handle,
        nameComponents: components,
        displayName: "Me",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil,
        isMe: true,
        suggestionType: .instantMessageAddress
    )
    precondition(meSuggested.suggestionType == .instantMessageAddress)
    let related = INPerson(
        personHandle: handle,
        nameComponents: components,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil,
        relationship: INPersonRelationship(rawValue: "friend")
    )
    precondition(related.relationship?.rawValue == "friend")
}

func testMessageAttachmentReactionAndLinkInits() {
    let person = wave9Person()
    let file = INFile(data: Data([0x01]), filename: "a.bin", typeIdentifier: "public.data")
    let short = INMessage(
        identifier: "m-short",
        content: "hi",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person]
    )
    precondition(short.identifier == "m-short")
    let typed = INMessage(
        identifier: "m-typed",
        conversationIdentifier: "c",
        content: "hi",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        messageType: .text
    )
    precondition(typed.messageType == .text)
    let attachments = INMessage(
        identifier: "m-att",
        conversationIdentifier: "c",
        content: "file",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        messageType: .text,
        serviceName: "iMessage",
        attachmentFiles: [file]
    )
    precondition(attachments.attachmentFiles?.count == 1)
    let audio = INMessage(
        identifier: "m-audio",
        conversationIdentifier: "c",
        content: nil,
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        messageType: .audio,
        serviceName: "iMessage",
        audioMessageFile: file
    )
    precondition(audio.audioMessageFile?.filename == "a.bin")
    let metadata = INMessageLinkMetadata(
        siteName: "Example",
        summary: "Sum",
        title: "Title",
        openGraphType: "article",
        linkURL: URL(fileURLWithPath: "/tmp/link")
    )
    precondition(metadata.linkURL?.path == "/tmp/link")
    let linked = INMessage(
        identifier: "m-link",
        conversationIdentifier: "c",
        content: "link",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        serviceName: "iMessage",
        linkMetadata: metadata
    )
    precondition(linked.linkMetadata?.title == "Title")
    let counted = INMessage(
        identifier: "m-count",
        conversationIdentifier: "c",
        content: "n",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        serviceName: "iMessage",
        messageType: .text,
        numberOfAttachments: NSNumber(value: 2)
    )
    precondition(counted.numberOfAttachments?.intValue == 2)
    let reaction = INMessageReaction(reactionType: .emoji, reactionDescription: "like", emoji: "👍")
    precondition(reaction.reactionType == .emoji)
    precondition(reaction.reactionDescription == "like")
    let reacted = INMessage(
        identifier: "m-react",
        conversationIdentifier: "c",
        content: "hi",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        serviceName: "iMessage",
        messageType: .text,
        referencedMessage: short,
        reaction: reaction
    )
    precondition(reacted.reaction?.emoji == "👍")
    let sticker = INSticker(type: .emoji, emoji: "⭐")
    let stickered = INMessage(
        identifier: "m-sticker",
        conversationIdentifier: "c",
        content: nil,
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: nil,
        serviceName: "iMessage",
        messageType: .sticker,
        referencedMessage: nil,
        sticker: sticker,
        reaction: nil
    )
    precondition(stickered.sticker?.emoji == "⭐")
    let byTypeOnly = INMessage(
        identifier: "m-type",
        conversationIdentifier: "c",
        content: "x",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        messageType: .text
    )
    precondition(byTypeOnly.conversationIdentifier == "c")
}

func testCarPowerRemainingMeasurements() {
    let response = INGetCarPowerLevelStatusIntentResponse(code: .success, userActivity: nil)
    response.activeConnector = .ccs1
    response.chargingFormulaArguments = ["rate": "slow"]
    response.consumptionFormulaArguments = ["mix": "city"]
    response.currentBatteryCapacity = Measurement(value: 40, unit: UnitEnergy.kilowattHours)
    var updated = DateComponents()
    updated.year = 2026
    response.dateOfLastStateUpdate = updated
    response.distanceRemaining = Measurement(value: 120, unit: UnitLength.kilometers)
    response.distanceRemainingElectric = Measurement(value: 80, unit: UnitLength.kilometers)
    response.distanceRemainingFuel = Measurement(value: 40, unit: UnitLength.kilometers)
    response.maximumBatteryCapacity = Measurement(value: 60, unit: UnitEnergy.kilowattHours)
    response.maximumDistance = Measurement(value: 300, unit: UnitLength.kilometers)
    response.maximumDistanceElectric = Measurement(value: 200, unit: UnitLength.kilometers)
    response.maximumDistanceFuel = Measurement(value: 100, unit: UnitLength.kilometers)
    response.minimumBatteryCapacity = Measurement(value: 5, unit: UnitEnergy.kilowattHours)
    precondition(response.activeConnector == .ccs1)
    precondition(response.chargingFormulaArguments?["rate"] as? String == "slow")
    precondition(response.consumptionFormulaArguments?["mix"] as? String == "city")
    precondition(response.currentBatteryCapacity?.value == 40)
    precondition(response.dateOfLastStateUpdate?.year == 2026)
    precondition(response.distanceRemaining?.value == 120)
    precondition(response.distanceRemainingElectric?.value == 80)
    precondition(response.distanceRemainingFuel?.value == 40)
    precondition(response.maximumBatteryCapacity?.value == 60)
    precondition(response.maximumDistance?.value == 300)
    precondition(response.maximumDistanceElectric?.value == 200)
    precondition(response.maximumDistanceFuel?.value == 100)
    precondition(response.minimumBatteryCapacity?.value == 5)
}

func testRestaurantGuestDisplayPreferences() {
    let guest = INRestaurantGuest(nameComponents: nil, phoneNumber: "555", emailAddress: "a@b.c")
    precondition(wave9ArchiveRoundTrip(guest).emailAddress == "a@b.c")
    precondition(guest.phoneNumber == "555")
    let prefs = INRestaurantGuestDisplayPreferences()
    prefs.emailAddressEditable = true
    prefs.emailAddressFieldShouldBeDisplayed = true
    prefs.nameEditable = true
    prefs.nameFieldFirstNameOptional = true
    prefs.nameFieldLastNameOptional = false
    prefs.nameFieldShouldBeDisplayed = true
    prefs.phoneNumberEditable = true
    prefs.phoneNumberFieldShouldBeDisplayed = true
    precondition(prefs.emailAddressEditable)
    precondition(prefs.emailAddressFieldShouldBeDisplayed)
    precondition(prefs.nameEditable)
    precondition(prefs.nameFieldFirstNameOptional)
    precondition(prefs.nameFieldLastNameOptional == false)
    precondition(prefs.nameFieldShouldBeDisplayed)
    precondition(prefs.phoneNumberEditable)
    precondition(prefs.phoneNumberFieldShouldBeDisplayed)
}

func testPaymentAccountResolutionResult() {
    let account = wave9Account("A")
    precondition(INPaymentAccountResolutionResult.success(with: account).outcome == .success)
    precondition(INPaymentAccountResolutionResult.disambiguation(with: [account]).outcome == .disambiguation)
    precondition(INPaymentAccountResolutionResult.confirmationRequired(with: account).outcome == .confirmationRequired)
}

func testBillPayeeResolutionResult() {
    let payee = INBillPayee()
    precondition(INBillPayeeResolutionResult.success(with: payee).outcome == .success)
    precondition(INBillPayeeResolutionResult.disambiguation(with: [payee]).outcome == .disambiguation)
    precondition(INBillPayeeResolutionResult.confirmationRequired(with: payee).outcome == .confirmationRequired)
}

func testTaskResolutionResult() {
    let task = INTask()
    precondition(INTaskResolutionResult.success(with: task).outcome == .success)
    precondition(INTaskResolutionResult.disambiguation(with: [task]).outcome == .disambiguation)
    precondition(INTaskResolutionResult.confirmationRequired(with: task).outcome == .confirmationRequired)
}

func testTaskListResolutionResult() {
    let list = INTaskList(
        title: INSpeakableString(spokenPhrase: "L"),
        tasks: [],
        groupName: nil,
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "l"
    )
    precondition(INTaskListResolutionResult.success(with: list).outcome == .success)
    precondition(INTaskListResolutionResult.disambiguation(with: [list]).outcome == .disambiguation)
    precondition(INTaskListResolutionResult.confirmationRequired(with: list).outcome == .confirmationRequired)
}

func testMessageAttributeResolutionResult() {
    precondition(INMessageAttributeResolutionResult.success(with: .unread).outcome == .success)
    precondition(INMessageAttributeResolutionResult.confirmationRequired(with: .flagged).outcome == .confirmationRequired)
    precondition(INMessageAttributeOptionsResolutionResult.success(with: [.unread]).outcome == .success)
    precondition(
        INMessageAttributeOptionsResolutionResult.confirmationRequired(with: [.flagged]).outcome == .confirmationRequired
    )
}

func testCurrencyAmountResolutionResult() {
    let currency = INCurrencyAmount(amount: NSDecimalNumber(value: 3), currencyCode: "USD")
    precondition(INCurrencyAmountResolutionResult.success(with: currency).outcome == .success)
    precondition(INCurrencyAmountResolutionResult.disambiguation(with: [currency]).outcome == .disambiguation)
    precondition(INCurrencyAmountResolutionResult.confirmationRequired(with: currency).outcome == .confirmationRequired)
}

func testNoteResolutionResult() {
    let note = INNote(
        title: INSpeakableString(spokenPhrase: "n"),
        contents: [],
        groupName: nil,
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "n"
    )
    precondition(INNoteResolutionResult.success(with: note).outcome == .success)
    precondition(INNoteResolutionResult.disambiguation(with: [note]).outcome == .disambiguation)
    precondition(INNoteResolutionResult.confirmationRequired(with: note).outcome == .confirmationRequired)
}

func testObjectResolutionResult() {
    let object = INObject(identifier: "id", display: "Ada")
    precondition(INObjectResolutionResult.success(with: object).outcome == .success)
    precondition(INObjectResolutionResult.disambiguation(with: [object]).outcome == .disambiguation)
    precondition(INObjectResolutionResult.confirmationRequired(with: object).outcome == .confirmationRequired)
}

func testRestaurantGuestResolutionResult() {
    let guest = INRestaurantGuest(nameComponents: nil, phoneNumber: "555", emailAddress: "a@b.c")
    precondition(INRestaurantGuestResolutionResult.success(with: guest).outcome == .success)
    precondition(INRestaurantGuestResolutionResult.disambiguation(with: [guest]).outcome == .disambiguation)
    precondition(INRestaurantGuestResolutionResult.confirmationRequired(with: guest).outcome == .confirmationRequired)
}

func testSpeakableStringResolutionResult() {
    let spoken = INSpeakableString(spokenPhrase: "Hello")
    precondition(INSpeakableStringResolutionResult.success(with: spoken).outcome == .success)
    precondition(INSpeakableStringResolutionResult.disambiguation(with: [spoken]).outcome == .disambiguation)
    precondition(INSpeakableStringResolutionResult.confirmationRequired(with: spoken).outcome == .confirmationRequired)
}

func testBooleanResolutionResultConfirmationRequired() {
    let booleanConfirm = INBooleanResolutionResult.confirmationRequired(with: Optional<Bool>.some(true))
    precondition(booleanConfirm.outcome == .confirmationRequired)
}

func testAddTasksHandlerDispatch() {
    let intent = INAddTasksIntent()
    let handler = Wave9AddTasksHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INAddTasksIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INAddTasksIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.contains { $0.outcome == .needsValue })

    var specializedList: INAddTasksTargetTaskListResolutionResult?
    handler.resolveTargetTaskList(for: intent, completion: { specializedList = $0 })
    precondition(specializedList?.outcome == .needsValue)
    var legacyList: INTaskListResolutionResult?
    handler.resolveTargetTaskList(for: intent, with: { legacyList = $0 })
    precondition(legacyList?.outcome == .needsValue)
    var titles: [INSpeakableStringResolutionResult]?
    handler.resolveTaskTitles(for: intent) { titles = $0 }
    precondition(titles != nil)
    var specializedTrigger: INAddTasksTemporalEventTriggerResolutionResult?
    handler.resolveTemporalEventTrigger(for: intent, completion: { specializedTrigger = $0 })
    precondition(specializedTrigger?.outcome == .needsValue)
    var legacyTrigger: INTemporalEventTriggerResolutionResult?
    handler.resolveTemporalEventTrigger(for: intent, with: { legacyTrigger = $0 })
    precondition(legacyTrigger?.outcome == .needsValue)
}

func testPayBillHandlerDispatch() {
    let intent = INPayBillIntent()
    let handler = Wave9PayBillHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INPayBillIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INPayBillIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 7)
}

func testTransferMoneyHandlerDispatch() {
    let intent = INTransferMoneyIntent()
    let handler = Wave9TransferHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INTransferMoneyIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INTransferMoneyIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 5)
}

func testNotebookHandlerDispatch() {
    let intent = INSearchForNotebookItemsIntent()
    let handler = Wave9NotebookHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INSearchForNotebookItemsIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INSearchForNotebookItemsIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 10)
}

func testSetTaskAttributeHandlerDispatch() {
    let intent = INSetTaskAttributeIntent()
    let handler = Wave9SetTaskHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INSetTaskAttributeIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INSetTaskAttributeIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 7)

    var specializedTrigger: INSetTaskAttributeTemporalEventTriggerResolutionResult?
    handler.resolveTemporalEventTrigger(for: intent, completion: { specializedTrigger = $0 })
    precondition(specializedTrigger?.outcome == .needsValue)
    var legacyTrigger: INTemporalEventTriggerResolutionResult?
    handler.resolveTemporalEventTrigger(for: intent, with: { legacyTrigger = $0 })
    precondition(legacyTrigger?.outcome == .needsValue)
}

func testSearchCallHistoryHandlerDispatch() {
    let intent = INSearchCallHistoryIntent()
    let handler = Wave9CallHistoryHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INSearchCallHistoryIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INSearchCallHistoryIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 5)
}

func testBookRestaurantHandlerDispatch() {
    let intent = INBookRestaurantReservationIntent()
    let handler = Wave9BookRestaurantHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INBookRestaurantReservationIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INBookRestaurantReservationIntentResponse
    precondition(confirmed?.code == .success)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 5)
}

func testSearchForPhotosHandlerDispatch() {
    let search = INSearchForPhotosIntent()
    let searchHandler = Wave9PhotosHandler()
    let searchHandled = INHostIntentDispatcher.handle(search, handler: searchHandler) as? INSearchForPhotosIntentResponse
    precondition(searchHandled?.code == .continueInApp)
    let searchConfirmed = INHostIntentDispatcher.confirm(search, handler: searchHandler) as? INSearchForPhotosIntentResponse
    precondition(searchConfirmed?.code == .ready)
    let searchResolved = INHostIntentDispatcher.resolve(search, handler: searchHandler)
    precondition(searchResolved.contains { $0.outcome == .needsValue })
}

func testStartPhotoPlaybackHandlerDispatch() {
    let playback = INStartPhotoPlaybackIntent()
    let playbackHandler = Wave9PlaybackHandler()
    let playbackHandled = INHostIntentDispatcher.handle(playback, handler: playbackHandler) as? INStartPhotoPlaybackIntentResponse
    precondition(playbackHandled?.code == .continueInApp)
    let playbackConfirmed = INHostIntentDispatcher.confirm(playback, handler: playbackHandler) as? INStartPhotoPlaybackIntentResponse
    precondition(playbackConfirmed?.code == .ready)
    let playbackResolved = INHostIntentDispatcher.resolve(playback, handler: playbackHandler)
    precondition(playbackResolved.count == 3)
}

func testClimateHandlerDispatch() {
    let intent = INSetClimateSettingsInCarIntent()
    let handler = Wave9ClimateHandler()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INSetClimateSettingsInCarIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INSetClimateSettingsInCarIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(resolved.count == 12)
}

func testSearchForAccountsHandlerDispatch() {
    let accounts = INSearchForAccountsIntent()
    let accountsHandler = Wave9AccountsHandler()
    let accountsHandled = INHostIntentDispatcher.handle(accounts, handler: accountsHandler) as? INSearchForAccountsIntentResponse
    precondition(accountsHandled?.code == .success)
    let accountsConfirmed = INHostIntentDispatcher.confirm(accounts, handler: accountsHandler) as? INSearchForAccountsIntentResponse
    precondition(accountsConfirmed?.code == .ready)
    let accountsResolved = INHostIntentDispatcher.resolve(accounts, handler: accountsHandler)
    precondition(accountsResolved.count == 4)
}

func testSearchForBillsHandlerDispatch() {
    let bills = INSearchForBillsIntent()
    let billsHandler = Wave9BillsHandler()
    let billsHandled = INHostIntentDispatcher.handle(bills, handler: billsHandler) as? INSearchForBillsIntentResponse
    precondition(billsHandled?.code == .success)
    let billsConfirmed = INHostIntentDispatcher.confirm(bills, handler: billsHandler) as? INSearchForBillsIntentResponse
    precondition(billsConfirmed?.code == .ready)
    let billsResolved = INHostIntentDispatcher.resolve(bills, handler: billsHandler)
    precondition(billsResolved.count == 5)
}
