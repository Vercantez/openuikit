// Generated Intents handler protocols. Optional ObjC requirements become
// Swift defaults that fail closed rather than inventing Siri success.

public protocol INActivateCarSignalIntentHandling: NSObjectProtocol {
    func confirm(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse
    func handle(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse
    func resolveCarName(for intent: INActivateCarSignalIntent) async -> INSpeakableStringResolutionResult
    func resolveSignals(for intent: INActivateCarSignalIntent) async -> INCarSignalOptionsResolutionResult
}

public extension INActivateCarSignalIntentHandling {
    func confirm(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse { INActivateCarSignalIntentResponse() }
    func resolveCarName(for intent: INActivateCarSignalIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveSignals(for intent: INActivateCarSignalIntent) async -> INCarSignalOptionsResolutionResult { INCarSignalOptionsResolutionResult.needsValue() }
}

public protocol INAddMediaIntentHandling: NSObjectProtocol {
    func confirm(intent: INAddMediaIntent) async -> INAddMediaIntentResponse
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse
    func resolveMediaDestination(for intent: INAddMediaIntent) async -> INAddMediaMediaDestinationResolutionResult
    func resolveMediaItems(for intent: INAddMediaIntent) async -> [INAddMediaMediaItemResolutionResult]
}

public extension INAddMediaIntentHandling {
    func confirm(intent: INAddMediaIntent) async -> INAddMediaIntentResponse { INAddMediaIntentResponse() }
    func resolveMediaDestination(for intent: INAddMediaIntent) async -> INAddMediaMediaDestinationResolutionResult { INAddMediaMediaDestinationResolutionResult.needsValue() }
    func resolveMediaItems(for intent: INAddMediaIntent) async -> [INAddMediaMediaItemResolutionResult] { [] }
}

public protocol INAddTasksIntentHandling: NSObjectProtocol {
    func confirm(intent: INAddTasksIntent) async -> INAddTasksIntentResponse
    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse
    func resolvePriority(for intent: INAddTasksIntent) async -> INTaskPriorityResolutionResult
    func resolveSpatialEventTrigger(for intent: INAddTasksIntent) async -> INSpatialEventTriggerResolutionResult
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INAddTasksTargetTaskListResolutionResult
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INTaskListResolutionResult
    func resolveTaskTitles(for intent: INAddTasksIntent) async -> [INSpeakableStringResolutionResult]
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INAddTasksTemporalEventTriggerResolutionResult
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INTemporalEventTriggerResolutionResult
}

public extension INAddTasksIntentHandling {
    func confirm(intent: INAddTasksIntent) async -> INAddTasksIntentResponse { INAddTasksIntentResponse() }
    func resolvePriority(for intent: INAddTasksIntent) async -> INTaskPriorityResolutionResult { INTaskPriorityResolutionResult.needsValue() }
    func resolveSpatialEventTrigger(for intent: INAddTasksIntent) async -> INSpatialEventTriggerResolutionResult { INSpatialEventTriggerResolutionResult.needsValue() }
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INAddTasksTargetTaskListResolutionResult { INAddTasksTargetTaskListResolutionResult.needsValue() }
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INTaskListResolutionResult { INTaskListResolutionResult.needsValue() }
    func resolveTaskTitles(for intent: INAddTasksIntent) async -> [INSpeakableStringResolutionResult] { [] }
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INAddTasksTemporalEventTriggerResolutionResult { INAddTasksTemporalEventTriggerResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INTemporalEventTriggerResolutionResult { INTemporalEventTriggerResolutionResult.needsValue() }
}

public protocol INAnswerCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse
    func handle(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse
}

public extension INAnswerCallIntentHandling {
    func confirm(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse { INAnswerCallIntentResponse() }
}

public protocol INAppendToNoteIntentHandling: NSObjectProtocol {
    func confirm(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse
    func handle(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse
    func resolveContent(for intent: INAppendToNoteIntent) async -> INNoteContentResolutionResult
    func resolveTargetNote(for intent: INAppendToNoteIntent) async -> INNoteResolutionResult
}

public extension INAppendToNoteIntentHandling {
    func confirm(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse { INAppendToNoteIntentResponse() }
    func resolveContent(for intent: INAppendToNoteIntent) async -> INNoteContentResolutionResult { INNoteContentResolutionResult.needsValue() }
    func resolveTargetNote(for intent: INAppendToNoteIntent) async -> INNoteResolutionResult { INNoteResolutionResult.needsValue() }
}

public protocol INBookRestaurantReservationIntentHandling: NSObjectProtocol {
    func confirm(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse
    func handle(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse
    func resolveBookingDateComponents(for intent: INBookRestaurantReservationIntent) async -> INDateComponentsResolutionResult
    func resolveGuest(for intent: INBookRestaurantReservationIntent) async -> INRestaurantGuestResolutionResult
    func resolveGuestProvidedSpecialRequestText(for intent: INBookRestaurantReservationIntent) async -> INStringResolutionResult
    func resolvePartySize(for intent: INBookRestaurantReservationIntent) async -> INIntegerResolutionResult
    func resolveRestaurant(for intent: INBookRestaurantReservationIntent) async -> INRestaurantResolutionResult
}

public extension INBookRestaurantReservationIntentHandling {
    func confirm(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse { INBookRestaurantReservationIntentResponse() }
    func resolveBookingDateComponents(for intent: INBookRestaurantReservationIntent) async -> INDateComponentsResolutionResult { INDateComponentsResolutionResult.needsValue() }
    func resolveGuest(for intent: INBookRestaurantReservationIntent) async -> INRestaurantGuestResolutionResult { INRestaurantGuestResolutionResult.needsValue() }
    func resolveGuestProvidedSpecialRequestText(for intent: INBookRestaurantReservationIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolvePartySize(for intent: INBookRestaurantReservationIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveRestaurant(for intent: INBookRestaurantReservationIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
}

public protocol INCancelRideIntentHandling: NSObjectProtocol {
    func confirm(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse
    func handle(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse
}

public extension INCancelRideIntentHandling {
    func confirm(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse { INCancelRideIntentResponse() }
}

public protocol INCancelWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse
    func handle(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse
    func resolveWorkoutName(for intent: INCancelWorkoutIntent) async -> INSpeakableStringResolutionResult
}

public extension INCancelWorkoutIntentHandling {
    func confirm(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse { INCancelWorkoutIntentResponse() }
    func resolveWorkoutName(for intent: INCancelWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INCreateNoteIntentHandling: NSObjectProtocol {
    func confirm(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse
    func handle(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse
    func resolveContent(for intent: INCreateNoteIntent) async -> INNoteContentResolutionResult
    func resolveGroupName(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult
    func resolveTitle(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult
}

public extension INCreateNoteIntentHandling {
    func confirm(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse { INCreateNoteIntentResponse() }
    func resolveContent(for intent: INCreateNoteIntent) async -> INNoteContentResolutionResult { INNoteContentResolutionResult.needsValue() }
    func resolveGroupName(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTitle(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INCreateTaskListIntentHandling: NSObjectProtocol {
    func confirm(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse
    func handle(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse
    func resolveGroupName(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult
    func resolveTaskTitles(for intent: INCreateTaskListIntent) async -> [INSpeakableStringResolutionResult]
    func resolveTitle(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult
}

public extension INCreateTaskListIntentHandling {
    func confirm(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse { INCreateTaskListIntentResponse() }
    func resolveGroupName(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTaskTitles(for intent: INCreateTaskListIntent) async -> [INSpeakableStringResolutionResult] { [] }
    func resolveTitle(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INDeleteTasksIntentHandling: NSObjectProtocol {
    func confirm(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse
    func handle(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse
    func resolveTaskList(for intent: INDeleteTasksIntent) async -> INDeleteTasksTaskListResolutionResult
    func resolveTasks(for intent: INDeleteTasksIntent) async -> [INDeleteTasksTaskResolutionResult]
}

public extension INDeleteTasksIntentHandling {
    func confirm(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse { INDeleteTasksIntentResponse() }
    func resolveTaskList(for intent: INDeleteTasksIntent) async -> INDeleteTasksTaskListResolutionResult { INDeleteTasksTaskListResolutionResult.needsValue() }
    func resolveTasks(for intent: INDeleteTasksIntent) async -> [INDeleteTasksTaskResolutionResult] { [] }
}

public protocol INEditMessageIntentHandling: NSObjectProtocol {
    func confirm(intent: INEditMessageIntent) async -> INEditMessageIntentResponse
    func handle(intent: INEditMessageIntent) async -> INEditMessageIntentResponse
    func resolveEditedContent(for intent: INEditMessageIntent) async -> INStringResolutionResult
}

public extension INEditMessageIntentHandling {
    func confirm(intent: INEditMessageIntent) async -> INEditMessageIntentResponse { INEditMessageIntentResponse() }
    func resolveEditedContent(for intent: INEditMessageIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
}

public protocol INEndWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse
    func handle(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse
    func resolveWorkoutName(for intent: INEndWorkoutIntent) async -> INSpeakableStringResolutionResult
}

public extension INEndWorkoutIntentHandling {
    func confirm(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse { INEndWorkoutIntentResponse() }
    func resolveWorkoutName(for intent: INEndWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INGetAvailableRestaurantReservationBookingDefaultsIntentHandling: NSObjectProtocol {
    func confirm(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse
    func handle(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INRestaurantResolutionResult
}

public extension INGetAvailableRestaurantReservationBookingDefaultsIntentHandling {
    func confirm(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse { INGetAvailableRestaurantReservationBookingDefaultsIntentResponse() }
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
}

public protocol INGetAvailableRestaurantReservationBookingsIntentHandling: NSObjectProtocol {
    func confirm(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse
    func handle(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse
    func resolvePartySize(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INIntegerResolutionResult
    func resolvePreferredBookingDateComponents(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INDateComponentsResolutionResult
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult
}

public extension INGetAvailableRestaurantReservationBookingsIntentHandling {
    func confirm(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse { INGetAvailableRestaurantReservationBookingsIntentResponse() }
    func resolvePartySize(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolvePreferredBookingDateComponents(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INDateComponentsResolutionResult { INDateComponentsResolutionResult.needsValue() }
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
}

public protocol INGetCarLockStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse
    func handle(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse
    func resolveCarName(for intent: INGetCarLockStatusIntent) async -> INSpeakableStringResolutionResult
}

public extension INGetCarLockStatusIntentHandling {
    func confirm(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse { INGetCarLockStatusIntentResponse() }
    func resolveCarName(for intent: INGetCarLockStatusIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INGetCarPowerLevelStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INGetCarPowerLevelStatusIntent) async -> INGetCarPowerLevelStatusIntentResponse
    func handle(intent: INGetCarPowerLevelStatusIntent) async -> INGetCarPowerLevelStatusIntentResponse
    func confirm(intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INGetCarPowerLevelStatusIntentResponse) -> Void)
    func handle(intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INGetCarPowerLevelStatusIntentResponse) -> Void)
    func resolveCarName(for intent: INGetCarPowerLevelStatusIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func startSendingUpdates(for intent: INGetCarPowerLevelStatusIntent, to observer: any INGetCarPowerLevelStatusIntentResponseObserver)
    func stopSendingUpdates(for intent: INGetCarPowerLevelStatusIntent)
}

public extension INGetCarPowerLevelStatusIntentHandling {
    func confirm(intent: INGetCarPowerLevelStatusIntent) async -> INGetCarPowerLevelStatusIntentResponse {
        INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INGetCarPowerLevelStatusIntent) async -> INGetCarPowerLevelStatusIntentResponse {
        INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INGetCarPowerLevelStatusIntentResponse) -> Void) {
        completion(INGetCarPowerLevelStatusIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INGetCarPowerLevelStatusIntentResponse) -> Void) {
        completion(INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INGetCarPowerLevelStatusIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func startSendingUpdates(for intent: INGetCarPowerLevelStatusIntent, to observer: any INGetCarPowerLevelStatusIntentResponseObserver) { }
    func stopSendingUpdates(for intent: INGetCarPowerLevelStatusIntent) { }
}

public protocol INGetCarPowerLevelStatusIntentResponseObserver: NSObjectProtocol {
    func didUpdate(getCarPowerLevelStatus response: INGetCarPowerLevelStatusIntentResponse)
}

public protocol INGetRestaurantGuestIntentHandling: NSObjectProtocol {
    func confirm(getRestaurantGuest guestIntent: INGetRestaurantGuestIntent) async -> INGetRestaurantGuestIntentResponse
    func handle(getRestaurantGuest intent: INGetRestaurantGuestIntent) async -> INGetRestaurantGuestIntentResponse
}

public extension INGetRestaurantGuestIntentHandling {
    func confirm(getRestaurantGuest guestIntent: INGetRestaurantGuestIntent) async -> INGetRestaurantGuestIntentResponse { INGetRestaurantGuestIntentResponse() }
}

public protocol INGetRideStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INGetRideStatusIntent) async -> INGetRideStatusIntentResponse
    func handle(intent: INGetRideStatusIntent) async -> INGetRideStatusIntentResponse
    func confirm(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void)
    func handle(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void)
    func startSendingUpdates(for intent: INGetRideStatusIntent, to observer: any INGetRideStatusIntentResponseObserver)
    func stopSendingUpdates(for intent: INGetRideStatusIntent)
}

public extension INGetRideStatusIntentHandling {
    func confirm(intent: INGetRideStatusIntent) async -> INGetRideStatusIntentResponse {
        INGetRideStatusIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INGetRideStatusIntent) async -> INGetRideStatusIntentResponse {
        INGetRideStatusIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        completion(INGetRideStatusIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        completion(INGetRideStatusIntentResponse(code: .failure, userActivity: nil))
    }
    func startSendingUpdates(for intent: INGetRideStatusIntent, to observer: any INGetRideStatusIntentResponseObserver) { }
    func stopSendingUpdates(for intent: INGetRideStatusIntent) { }
}

public protocol INGetRideStatusIntentResponseObserver: NSObjectProtocol {
    func didUpdate(getRideStatus response: INGetRideStatusIntentResponse)
}

public protocol INGetUserCurrentRestaurantReservationBookingsIntentHandling: NSObjectProtocol {
    func confirm(getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INGetUserCurrentRestaurantReservationBookingsIntentResponse
    func handle(getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INGetUserCurrentRestaurantReservationBookingsIntentResponse
    func resolveRestaurant(for intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult
}

public extension INGetUserCurrentRestaurantReservationBookingsIntentHandling {
    func confirm(getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INGetUserCurrentRestaurantReservationBookingsIntentResponse { INGetUserCurrentRestaurantReservationBookingsIntentResponse() }
    func resolveRestaurant(for intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
}

public protocol INGetVisualCodeIntentHandling: NSObjectProtocol {
    func confirm(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse
    func handle(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent) async -> INVisualCodeTypeResolutionResult
}

public extension INGetVisualCodeIntentHandling {
    func confirm(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse { INGetVisualCodeIntentResponse() }
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent) async -> INVisualCodeTypeResolutionResult { INVisualCodeTypeResolutionResult.needsValue() }
}

public protocol INHangUpCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INHangUpCallIntent) async -> INHangUpCallIntentResponse
    func handle(intent: INHangUpCallIntent) async -> INHangUpCallIntentResponse
}

public extension INHangUpCallIntentHandling {
    func confirm(intent: INHangUpCallIntent) async -> INHangUpCallIntentResponse { INHangUpCallIntentResponse() }
}

public protocol INIntentHandlerProviding: NSObjectProtocol {
    func handler(for intent: INIntent) -> Any?
}

public protocol INListCarsIntentHandling: NSObjectProtocol {
    func confirm(intent: INListCarsIntent) async -> INListCarsIntentResponse
    func handle(intent: INListCarsIntent) async -> INListCarsIntentResponse
}

public extension INListCarsIntentHandling {
    func confirm(intent: INListCarsIntent) async -> INListCarsIntentResponse { INListCarsIntentResponse() }
}

public protocol INListRideOptionsIntentHandling: NSObjectProtocol {
    func confirm(intent: INListRideOptionsIntent) async -> INListRideOptionsIntentResponse
    func handle(intent: INListRideOptionsIntent) async -> INListRideOptionsIntentResponse
    func confirm(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void)
    func handle(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void)
    func resolveDropOffLocation(for intent: INListRideOptionsIntent) async -> INPlacemarkResolutionResult
    func resolvePickupLocation(for intent: INListRideOptionsIntent) async -> INPlacemarkResolutionResult
}

public extension INListRideOptionsIntentHandling {
    func confirm(intent: INListRideOptionsIntent) async -> INListRideOptionsIntentResponse {
        INListRideOptionsIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INListRideOptionsIntent) async -> INListRideOptionsIntentResponse {
        INListRideOptionsIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        completion(INListRideOptionsIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        completion(INListRideOptionsIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveDropOffLocation(for intent: INListRideOptionsIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolvePickupLocation(for intent: INListRideOptionsIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
}

public protocol INPauseWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INPauseWorkoutIntent) async -> INPauseWorkoutIntentResponse
    func handle(intent: INPauseWorkoutIntent) async -> INPauseWorkoutIntentResponse
    func resolveWorkoutName(for intent: INPauseWorkoutIntent) async -> INSpeakableStringResolutionResult
}

public extension INPauseWorkoutIntentHandling {
    func confirm(intent: INPauseWorkoutIntent) async -> INPauseWorkoutIntentResponse { INPauseWorkoutIntentResponse() }
    func resolveWorkoutName(for intent: INPauseWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INPayBillIntentHandling: NSObjectProtocol {
    func confirm(intent: INPayBillIntent) async -> INPayBillIntentResponse
    func handle(intent: INPayBillIntent) async -> INPayBillIntentResponse
    func resolveBillPayee(for intent: INPayBillIntent) async -> INBillPayeeResolutionResult
    func resolveBillType(for intent: INPayBillIntent) async -> INBillTypeResolutionResult
    func resolveDueDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult
    func resolveFromAccount(for intent: INPayBillIntent) async -> INPaymentAccountResolutionResult
    func resolveTransactionAmount(for intent: INPayBillIntent) async -> INPaymentAmountResolutionResult
    func resolveTransactionNote(for intent: INPayBillIntent) async -> INStringResolutionResult
    func resolveTransactionScheduledDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult
}

public extension INPayBillIntentHandling {
    func confirm(intent: INPayBillIntent) async -> INPayBillIntentResponse { INPayBillIntentResponse() }
    func resolveBillPayee(for intent: INPayBillIntent) async -> INBillPayeeResolutionResult { INBillPayeeResolutionResult.needsValue() }
    func resolveBillType(for intent: INPayBillIntent) async -> INBillTypeResolutionResult { INBillTypeResolutionResult.needsValue() }
    func resolveDueDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveFromAccount(for intent: INPayBillIntent) async -> INPaymentAccountResolutionResult { INPaymentAccountResolutionResult.needsValue() }
    func resolveTransactionAmount(for intent: INPayBillIntent) async -> INPaymentAmountResolutionResult { INPaymentAmountResolutionResult.needsValue() }
    func resolveTransactionNote(for intent: INPayBillIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveTransactionScheduledDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
}

public protocol INPlayMediaIntentHandling: NSObjectProtocol {
    func confirm(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult]
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult
    func resolveResumePlayback(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult
}

public extension INPlayMediaIntentHandling {
    func confirm(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse { INPlayMediaIntentResponse() }
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] { [] }
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult { INPlaybackQueueLocationResolutionResult.needsValue() }
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult { INPlaybackRepeatModeResolutionResult.needsValue() }
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult { INPlayMediaPlaybackSpeedResolutionResult.needsValue() }
    func resolveResumePlayback(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
}

public protocol INRequestPaymentIntentHandling: NSObjectProtocol {
    func confirm(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse
    func handle(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent) async -> INRequestPaymentCurrencyAmountResolutionResult
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void)
    func resolveNote(for intent: INRequestPaymentIntent) async -> INStringResolutionResult
    func resolvePayer(for intent: INRequestPaymentIntent) async -> INRequestPaymentPayerResolutionResult
    func resolvePayer(for intent: INRequestPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void)
}

public extension INRequestPaymentIntentHandling {
    func confirm(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse { INRequestPaymentIntentResponse() }
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent) async -> INRequestPaymentCurrencyAmountResolutionResult { INRequestPaymentCurrencyAmountResolutionResult.needsValue() }
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void) { completion(INCurrencyAmountResolutionResult.needsValue()) }
    func resolveNote(for intent: INRequestPaymentIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolvePayer(for intent: INRequestPaymentIntent) async -> INRequestPaymentPayerResolutionResult { INRequestPaymentPayerResolutionResult.needsValue() }
    func resolvePayer(for intent: INRequestPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void) { completion(INPersonResolutionResult.needsValue()) }
}

public protocol INRequestRideIntentHandling: NSObjectProtocol {
    func confirm(intent: INRequestRideIntent) async -> INRequestRideIntentResponse
    func handle(intent: INRequestRideIntent) async -> INRequestRideIntentResponse
    func confirm(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void)
    func handle(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void)
    func resolveDropOffLocation(for intent: INRequestRideIntent) async -> INPlacemarkResolutionResult
    func resolvePartySize(for intent: INRequestRideIntent) async -> INIntegerResolutionResult
    func resolvePartySize(for intent: INRequestRideIntent, completion: @escaping (INIntegerResolutionResult) -> Void)
    func resolvePickupLocation(for intent: INRequestRideIntent) async -> INPlacemarkResolutionResult
    func resolveRideOptionName(for intent: INRequestRideIntent) async -> INSpeakableStringResolutionResult
    func resolveRideOptionName(for intent: INRequestRideIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveScheduledPickupTime(for intent: INRequestRideIntent) async -> INDateComponentsRangeResolutionResult
    func resolveScheduledPickupTime(for intent: INRequestRideIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
}

public extension INRequestRideIntentHandling {
    func confirm(intent: INRequestRideIntent) async -> INRequestRideIntentResponse {
        INRequestRideIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INRequestRideIntent) async -> INRequestRideIntentResponse {
        INRequestRideIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        completion(INRequestRideIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        completion(INRequestRideIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveDropOffLocation(for intent: INRequestRideIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolvePartySize(for intent: INRequestRideIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolvePartySize(for intent: INRequestRideIntent, completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
    func resolvePickupLocation(for intent: INRequestRideIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolveRideOptionName(for intent: INRequestRideIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveRideOptionName(for intent: INRequestRideIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveScheduledPickupTime(for intent: INRequestRideIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveScheduledPickupTime(for intent: INRequestRideIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
}

public protocol INResumeWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INResumeWorkoutIntent) async -> INResumeWorkoutIntentResponse
    func handle(intent: INResumeWorkoutIntent) async -> INResumeWorkoutIntentResponse
    func resolveWorkoutName(for intent: INResumeWorkoutIntent) async -> INSpeakableStringResolutionResult
}

public extension INResumeWorkoutIntentHandling {
    func confirm(intent: INResumeWorkoutIntent) async -> INResumeWorkoutIntentResponse { INResumeWorkoutIntentResponse() }
    func resolveWorkoutName(for intent: INResumeWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INSaveProfileInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse
    func handle(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse
    func resolveProfileName(for intent: INSaveProfileInCarIntent) async -> INStringResolutionResult
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent) async -> INIntegerResolutionResult
}

public extension INSaveProfileInCarIntentHandling {
    func confirm(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse { INSaveProfileInCarIntentResponse() }
    func resolveProfileName(for intent: INSaveProfileInCarIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
}

public protocol INSearchCallHistoryIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse
    func handle(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse
    func resolveCallType(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeResolutionResult
    func resolveCallTypes(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeOptionsResolutionResult
    func resolveDateCreated(for intent: INSearchCallHistoryIntent) async -> INDateComponentsRangeResolutionResult
    func resolveRecipient(for intent: INSearchCallHistoryIntent) async -> INPersonResolutionResult
    func resolveUnseen(for intent: INSearchCallHistoryIntent) async -> INBooleanResolutionResult
}

public extension INSearchCallHistoryIntentHandling {
    func confirm(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse { INSearchCallHistoryIntentResponse() }
    func resolveCallType(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeResolutionResult { INCallRecordTypeResolutionResult.needsValue() }
    func resolveCallTypes(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeOptionsResolutionResult { INCallRecordTypeOptionsResolutionResult.needsValue() }
    func resolveDateCreated(for intent: INSearchCallHistoryIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveRecipient(for intent: INSearchCallHistoryIntent) async -> INPersonResolutionResult { INPersonResolutionResult.needsValue() }
    func resolveUnseen(for intent: INSearchCallHistoryIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
}

public protocol INSearchForAccountsIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse
    func handle(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse
    func resolveAccountNickname(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult
    func resolveAccountType(for intent: INSearchForAccountsIntent) async -> INAccountTypeResolutionResult
    func resolveOrganizationName(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult
    func resolveRequestedBalanceType(for intent: INSearchForAccountsIntent) async -> INBalanceTypeResolutionResult
}

public extension INSearchForAccountsIntentHandling {
    func confirm(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse { INSearchForAccountsIntentResponse() }
    func resolveAccountNickname(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveAccountType(for intent: INSearchForAccountsIntent) async -> INAccountTypeResolutionResult { INAccountTypeResolutionResult.needsValue() }
    func resolveOrganizationName(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveRequestedBalanceType(for intent: INSearchForAccountsIntent) async -> INBalanceTypeResolutionResult { INBalanceTypeResolutionResult.needsValue() }
}

public protocol INSearchForBillsIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse
    func handle(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse
    func resolveBillPayee(for intent: INSearchForBillsIntent) async -> INBillPayeeResolutionResult
    func resolveBillType(for intent: INSearchForBillsIntent) async -> INBillTypeResolutionResult
    func resolveDueDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult
    func resolvePaymentDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult
    func resolveStatus(for intent: INSearchForBillsIntent) async -> INPaymentStatusResolutionResult
}

public extension INSearchForBillsIntentHandling {
    func confirm(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse { INSearchForBillsIntentResponse() }
    func resolveBillPayee(for intent: INSearchForBillsIntent) async -> INBillPayeeResolutionResult { INBillPayeeResolutionResult.needsValue() }
    func resolveBillType(for intent: INSearchForBillsIntent) async -> INBillTypeResolutionResult { INBillTypeResolutionResult.needsValue() }
    func resolveDueDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolvePaymentDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveStatus(for intent: INSearchForBillsIntent) async -> INPaymentStatusResolutionResult { INPaymentStatusResolutionResult.needsValue() }
}

public protocol INSearchForMediaIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse
    func handle(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse
    func resolveMediaItems(for intent: INSearchForMediaIntent) async -> [INSearchForMediaMediaItemResolutionResult]
}

public extension INSearchForMediaIntentHandling {
    func confirm(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse { INSearchForMediaIntentResponse() }
    func resolveMediaItems(for intent: INSearchForMediaIntent) async -> [INSearchForMediaMediaItemResolutionResult] { [] }
}

public protocol INSearchForMessagesIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForMessagesIntent) async -> INSearchForMessagesIntentResponse
    func handle(intent: INSearchForMessagesIntent) async -> INSearchForMessagesIntentResponse
    func confirm(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void)
    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void)
    func resolveAttributes(for intent: INSearchForMessagesIntent) async -> INMessageAttributeOptionsResolutionResult
    func resolveAttributes(for intent: INSearchForMessagesIntent, completion: @escaping (INMessageAttributeOptionsResolutionResult) -> Void)
    func resolveDateTimeRange(for intent: INSearchForMessagesIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDateTimeRange(for intent: INSearchForMessagesIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveGroupNames(for intent: INSearchForMessagesIntent, with completion: @escaping ([INStringResolutionResult]) -> Void)
    func resolveRecipients(for intent: INSearchForMessagesIntent) async -> [INPersonResolutionResult]
    func resolveSenders(for intent: INSearchForMessagesIntent) async -> [INPersonResolutionResult]
    func resolveSpeakableGroupNames(for intent: INSearchForMessagesIntent) async -> [INSpeakableStringResolutionResult]
}

public extension INSearchForMessagesIntentHandling {
    func confirm(intent: INSearchForMessagesIntent) async -> INSearchForMessagesIntentResponse {
        INSearchForMessagesIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSearchForMessagesIntent) async -> INSearchForMessagesIntentResponse {
        INSearchForMessagesIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        completion(INSearchForMessagesIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        completion(INSearchForMessagesIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAttributes(for intent: INSearchForMessagesIntent) async -> INMessageAttributeOptionsResolutionResult { INMessageAttributeOptionsResolutionResult.needsValue() }
    func resolveAttributes(for intent: INSearchForMessagesIntent, completion: @escaping (INMessageAttributeOptionsResolutionResult) -> Void) {
        completion(INMessageAttributeOptionsResolutionResult.needsValue())
    }
    func resolveDateTimeRange(for intent: INSearchForMessagesIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDateTimeRange(for intent: INSearchForMessagesIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveGroupNames(for intent: INSearchForMessagesIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
        completion([INStringResolutionResult.needsValue()])
    }
    func resolveRecipients(for intent: INSearchForMessagesIntent) async -> [INPersonResolutionResult] { [] }
    func resolveSenders(for intent: INSearchForMessagesIntent) async -> [INPersonResolutionResult] { [] }
    func resolveSpeakableGroupNames(for intent: INSearchForMessagesIntent) async -> [INSpeakableStringResolutionResult] { [] }
}

public protocol INSearchForNotebookItemsIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse
    func handle(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse
    func resolveContent(for intent: INSearchForNotebookItemsIntent) async -> INStringResolutionResult
    func resolveDateSearchType(for intent: INSearchForNotebookItemsIntent) async -> INDateSearchTypeResolutionResult
    func resolveDateTime(for intent: INSearchForNotebookItemsIntent) async -> INDateComponentsRangeResolutionResult
    func resolveItemType(for intent: INSearchForNotebookItemsIntent) async -> INNotebookItemTypeResolutionResult
    func resolveLocation(for intent: INSearchForNotebookItemsIntent) async -> INPlacemarkResolutionResult
    func resolveLocationSearchType(for intent: INSearchForNotebookItemsIntent) async -> INLocationSearchTypeResolutionResult
    func resolveStatus(for intent: INSearchForNotebookItemsIntent) async -> INTaskStatusResolutionResult
    func resolveTaskPriority(for intent: INSearchForNotebookItemsIntent) async -> INTaskPriorityResolutionResult
    func resolveTemporalEventTriggerTypes(for intent: INSearchForNotebookItemsIntent) async -> INTemporalEventTriggerTypeOptionsResolutionResult
    func resolveTitle(for intent: INSearchForNotebookItemsIntent) async -> INSpeakableStringResolutionResult
}

public extension INSearchForNotebookItemsIntentHandling {
    func confirm(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse { INSearchForNotebookItemsIntentResponse() }
    func resolveContent(for intent: INSearchForNotebookItemsIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveDateSearchType(for intent: INSearchForNotebookItemsIntent) async -> INDateSearchTypeResolutionResult { INDateSearchTypeResolutionResult.needsValue() }
    func resolveDateTime(for intent: INSearchForNotebookItemsIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveItemType(for intent: INSearchForNotebookItemsIntent) async -> INNotebookItemTypeResolutionResult { INNotebookItemTypeResolutionResult.needsValue() }
    func resolveLocation(for intent: INSearchForNotebookItemsIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolveLocationSearchType(for intent: INSearchForNotebookItemsIntent) async -> INLocationSearchTypeResolutionResult { INLocationSearchTypeResolutionResult.needsValue() }
    func resolveStatus(for intent: INSearchForNotebookItemsIntent) async -> INTaskStatusResolutionResult { INTaskStatusResolutionResult.needsValue() }
    func resolveTaskPriority(for intent: INSearchForNotebookItemsIntent) async -> INTaskPriorityResolutionResult { INTaskPriorityResolutionResult.needsValue() }
    func resolveTemporalEventTriggerTypes(for intent: INSearchForNotebookItemsIntent) async -> INTemporalEventTriggerTypeOptionsResolutionResult { INTemporalEventTriggerTypeOptionsResolutionResult.needsValue() }
    func resolveTitle(for intent: INSearchForNotebookItemsIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INSearchForPhotosIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse
    func handle(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse
    func resolveAlbumName(for intent: INSearchForPhotosIntent) async -> INStringResolutionResult
    func resolveDateCreated(for intent: INSearchForPhotosIntent) async -> INDateComponentsRangeResolutionResult
    func resolveLocationCreated(for intent: INSearchForPhotosIntent) async -> INPlacemarkResolutionResult
    func resolvePeopleInPhoto(for intent: INSearchForPhotosIntent) async -> [INPersonResolutionResult]
    func resolveSearchTerms(for intent: INSearchForPhotosIntent) async -> [INStringResolutionResult]
}

public extension INSearchForPhotosIntentHandling {
    func confirm(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse { INSearchForPhotosIntentResponse() }
    func resolveAlbumName(for intent: INSearchForPhotosIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveDateCreated(for intent: INSearchForPhotosIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveLocationCreated(for intent: INSearchForPhotosIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolvePeopleInPhoto(for intent: INSearchForPhotosIntent) async -> [INPersonResolutionResult] { [] }
    func resolveSearchTerms(for intent: INSearchForPhotosIntent) async -> [INStringResolutionResult] { [] }
}

public protocol INSendMessageIntentHandling: NSObjectProtocol {
    func confirm(intent: INSendMessageIntent) async -> INSendMessageIntentResponse
    func handle(intent: INSendMessageIntent) async -> INSendMessageIntentResponse
    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void)
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void)
    func resolveContent(for intent: INSendMessageIntent) async -> INStringResolutionResult
    func resolveContent(for intent: INSendMessageIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolveGroupName(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolveOutgoingMessageType(for intent: INSendMessageIntent) async -> INOutgoingMessageTypeResolutionResult
    func resolveRecipients(for intent: INSendMessageIntent) async -> [INSendMessageRecipientResolutionResult]
    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void)
    func resolveSpeakableGroupName(for intent: INSendMessageIntent) async -> INSpeakableStringResolutionResult
    func resolveSpeakableGroupName(for intent: INSendMessageIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INSendMessageIntentHandling {
    func confirm(intent: INSendMessageIntent) async -> INSendMessageIntentResponse {
        INSendMessageIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSendMessageIntent) async -> INSendMessageIntentResponse {
        INSendMessageIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        completion(INSendMessageIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        completion(INSendMessageIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveContent(for intent: INSendMessageIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveContent(for intent: INSendMessageIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveGroupName(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveOutgoingMessageType(for intent: INSendMessageIntent) async -> INOutgoingMessageTypeResolutionResult { INOutgoingMessageTypeResolutionResult.needsValue() }
    func resolveRecipients(for intent: INSendMessageIntent) async -> [INSendMessageRecipientResolutionResult] { [] }
    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([INPersonResolutionResult.needsValue()])
    }
    func resolveSpeakableGroupName(for intent: INSendMessageIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveSpeakableGroupName(for intent: INSendMessageIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INSendPaymentIntentHandling: NSObjectProtocol {
    func confirm(intent: INSendPaymentIntent) async -> INSendPaymentIntentResponse
    func handle(intent: INSendPaymentIntent) async -> INSendPaymentIntentResponse
    func resolveCurrencyAmount(for intent: INSendPaymentIntent) async -> INSendPaymentCurrencyAmountResolutionResult
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void)
    func resolveNote(for intent: INSendPaymentIntent) async -> INStringResolutionResult
    func resolvePayee(for intent: INSendPaymentIntent) async -> INSendPaymentPayeeResolutionResult
    func resolvePayee(for intent: INSendPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void)
}

public extension INSendPaymentIntentHandling {
    func confirm(intent: INSendPaymentIntent) async -> INSendPaymentIntentResponse { INSendPaymentIntentResponse() }
    func resolveCurrencyAmount(for intent: INSendPaymentIntent) async -> INSendPaymentCurrencyAmountResolutionResult { INSendPaymentCurrencyAmountResolutionResult.needsValue() }
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void) { completion(INCurrencyAmountResolutionResult.needsValue()) }
    func resolveNote(for intent: INSendPaymentIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolvePayee(for intent: INSendPaymentIntent) async -> INSendPaymentPayeeResolutionResult { INSendPaymentPayeeResolutionResult.needsValue() }
    func resolvePayee(for intent: INSendPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void) { completion(INPersonResolutionResult.needsValue()) }
}

public protocol INSendRideFeedbackIntentHandling: NSObjectProtocol {
    func confirm(sendRideFeedback sendRideFeedbackIntent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse
}

public extension INSendRideFeedbackIntentHandling {
    func confirm(sendRideFeedback sendRideFeedbackIntent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse { INSendRideFeedbackIntentResponse() }
}

public protocol INSetAudioSourceInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse
    func handle(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent) async -> INCarAudioSourceResolutionResult
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent) async -> INRelativeReferenceResolutionResult
}

public extension INSetAudioSourceInCarIntentHandling {
    func confirm(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse { INSetAudioSourceInCarIntentResponse() }
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent) async -> INCarAudioSourceResolutionResult { INCarAudioSourceResolutionResult.needsValue() }
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent) async -> INRelativeReferenceResolutionResult { INRelativeReferenceResolutionResult.needsValue() }
}

public protocol INSetCarLockStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse
    func handle(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse
    func resolveCarName(for intent: INSetCarLockStatusIntent) async -> INSpeakableStringResolutionResult
    func resolveLocked(for intent: INSetCarLockStatusIntent) async -> INBooleanResolutionResult
}

public extension INSetCarLockStatusIntentHandling {
    func confirm(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse { INSetCarLockStatusIntentResponse() }
    func resolveCarName(for intent: INSetCarLockStatusIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveLocked(for intent: INSetCarLockStatusIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
}

public protocol INSetClimateSettingsInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse
    func handle(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse
    func resolveAirCirculationMode(for intent: INSetClimateSettingsInCarIntent) async -> INCarAirCirculationModeResolutionResult
    func resolveCarName(for intent: INSetClimateSettingsInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveClimateZone(for intent: INSetClimateSettingsInCarIntent) async -> INCarSeatResolutionResult
    func resolveEnableAirConditioner(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableAutoMode(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableClimateControl(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableFan(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveFanSpeedIndex(for intent: INSetClimateSettingsInCarIntent) async -> INIntegerResolutionResult
    func resolveFanSpeedPercentage(for intent: INSetClimateSettingsInCarIntent) async -> INDoubleResolutionResult
    func resolveRelativeFanSpeedSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult
    func resolveRelativeTemperatureSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult
    func resolveTemperature(for intent: INSetClimateSettingsInCarIntent) async -> INTemperatureResolutionResult
}

public extension INSetClimateSettingsInCarIntentHandling {
    func confirm(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse { INSetClimateSettingsInCarIntentResponse() }
    func resolveAirCirculationMode(for intent: INSetClimateSettingsInCarIntent) async -> INCarAirCirculationModeResolutionResult { INCarAirCirculationModeResolutionResult.needsValue() }
    func resolveCarName(for intent: INSetClimateSettingsInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveClimateZone(for intent: INSetClimateSettingsInCarIntent) async -> INCarSeatResolutionResult { INCarSeatResolutionResult.needsValue() }
    func resolveEnableAirConditioner(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableAutoMode(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableClimateControl(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableFan(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveFanSpeedIndex(for intent: INSetClimateSettingsInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveFanSpeedPercentage(for intent: INSetClimateSettingsInCarIntent) async -> INDoubleResolutionResult { INDoubleResolutionResult.needsValue() }
    func resolveRelativeFanSpeedSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult { INRelativeSettingResolutionResult.needsValue() }
    func resolveRelativeTemperatureSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult { INRelativeSettingResolutionResult.needsValue() }
    func resolveTemperature(for intent: INSetClimateSettingsInCarIntent) async -> INTemperatureResolutionResult { INTemperatureResolutionResult.needsValue() }
}

public protocol INSetDefrosterSettingsInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse
    func handle(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse
    func resolveCarName(for intent: INSetDefrosterSettingsInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveDefroster(for intent: INSetDefrosterSettingsInCarIntent) async -> INCarDefrosterResolutionResult
    func resolveEnable(for intent: INSetDefrosterSettingsInCarIntent) async -> INBooleanResolutionResult
}

public extension INSetDefrosterSettingsInCarIntentHandling {
    func confirm(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse { INSetDefrosterSettingsInCarIntentResponse() }
    func resolveCarName(for intent: INSetDefrosterSettingsInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveDefroster(for intent: INSetDefrosterSettingsInCarIntent) async -> INCarDefrosterResolutionResult { INCarDefrosterResolutionResult.needsValue() }
    func resolveEnable(for intent: INSetDefrosterSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
}

public protocol INSetMessageAttributeIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse
    func handle(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse
    func resolveAttribute(for intent: INSetMessageAttributeIntent) async -> INMessageAttributeResolutionResult
}

public extension INSetMessageAttributeIntentHandling {
    func confirm(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse { INSetMessageAttributeIntentResponse() }
    func resolveAttribute(for intent: INSetMessageAttributeIntent) async -> INMessageAttributeResolutionResult { INMessageAttributeResolutionResult.needsValue() }
}

public protocol INSetProfileInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse
    func handle(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse
    func resolveCarName(for intent: INSetProfileInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveDefaultProfile(forSetProfileInCar intent: INSetProfileInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveProfileName(for intent: INSetProfileInCarIntent) async -> INStringResolutionResult
    func resolveProfileNumber(for intent: INSetProfileInCarIntent) async -> INIntegerResolutionResult
}

public extension INSetProfileInCarIntentHandling {
    func confirm(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse { INSetProfileInCarIntentResponse() }
    func resolveCarName(for intent: INSetProfileInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveDefaultProfile(forSetProfileInCar intent: INSetProfileInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) { completion(INBooleanResolutionResult.needsValue()) }
    func resolveProfileName(for intent: INSetProfileInCarIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveProfileNumber(for intent: INSetProfileInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
}

public protocol INSetRadioStationIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse
    func handle(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse
    func resolveChannel(for intent: INSetRadioStationIntent) async -> INStringResolutionResult
    func resolveFrequency(for intent: INSetRadioStationIntent) async -> INDoubleResolutionResult
    func resolvePresetNumber(for intent: INSetRadioStationIntent) async -> INIntegerResolutionResult
    func resolveRadioType(for intent: INSetRadioStationIntent) async -> INRadioTypeResolutionResult
    func resolveStationName(for intent: INSetRadioStationIntent) async -> INStringResolutionResult
}

public extension INSetRadioStationIntentHandling {
    func confirm(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse { INSetRadioStationIntentResponse() }
    func resolveChannel(for intent: INSetRadioStationIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveFrequency(for intent: INSetRadioStationIntent) async -> INDoubleResolutionResult { INDoubleResolutionResult.needsValue() }
    func resolvePresetNumber(for intent: INSetRadioStationIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveRadioType(for intent: INSetRadioStationIntent) async -> INRadioTypeResolutionResult { INRadioTypeResolutionResult.needsValue() }
    func resolveStationName(for intent: INSetRadioStationIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
}

public protocol INSetSeatSettingsInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse
    func handle(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse
    func resolveCarName(for intent: INSetSeatSettingsInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveEnableCooling(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableHeating(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableMassage(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveLevel(for intent: INSetSeatSettingsInCarIntent) async -> INIntegerResolutionResult
    func resolveRelativeLevelSetting(for intent: INSetSeatSettingsInCarIntent) async -> INRelativeSettingResolutionResult
    func resolveSeat(for intent: INSetSeatSettingsInCarIntent) async -> INCarSeatResolutionResult
}

public extension INSetSeatSettingsInCarIntentHandling {
    func confirm(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse { INSetSeatSettingsInCarIntentResponse() }
    func resolveCarName(for intent: INSetSeatSettingsInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveEnableCooling(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableHeating(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableMassage(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveLevel(for intent: INSetSeatSettingsInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveRelativeLevelSetting(for intent: INSetSeatSettingsInCarIntent) async -> INRelativeSettingResolutionResult { INRelativeSettingResolutionResult.needsValue() }
    func resolveSeat(for intent: INSetSeatSettingsInCarIntent) async -> INCarSeatResolutionResult { INCarSeatResolutionResult.needsValue() }
}

public protocol INSetTaskAttributeIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse
    func handle(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse
    func resolvePriority(for intent: INSetTaskAttributeIntent) async -> INTaskPriorityResolutionResult
    func resolveSpatialEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSpatialEventTriggerResolutionResult
    func resolveStatus(for intent: INSetTaskAttributeIntent) async -> INTaskStatusResolutionResult
    func resolveTargetTask(for intent: INSetTaskAttributeIntent) async -> INTaskResolutionResult
    func resolveTaskTitle(for intent: INSetTaskAttributeIntent) async -> INSpeakableStringResolutionResult
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeTemporalEventTriggerResolutionResult
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INTemporalEventTriggerResolutionResult
}

public extension INSetTaskAttributeIntentHandling {
    func confirm(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse { INSetTaskAttributeIntentResponse() }
    func resolvePriority(for intent: INSetTaskAttributeIntent) async -> INTaskPriorityResolutionResult { INTaskPriorityResolutionResult.needsValue() }
    func resolveSpatialEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSpatialEventTriggerResolutionResult { INSpatialEventTriggerResolutionResult.needsValue() }
    func resolveStatus(for intent: INSetTaskAttributeIntent) async -> INTaskStatusResolutionResult { INTaskStatusResolutionResult.needsValue() }
    func resolveTargetTask(for intent: INSetTaskAttributeIntent) async -> INTaskResolutionResult { INTaskResolutionResult.needsValue() }
    func resolveTaskTitle(for intent: INSetTaskAttributeIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeTemporalEventTriggerResolutionResult { INSetTaskAttributeTemporalEventTriggerResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INTemporalEventTriggerResolutionResult { INTemporalEventTriggerResolutionResult.needsValue() }
}

public protocol INShareFocusStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INShareFocusStatusIntent) async -> INShareFocusStatusIntentResponse
    func handle(intent: INShareFocusStatusIntent) async -> INShareFocusStatusIntentResponse
}

public extension INShareFocusStatusIntentHandling {
    func confirm(intent: INShareFocusStatusIntent) async -> INShareFocusStatusIntentResponse { INShareFocusStatusIntentResponse() }
}

public protocol INSnoozeTasksIntentHandling: NSObjectProtocol {
    func confirm(intent: INSnoozeTasksIntent) async -> INSnoozeTasksIntentResponse
    func handle(intent: INSnoozeTasksIntent) async -> INSnoozeTasksIntentResponse
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent) async -> INDateComponentsRangeResolutionResult
    func resolveTasks(for intent: INSnoozeTasksIntent) async -> [INSnoozeTasksTaskResolutionResult]
}

public extension INSnoozeTasksIntentHandling {
    func confirm(intent: INSnoozeTasksIntent) async -> INSnoozeTasksIntentResponse { INSnoozeTasksIntentResponse() }
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveTasks(for intent: INSnoozeTasksIntent) async -> [INSnoozeTasksTaskResolutionResult] { [] }
}

public protocol INSpeakable: NSObjectProtocol {
}

public protocol INStartAudioCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse
    func handle(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse
    func resolveContacts(for intent: INStartAudioCallIntent) async -> [INPersonResolutionResult]
    func resolveDestinationType(for intent: INStartAudioCallIntent) async -> INCallDestinationTypeResolutionResult
}

public extension INStartAudioCallIntentHandling {
    func confirm(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse { INStartAudioCallIntentResponse() }
    func resolveContacts(for intent: INStartAudioCallIntent) async -> [INPersonResolutionResult] { [] }
    func resolveDestinationType(for intent: INStartAudioCallIntent) async -> INCallDestinationTypeResolutionResult { INCallDestinationTypeResolutionResult.needsValue() }
}

public protocol INStartCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartCallIntent) async -> INStartCallIntentResponse
    func handle(intent: INStartCallIntent) async -> INStartCallIntentResponse
    func confirm(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void)
    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void)
    func resolveCallCapability(for intent: INStartCallIntent) async -> INStartCallCallCapabilityResolutionResult
    func resolveCallCapability(for intent: INStartCallIntent, completion: @escaping (INStartCallCallCapabilityResolutionResult) -> Void)
    func resolveCallRecordToCallBack(for intent: INStartCallIntent) async -> INCallRecordResolutionResult
    func resolveContacts(for intent: INStartCallIntent) async -> [INStartCallContactResolutionResult]
    func resolveDestinationType(for intent: INStartCallIntent) async -> INCallDestinationTypeResolutionResult
    func resolveDestinationType(for intent: INStartCallIntent, completion: @escaping (INCallDestinationTypeResolutionResult) -> Void)
}

public extension INStartCallIntentHandling {
    func confirm(intent: INStartCallIntent) async -> INStartCallIntentResponse {
        INStartCallIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INStartCallIntent) async -> INStartCallIntentResponse {
        INStartCallIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        completion(INStartCallIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        completion(INStartCallIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCallCapability(for intent: INStartCallIntent) async -> INStartCallCallCapabilityResolutionResult { INStartCallCallCapabilityResolutionResult.needsValue() }
    func resolveCallCapability(for intent: INStartCallIntent, completion: @escaping (INStartCallCallCapabilityResolutionResult) -> Void) {
        completion(INStartCallCallCapabilityResolutionResult.needsValue())
    }
    func resolveCallRecordToCallBack(for intent: INStartCallIntent) async -> INCallRecordResolutionResult { INCallRecordResolutionResult.needsValue() }
    func resolveContacts(for intent: INStartCallIntent) async -> [INStartCallContactResolutionResult] { [] }
    func resolveDestinationType(for intent: INStartCallIntent) async -> INCallDestinationTypeResolutionResult { INCallDestinationTypeResolutionResult.needsValue() }
    func resolveDestinationType(for intent: INStartCallIntent, completion: @escaping (INCallDestinationTypeResolutionResult) -> Void) {
        completion(INCallDestinationTypeResolutionResult.needsValue())
    }
}

public protocol INStartPhotoPlaybackIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartPhotoPlaybackIntent) async -> INStartPhotoPlaybackIntentResponse
    func handle(intent: INStartPhotoPlaybackIntent) async -> INStartPhotoPlaybackIntentResponse
    func resolveAlbumName(for intent: INStartPhotoPlaybackIntent) async -> INStringResolutionResult
    func resolveDateCreated(for intent: INStartPhotoPlaybackIntent) async -> INDateComponentsRangeResolutionResult
    func resolveLocationCreated(for intent: INStartPhotoPlaybackIntent) async -> INPlacemarkResolutionResult
    func resolvePeopleInPhoto(for intent: INStartPhotoPlaybackIntent) async -> [INPersonResolutionResult]
}

public extension INStartPhotoPlaybackIntentHandling {
    func confirm(intent: INStartPhotoPlaybackIntent) async -> INStartPhotoPlaybackIntentResponse { INStartPhotoPlaybackIntentResponse() }
    func resolveAlbumName(for intent: INStartPhotoPlaybackIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveDateCreated(for intent: INStartPhotoPlaybackIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveLocationCreated(for intent: INStartPhotoPlaybackIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolvePeopleInPhoto(for intent: INStartPhotoPlaybackIntent) async -> [INPersonResolutionResult] { [] }
}

public protocol INStartVideoCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse
    func handle(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse
    func resolveContacts(for intent: INStartVideoCallIntent) async -> [INPersonResolutionResult]
}

public extension INStartVideoCallIntentHandling {
    func confirm(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse { INStartVideoCallIntentResponse() }
    func resolveContacts(for intent: INStartVideoCallIntent) async -> [INPersonResolutionResult] { [] }
}

public protocol INStartWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse
    func handle(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse
    func resolveGoalValue(for intent: INStartWorkoutIntent) async -> INDoubleResolutionResult
    func resolveIsOpenEnded(for intent: INStartWorkoutIntent) async -> INBooleanResolutionResult
    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent) async -> INWorkoutGoalUnitTypeResolutionResult
    func resolveWorkoutLocationType(for intent: INStartWorkoutIntent) async -> INWorkoutLocationTypeResolutionResult
    func resolveWorkoutName(for intent: INStartWorkoutIntent) async -> INSpeakableStringResolutionResult
}

public extension INStartWorkoutIntentHandling {
    func confirm(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse { INStartWorkoutIntentResponse() }
    func resolveGoalValue(for intent: INStartWorkoutIntent) async -> INDoubleResolutionResult { INDoubleResolutionResult.needsValue() }
    func resolveIsOpenEnded(for intent: INStartWorkoutIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent) async -> INWorkoutGoalUnitTypeResolutionResult { INWorkoutGoalUnitTypeResolutionResult.needsValue() }
    func resolveWorkoutLocationType(for intent: INStartWorkoutIntent) async -> INWorkoutLocationTypeResolutionResult { INWorkoutLocationTypeResolutionResult.needsValue() }
    func resolveWorkoutName(for intent: INStartWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
}

public protocol INTransferMoneyIntentHandling: NSObjectProtocol {
    func confirm(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse
    func handle(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse
    func resolveFromAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult
    func resolveToAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult
    func resolveTransactionAmount(for intent: INTransferMoneyIntent) async -> INPaymentAmountResolutionResult
    func resolveTransactionNote(for intent: INTransferMoneyIntent) async -> INStringResolutionResult
    func resolveTransactionScheduledDate(for intent: INTransferMoneyIntent) async -> INDateComponentsRangeResolutionResult
}

public extension INTransferMoneyIntentHandling {
    func confirm(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse { INTransferMoneyIntentResponse() }
    func resolveFromAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult { INPaymentAccountResolutionResult.needsValue() }
    func resolveToAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult { INPaymentAccountResolutionResult.needsValue() }
    func resolveTransactionAmount(for intent: INTransferMoneyIntent) async -> INPaymentAmountResolutionResult { INPaymentAmountResolutionResult.needsValue() }
    func resolveTransactionNote(for intent: INTransferMoneyIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveTransactionScheduledDate(for intent: INTransferMoneyIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
}

public protocol INUnsendMessagesIntentHandling: NSObjectProtocol {
    func confirm(intent: INUnsendMessagesIntent) async -> INUnsendMessagesIntentResponse
    func handle(intent: INUnsendMessagesIntent) async -> INUnsendMessagesIntentResponse
}

public extension INUnsendMessagesIntentHandling {
    func confirm(intent: INUnsendMessagesIntent) async -> INUnsendMessagesIntentResponse { INUnsendMessagesIntentResponse() }
}

public protocol INUpdateMediaAffinityIntentHandling: NSObjectProtocol {
    func confirm(intent: INUpdateMediaAffinityIntent) async -> INUpdateMediaAffinityIntentResponse
    func handle(intent: INUpdateMediaAffinityIntent) async -> INUpdateMediaAffinityIntentResponse
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent) async -> INMediaAffinityTypeResolutionResult
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent) async -> [INUpdateMediaAffinityMediaItemResolutionResult]
}

public extension INUpdateMediaAffinityIntentHandling {
    func confirm(intent: INUpdateMediaAffinityIntent) async -> INUpdateMediaAffinityIntentResponse { INUpdateMediaAffinityIntentResponse() }
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent) async -> INMediaAffinityTypeResolutionResult { INMediaAffinityTypeResolutionResult.needsValue() }
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent) async -> [INUpdateMediaAffinityMediaItemResolutionResult] { [] }
}

public protocol INVisualCodeDomainHandling: INGetVisualCodeIntentHandling {
}

public protocol INWorkoutsDomainHandling: INCancelWorkoutIntentHandling, INEndWorkoutIntentHandling, INPauseWorkoutIntentHandling, INResumeWorkoutIntentHandling, INStartWorkoutIntentHandling {
}

public protocol INCallsDomainHandling: INSearchCallHistoryIntentHandling, INStartAudioCallIntentHandling, INStartVideoCallIntentHandling {
}

public protocol INCarCommandsDomainHandling: INActivateCarSignalIntentHandling, INGetCarLockStatusIntentHandling, INGetCarPowerLevelStatusIntentHandling, INSetCarLockStatusIntentHandling {
}

public protocol INCarPlayDomainHandling: INSaveProfileInCarIntentHandling, INSetAudioSourceInCarIntentHandling, INSetClimateSettingsInCarIntentHandling, INSetDefrosterSettingsInCarIntentHandling, INSetProfileInCarIntentHandling, INSetSeatSettingsInCarIntentHandling {
}

public protocol INMessagesDomainHandling: INSearchForMessagesIntentHandling, INSendMessageIntentHandling, INSetMessageAttributeIntentHandling {
}

public protocol INNotebookDomainHandling: INAddTasksIntentHandling, INAppendToNoteIntentHandling, INCreateNoteIntentHandling, INCreateTaskListIntentHandling, INSearchForNotebookItemsIntentHandling, INSetTaskAttributeIntentHandling {
}

public protocol INPaymentsDomainHandling: INPayBillIntentHandling, INRequestPaymentIntentHandling, INSearchForAccountsIntentHandling, INSearchForBillsIntentHandling, INSendPaymentIntentHandling, INTransferMoneyIntentHandling {
}

public protocol INPhotosDomainHandling: INSearchForPhotosIntentHandling, INStartPhotoPlaybackIntentHandling {
}

public protocol INRadioDomainHandling: INSetRadioStationIntentHandling {
}

public protocol INRidesharingDomainHandling: INCancelRideIntentHandling, INGetRideStatusIntentHandling, INListRideOptionsIntentHandling, INRequestRideIntentHandling, INSendRideFeedbackIntentHandling {
}
