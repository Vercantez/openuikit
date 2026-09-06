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
        if let profile = intent as? INSetProfileInCarIntent,
           let typed = handler as? any INSetProfileInCarIntentHandling {
            var response: INSetProfileInCarIntentResponse?
            typed.handle(intent: profile) { response = $0 }
            return response ?? INSetProfileInCarIntentResponse(code: .failure, userActivity: nil)
        }
        if let play = intent as? INPlayMediaIntent,
           let typed = handler as? any INPlayMediaIntentHandling {
            var response: INPlayMediaIntentResponse?
            typed.handle(intent: play) { response = $0 }
            return response ?? INPlayMediaIntentResponse(code: .failure, userActivity: nil)
        }
        if let requestPay = intent as? INRequestPaymentIntent,
           let typed = handler as? any INRequestPaymentIntentHandling {
            var response: INRequestPaymentIntentResponse?
            typed.handle(intent: requestPay) { response = $0 }
            return response ?? INRequestPaymentIntentResponse(code: .failure, userActivity: nil)
        }
        if let sendPay = intent as? INSendPaymentIntent,
           let typed = handler as? any INSendPaymentIntentHandling {
            var response: INSendPaymentIntentResponse?
            typed.handle(intent: sendPay) { response = $0 }
            return response ?? INSendPaymentIntentResponse(code: .failure, userActivity: nil)
        }
        if let seat = intent as? INSetSeatSettingsInCarIntent,
           let typed = handler as? any INSetSeatSettingsInCarIntentHandling {
            var response: INSetSeatSettingsInCarIntentResponse?
            typed.handle(intent: seat) { response = $0 }
            return response ?? INSetSeatSettingsInCarIntentResponse(code: .failure, userActivity: nil)
        }
        if let radio = intent as? INSetRadioStationIntent,
           let typed = handler as? any INSetRadioStationIntentHandling {
            var response: INSetRadioStationIntentResponse?
            typed.handle(intent: radio) { response = $0 }
            return response ?? INSetRadioStationIntentResponse(code: .failure, userActivity: nil)
        }
        if let workout = intent as? INStartWorkoutIntent,
           let typed = handler as? any INStartWorkoutIntentHandling {
            var response: INStartWorkoutIntentResponse?
            typed.handle(intent: workout) { response = $0 }
            return response ?? INStartWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        if let note = intent as? INCreateNoteIntent,
           let typed = handler as? any INCreateNoteIntentHandling {
            var response: INCreateNoteIntentResponse?
            typed.handle(intent: note) { response = $0 }
            return response ?? INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }
        if let list = intent as? INCreateTaskListIntent,
           let typed = handler as? any INCreateTaskListIntentHandling {
            var response: INCreateTaskListIntentResponse?
            typed.handle(intent: list) { response = $0 }
            return response ?? INCreateTaskListIntentResponse(code: .failure, userActivity: nil)
        }
        if let deleteTasks = intent as? INDeleteTasksIntent,
           let typed = handler as? any INDeleteTasksIntentHandling {
            var response: INDeleteTasksIntentResponse?
            typed.handle(intent: deleteTasks) { response = $0 }
            return response ?? INDeleteTasksIntentResponse(code: .failure, userActivity: nil)
        }
        if let defroster = intent as? INSetDefrosterSettingsInCarIntent,
           let typed = handler as? any INSetDefrosterSettingsInCarIntentHandling {
            var response: INSetDefrosterSettingsInCarIntentResponse?
            typed.handle(intent: defroster) { response = $0 }
            return response ?? INSetDefrosterSettingsInCarIntentResponse(code: .failure, userActivity: nil)
        }
        if let defaults = intent as? INGetAvailableRestaurantReservationBookingDefaultsIntent,
           let typed = handler as? any INGetAvailableRestaurantReservationBookingDefaultsIntentHandling {
            var response: INGetAvailableRestaurantReservationBookingDefaultsIntentResponse?
            typed.handle(getAvailableRestaurantReservationBookingDefaults: defaults) { response = $0 }
            return response ?? INGetAvailableRestaurantReservationBookingDefaultsIntentResponse()
        }
        if let bookings = intent as? INGetAvailableRestaurantReservationBookingsIntent,
           let typed = handler as? any INGetAvailableRestaurantReservationBookingsIntentHandling {
            var response: INGetAvailableRestaurantReservationBookingsIntentResponse?
            typed.handle(getAvailableRestaurantReservationBookings: bookings) { response = $0 }
            return response ?? INGetAvailableRestaurantReservationBookingsIntentResponse()
        }
        if let current = intent as? INGetUserCurrentRestaurantReservationBookingsIntent,
           let typed = handler as? any INGetUserCurrentRestaurantReservationBookingsIntentHandling {
            var response: INGetUserCurrentRestaurantReservationBookingsIntentResponse?
            typed.handle(getUserCurrentRestaurantReservationBookings: current) { response = $0 }
            return response ?? INGetUserCurrentRestaurantReservationBookingsIntentResponse()
        }
        if let addMedia = intent as? INAddMediaIntent,
           let typed = handler as? any INAddMediaIntentHandling {
            var response: INAddMediaIntentResponse?
            typed.handle(intent: addMedia) { response = $0 }
            return response ?? INAddMediaIntentResponse(code: .failure, userActivity: nil)
        }
        if let activate = intent as? INActivateCarSignalIntent,
           let typed = handler as? any INActivateCarSignalIntentHandling {
            var response: INActivateCarSignalIntentResponse?
            typed.handle(intent: activate) { response = $0 }
            return response ?? INActivateCarSignalIntentResponse(code: .failure, userActivity: nil)
        }
        if let answer = intent as? INAnswerCallIntent,
           let typed = handler as? any INAnswerCallIntentHandling {
            var response: INAnswerCallIntentResponse?
            typed.handle(intent: answer) { response = $0 }
            return response ?? INAnswerCallIntentResponse(code: .failure, userActivity: nil)
        }
        if let append = intent as? INAppendToNoteIntent,
           let typed = handler as? any INAppendToNoteIntentHandling {
            var response: INAppendToNoteIntentResponse?
            typed.handle(intent: append) { response = $0 }
            return response ?? INAppendToNoteIntentResponse(code: .failure, userActivity: nil)
        }
        if let cancelRide = intent as? INCancelRideIntent,
           let typed = handler as? any INCancelRideIntentHandling {
            var response: INCancelRideIntentResponse?
            typed.handle(cancelRide: cancelRide) { response = $0 }
            return response ?? INCancelRideIntentResponse(code: .failure, userActivity: nil)
        }
        if let cancelWorkout = intent as? INCancelWorkoutIntent,
           let typed = handler as? any INCancelWorkoutIntentHandling {
            var response: INCancelWorkoutIntentResponse?
            typed.handle(intent: cancelWorkout) { response = $0 }
            return response ?? INCancelWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        if let edit = intent as? INEditMessageIntent,
           let typed = handler as? any INEditMessageIntentHandling {
            var response: INEditMessageIntentResponse?
            typed.handle(intent: edit) { response = $0 }
            return response ?? INEditMessageIntentResponse(code: .failure, userActivity: nil)
        }
        if let endWorkout = intent as? INEndWorkoutIntent,
           let typed = handler as? any INEndWorkoutIntentHandling {
            var response: INEndWorkoutIntentResponse?
            typed.handle(intent: endWorkout) { response = $0 }
            return response ?? INEndWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        if let lockStatus = intent as? INGetCarLockStatusIntent,
           let typed = handler as? any INGetCarLockStatusIntentHandling {
            var response: INGetCarLockStatusIntentResponse?
            typed.handle(intent: lockStatus) { response = $0 }
            return response ?? INGetCarLockStatusIntentResponse(code: .failure, userActivity: nil)
        }
        if let visual = intent as? INGetVisualCodeIntent,
           let typed = handler as? any INGetVisualCodeIntentHandling {
            var response: INGetVisualCodeIntentResponse?
            typed.handle(intent: visual) { response = $0 }
            return response ?? INGetVisualCodeIntentResponse(code: .failure, userActivity: nil)
        }
        if let pause = intent as? INPauseWorkoutIntent,
           let typed = handler as? any INPauseWorkoutIntentHandling {
            var response: INPauseWorkoutIntentResponse?
            typed.handle(intent: pause) { response = $0 }
            return response ?? INPauseWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        if let resume = intent as? INResumeWorkoutIntent,
           let typed = handler as? any INResumeWorkoutIntentHandling {
            var response: INResumeWorkoutIntentResponse?
            typed.handle(intent: resume) { response = $0 }
            return response ?? INResumeWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        if let saveProfile = intent as? INSaveProfileInCarIntent,
           let typed = handler as? any INSaveProfileInCarIntentHandling {
            var response: INSaveProfileInCarIntentResponse?
            typed.handle(intent: saveProfile) { response = $0 }
            return response ?? INSaveProfileInCarIntentResponse(code: .failure, userActivity: nil)
        }
        if let searchMedia = intent as? INSearchForMediaIntent,
           let typed = handler as? any INSearchForMediaIntentHandling {
            var response: INSearchForMediaIntentResponse?
            typed.handle(intent: searchMedia) { response = $0 }
            return response ?? INSearchForMediaIntentResponse(code: .failure, userActivity: nil)
        }
        if let rideFeedback = intent as? INSendRideFeedbackIntent,
           let typed = handler as? any INSendRideFeedbackIntentHandling {
            var response: INSendRideFeedbackIntentResponse?
            typed.handle(sendRideFeedback: rideFeedback) { response = $0 }
            return response ?? INSendRideFeedbackIntentResponse(code: .failure, userActivity: nil)
        }
        if let audioSource = intent as? INSetAudioSourceInCarIntent,
           let typed = handler as? any INSetAudioSourceInCarIntentHandling {
            var response: INSetAudioSourceInCarIntentResponse?
            typed.handle(intent: audioSource) { response = $0 }
            return response ?? INSetAudioSourceInCarIntentResponse(code: .failure, userActivity: nil)
        }
        if let lock = intent as? INSetCarLockStatusIntent,
           let typed = handler as? any INSetCarLockStatusIntentHandling {
            var response: INSetCarLockStatusIntentResponse?
            typed.handle(intent: lock) { response = $0 }
            return response ?? INSetCarLockStatusIntentResponse(code: .failure, userActivity: nil)
        }
        if let attribute = intent as? INSetMessageAttributeIntent,
           let typed = handler as? any INSetMessageAttributeIntentHandling {
            var response: INSetMessageAttributeIntentResponse?
            typed.handle(intent: attribute) { response = $0 }
            return response ?? INSetMessageAttributeIntentResponse(code: .failure, userActivity: nil)
        }
        if let snooze = intent as? INSnoozeTasksIntent,
           let typed = handler as? any INSnoozeTasksIntentHandling {
            var response: INSnoozeTasksIntentResponse?
            typed.handle(intent: snooze) { response = $0 }
            return response ?? INSnoozeTasksIntentResponse(code: .failure, userActivity: nil)
        }
        if let audioCall = intent as? INStartAudioCallIntent,
           let typed = handler as? any INStartAudioCallIntentHandling {
            var response: INStartAudioCallIntentResponse?
            typed.handle(intent: audioCall) { response = $0 }
            return response ?? INStartAudioCallIntentResponse(code: .failure, userActivity: nil)
        }
        if let videoCall = intent as? INStartVideoCallIntent,
           let typed = handler as? any INStartVideoCallIntentHandling {
            var response: INStartVideoCallIntentResponse?
            typed.handle(intent: videoCall) { response = $0 }
            return response ?? INStartVideoCallIntentResponse(code: .failure, userActivity: nil)
        }
        if let affinity = intent as? INUpdateMediaAffinityIntent,
           let typed = handler as? any INUpdateMediaAffinityIntentHandling {
            var response: INUpdateMediaAffinityIntentResponse?
            typed.handle(intent: affinity) { response = $0 }
            return response ?? INUpdateMediaAffinityIntentResponse(code: .failure, userActivity: nil)
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
        if let profile = intent as? INSetProfileInCarIntent,
           let typed = handler as? any INSetProfileInCarIntentHandling {
            var response: INSetProfileInCarIntentResponse?
            typed.confirm(intent: profile) { response = $0 }
            return response ?? INSetProfileInCarIntentResponse(code: .ready, userActivity: nil)
        }
        if let play = intent as? INPlayMediaIntent,
           let typed = handler as? any INPlayMediaIntentHandling {
            var response: INPlayMediaIntentResponse?
            typed.confirm(intent: play) { response = $0 }
            return response ?? INPlayMediaIntentResponse(code: .ready, userActivity: nil)
        }
        if let requestPay = intent as? INRequestPaymentIntent,
           let typed = handler as? any INRequestPaymentIntentHandling {
            var response: INRequestPaymentIntentResponse?
            typed.confirm(intent: requestPay) { response = $0 }
            return response ?? INRequestPaymentIntentResponse(code: .ready, userActivity: nil)
        }
        if let sendPay = intent as? INSendPaymentIntent,
           let typed = handler as? any INSendPaymentIntentHandling {
            var response: INSendPaymentIntentResponse?
            typed.confirm(intent: sendPay) { response = $0 }
            return response ?? INSendPaymentIntentResponse(code: .ready, userActivity: nil)
        }
        if let seat = intent as? INSetSeatSettingsInCarIntent,
           let typed = handler as? any INSetSeatSettingsInCarIntentHandling {
            var response: INSetSeatSettingsInCarIntentResponse?
            typed.confirm(intent: seat) { response = $0 }
            return response ?? INSetSeatSettingsInCarIntentResponse(code: .ready, userActivity: nil)
        }
        if let radio = intent as? INSetRadioStationIntent,
           let typed = handler as? any INSetRadioStationIntentHandling {
            var response: INSetRadioStationIntentResponse?
            typed.confirm(intent: radio) { response = $0 }
            return response ?? INSetRadioStationIntentResponse(code: .ready, userActivity: nil)
        }
        if let workout = intent as? INStartWorkoutIntent,
           let typed = handler as? any INStartWorkoutIntentHandling {
            var response: INStartWorkoutIntentResponse?
            typed.confirm(intent: workout) { response = $0 }
            return response ?? INStartWorkoutIntentResponse(code: .ready, userActivity: nil)
        }
        if let note = intent as? INCreateNoteIntent,
           let typed = handler as? any INCreateNoteIntentHandling {
            var response: INCreateNoteIntentResponse?
            typed.confirm(intent: note) { response = $0 }
            return response ?? INCreateNoteIntentResponse(code: .ready, userActivity: nil)
        }
        if let list = intent as? INCreateTaskListIntent,
           let typed = handler as? any INCreateTaskListIntentHandling {
            var response: INCreateTaskListIntentResponse?
            typed.confirm(intent: list) { response = $0 }
            return response ?? INCreateTaskListIntentResponse(code: .ready, userActivity: nil)
        }
        if let deleteTasks = intent as? INDeleteTasksIntent,
           let typed = handler as? any INDeleteTasksIntentHandling {
            var response: INDeleteTasksIntentResponse?
            typed.confirm(intent: deleteTasks) { response = $0 }
            return response ?? INDeleteTasksIntentResponse(code: .ready, userActivity: nil)
        }
        if let defroster = intent as? INSetDefrosterSettingsInCarIntent,
           let typed = handler as? any INSetDefrosterSettingsInCarIntentHandling {
            var response: INSetDefrosterSettingsInCarIntentResponse?
            typed.confirm(intent: defroster) { response = $0 }
            return response ?? INSetDefrosterSettingsInCarIntentResponse(code: .ready, userActivity: nil)
        }
        if let defaults = intent as? INGetAvailableRestaurantReservationBookingDefaultsIntent,
           let typed = handler as? any INGetAvailableRestaurantReservationBookingDefaultsIntentHandling {
            var response: INGetAvailableRestaurantReservationBookingDefaultsIntentResponse?
            typed.confirm(getAvailableRestaurantReservationBookingDefaults: defaults) { response = $0 }
            return response ?? INGetAvailableRestaurantReservationBookingDefaultsIntentResponse()
        }
        if let bookings = intent as? INGetAvailableRestaurantReservationBookingsIntent,
           let typed = handler as? any INGetAvailableRestaurantReservationBookingsIntentHandling {
            var response: INGetAvailableRestaurantReservationBookingsIntentResponse?
            typed.confirm(getAvailableRestaurantReservationBookings: bookings) { response = $0 }
            return response ?? INGetAvailableRestaurantReservationBookingsIntentResponse()
        }
        if let current = intent as? INGetUserCurrentRestaurantReservationBookingsIntent,
           let typed = handler as? any INGetUserCurrentRestaurantReservationBookingsIntentHandling {
            var response: INGetUserCurrentRestaurantReservationBookingsIntentResponse?
            typed.confirm(getUserCurrentRestaurantReservationBookings: current) { response = $0 }
            return response ?? INGetUserCurrentRestaurantReservationBookingsIntentResponse()
        }
        if let addMedia = intent as? INAddMediaIntent,
           let typed = handler as? any INAddMediaIntentHandling {
            var response: INAddMediaIntentResponse?
            typed.confirm(intent: addMedia) { response = $0 }
            return response ?? INAddMediaIntentResponse(code: .ready, userActivity: nil)
        }
        if let activate = intent as? INActivateCarSignalIntent,
           let typed = handler as? any INActivateCarSignalIntentHandling {
            var response: INActivateCarSignalIntentResponse?
            typed.confirm(intent: activate) { response = $0 }
            return response ?? INActivateCarSignalIntentResponse(code: .ready, userActivity: nil)
        }
        if let answer = intent as? INAnswerCallIntent,
           let typed = handler as? any INAnswerCallIntentHandling {
            var response: INAnswerCallIntentResponse?
            typed.confirm(intent: answer) { response = $0 }
            return response ?? INAnswerCallIntentResponse(code: .ready, userActivity: nil)
        }
        if let append = intent as? INAppendToNoteIntent,
           let typed = handler as? any INAppendToNoteIntentHandling {
            var response: INAppendToNoteIntentResponse?
            typed.confirm(intent: append) { response = $0 }
            return response ?? INAppendToNoteIntentResponse(code: .ready, userActivity: nil)
        }
        if let cancelRide = intent as? INCancelRideIntent,
           let typed = handler as? any INCancelRideIntentHandling {
            var response: INCancelRideIntentResponse?
            typed.confirm(cancelRide: cancelRide) { response = $0 }
            return response ?? INCancelRideIntentResponse(code: .ready, userActivity: nil)
        }
        if let cancelWorkout = intent as? INCancelWorkoutIntent,
           let typed = handler as? any INCancelWorkoutIntentHandling {
            var response: INCancelWorkoutIntentResponse?
            typed.confirm(intent: cancelWorkout) { response = $0 }
            return response ?? INCancelWorkoutIntentResponse(code: .ready, userActivity: nil)
        }
        if let edit = intent as? INEditMessageIntent,
           let typed = handler as? any INEditMessageIntentHandling {
            var response: INEditMessageIntentResponse?
            typed.confirm(intent: edit) { response = $0 }
            return response ?? INEditMessageIntentResponse(code: .ready, userActivity: nil)
        }
        if let endWorkout = intent as? INEndWorkoutIntent,
           let typed = handler as? any INEndWorkoutIntentHandling {
            var response: INEndWorkoutIntentResponse?
            typed.confirm(intent: endWorkout) { response = $0 }
            return response ?? INEndWorkoutIntentResponse(code: .ready, userActivity: nil)
        }
        if let lockStatus = intent as? INGetCarLockStatusIntent,
           let typed = handler as? any INGetCarLockStatusIntentHandling {
            var response: INGetCarLockStatusIntentResponse?
            typed.confirm(intent: lockStatus) { response = $0 }
            return response ?? INGetCarLockStatusIntentResponse(code: .ready, userActivity: nil)
        }
        if let visual = intent as? INGetVisualCodeIntent,
           let typed = handler as? any INGetVisualCodeIntentHandling {
            var response: INGetVisualCodeIntentResponse?
            typed.confirm(intent: visual) { response = $0 }
            return response ?? INGetVisualCodeIntentResponse(code: .ready, userActivity: nil)
        }
        if let pause = intent as? INPauseWorkoutIntent,
           let typed = handler as? any INPauseWorkoutIntentHandling {
            var response: INPauseWorkoutIntentResponse?
            typed.confirm(intent: pause) { response = $0 }
            return response ?? INPauseWorkoutIntentResponse(code: .ready, userActivity: nil)
        }
        if let resume = intent as? INResumeWorkoutIntent,
           let typed = handler as? any INResumeWorkoutIntentHandling {
            var response: INResumeWorkoutIntentResponse?
            typed.confirm(intent: resume) { response = $0 }
            return response ?? INResumeWorkoutIntentResponse(code: .ready, userActivity: nil)
        }
        if let saveProfile = intent as? INSaveProfileInCarIntent,
           let typed = handler as? any INSaveProfileInCarIntentHandling {
            var response: INSaveProfileInCarIntentResponse?
            typed.confirm(intent: saveProfile) { response = $0 }
            return response ?? INSaveProfileInCarIntentResponse(code: .ready, userActivity: nil)
        }
        if let searchMedia = intent as? INSearchForMediaIntent,
           let typed = handler as? any INSearchForMediaIntentHandling {
            var response: INSearchForMediaIntentResponse?
            typed.confirm(intent: searchMedia) { response = $0 }
            return response ?? INSearchForMediaIntentResponse(code: .ready, userActivity: nil)
        }
        if let rideFeedback = intent as? INSendRideFeedbackIntent,
           let typed = handler as? any INSendRideFeedbackIntentHandling {
            var response: INSendRideFeedbackIntentResponse?
            typed.confirm(sendRideFeedback: rideFeedback) { response = $0 }
            return response ?? INSendRideFeedbackIntentResponse(code: .ready, userActivity: nil)
        }
        if let audioSource = intent as? INSetAudioSourceInCarIntent,
           let typed = handler as? any INSetAudioSourceInCarIntentHandling {
            var response: INSetAudioSourceInCarIntentResponse?
            typed.confirm(intent: audioSource) { response = $0 }
            return response ?? INSetAudioSourceInCarIntentResponse(code: .ready, userActivity: nil)
        }
        if let lock = intent as? INSetCarLockStatusIntent,
           let typed = handler as? any INSetCarLockStatusIntentHandling {
            var response: INSetCarLockStatusIntentResponse?
            typed.confirm(intent: lock) { response = $0 }
            return response ?? INSetCarLockStatusIntentResponse(code: .ready, userActivity: nil)
        }
        if let attribute = intent as? INSetMessageAttributeIntent,
           let typed = handler as? any INSetMessageAttributeIntentHandling {
            var response: INSetMessageAttributeIntentResponse?
            typed.confirm(intent: attribute) { response = $0 }
            return response ?? INSetMessageAttributeIntentResponse(code: .ready, userActivity: nil)
        }
        if let snooze = intent as? INSnoozeTasksIntent,
           let typed = handler as? any INSnoozeTasksIntentHandling {
            var response: INSnoozeTasksIntentResponse?
            typed.confirm(intent: snooze) { response = $0 }
            return response ?? INSnoozeTasksIntentResponse(code: .ready, userActivity: nil)
        }
        if let audioCall = intent as? INStartAudioCallIntent,
           let typed = handler as? any INStartAudioCallIntentHandling {
            var response: INStartAudioCallIntentResponse?
            typed.confirm(intent: audioCall) { response = $0 }
            return response ?? INStartAudioCallIntentResponse(code: .ready, userActivity: nil)
        }
        if let videoCall = intent as? INStartVideoCallIntent,
           let typed = handler as? any INStartVideoCallIntentHandling {
            var response: INStartVideoCallIntentResponse?
            typed.confirm(intent: videoCall) { response = $0 }
            return response ?? INStartVideoCallIntentResponse(code: .ready, userActivity: nil)
        }
        if let affinity = intent as? INUpdateMediaAffinityIntent,
           let typed = handler as? any INUpdateMediaAffinityIntentHandling {
            var response: INUpdateMediaAffinityIntentResponse?
            typed.confirm(intent: affinity) { response = $0 }
            return response ?? INUpdateMediaAffinityIntentResponse(code: .ready, userActivity: nil)
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
            typed.resolveGroupNames(for: search) { results.append(contentsOf: $0) }
            typed.resolveRecipients(for: search) { results.append(contentsOf: $0) }
            typed.resolveSenders(for: search) { results.append(contentsOf: $0) }
            typed.resolveSpeakableGroupNames(for: search) { results.append(contentsOf: $0) }
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
            return resolveAddTasks(add, handler: typed)
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
            return resolveSetTaskAttribute(setTask, handler: typed)
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
        if let profile = intent as? INSetProfileInCarIntent,
           let typed = handler as? any INSetProfileInCarIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCarName(for: profile) { results.append($0) }
            typed.resolveDefaultProfile(forSetProfileInCar: profile) { results.append($0) }
            typed.resolveProfileName(for: profile) { results.append($0) }
            typed.resolveProfileNumber(for: profile) { results.append($0) }
            return results
        }
        if let play = intent as? INPlayMediaIntent,
           let typed = handler as? any INPlayMediaIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveMediaItems(for: play) { results.append(contentsOf: $0) }
            typed.resolvePlayShuffled(for: play) { results.append($0) }
            typed.resolvePlaybackQueueLocation(for: play) { results.append($0) }
            typed.resolvePlaybackRepeatMode(for: play) { results.append($0) }
            typed.resolvePlaybackSpeed(for: play) { results.append($0) }
            typed.resolveResumePlayback(for: play) { results.append($0) }
            return results
        }
        if let requestPay = intent as? INRequestPaymentIntent,
           let typed = handler as? any INRequestPaymentIntentHandling {
            return resolveRequestPayment(requestPay, handler: typed)
        }
        if let sendPay = intent as? INSendPaymentIntent,
           let typed = handler as? any INSendPaymentIntentHandling {
            return resolveSendPayment(sendPay, handler: typed)
        }
        if let seat = intent as? INSetSeatSettingsInCarIntent,
           let typed = handler as? any INSetSeatSettingsInCarIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCarName(for: seat) { results.append($0) }
            typed.resolveEnableCooling(for: seat) { results.append($0) }
            typed.resolveEnableHeating(for: seat) { results.append($0) }
            typed.resolveEnableMassage(for: seat) { results.append($0) }
            typed.resolveLevel(for: seat) { results.append($0) }
            typed.resolveRelativeLevelSetting(for: seat) { results.append($0) }
            typed.resolveSeat(for: seat) { results.append($0) }
            return results
        }
        if let radio = intent as? INSetRadioStationIntent,
           let typed = handler as? any INSetRadioStationIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveChannel(for: radio) { results.append($0) }
            typed.resolveFrequency(for: radio) { results.append($0) }
            typed.resolvePresetNumber(for: radio) { results.append($0) }
            typed.resolveRadioType(for: radio) { results.append($0) }
            typed.resolveStationName(for: radio) { results.append($0) }
            return results
        }
        if let workout = intent as? INStartWorkoutIntent,
           let typed = handler as? any INStartWorkoutIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveGoalValue(for: workout) { results.append($0) }
            typed.resolveIsOpenEnded(for: workout) { results.append($0) }
            typed.resolveWorkoutGoalUnitType(for: workout) { results.append($0) }
            typed.resolveWorkoutLocationType(for: workout) { results.append($0) }
            typed.resolveWorkoutName(for: workout) { results.append($0) }
            return results
        }
        if let note = intent as? INCreateNoteIntent,
           let typed = handler as? any INCreateNoteIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveContent(for: note) { results.append($0) }
            typed.resolveGroupName(for: note) { results.append($0) }
            typed.resolveTitle(for: note) { results.append($0) }
            return results
        }
        if let list = intent as? INCreateTaskListIntent,
           let typed = handler as? any INCreateTaskListIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveGroupName(for: list) { results.append($0) }
            typed.resolveTaskTitles(for: list) { results.append(contentsOf: $0) }
            typed.resolveTitle(for: list) { results.append($0) }
            return results
        }
        if let deleteTasks = intent as? INDeleteTasksIntent,
           let typed = handler as? any INDeleteTasksIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveTaskList(for: deleteTasks) { results.append($0) }
            typed.resolveTasks(for: deleteTasks) { results.append(contentsOf: $0) }
            return results
        }
        if let defroster = intent as? INSetDefrosterSettingsInCarIntent,
           let typed = handler as? any INSetDefrosterSettingsInCarIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCarName(for: defroster) { results.append($0) }
            typed.resolveDefroster(for: defroster) { results.append($0) }
            typed.resolveEnable(for: defroster) { results.append($0) }
            return results
        }
        if let defaults = intent as? INGetAvailableRestaurantReservationBookingDefaultsIntent,
           let typed = handler as? any INGetAvailableRestaurantReservationBookingDefaultsIntentHandling {
            var result: INRestaurantResolutionResult?
            typed.resolveRestaurant(for: defaults) { result = $0 }
            return [result ?? INRestaurantResolutionResult.needsValue()]
        }
        if let bookings = intent as? INGetAvailableRestaurantReservationBookingsIntent,
           let typed = handler as? any INGetAvailableRestaurantReservationBookingsIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolvePartySize(for: bookings) { results.append($0) }
            typed.resolvePreferredBookingDateComponents(for: bookings) { results.append($0) }
            typed.resolveRestaurant(for: bookings) { results.append($0) }
            return results
        }
        if let current = intent as? INGetUserCurrentRestaurantReservationBookingsIntent,
           let typed = handler as? any INGetUserCurrentRestaurantReservationBookingsIntentHandling {
            var result: INRestaurantResolutionResult?
            typed.resolveRestaurant(for: current) { result = $0 }
            return [result ?? INRestaurantResolutionResult.needsValue()]
        }
        if let addMedia = intent as? INAddMediaIntent,
           let typed = handler as? any INAddMediaIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveMediaDestination(for: addMedia) { results.append($0) }
            typed.resolveMediaItems(for: addMedia) { results.append(contentsOf: $0) }
            return results
        }
        if let activate = intent as? INActivateCarSignalIntent,
           let typed = handler as? any INActivateCarSignalIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCarName(for: activate) { results.append($0) }
            typed.resolveSignals(for: activate) { results.append($0) }
            return results
        }
        if let append = intent as? INAppendToNoteIntent,
           let typed = handler as? any INAppendToNoteIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveContent(for: append) { results.append($0) }
            typed.resolveTargetNote(for: append) { results.append($0) }
            return results
        }
        if let cancelWorkout = intent as? INCancelWorkoutIntent,
           let typed = handler as? any INCancelWorkoutIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveWorkoutName(for: cancelWorkout) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let edit = intent as? INEditMessageIntent,
           let typed = handler as? any INEditMessageIntentHandling {
            var result: INStringResolutionResult?
            typed.resolveEditedContent(for: edit) { result = $0 }
            return [result ?? INStringResolutionResult.needsValue()]
        }
        if let endWorkout = intent as? INEndWorkoutIntent,
           let typed = handler as? any INEndWorkoutIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveWorkoutName(for: endWorkout) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let lockStatus = intent as? INGetCarLockStatusIntent,
           let typed = handler as? any INGetCarLockStatusIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveCarName(for: lockStatus) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let visual = intent as? INGetVisualCodeIntent,
           let typed = handler as? any INGetVisualCodeIntentHandling {
            var result: INVisualCodeTypeResolutionResult?
            typed.resolveVisualCodeType(for: visual) { result = $0 }
            return [result ?? INVisualCodeTypeResolutionResult.needsValue()]
        }
        if let pause = intent as? INPauseWorkoutIntent,
           let typed = handler as? any INPauseWorkoutIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveWorkoutName(for: pause) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let resume = intent as? INResumeWorkoutIntent,
           let typed = handler as? any INResumeWorkoutIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveWorkoutName(for: resume) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let saveProfile = intent as? INSaveProfileInCarIntent,
           let typed = handler as? any INSaveProfileInCarIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveProfileName(for: saveProfile) { results.append($0) }
            typed.resolveProfileNumber(for: saveProfile) { results.append($0) }
            return results
        }
        if let searchMedia = intent as? INSearchForMediaIntent,
           let typed = handler as? any INSearchForMediaIntentHandling {
            var results: [INSearchForMediaMediaItemResolutionResult] = []
            typed.resolveMediaItems(for: searchMedia) { results = $0 }
            return results
        }
        if let audioSource = intent as? INSetAudioSourceInCarIntent,
           let typed = handler as? any INSetAudioSourceInCarIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAudioSource(for: audioSource) { results.append($0) }
            typed.resolveRelativeAudioSourceReference(for: audioSource) { results.append($0) }
            return results
        }
        if let lock = intent as? INSetCarLockStatusIntent,
           let typed = handler as? any INSetCarLockStatusIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCarName(for: lock) { results.append($0) }
            typed.resolveLocked(for: lock) { results.append($0) }
            return results
        }
        if let attribute = intent as? INSetMessageAttributeIntent,
           let typed = handler as? any INSetMessageAttributeIntentHandling {
            var result: INMessageAttributeResolutionResult?
            typed.resolveAttribute(for: attribute) { result = $0 }
            return [result ?? INMessageAttributeResolutionResult.needsValue()]
        }
        if let snooze = intent as? INSnoozeTasksIntent,
           let typed = handler as? any INSnoozeTasksIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveNextTriggerTime(for: snooze) { results.append($0) }
            typed.resolveTasks(for: snooze) { results.append(contentsOf: $0) }
            return results
        }
        if let audioCall = intent as? INStartAudioCallIntent,
           let typed = handler as? any INStartAudioCallIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveContacts(for: audioCall) { results.append(contentsOf: $0) }
            typed.resolveDestinationType(for: audioCall) { results.append($0) }
            return results
        }
        if let videoCall = intent as? INStartVideoCallIntent,
           let typed = handler as? any INStartVideoCallIntentHandling {
            var results: [INPersonResolutionResult] = []
            typed.resolveContacts(for: videoCall) { results = $0 }
            return results
        }
        if let affinity = intent as? INUpdateMediaAffinityIntent,
           let typed = handler as? any INUpdateMediaAffinityIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAffinityType(for: affinity) { results.append($0) }
            typed.resolveMediaItems(for: affinity) { results.append(contentsOf: $0) }
            return results
        }
        return [INIntentResolutionResult.needsValue()]
    }

    // Generic helpers open the existential so overloaded resolve methods
    // that differ only by completion type are not ambiguous.
    private static func resolveAddTasks<H: INAddTasksIntentHandling>(
        _ intent: INAddTasksIntent,
        handler: H
    ) -> [INIntentResolutionResult] {
        var results: [INIntentResolutionResult] = []
        handler.resolvePriority(for: intent) { results.append($0) }
        handler.resolveSpatialEventTrigger(for: intent) { results.append($0) }
        let specializedList: (INAddTasksTargetTaskListResolutionResult) -> Void = { results.append($0) }
        let legacyList: (INTaskListResolutionResult) -> Void = { results.append($0) }
        handler.resolveTargetTaskList(for: intent, completion: specializedList)
        handler.resolveTargetTaskList(for: intent, with: legacyList)
        handler.resolveTaskTitles(for: intent) { results.append(contentsOf: $0) }
        let specializedTrigger: (INAddTasksTemporalEventTriggerResolutionResult) -> Void = { results.append($0) }
        let legacyTrigger: (INTemporalEventTriggerResolutionResult) -> Void = { results.append($0) }
        handler.resolveTemporalEventTrigger(for: intent, completion: specializedTrigger)
        handler.resolveTemporalEventTrigger(for: intent, with: legacyTrigger)
        return results
    }

    private static func resolveSetTaskAttribute<H: INSetTaskAttributeIntentHandling>(
        _ intent: INSetTaskAttributeIntent,
        handler: H
    ) -> [INIntentResolutionResult] {
        var results: [INIntentResolutionResult] = []
        handler.resolvePriority(for: intent) { results.append($0) }
        handler.resolveSpatialEventTrigger(for: intent) { results.append($0) }
        handler.resolveStatus(for: intent) { results.append($0) }
        handler.resolveTargetTask(for: intent) { results.append($0) }
        handler.resolveTaskTitle(for: intent) { results.append($0) }
        let specializedTrigger: (INSetTaskAttributeTemporalEventTriggerResolutionResult) -> Void = { results.append($0) }
        let legacyTrigger: (INTemporalEventTriggerResolutionResult) -> Void = { results.append($0) }
        handler.resolveTemporalEventTrigger(for: intent, completion: specializedTrigger)
        handler.resolveTemporalEventTrigger(for: intent, with: legacyTrigger)
        return results
    }

    private static func resolveRequestPayment<H: INRequestPaymentIntentHandling>(
        _ intent: INRequestPaymentIntent,
        handler: H
    ) -> [INIntentResolutionResult] {
        var results: [INIntentResolutionResult] = []
        let specializedAmount: (INRequestPaymentCurrencyAmountResolutionResult) -> Void = { results.append($0) }
        let legacyAmount: (INCurrencyAmountResolutionResult) -> Void = { results.append($0) }
        handler.resolveCurrencyAmount(for: intent, completion: specializedAmount)
        handler.resolveCurrencyAmount(for: intent, with: legacyAmount)
        handler.resolveNote(for: intent) { results.append($0) }
        let specializedPayer: (INRequestPaymentPayerResolutionResult) -> Void = { results.append($0) }
        let legacyPayer: (INPersonResolutionResult) -> Void = { results.append($0) }
        handler.resolvePayer(for: intent, completion: specializedPayer)
        handler.resolvePayer(for: intent, with: legacyPayer)
        return results
    }

    private static func resolveSendPayment<H: INSendPaymentIntentHandling>(
        _ intent: INSendPaymentIntent,
        handler: H
    ) -> [INIntentResolutionResult] {
        var results: [INIntentResolutionResult] = []
        let specializedAmount: (INSendPaymentCurrencyAmountResolutionResult) -> Void = { results.append($0) }
        let legacyAmount: (INCurrencyAmountResolutionResult) -> Void = { results.append($0) }
        handler.resolveCurrencyAmount(for: intent, completion: specializedAmount)
        handler.resolveCurrencyAmount(for: intent, with: legacyAmount)
        handler.resolveNote(for: intent) { results.append($0) }
        let specializedPayee: (INSendPaymentPayeeResolutionResult) -> Void = { results.append($0) }
        let legacyPayee: (INPersonResolutionResult) -> Void = { results.append($0) }
        handler.resolvePayee(for: intent, completion: specializedPayee)
        handler.resolvePayee(for: intent, with: legacyPayee)
        return results
    }
}

extension INIntentResolutionResult {
    @_spi(OpenIntentsHost)
    public var linuxOutcomeCode: Int { outcome.rawValue }
}
