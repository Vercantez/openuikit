// Host dispatcher, extension routing, and resolution reflection for the
// isolated Linux Intents starting point. Apple Siri speech, account sync,
// and extension-process launch remain fail-closed.

@_spi(OpenIntentsHost)
public enum INHostIntentAction: String, Sendable {
    case handle
    case confirm
    case resolve
}

@_spi(OpenIntentsHost)
public enum INHostIntentDispatcher {
    public static func dispatch(
        _ intent: INIntent,
        action: INHostIntentAction,
        handler: Any
    ) -> Any {
        switch action {
        case .handle:
            return handle(intent, handler: handler)
        case .confirm:
            return confirm(intent, handler: handler)
        case .resolve:
            return resolve(intent, handler: handler)
        }
    }

    public static func handle(_ intent: INIntent, handler: Any) -> INIntentResponse {
        if let send = intent as? INSendMessageIntent,
           let typed = handler as? any INSendMessageIntentHandling {
            var response: INSendMessageIntentResponse?
            typed.handle(intent: send) { response = $0 }
            return response ?? INSendMessageIntentResponse(code: .failure, userActivity: nil)
        }
        if let search = intent as? INSearchForMessagesIntent,
           let typed = handler as? any INSearchForMessagesIntentHandling {
            var response: INSearchForMessagesIntentResponse?
            typed.handle(intent: search) { response = $0 }
            return response ?? INSearchForMessagesIntentResponse(code: .failure, userActivity: nil)
        }
        if let start = intent as? INStartCallIntent,
           let typed = handler as? any INStartCallIntentHandling {
            var response: INStartCallIntentResponse?
            typed.handle(intent: start) { response = $0 }
            return response ?? INStartCallIntentResponse(code: .failure, userActivity: nil)
        }
        if let car = intent as? INGetCarPowerLevelStatusIntent,
           let typed = handler as? any INGetCarPowerLevelStatusIntentHandling {
            var response: INGetCarPowerLevelStatusIntentResponse?
            typed.handle(intent: car) { response = $0 }
            return response ?? INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil)
        }
        if let ride = intent as? INGetRideStatusIntent,
           let typed = handler as? any INGetRideStatusIntentHandling {
            var response: INGetRideStatusIntentResponse?
            typed.handle(intent: ride) { response = $0 }
            return response ?? INGetRideStatusIntentResponse(code: .failure, userActivity: nil)
        }
        if let list = intent as? INListRideOptionsIntent,
           let typed = handler as? any INListRideOptionsIntentHandling {
            var response: INListRideOptionsIntentResponse?
            typed.handle(intent: list) { response = $0 }
            return response ?? INListRideOptionsIntentResponse(code: .failure, userActivity: nil)
        }
        if let request = intent as? INRequestRideIntent,
           let typed = handler as? any INRequestRideIntentHandling {
            var response: INRequestRideIntentResponse?
            typed.handle(intent: request) { response = $0 }
            return response ?? INRequestRideIntentResponse(code: .failure, userActivity: nil)
        }
        if let add = intent as? INAddTasksIntent,
           let typed = handler as? any INAddTasksIntentHandling {
            var response: INAddTasksIntentResponse?
            typed.handle(intent: add) { response = $0 }
            return response ?? INAddTasksIntentResponse(code: .failure, userActivity: nil)
        }
        if let pay = intent as? INPayBillIntent,
           let typed = handler as? any INPayBillIntentHandling {
            var response: INPayBillIntentResponse?
            typed.handle(intent: pay) { response = $0 }
            return response ?? INPayBillIntentResponse(code: .failure, userActivity: nil)
        }
        if let transfer = intent as? INTransferMoneyIntent,
           let typed = handler as? any INTransferMoneyIntentHandling {
            var response: INTransferMoneyIntentResponse?
            typed.handle(intent: transfer) { response = $0 }
            return response ?? INTransferMoneyIntentResponse(code: .failure, userActivity: nil)
        }
        if let notebook = intent as? INSearchForNotebookItemsIntent,
           let typed = handler as? any INSearchForNotebookItemsIntentHandling {
            var response: INSearchForNotebookItemsIntentResponse?
            typed.handle(intent: notebook) { response = $0 }
            return response ?? INSearchForNotebookItemsIntentResponse(code: .failure, userActivity: nil)
        }
        if let setTask = intent as? INSetTaskAttributeIntent,
           let typed = handler as? any INSetTaskAttributeIntentHandling {
            var response: INSetTaskAttributeIntentResponse?
            typed.handle(intent: setTask) { response = $0 }
            return response ?? INSetTaskAttributeIntentResponse(code: .failure, userActivity: nil)
        }
        if let history = intent as? INSearchCallHistoryIntent,
           let typed = handler as? any INSearchCallHistoryIntentHandling {
            var response: INSearchCallHistoryIntentResponse?
            typed.handle(intent: history) { response = $0 }
            return response ?? INSearchCallHistoryIntentResponse(code: .failure, userActivity: nil)
        }
        if let book = intent as? INBookRestaurantReservationIntent,
           let typed = handler as? any INBookRestaurantReservationIntentHandling {
            var response: INBookRestaurantReservationIntentResponse?
            typed.handle(bookRestaurantReservation: book) { response = $0 }
            return response ?? INBookRestaurantReservationIntentResponse(code: .failure, userActivity: nil)
        }
        if let photos = intent as? INSearchForPhotosIntent,
           let typed = handler as? any INSearchForPhotosIntentHandling {
            var response: INSearchForPhotosIntentResponse?
            typed.handle(intent: photos) { response = $0 }
            return response ?? INSearchForPhotosIntentResponse(code: .failure, userActivity: nil)
        }
        if let playback = intent as? INStartPhotoPlaybackIntent,
           let typed = handler as? any INStartPhotoPlaybackIntentHandling {
            var response: INStartPhotoPlaybackIntentResponse?
            typed.handle(intent: playback) { response = $0 }
            return response ?? INStartPhotoPlaybackIntentResponse(code: .failure, userActivity: nil)
        }
        if let climate = intent as? INSetClimateSettingsInCarIntent,
           let typed = handler as? any INSetClimateSettingsInCarIntentHandling {
            var response: INSetClimateSettingsInCarIntentResponse?
            typed.handle(intent: climate) { response = $0 }
            return response ?? INSetClimateSettingsInCarIntentResponse(code: .failure, userActivity: nil)
        }
        if let accounts = intent as? INSearchForAccountsIntent,
           let typed = handler as? any INSearchForAccountsIntentHandling {
            var response: INSearchForAccountsIntentResponse?
            typed.handle(intent: accounts) { response = $0 }
            return response ?? INSearchForAccountsIntentResponse(code: .failure, userActivity: nil)
        }
        if let bills = intent as? INSearchForBillsIntent,
           let typed = handler as? any INSearchForBillsIntentHandling {
            var response: INSearchForBillsIntentResponse?
            typed.handle(intent: bills) { response = $0 }
            return response ?? INSearchForBillsIntentResponse(code: .failure, userActivity: nil)
        }
        return INIntentResponse()
    }

    public static func confirm(_ intent: INIntent, handler: Any) -> INIntentResponse {
        if let send = intent as? INSendMessageIntent,
           let typed = handler as? any INSendMessageIntentHandling {
            var response: INSendMessageIntentResponse?
            typed.confirm(intent: send) { response = $0 }
            return response ?? INSendMessageIntentResponse(code: .ready, userActivity: nil)
        }
        if let search = intent as? INSearchForMessagesIntent,
           let typed = handler as? any INSearchForMessagesIntentHandling {
            var response: INSearchForMessagesIntentResponse?
            typed.confirm(intent: search) { response = $0 }
            return response ?? INSearchForMessagesIntentResponse(code: .ready, userActivity: nil)
        }
        if let start = intent as? INStartCallIntent,
           let typed = handler as? any INStartCallIntentHandling {
            var response: INStartCallIntentResponse?
            typed.confirm(intent: start) { response = $0 }
            return response ?? INStartCallIntentResponse(code: .ready, userActivity: nil)
        }
        if let car = intent as? INGetCarPowerLevelStatusIntent,
           let typed = handler as? any INGetCarPowerLevelStatusIntentHandling {
            var response: INGetCarPowerLevelStatusIntentResponse?
            typed.confirm(intent: car) { response = $0 }
            return response ?? INGetCarPowerLevelStatusIntentResponse(code: .ready, userActivity: nil)
        }
        if let ride = intent as? INGetRideStatusIntent,
           let typed = handler as? any INGetRideStatusIntentHandling {
            var response: INGetRideStatusIntentResponse?
            typed.confirm(intent: ride) { response = $0 }
            return response ?? INGetRideStatusIntentResponse(code: .ready, userActivity: nil)
        }
        if let list = intent as? INListRideOptionsIntent,
           let typed = handler as? any INListRideOptionsIntentHandling {
            var response: INListRideOptionsIntentResponse?
            typed.confirm(intent: list) { response = $0 }
            return response ?? INListRideOptionsIntentResponse(code: .ready, userActivity: nil)
        }
        if let request = intent as? INRequestRideIntent,
           let typed = handler as? any INRequestRideIntentHandling {
            var response: INRequestRideIntentResponse?
            typed.confirm(intent: request) { response = $0 }
            return response ?? INRequestRideIntentResponse(code: .ready, userActivity: nil)
        }
        if let add = intent as? INAddTasksIntent,
           let typed = handler as? any INAddTasksIntentHandling {
            var response: INAddTasksIntentResponse?
            typed.confirm(intent: add) { response = $0 }
            return response ?? INAddTasksIntentResponse(code: .ready, userActivity: nil)
        }
        if let pay = intent as? INPayBillIntent,
           let typed = handler as? any INPayBillIntentHandling {
            var response: INPayBillIntentResponse?
            typed.confirm(intent: pay) { response = $0 }
            return response ?? INPayBillIntentResponse(code: .ready, userActivity: nil)
        }
        if let transfer = intent as? INTransferMoneyIntent,
           let typed = handler as? any INTransferMoneyIntentHandling {
            var response: INTransferMoneyIntentResponse?
            typed.confirm(intent: transfer) { response = $0 }
            return response ?? INTransferMoneyIntentResponse(code: .ready, userActivity: nil)
        }
        if let notebook = intent as? INSearchForNotebookItemsIntent,
           let typed = handler as? any INSearchForNotebookItemsIntentHandling {
            var response: INSearchForNotebookItemsIntentResponse?
            typed.confirm(intent: notebook) { response = $0 }
            return response ?? INSearchForNotebookItemsIntentResponse(code: .ready, userActivity: nil)
        }
        if let setTask = intent as? INSetTaskAttributeIntent,
           let typed = handler as? any INSetTaskAttributeIntentHandling {
            var response: INSetTaskAttributeIntentResponse?
            typed.confirm(intent: setTask) { response = $0 }
            return response ?? INSetTaskAttributeIntentResponse(code: .ready, userActivity: nil)
        }
        if let history = intent as? INSearchCallHistoryIntent,
           let typed = handler as? any INSearchCallHistoryIntentHandling {
            var response: INSearchCallHistoryIntentResponse?
            typed.confirm(intent: history) { response = $0 }
            return response ?? INSearchCallHistoryIntentResponse(code: .ready, userActivity: nil)
        }
        if let book = intent as? INBookRestaurantReservationIntent,
           let typed = handler as? any INBookRestaurantReservationIntentHandling {
            var response: INBookRestaurantReservationIntentResponse?
            typed.confirm(bookRestaurantReservation: book) { response = $0 }
            return response ?? INBookRestaurantReservationIntentResponse(code: .success, userActivity: nil)
        }
        if let photos = intent as? INSearchForPhotosIntent,
           let typed = handler as? any INSearchForPhotosIntentHandling {
            var response: INSearchForPhotosIntentResponse?
            typed.confirm(intent: photos) { response = $0 }
            return response ?? INSearchForPhotosIntentResponse(code: .ready, userActivity: nil)
        }
        if let playback = intent as? INStartPhotoPlaybackIntent,
           let typed = handler as? any INStartPhotoPlaybackIntentHandling {
            var response: INStartPhotoPlaybackIntentResponse?
            typed.confirm(intent: playback) { response = $0 }
            return response ?? INStartPhotoPlaybackIntentResponse(code: .ready, userActivity: nil)
        }
        if let climate = intent as? INSetClimateSettingsInCarIntent,
           let typed = handler as? any INSetClimateSettingsInCarIntentHandling {
            var response: INSetClimateSettingsInCarIntentResponse?
            typed.confirm(intent: climate) { response = $0 }
            return response ?? INSetClimateSettingsInCarIntentResponse(code: .ready, userActivity: nil)
        }
        if let accounts = intent as? INSearchForAccountsIntent,
           let typed = handler as? any INSearchForAccountsIntentHandling {
            var response: INSearchForAccountsIntentResponse?
            typed.confirm(intent: accounts) { response = $0 }
            return response ?? INSearchForAccountsIntentResponse(code: .ready, userActivity: nil)
        }
        if let bills = intent as? INSearchForBillsIntent,
           let typed = handler as? any INSearchForBillsIntentHandling {
            var response: INSearchForBillsIntentResponse?
            typed.confirm(intent: bills) { response = $0 }
            return response ?? INSearchForBillsIntentResponse(code: .ready, userActivity: nil)
        }
        return INIntentResponse()
    }

    public static func resolve(_ intent: INIntent, handler: Any) -> [INIntentResolutionResult] {
        if let send = intent as? INSendMessageIntent,
           let typed = handler as? any INSendMessageIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveContent(for: send) { results.append($0) }
            typed.resolveSpeakableGroupName(for: send) { results.append($0) }
            return results
        }
        if let search = intent as? INSearchForMessagesIntent,
           let typed = handler as? any INSearchForMessagesIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAttributes(for: search) { results.append($0) }
            typed.resolveDateTimeRange(for: search) { results.append($0) }
            return results
        }
        if let start = intent as? INStartCallIntent,
           let typed = handler as? any INStartCallIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCallCapability(for: start) { results.append($0) }
            typed.resolveDestinationType(for: start) { results.append($0) }
            return results
        }
        if let car = intent as? INGetCarPowerLevelStatusIntent,
           let typed = handler as? any INGetCarPowerLevelStatusIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveCarName(for: car) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let request = intent as? INRequestRideIntent,
           let typed = handler as? any INRequestRideIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolvePartySize(for: request) { results.append($0) }
            typed.resolveRideOptionName(for: request) { results.append($0) }
            typed.resolveScheduledPickupTime(for: request) { results.append($0) }
            return results
        }
        if let add = intent as? INAddTasksIntent,
           let typed = handler as? any INAddTasksIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolvePriority(for: add) { results.append($0) }
            typed.resolveSpatialEventTrigger(for: add) { results.append($0) }
            typed.resolveTargetTaskList(for: add, completion: { results.append($0) })
            typed.resolveTargetTaskList(for: add, with: { results.append($0) })
            typed.resolveTemporalEventTrigger(for: add, completion: { results.append($0) })
            typed.resolveTemporalEventTrigger(for: add, with: { results.append($0) })
            return results
        }
        if let pay = intent as? INPayBillIntent,
           let typed = handler as? any INPayBillIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveBillPayee(for: pay) { results.append($0) }
            typed.resolveBillType(for: pay) { results.append($0) }
            typed.resolveDueDate(for: pay) { results.append($0) }
            typed.resolveFromAccount(for: pay) { results.append($0) }
            typed.resolveTransactionAmount(for: pay) { results.append($0) }
            typed.resolveTransactionNote(for: pay) { results.append($0) }
            typed.resolveTransactionScheduledDate(for: pay) { results.append($0) }
            return results
        }
        if let transfer = intent as? INTransferMoneyIntent,
           let typed = handler as? any INTransferMoneyIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveFromAccount(for: transfer) { results.append($0) }
            typed.resolveToAccount(for: transfer) { results.append($0) }
            typed.resolveTransactionAmount(for: transfer) { results.append($0) }
            typed.resolveTransactionNote(for: transfer) { results.append($0) }
            typed.resolveTransactionScheduledDate(for: transfer) { results.append($0) }
            return results
        }
        if let notebook = intent as? INSearchForNotebookItemsIntent,
           let typed = handler as? any INSearchForNotebookItemsIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveContent(for: notebook) { results.append($0) }
            typed.resolveDateSearchType(for: notebook) { results.append($0) }
            typed.resolveDateTime(for: notebook) { results.append($0) }
            typed.resolveItemType(for: notebook) { results.append($0) }
            typed.resolveLocation(for: notebook) { results.append($0) }
            typed.resolveLocationSearchType(for: notebook) { results.append($0) }
            typed.resolveStatus(for: notebook) { results.append($0) }
            typed.resolveTaskPriority(for: notebook) { results.append($0) }
            typed.resolveTemporalEventTriggerTypes(for: notebook) { results.append($0) }
            typed.resolveTitle(for: notebook) { results.append($0) }
            return results
        }
        if let setTask = intent as? INSetTaskAttributeIntent,
           let typed = handler as? any INSetTaskAttributeIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolvePriority(for: setTask) { results.append($0) }
            typed.resolveSpatialEventTrigger(for: setTask) { results.append($0) }
            typed.resolveStatus(for: setTask) { results.append($0) }
            typed.resolveTargetTask(for: setTask) { results.append($0) }
            typed.resolveTaskTitle(for: setTask) { results.append($0) }
            typed.resolveTemporalEventTrigger(for: setTask, completion: { results.append($0) })
            typed.resolveTemporalEventTrigger(for: setTask, with: { results.append($0) })
            return results
        }
        if let history = intent as? INSearchCallHistoryIntent,
           let typed = handler as? any INSearchCallHistoryIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCallType(for: history) { results.append($0) }
            typed.resolveCallTypes(for: history) { results.append($0) }
            typed.resolveDateCreated(for: history) { results.append($0) }
            typed.resolveRecipient(for: history) { results.append($0) }
            typed.resolveUnseen(for: history) { results.append($0) }
            return results
        }
        if let book = intent as? INBookRestaurantReservationIntent,
           let typed = handler as? any INBookRestaurantReservationIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveBookingDateComponents(for: book) { results.append($0) }
            typed.resolveGuest(for: book) { results.append($0) }
            typed.resolveGuestProvidedSpecialRequestText(for: book) { results.append($0) }
            typed.resolvePartySize(for: book) { results.append($0) }
            typed.resolveRestaurant(for: book) { results.append($0) }
            return results
        }
        if let photos = intent as? INSearchForPhotosIntent,
           let typed = handler as? any INSearchForPhotosIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAlbumName(for: photos) { results.append($0) }
            typed.resolveDateCreated(for: photos) { results.append($0) }
            typed.resolveLocationCreated(for: photos) { results.append($0) }
            typed.resolvePeopleInPhoto(for: photos) { results.append(contentsOf: $0) }
            typed.resolveSearchTerms(for: photos) { results.append(contentsOf: $0) }
            return results
        }
        if let playback = intent as? INStartPhotoPlaybackIntent,
           let typed = handler as? any INStartPhotoPlaybackIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAlbumName(for: playback) { results.append($0) }
            typed.resolveDateCreated(for: playback) { results.append($0) }
            typed.resolveLocationCreated(for: playback) { results.append($0) }
            typed.resolvePeopleInPhoto(for: playback) { results.append(contentsOf: $0) }
            return results
        }
        if let climate = intent as? INSetClimateSettingsInCarIntent,
           let typed = handler as? any INSetClimateSettingsInCarIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAirCirculationMode(for: climate) { results.append($0) }
            typed.resolveCarName(for: climate) { results.append($0) }
            typed.resolveClimateZone(for: climate) { results.append($0) }
            typed.resolveEnableAirConditioner(for: climate) { results.append($0) }
            typed.resolveEnableAutoMode(for: climate) { results.append($0) }
            typed.resolveEnableClimateControl(for: climate) { results.append($0) }
            typed.resolveEnableFan(for: climate) { results.append($0) }
            typed.resolveFanSpeedIndex(for: climate) { results.append($0) }
            typed.resolveFanSpeedPercentage(for: climate) { results.append($0) }
            typed.resolveRelativeFanSpeedSetting(for: climate) { results.append($0) }
            typed.resolveRelativeTemperatureSetting(for: climate) { results.append($0) }
            typed.resolveTemperature(for: climate) { results.append($0) }
            return results
        }
        if let accounts = intent as? INSearchForAccountsIntent,
           let typed = handler as? any INSearchForAccountsIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAccountNickname(for: accounts) { results.append($0) }
            typed.resolveAccountType(for: accounts) { results.append($0) }
            typed.resolveOrganizationName(for: accounts) { results.append($0) }
            typed.resolveRequestedBalanceType(for: accounts) { results.append($0) }
            return results
        }
        if let bills = intent as? INSearchForBillsIntent,
           let typed = handler as? any INSearchForBillsIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveBillPayee(for: bills) { results.append($0) }
            typed.resolveBillType(for: bills) { results.append($0) }
            typed.resolveDueDateRange(for: bills) { results.append($0) }
            typed.resolvePaymentDateRange(for: bills) { results.append($0) }
            typed.resolveStatus(for: bills) { results.append($0) }
            return results
        }
        return [INIntentResolutionResult.needsValue()]
    }
}

extension INIntentResolutionResult {
    @_spi(OpenIntentsHost)
    public var linuxOutcomeCode: Int { outcome.rawValue }
}
