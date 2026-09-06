// Generated Intents handler protocols. Optional ObjC requirements become
// Swift defaults that fail closed rather than inventing Siri success.

public protocol INActivateCarSignalIntentHandling: NSObjectProtocol {
    func confirm(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse
    func handle(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse
    func confirm(intent: INActivateCarSignalIntent, completion: @escaping (INActivateCarSignalIntentResponse) -> Void)
    func handle(intent: INActivateCarSignalIntent, completion: @escaping (INActivateCarSignalIntentResponse) -> Void)
    func resolveCarName(for intent: INActivateCarSignalIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INActivateCarSignalIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveSignals(for intent: INActivateCarSignalIntent) async -> INCarSignalOptionsResolutionResult
    func resolveSignals(for intent: INActivateCarSignalIntent, with completion: @escaping (INCarSignalOptionsResolutionResult) -> Void)
}

public extension INActivateCarSignalIntentHandling {
    func confirm(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse { INActivateCarSignalIntentResponse() }
    func handle(intent: INActivateCarSignalIntent) async -> INActivateCarSignalIntentResponse {
        INActivateCarSignalIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INActivateCarSignalIntent, completion: @escaping (INActivateCarSignalIntentResponse) -> Void) {
        completion(INActivateCarSignalIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INActivateCarSignalIntent, completion: @escaping (INActivateCarSignalIntentResponse) -> Void) {
        completion(INActivateCarSignalIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INActivateCarSignalIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INActivateCarSignalIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveSignals(for intent: INActivateCarSignalIntent) async -> INCarSignalOptionsResolutionResult { INCarSignalOptionsResolutionResult.needsValue() }
    func resolveSignals(for intent: INActivateCarSignalIntent, with completion: @escaping (INCarSignalOptionsResolutionResult) -> Void) {
        completion(INCarSignalOptionsResolutionResult.needsValue())
    }
}

public protocol INAddMediaIntentHandling: NSObjectProtocol {
    func confirm(intent: INAddMediaIntent) async -> INAddMediaIntentResponse
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse
    func confirm(intent: INAddMediaIntent, completion: @escaping (INAddMediaIntentResponse) -> Void)
    func handle(intent: INAddMediaIntent, completion: @escaping (INAddMediaIntentResponse) -> Void)
    func resolveMediaDestination(for intent: INAddMediaIntent) async -> INAddMediaMediaDestinationResolutionResult
    func resolveMediaDestination(for intent: INAddMediaIntent, with completion: @escaping (INAddMediaMediaDestinationResolutionResult) -> Void)
    func resolveMediaItems(for intent: INAddMediaIntent) async -> [INAddMediaMediaItemResolutionResult]
    func resolveMediaItems(for intent: INAddMediaIntent, with completion: @escaping ([INAddMediaMediaItemResolutionResult]) -> Void)
}

public extension INAddMediaIntentHandling {
    func confirm(intent: INAddMediaIntent) async -> INAddMediaIntentResponse { INAddMediaIntentResponse() }
    func handle(intent: INAddMediaIntent) async -> INAddMediaIntentResponse {
        INAddMediaIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INAddMediaIntent, completion: @escaping (INAddMediaIntentResponse) -> Void) {
        completion(INAddMediaIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INAddMediaIntent, completion: @escaping (INAddMediaIntentResponse) -> Void) {
        completion(INAddMediaIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveMediaDestination(for intent: INAddMediaIntent) async -> INAddMediaMediaDestinationResolutionResult { INAddMediaMediaDestinationResolutionResult.needsValue() }
    func resolveMediaDestination(for intent: INAddMediaIntent, with completion: @escaping (INAddMediaMediaDestinationResolutionResult) -> Void) {
        completion(INAddMediaMediaDestinationResolutionResult.needsValue())
    }
    func resolveMediaItems(for intent: INAddMediaIntent) async -> [INAddMediaMediaItemResolutionResult] { [] }
    func resolveMediaItems(for intent: INAddMediaIntent, with completion: @escaping ([INAddMediaMediaItemResolutionResult]) -> Void) {
        completion([])
    }
}

public protocol INAddTasksIntentHandling: NSObjectProtocol {
    func confirm(intent: INAddTasksIntent) async -> INAddTasksIntentResponse
    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse
    func confirm(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void)
    func handle(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void)
    func resolvePriority(for intent: INAddTasksIntent) async -> INTaskPriorityResolutionResult
    func resolvePriority(for intent: INAddTasksIntent, completion: @escaping (INTaskPriorityResolutionResult) -> Void)
    func resolveSpatialEventTrigger(for intent: INAddTasksIntent) async -> INSpatialEventTriggerResolutionResult
    func resolveSpatialEventTrigger(for intent: INAddTasksIntent, completion: @escaping (INSpatialEventTriggerResolutionResult) -> Void)
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INAddTasksTargetTaskListResolutionResult
    func resolveTargetTaskList(for intent: INAddTasksIntent, completion: @escaping (INAddTasksTargetTaskListResolutionResult) -> Void)
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INTaskListResolutionResult
    func resolveTargetTaskList(for intent: INAddTasksIntent, with completion: @escaping (INTaskListResolutionResult) -> Void)
    func resolveTaskTitles(for intent: INAddTasksIntent) async -> [INSpeakableStringResolutionResult]
    func resolveTaskTitles(for intent: INAddTasksIntent, completion: @escaping ([INSpeakableStringResolutionResult]) -> Void)
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INAddTasksTemporalEventTriggerResolutionResult
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent, completion: @escaping (INAddTasksTemporalEventTriggerResolutionResult) -> Void)
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INTemporalEventTriggerResolutionResult
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent, with completion: @escaping (INTemporalEventTriggerResolutionResult) -> Void)
}

public extension INAddTasksIntentHandling {
    func confirm(intent: INAddTasksIntent) async -> INAddTasksIntentResponse {
        INAddTasksIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse {
        INAddTasksIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void) {
        completion(INAddTasksIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void) {
        completion(INAddTasksIntentResponse(code: .failure, userActivity: nil))
    }
    func resolvePriority(for intent: INAddTasksIntent) async -> INTaskPriorityResolutionResult { INTaskPriorityResolutionResult.needsValue() }
    func resolvePriority(for intent: INAddTasksIntent, completion: @escaping (INTaskPriorityResolutionResult) -> Void) {
        completion(INTaskPriorityResolutionResult.needsValue())
    }
    func resolveSpatialEventTrigger(for intent: INAddTasksIntent) async -> INSpatialEventTriggerResolutionResult { INSpatialEventTriggerResolutionResult.needsValue() }
    func resolveSpatialEventTrigger(for intent: INAddTasksIntent, completion: @escaping (INSpatialEventTriggerResolutionResult) -> Void) {
        completion(INSpatialEventTriggerResolutionResult.needsValue())
    }
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INAddTasksTargetTaskListResolutionResult { INAddTasksTargetTaskListResolutionResult.needsValue() }
    func resolveTargetTaskList(for intent: INAddTasksIntent, completion: @escaping (INAddTasksTargetTaskListResolutionResult) -> Void) {
        completion(INAddTasksTargetTaskListResolutionResult.needsValue())
    }
    func resolveTargetTaskList(for intent: INAddTasksIntent) async -> INTaskListResolutionResult { INTaskListResolutionResult.needsValue() }
    func resolveTargetTaskList(for intent: INAddTasksIntent, with completion: @escaping (INTaskListResolutionResult) -> Void) {
        completion(INTaskListResolutionResult.needsValue())
    }
    func resolveTaskTitles(for intent: INAddTasksIntent) async -> [INSpeakableStringResolutionResult] { [] }
    func resolveTaskTitles(for intent: INAddTasksIntent, completion: @escaping ([INSpeakableStringResolutionResult]) -> Void) {
        completion([])
    }
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INAddTasksTemporalEventTriggerResolutionResult { INAddTasksTemporalEventTriggerResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent, completion: @escaping (INAddTasksTemporalEventTriggerResolutionResult) -> Void) {
        completion(INAddTasksTemporalEventTriggerResolutionResult.needsValue())
    }
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent) async -> INTemporalEventTriggerResolutionResult { INTemporalEventTriggerResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INAddTasksIntent, with completion: @escaping (INTemporalEventTriggerResolutionResult) -> Void) {
        completion(INTemporalEventTriggerResolutionResult.needsValue())
    }
}

public protocol INAnswerCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse
    func handle(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse
    func confirm(intent: INAnswerCallIntent, completion: @escaping (INAnswerCallIntentResponse) -> Void)
    func handle(intent: INAnswerCallIntent, completion: @escaping (INAnswerCallIntentResponse) -> Void)
}

public extension INAnswerCallIntentHandling {
    func confirm(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse { INAnswerCallIntentResponse() }
    func handle(intent: INAnswerCallIntent) async -> INAnswerCallIntentResponse {
        INAnswerCallIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INAnswerCallIntent, completion: @escaping (INAnswerCallIntentResponse) -> Void) {
        completion(INAnswerCallIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INAnswerCallIntent, completion: @escaping (INAnswerCallIntentResponse) -> Void) {
        completion(INAnswerCallIntentResponse(code: .failure, userActivity: nil))
    }
}

public protocol INAppendToNoteIntentHandling: NSObjectProtocol {
    func confirm(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse
    func handle(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse
    func confirm(intent: INAppendToNoteIntent, completion: @escaping (INAppendToNoteIntentResponse) -> Void)
    func handle(intent: INAppendToNoteIntent, completion: @escaping (INAppendToNoteIntentResponse) -> Void)
    func resolveContent(for intent: INAppendToNoteIntent) async -> INNoteContentResolutionResult
    func resolveContent(for intent: INAppendToNoteIntent, with completion: @escaping (INNoteContentResolutionResult) -> Void)
    func resolveTargetNote(for intent: INAppendToNoteIntent) async -> INNoteResolutionResult
    func resolveTargetNote(for intent: INAppendToNoteIntent, with completion: @escaping (INNoteResolutionResult) -> Void)
}

public extension INAppendToNoteIntentHandling {
    func confirm(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse { INAppendToNoteIntentResponse() }
    func handle(intent: INAppendToNoteIntent) async -> INAppendToNoteIntentResponse {
        INAppendToNoteIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INAppendToNoteIntent, completion: @escaping (INAppendToNoteIntentResponse) -> Void) {
        completion(INAppendToNoteIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INAppendToNoteIntent, completion: @escaping (INAppendToNoteIntentResponse) -> Void) {
        completion(INAppendToNoteIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveContent(for intent: INAppendToNoteIntent) async -> INNoteContentResolutionResult { INNoteContentResolutionResult.needsValue() }
    func resolveContent(for intent: INAppendToNoteIntent, with completion: @escaping (INNoteContentResolutionResult) -> Void) {
        completion(INNoteContentResolutionResult.needsValue())
    }
    func resolveTargetNote(for intent: INAppendToNoteIntent) async -> INNoteResolutionResult { INNoteResolutionResult.needsValue() }
    func resolveTargetNote(for intent: INAppendToNoteIntent, with completion: @escaping (INNoteResolutionResult) -> Void) {
        completion(INNoteResolutionResult.needsValue())
    }
}

public protocol INBookRestaurantReservationIntentHandling: NSObjectProtocol {
    func confirm(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse
    func handle(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse
    func confirm(bookRestaurantReservation intent: INBookRestaurantReservationIntent, completion: @escaping (INBookRestaurantReservationIntentResponse) -> Void)
    func handle(bookRestaurantReservation intent: INBookRestaurantReservationIntent, completion: @escaping (INBookRestaurantReservationIntentResponse) -> Void)
    func resolveBookingDateComponents(for intent: INBookRestaurantReservationIntent) async -> INDateComponentsResolutionResult
    func resolveBookingDateComponents(for intent: INBookRestaurantReservationIntent, completion: @escaping (INDateComponentsResolutionResult) -> Void)
    func resolveGuest(for intent: INBookRestaurantReservationIntent) async -> INRestaurantGuestResolutionResult
    func resolveGuest(for intent: INBookRestaurantReservationIntent, completion: @escaping (INRestaurantGuestResolutionResult) -> Void)
    func resolveGuestProvidedSpecialRequestText(for intent: INBookRestaurantReservationIntent) async -> INStringResolutionResult
    func resolveGuestProvidedSpecialRequestText(for intent: INBookRestaurantReservationIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolvePartySize(for intent: INBookRestaurantReservationIntent) async -> INIntegerResolutionResult
    func resolvePartySize(for intent: INBookRestaurantReservationIntent, completion: @escaping (INIntegerResolutionResult) -> Void)
    func resolveRestaurant(for intent: INBookRestaurantReservationIntent) async -> INRestaurantResolutionResult
    func resolveRestaurant(for intent: INBookRestaurantReservationIntent, completion: @escaping (INRestaurantResolutionResult) -> Void)
}

public extension INBookRestaurantReservationIntentHandling {
    func confirm(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse {
        INBookRestaurantReservationIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(bookRestaurantReservation intent: INBookRestaurantReservationIntent) async -> INBookRestaurantReservationIntentResponse {
        INBookRestaurantReservationIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(bookRestaurantReservation intent: INBookRestaurantReservationIntent, completion: @escaping (INBookRestaurantReservationIntentResponse) -> Void) {
        completion(INBookRestaurantReservationIntentResponse(code: .success, userActivity: nil))
    }
    func handle(bookRestaurantReservation intent: INBookRestaurantReservationIntent, completion: @escaping (INBookRestaurantReservationIntentResponse) -> Void) {
        completion(INBookRestaurantReservationIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveBookingDateComponents(for intent: INBookRestaurantReservationIntent) async -> INDateComponentsResolutionResult { INDateComponentsResolutionResult.needsValue() }
    func resolveBookingDateComponents(for intent: INBookRestaurantReservationIntent, completion: @escaping (INDateComponentsResolutionResult) -> Void) {
        completion(INDateComponentsResolutionResult.needsValue())
    }
    func resolveGuest(for intent: INBookRestaurantReservationIntent) async -> INRestaurantGuestResolutionResult { INRestaurantGuestResolutionResult.needsValue() }
    func resolveGuest(for intent: INBookRestaurantReservationIntent, completion: @escaping (INRestaurantGuestResolutionResult) -> Void) {
        completion(INRestaurantGuestResolutionResult.needsValue())
    }
    func resolveGuestProvidedSpecialRequestText(for intent: INBookRestaurantReservationIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveGuestProvidedSpecialRequestText(for intent: INBookRestaurantReservationIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolvePartySize(for intent: INBookRestaurantReservationIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolvePartySize(for intent: INBookRestaurantReservationIntent, completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
    func resolveRestaurant(for intent: INBookRestaurantReservationIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
    func resolveRestaurant(for intent: INBookRestaurantReservationIntent, completion: @escaping (INRestaurantResolutionResult) -> Void) {
        completion(INRestaurantResolutionResult.needsValue())
    }
}

public protocol INCancelRideIntentHandling: NSObjectProtocol {
    func confirm(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse
    func handle(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse
    func confirm(cancelRide intent: INCancelRideIntent, completion: @escaping (INCancelRideIntentResponse) -> Void)
    func handle(cancelRide intent: INCancelRideIntent, completion: @escaping (INCancelRideIntentResponse) -> Void)
}

public extension INCancelRideIntentHandling {
    func confirm(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse { INCancelRideIntentResponse() }
    func handle(cancelRide intent: INCancelRideIntent) async -> INCancelRideIntentResponse {
        INCancelRideIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(cancelRide intent: INCancelRideIntent, completion: @escaping (INCancelRideIntentResponse) -> Void) {
        completion(INCancelRideIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(cancelRide intent: INCancelRideIntent, completion: @escaping (INCancelRideIntentResponse) -> Void) {
        completion(INCancelRideIntentResponse(code: .failure, userActivity: nil))
    }
}

public protocol INCancelWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse
    func handle(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse
    func confirm(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void)
    func handle(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void)
    func resolveWorkoutName(for intent: INCancelWorkoutIntent) async -> INSpeakableStringResolutionResult
    func resolveWorkoutName(for intent: INCancelWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INCancelWorkoutIntentHandling {
    func confirm(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse { INCancelWorkoutIntentResponse() }
    func handle(intent: INCancelWorkoutIntent) async -> INCancelWorkoutIntentResponse {
        INCancelWorkoutIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        completion(INCancelWorkoutIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        completion(INCancelWorkoutIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INCancelWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveWorkoutName(for intent: INCancelWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INCreateNoteIntentHandling: NSObjectProtocol {
    func confirm(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse
    func handle(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse
    func confirm(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Void)
    func handle(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Void)
    func resolveContent(for intent: INCreateNoteIntent) async -> INNoteContentResolutionResult
    func resolveContent(for intent: INCreateNoteIntent, with completion: @escaping (INNoteContentResolutionResult) -> Void)
    func resolveGroupName(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult
    func resolveGroupName(for intent: INCreateNoteIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveTitle(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult
    func resolveTitle(for intent: INCreateNoteIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INCreateNoteIntentHandling {
    func confirm(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse { INCreateNoteIntentResponse() }
    func handle(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse {
        INCreateNoteIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Void) {
        completion(INCreateNoteIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Void) {
        completion(INCreateNoteIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveContent(for intent: INCreateNoteIntent) async -> INNoteContentResolutionResult { INNoteContentResolutionResult.needsValue() }
    func resolveContent(for intent: INCreateNoteIntent, with completion: @escaping (INNoteContentResolutionResult) -> Void) {
        completion(INNoteContentResolutionResult.needsValue())
    }
    func resolveGroupName(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveGroupName(for intent: INCreateNoteIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveTitle(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTitle(for intent: INCreateNoteIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INCreateTaskListIntentHandling: NSObjectProtocol {
    func confirm(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse
    func handle(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse
    func confirm(intent: INCreateTaskListIntent, completion: @escaping (INCreateTaskListIntentResponse) -> Void)
    func handle(intent: INCreateTaskListIntent, completion: @escaping (INCreateTaskListIntentResponse) -> Void)
    func resolveGroupName(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult
    func resolveGroupName(for intent: INCreateTaskListIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveTaskTitles(for intent: INCreateTaskListIntent) async -> [INSpeakableStringResolutionResult]
    func resolveTaskTitles(for intent: INCreateTaskListIntent, with completion: @escaping ([INSpeakableStringResolutionResult]) -> Void)
    func resolveTitle(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult
    func resolveTitle(for intent: INCreateTaskListIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INCreateTaskListIntentHandling {
    func confirm(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse { INCreateTaskListIntentResponse() }
    func handle(intent: INCreateTaskListIntent) async -> INCreateTaskListIntentResponse {
        INCreateTaskListIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INCreateTaskListIntent, completion: @escaping (INCreateTaskListIntentResponse) -> Void) {
        completion(INCreateTaskListIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INCreateTaskListIntent, completion: @escaping (INCreateTaskListIntentResponse) -> Void) {
        completion(INCreateTaskListIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveGroupName(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveGroupName(for intent: INCreateTaskListIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveTaskTitles(for intent: INCreateTaskListIntent) async -> [INSpeakableStringResolutionResult] { [] }
    func resolveTaskTitles(for intent: INCreateTaskListIntent, with completion: @escaping ([INSpeakableStringResolutionResult]) -> Void) {
        completion([])
    }
    func resolveTitle(for intent: INCreateTaskListIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTitle(for intent: INCreateTaskListIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INDeleteTasksIntentHandling: NSObjectProtocol {
    func confirm(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse
    func handle(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse
    func confirm(intent: INDeleteTasksIntent, completion: @escaping (INDeleteTasksIntentResponse) -> Void)
    func handle(intent: INDeleteTasksIntent, completion: @escaping (INDeleteTasksIntentResponse) -> Void)
    func resolveTaskList(for intent: INDeleteTasksIntent) async -> INDeleteTasksTaskListResolutionResult
    func resolveTaskList(for intent: INDeleteTasksIntent, with completion: @escaping (INDeleteTasksTaskListResolutionResult) -> Void)
    func resolveTasks(for intent: INDeleteTasksIntent) async -> [INDeleteTasksTaskResolutionResult]
    func resolveTasks(for intent: INDeleteTasksIntent, with completion: @escaping ([INDeleteTasksTaskResolutionResult]) -> Void)
}

public extension INDeleteTasksIntentHandling {
    func confirm(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse { INDeleteTasksIntentResponse() }
    func handle(intent: INDeleteTasksIntent) async -> INDeleteTasksIntentResponse {
        INDeleteTasksIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INDeleteTasksIntent, completion: @escaping (INDeleteTasksIntentResponse) -> Void) {
        completion(INDeleteTasksIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INDeleteTasksIntent, completion: @escaping (INDeleteTasksIntentResponse) -> Void) {
        completion(INDeleteTasksIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveTaskList(for intent: INDeleteTasksIntent) async -> INDeleteTasksTaskListResolutionResult { INDeleteTasksTaskListResolutionResult.needsValue() }
    func resolveTaskList(for intent: INDeleteTasksIntent, with completion: @escaping (INDeleteTasksTaskListResolutionResult) -> Void) {
        completion(INDeleteTasksTaskListResolutionResult.needsValue())
    }
    func resolveTasks(for intent: INDeleteTasksIntent) async -> [INDeleteTasksTaskResolutionResult] { [] }
    func resolveTasks(for intent: INDeleteTasksIntent, with completion: @escaping ([INDeleteTasksTaskResolutionResult]) -> Void) {
        completion([])
    }
}

public protocol INEditMessageIntentHandling: NSObjectProtocol {
    func confirm(intent: INEditMessageIntent) async -> INEditMessageIntentResponse
    func handle(intent: INEditMessageIntent) async -> INEditMessageIntentResponse
    func confirm(intent: INEditMessageIntent, completion: @escaping (INEditMessageIntentResponse) -> Void)
    func handle(intent: INEditMessageIntent, completion: @escaping (INEditMessageIntentResponse) -> Void)
    func resolveEditedContent(for intent: INEditMessageIntent) async -> INStringResolutionResult
    func resolveEditedContent(for intent: INEditMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void)
}

public extension INEditMessageIntentHandling {
    func confirm(intent: INEditMessageIntent) async -> INEditMessageIntentResponse { INEditMessageIntentResponse() }
    func handle(intent: INEditMessageIntent) async -> INEditMessageIntentResponse {
        INEditMessageIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INEditMessageIntent, completion: @escaping (INEditMessageIntentResponse) -> Void) {
        completion(INEditMessageIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INEditMessageIntent, completion: @escaping (INEditMessageIntentResponse) -> Void) {
        completion(INEditMessageIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveEditedContent(for intent: INEditMessageIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveEditedContent(for intent: INEditMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
}

public protocol INEndWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse
    func handle(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse
    func confirm(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void)
    func handle(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void)
    func resolveWorkoutName(for intent: INEndWorkoutIntent) async -> INSpeakableStringResolutionResult
    func resolveWorkoutName(for intent: INEndWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INEndWorkoutIntentHandling {
    func confirm(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse { INEndWorkoutIntentResponse() }
    func handle(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse {
        INEndWorkoutIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        completion(INEndWorkoutIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        completion(INEndWorkoutIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INEndWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveWorkoutName(for intent: INEndWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INGetAvailableRestaurantReservationBookingDefaultsIntentHandling: NSObjectProtocol {
    func confirm(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse
    func handle(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse
    func confirm(
        getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingDefaultsIntentResponse) -> Void
    )
    func handle(
        getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingDefaultsIntentResponse) -> Void
    )
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INRestaurantResolutionResult
    func resolveRestaurant(
        for intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        with completion: @escaping (INRestaurantResolutionResult) -> Void
    )
}

public extension INGetAvailableRestaurantReservationBookingDefaultsIntentHandling {
    func confirm(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse { INGetAvailableRestaurantReservationBookingDefaultsIntentResponse() }
    func handle(getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INGetAvailableRestaurantReservationBookingDefaultsIntentResponse { INGetAvailableRestaurantReservationBookingDefaultsIntentResponse() }
    func confirm(
        getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingDefaultsIntentResponse) -> Void
    ) {
        completion(INGetAvailableRestaurantReservationBookingDefaultsIntentResponse())
    }
    func handle(
        getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingDefaultsIntentResponse) -> Void
    ) {
        completion(INGetAvailableRestaurantReservationBookingDefaultsIntentResponse())
    }
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingDefaultsIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
    func resolveRestaurant(
        for intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        with completion: @escaping (INRestaurantResolutionResult) -> Void
    ) {
        completion(INRestaurantResolutionResult.needsValue())
    }
}

public protocol INGetAvailableRestaurantReservationBookingsIntentHandling: NSObjectProtocol {
    func confirm(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse
    func handle(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse
    func confirm(
        getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingsIntentResponse) -> Void
    )
    func handle(
        getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingsIntentResponse) -> Void
    )
    func resolvePartySize(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INIntegerResolutionResult
    func resolvePartySize(for intent: INGetAvailableRestaurantReservationBookingsIntent, with completion: @escaping (INIntegerResolutionResult) -> Void)
    func resolvePreferredBookingDateComponents(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INDateComponentsResolutionResult
    func resolvePreferredBookingDateComponents(for intent: INGetAvailableRestaurantReservationBookingsIntent, with completion: @escaping (INDateComponentsResolutionResult) -> Void)
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingsIntent, with completion: @escaping (INRestaurantResolutionResult) -> Void)
}

public extension INGetAvailableRestaurantReservationBookingsIntentHandling {
    func confirm(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse { INGetAvailableRestaurantReservationBookingsIntentResponse() }
    func handle(getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INGetAvailableRestaurantReservationBookingsIntentResponse { INGetAvailableRestaurantReservationBookingsIntentResponse() }
    func confirm(
        getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingsIntentResponse) -> Void
    ) {
        completion(INGetAvailableRestaurantReservationBookingsIntentResponse())
    }
    func handle(
        getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingsIntentResponse) -> Void
    ) {
        completion(INGetAvailableRestaurantReservationBookingsIntentResponse())
    }
    func resolvePartySize(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolvePartySize(for intent: INGetAvailableRestaurantReservationBookingsIntent, with completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
    func resolvePreferredBookingDateComponents(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INDateComponentsResolutionResult { INDateComponentsResolutionResult.needsValue() }
    func resolvePreferredBookingDateComponents(for intent: INGetAvailableRestaurantReservationBookingsIntent, with completion: @escaping (INDateComponentsResolutionResult) -> Void) {
        completion(INDateComponentsResolutionResult.needsValue())
    }
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
    func resolveRestaurant(for intent: INGetAvailableRestaurantReservationBookingsIntent, with completion: @escaping (INRestaurantResolutionResult) -> Void) {
        completion(INRestaurantResolutionResult.needsValue())
    }
}

public protocol INGetCarLockStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse
    func handle(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse
    func confirm(intent: INGetCarLockStatusIntent, completion: @escaping (INGetCarLockStatusIntentResponse) -> Void)
    func handle(intent: INGetCarLockStatusIntent, completion: @escaping (INGetCarLockStatusIntentResponse) -> Void)
    func resolveCarName(for intent: INGetCarLockStatusIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INGetCarLockStatusIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INGetCarLockStatusIntentHandling {
    func confirm(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse { INGetCarLockStatusIntentResponse() }
    func handle(intent: INGetCarLockStatusIntent) async -> INGetCarLockStatusIntentResponse {
        INGetCarLockStatusIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INGetCarLockStatusIntent, completion: @escaping (INGetCarLockStatusIntentResponse) -> Void) {
        completion(INGetCarLockStatusIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INGetCarLockStatusIntent, completion: @escaping (INGetCarLockStatusIntentResponse) -> Void) {
        completion(INGetCarLockStatusIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INGetCarLockStatusIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INGetCarLockStatusIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
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
    func confirm(
        getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        completion: @escaping (INGetUserCurrentRestaurantReservationBookingsIntentResponse) -> Void
    )
    func handle(
        getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        completion: @escaping (INGetUserCurrentRestaurantReservationBookingsIntentResponse) -> Void
    )
    func resolveRestaurant(for intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult
    func resolveRestaurant(
        for intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        with completion: @escaping (INRestaurantResolutionResult) -> Void
    )
}

public extension INGetUserCurrentRestaurantReservationBookingsIntentHandling {
    func confirm(getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INGetUserCurrentRestaurantReservationBookingsIntentResponse { INGetUserCurrentRestaurantReservationBookingsIntentResponse() }
    func handle(getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INGetUserCurrentRestaurantReservationBookingsIntentResponse { INGetUserCurrentRestaurantReservationBookingsIntentResponse() }
    func confirm(
        getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        completion: @escaping (INGetUserCurrentRestaurantReservationBookingsIntentResponse) -> Void
    ) {
        completion(INGetUserCurrentRestaurantReservationBookingsIntentResponse())
    }
    func handle(
        getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        completion: @escaping (INGetUserCurrentRestaurantReservationBookingsIntentResponse) -> Void
    ) {
        completion(INGetUserCurrentRestaurantReservationBookingsIntentResponse())
    }
    func resolveRestaurant(for intent: INGetUserCurrentRestaurantReservationBookingsIntent) async -> INRestaurantResolutionResult { INRestaurantResolutionResult.needsValue() }
    func resolveRestaurant(
        for intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        with completion: @escaping (INRestaurantResolutionResult) -> Void
    ) {
        completion(INRestaurantResolutionResult.needsValue())
    }
}

public protocol INGetVisualCodeIntentHandling: NSObjectProtocol {
    func confirm(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse
    func handle(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse
    func confirm(intent: INGetVisualCodeIntent, completion: @escaping (INGetVisualCodeIntentResponse) -> Void)
    func handle(intent: INGetVisualCodeIntent, completion: @escaping (INGetVisualCodeIntentResponse) -> Void)
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent) async -> INVisualCodeTypeResolutionResult
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent, with completion: @escaping (INVisualCodeTypeResolutionResult) -> Void)
}

public extension INGetVisualCodeIntentHandling {
    func confirm(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse { INGetVisualCodeIntentResponse() }
    func handle(intent: INGetVisualCodeIntent) async -> INGetVisualCodeIntentResponse {
        INGetVisualCodeIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INGetVisualCodeIntent, completion: @escaping (INGetVisualCodeIntentResponse) -> Void) {
        completion(INGetVisualCodeIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INGetVisualCodeIntent, completion: @escaping (INGetVisualCodeIntentResponse) -> Void) {
        completion(INGetVisualCodeIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent) async -> INVisualCodeTypeResolutionResult { INVisualCodeTypeResolutionResult.needsValue() }
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent, with completion: @escaping (INVisualCodeTypeResolutionResult) -> Void) {
        completion(INVisualCodeTypeResolutionResult.needsValue())
    }
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
    func confirm(intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void)
    func handle(intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void)
    func resolveWorkoutName(for intent: INPauseWorkoutIntent) async -> INSpeakableStringResolutionResult
    func resolveWorkoutName(for intent: INPauseWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INPauseWorkoutIntentHandling {
    func confirm(intent: INPauseWorkoutIntent) async -> INPauseWorkoutIntentResponse { INPauseWorkoutIntentResponse() }
    func handle(intent: INPauseWorkoutIntent) async -> INPauseWorkoutIntentResponse {
        INPauseWorkoutIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        completion(INPauseWorkoutIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        completion(INPauseWorkoutIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INPauseWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveWorkoutName(for intent: INPauseWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INPayBillIntentHandling: NSObjectProtocol {
    func confirm(intent: INPayBillIntent) async -> INPayBillIntentResponse
    func handle(intent: INPayBillIntent) async -> INPayBillIntentResponse
    func confirm(intent: INPayBillIntent, completion: @escaping (INPayBillIntentResponse) -> Void)
    func handle(intent: INPayBillIntent, completion: @escaping (INPayBillIntentResponse) -> Void)
    func resolveBillPayee(for intent: INPayBillIntent) async -> INBillPayeeResolutionResult
    func resolveBillPayee(for intent: INPayBillIntent, completion: @escaping (INBillPayeeResolutionResult) -> Void)
    func resolveBillType(for intent: INPayBillIntent) async -> INBillTypeResolutionResult
    func resolveBillType(for intent: INPayBillIntent, completion: @escaping (INBillTypeResolutionResult) -> Void)
    func resolveDueDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDueDate(for intent: INPayBillIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveFromAccount(for intent: INPayBillIntent) async -> INPaymentAccountResolutionResult
    func resolveFromAccount(for intent: INPayBillIntent, completion: @escaping (INPaymentAccountResolutionResult) -> Void)
    func resolveTransactionAmount(for intent: INPayBillIntent) async -> INPaymentAmountResolutionResult
    func resolveTransactionAmount(for intent: INPayBillIntent, completion: @escaping (INPaymentAmountResolutionResult) -> Void)
    func resolveTransactionNote(for intent: INPayBillIntent) async -> INStringResolutionResult
    func resolveTransactionNote(for intent: INPayBillIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolveTransactionScheduledDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult
    func resolveTransactionScheduledDate(for intent: INPayBillIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
}

public extension INPayBillIntentHandling {
    func confirm(intent: INPayBillIntent) async -> INPayBillIntentResponse {
        INPayBillIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INPayBillIntent) async -> INPayBillIntentResponse {
        INPayBillIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INPayBillIntent, completion: @escaping (INPayBillIntentResponse) -> Void) {
        completion(INPayBillIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INPayBillIntent, completion: @escaping (INPayBillIntentResponse) -> Void) {
        completion(INPayBillIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveBillPayee(for intent: INPayBillIntent) async -> INBillPayeeResolutionResult { INBillPayeeResolutionResult.needsValue() }
    func resolveBillPayee(for intent: INPayBillIntent, completion: @escaping (INBillPayeeResolutionResult) -> Void) {
        completion(INBillPayeeResolutionResult.needsValue())
    }
    func resolveBillType(for intent: INPayBillIntent) async -> INBillTypeResolutionResult { INBillTypeResolutionResult.needsValue() }
    func resolveBillType(for intent: INPayBillIntent, completion: @escaping (INBillTypeResolutionResult) -> Void) {
        completion(INBillTypeResolutionResult.needsValue())
    }
    func resolveDueDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDueDate(for intent: INPayBillIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveFromAccount(for intent: INPayBillIntent) async -> INPaymentAccountResolutionResult { INPaymentAccountResolutionResult.needsValue() }
    func resolveFromAccount(for intent: INPayBillIntent, completion: @escaping (INPaymentAccountResolutionResult) -> Void) {
        completion(INPaymentAccountResolutionResult.needsValue())
    }
    func resolveTransactionAmount(for intent: INPayBillIntent) async -> INPaymentAmountResolutionResult { INPaymentAmountResolutionResult.needsValue() }
    func resolveTransactionAmount(for intent: INPayBillIntent, completion: @escaping (INPaymentAmountResolutionResult) -> Void) {
        completion(INPaymentAmountResolutionResult.needsValue())
    }
    func resolveTransactionNote(for intent: INPayBillIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveTransactionNote(for intent: INPayBillIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveTransactionScheduledDate(for intent: INPayBillIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveTransactionScheduledDate(for intent: INPayBillIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
}

public protocol INPlayMediaIntentHandling: NSObjectProtocol {
    func confirm(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse
    func confirm(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void)
    func handle(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void)
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult]
    func resolveMediaItems(for intent: INPlayMediaIntent, with completion: @escaping ([INPlayMediaMediaItemResolutionResult]) -> Void)
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult
    func resolvePlayShuffled(for intent: INPlayMediaIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent, with completion: @escaping (INPlaybackQueueLocationResolutionResult) -> Void)
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent, with completion: @escaping (INPlaybackRepeatModeResolutionResult) -> Void)
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent, with completion: @escaping (INPlayMediaPlaybackSpeedResolutionResult) -> Void)
    func resolveResumePlayback(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult
    func resolveResumePlayback(for intent: INPlayMediaIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
}

public extension INPlayMediaIntentHandling {
    func confirm(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse { INPlayMediaIntentResponse() }
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        INPlayMediaIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
        completion(INPlayMediaIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
        completion(INPlayMediaIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] { [] }
    func resolveMediaItems(for intent: INPlayMediaIntent, with completion: @escaping ([INPlayMediaMediaItemResolutionResult]) -> Void) {
        completion([])
    }
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolvePlayShuffled(for intent: INPlayMediaIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult { INPlaybackQueueLocationResolutionResult.needsValue() }
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent, with completion: @escaping (INPlaybackQueueLocationResolutionResult) -> Void) {
        completion(INPlaybackQueueLocationResolutionResult.needsValue())
    }
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult { INPlaybackRepeatModeResolutionResult.needsValue() }
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent, with completion: @escaping (INPlaybackRepeatModeResolutionResult) -> Void) {
        completion(INPlaybackRepeatModeResolutionResult.needsValue())
    }
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent) async -> INPlayMediaPlaybackSpeedResolutionResult { INPlayMediaPlaybackSpeedResolutionResult.needsValue() }
    func resolvePlaybackSpeed(for intent: INPlayMediaIntent, with completion: @escaping (INPlayMediaPlaybackSpeedResolutionResult) -> Void) {
        completion(INPlayMediaPlaybackSpeedResolutionResult.needsValue())
    }
    func resolveResumePlayback(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveResumePlayback(for intent: INPlayMediaIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
}

public protocol INRequestPaymentIntentHandling: NSObjectProtocol {
    func confirm(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse
    func handle(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse
    func confirm(intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentIntentResponse) -> Void)
    func handle(intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentIntentResponse) -> Void)
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent) async -> INRequestPaymentCurrencyAmountResolutionResult
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentCurrencyAmountResolutionResult) -> Void)
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void)
    func resolveNote(for intent: INRequestPaymentIntent) async -> INStringResolutionResult
    func resolveNote(for intent: INRequestPaymentIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolvePayer(for intent: INRequestPaymentIntent) async -> INRequestPaymentPayerResolutionResult
    func resolvePayer(for intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentPayerResolutionResult) -> Void)
    func resolvePayer(for intent: INRequestPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void)
}

public extension INRequestPaymentIntentHandling {
    func confirm(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse { INRequestPaymentIntentResponse() }
    func handle(intent: INRequestPaymentIntent) async -> INRequestPaymentIntentResponse {
        INRequestPaymentIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentIntentResponse) -> Void) {
        completion(INRequestPaymentIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentIntentResponse) -> Void) {
        completion(INRequestPaymentIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent) async -> INRequestPaymentCurrencyAmountResolutionResult { INRequestPaymentCurrencyAmountResolutionResult.needsValue() }
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentCurrencyAmountResolutionResult) -> Void) {
        completion(INRequestPaymentCurrencyAmountResolutionResult.needsValue())
    }
    func resolveCurrencyAmount(for intent: INRequestPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void) { completion(INCurrencyAmountResolutionResult.needsValue()) }
    func resolveNote(for intent: INRequestPaymentIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveNote(for intent: INRequestPaymentIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolvePayer(for intent: INRequestPaymentIntent) async -> INRequestPaymentPayerResolutionResult { INRequestPaymentPayerResolutionResult.needsValue() }
    func resolvePayer(for intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentPayerResolutionResult) -> Void) {
        completion(INRequestPaymentPayerResolutionResult.needsValue())
    }
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
    func confirm(intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void)
    func handle(intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void)
    func resolveWorkoutName(for intent: INResumeWorkoutIntent) async -> INSpeakableStringResolutionResult
    func resolveWorkoutName(for intent: INResumeWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INResumeWorkoutIntentHandling {
    func confirm(intent: INResumeWorkoutIntent) async -> INResumeWorkoutIntentResponse { INResumeWorkoutIntentResponse() }
    func handle(intent: INResumeWorkoutIntent) async -> INResumeWorkoutIntentResponse {
        INResumeWorkoutIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        completion(INResumeWorkoutIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        completion(INResumeWorkoutIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INResumeWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveWorkoutName(for intent: INResumeWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INSaveProfileInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse
    func handle(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse
    func confirm(intent: INSaveProfileInCarIntent, completion: @escaping (INSaveProfileInCarIntentResponse) -> Void)
    func handle(intent: INSaveProfileInCarIntent, completion: @escaping (INSaveProfileInCarIntentResponse) -> Void)
    func resolveProfileName(for intent: INSaveProfileInCarIntent) async -> INStringResolutionResult
    func resolveProfileName(for intent: INSaveProfileInCarIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent) async -> INIntegerResolutionResult
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void)
}

public extension INSaveProfileInCarIntentHandling {
    func confirm(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse { INSaveProfileInCarIntentResponse() }
    func handle(intent: INSaveProfileInCarIntent) async -> INSaveProfileInCarIntentResponse {
        INSaveProfileInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSaveProfileInCarIntent, completion: @escaping (INSaveProfileInCarIntentResponse) -> Void) {
        completion(INSaveProfileInCarIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSaveProfileInCarIntent, completion: @escaping (INSaveProfileInCarIntentResponse) -> Void) {
        completion(INSaveProfileInCarIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveProfileName(for intent: INSaveProfileInCarIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveProfileName(for intent: INSaveProfileInCarIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
}

public protocol INSearchCallHistoryIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse
    func handle(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse
    func confirm(intent: INSearchCallHistoryIntent, completion: @escaping (INSearchCallHistoryIntentResponse) -> Void)
    func handle(intent: INSearchCallHistoryIntent, completion: @escaping (INSearchCallHistoryIntentResponse) -> Void)
    func resolveCallType(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeResolutionResult
    func resolveCallType(for intent: INSearchCallHistoryIntent, completion: @escaping (INCallRecordTypeResolutionResult) -> Void)
    func resolveCallTypes(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeOptionsResolutionResult
    func resolveCallTypes(for intent: INSearchCallHistoryIntent, completion: @escaping (INCallRecordTypeOptionsResolutionResult) -> Void)
    func resolveDateCreated(for intent: INSearchCallHistoryIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDateCreated(for intent: INSearchCallHistoryIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveRecipient(for intent: INSearchCallHistoryIntent) async -> INPersonResolutionResult
    func resolveRecipient(for intent: INSearchCallHistoryIntent, completion: @escaping (INPersonResolutionResult) -> Void)
    func resolveUnseen(for intent: INSearchCallHistoryIntent) async -> INBooleanResolutionResult
    func resolveUnseen(for intent: INSearchCallHistoryIntent, completion: @escaping (INBooleanResolutionResult) -> Void)
}

public extension INSearchCallHistoryIntentHandling {
    func confirm(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse {
        INSearchCallHistoryIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSearchCallHistoryIntent) async -> INSearchCallHistoryIntentResponse {
        INSearchCallHistoryIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchCallHistoryIntent, completion: @escaping (INSearchCallHistoryIntentResponse) -> Void) {
        completion(INSearchCallHistoryIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchCallHistoryIntent, completion: @escaping (INSearchCallHistoryIntentResponse) -> Void) {
        completion(INSearchCallHistoryIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCallType(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeResolutionResult { INCallRecordTypeResolutionResult.needsValue() }
    func resolveCallType(for intent: INSearchCallHistoryIntent, completion: @escaping (INCallRecordTypeResolutionResult) -> Void) {
        completion(INCallRecordTypeResolutionResult.needsValue())
    }
    func resolveCallTypes(for intent: INSearchCallHistoryIntent) async -> INCallRecordTypeOptionsResolutionResult { INCallRecordTypeOptionsResolutionResult.needsValue() }
    func resolveCallTypes(for intent: INSearchCallHistoryIntent, completion: @escaping (INCallRecordTypeOptionsResolutionResult) -> Void) {
        completion(INCallRecordTypeOptionsResolutionResult.needsValue())
    }
    func resolveDateCreated(for intent: INSearchCallHistoryIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDateCreated(for intent: INSearchCallHistoryIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveRecipient(for intent: INSearchCallHistoryIntent) async -> INPersonResolutionResult { INPersonResolutionResult.needsValue() }
    func resolveRecipient(for intent: INSearchCallHistoryIntent, completion: @escaping (INPersonResolutionResult) -> Void) {
        completion(INPersonResolutionResult.needsValue())
    }
    func resolveUnseen(for intent: INSearchCallHistoryIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveUnseen(for intent: INSearchCallHistoryIntent, completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
}

public protocol INSearchForAccountsIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse
    func handle(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse
    func confirm(intent: INSearchForAccountsIntent, completion: @escaping (INSearchForAccountsIntentResponse) -> Void)
    func handle(intent: INSearchForAccountsIntent, completion: @escaping (INSearchForAccountsIntentResponse) -> Void)
    func resolveAccountNickname(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult
    func resolveAccountNickname(for intent: INSearchForAccountsIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveAccountType(for intent: INSearchForAccountsIntent) async -> INAccountTypeResolutionResult
    func resolveAccountType(for intent: INSearchForAccountsIntent, completion: @escaping (INAccountTypeResolutionResult) -> Void)
    func resolveOrganizationName(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult
    func resolveOrganizationName(for intent: INSearchForAccountsIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveRequestedBalanceType(for intent: INSearchForAccountsIntent) async -> INBalanceTypeResolutionResult
    func resolveRequestedBalanceType(for intent: INSearchForAccountsIntent, completion: @escaping (INBalanceTypeResolutionResult) -> Void)
}

public extension INSearchForAccountsIntentHandling {
    func confirm(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse {
        INSearchForAccountsIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSearchForAccountsIntent) async -> INSearchForAccountsIntentResponse {
        INSearchForAccountsIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchForAccountsIntent, completion: @escaping (INSearchForAccountsIntentResponse) -> Void) {
        completion(INSearchForAccountsIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchForAccountsIntent, completion: @escaping (INSearchForAccountsIntentResponse) -> Void) {
        completion(INSearchForAccountsIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAccountNickname(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveAccountNickname(for intent: INSearchForAccountsIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveAccountType(for intent: INSearchForAccountsIntent) async -> INAccountTypeResolutionResult { INAccountTypeResolutionResult.needsValue() }
    func resolveAccountType(for intent: INSearchForAccountsIntent, completion: @escaping (INAccountTypeResolutionResult) -> Void) {
        completion(INAccountTypeResolutionResult.needsValue())
    }
    func resolveOrganizationName(for intent: INSearchForAccountsIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveOrganizationName(for intent: INSearchForAccountsIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveRequestedBalanceType(for intent: INSearchForAccountsIntent) async -> INBalanceTypeResolutionResult { INBalanceTypeResolutionResult.needsValue() }
    func resolveRequestedBalanceType(for intent: INSearchForAccountsIntent, completion: @escaping (INBalanceTypeResolutionResult) -> Void) {
        completion(INBalanceTypeResolutionResult.needsValue())
    }
}

public protocol INSearchForBillsIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse
    func handle(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse
    func confirm(intent: INSearchForBillsIntent, completion: @escaping (INSearchForBillsIntentResponse) -> Void)
    func handle(intent: INSearchForBillsIntent, completion: @escaping (INSearchForBillsIntentResponse) -> Void)
    func resolveBillPayee(for intent: INSearchForBillsIntent) async -> INBillPayeeResolutionResult
    func resolveBillPayee(for intent: INSearchForBillsIntent, completion: @escaping (INBillPayeeResolutionResult) -> Void)
    func resolveBillType(for intent: INSearchForBillsIntent) async -> INBillTypeResolutionResult
    func resolveBillType(for intent: INSearchForBillsIntent, completion: @escaping (INBillTypeResolutionResult) -> Void)
    func resolveDueDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDueDateRange(for intent: INSearchForBillsIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolvePaymentDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult
    func resolvePaymentDateRange(for intent: INSearchForBillsIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveStatus(for intent: INSearchForBillsIntent) async -> INPaymentStatusResolutionResult
    func resolveStatus(for intent: INSearchForBillsIntent, completion: @escaping (INPaymentStatusResolutionResult) -> Void)
}

public extension INSearchForBillsIntentHandling {
    func confirm(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse {
        INSearchForBillsIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSearchForBillsIntent) async -> INSearchForBillsIntentResponse {
        INSearchForBillsIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchForBillsIntent, completion: @escaping (INSearchForBillsIntentResponse) -> Void) {
        completion(INSearchForBillsIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchForBillsIntent, completion: @escaping (INSearchForBillsIntentResponse) -> Void) {
        completion(INSearchForBillsIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveBillPayee(for intent: INSearchForBillsIntent) async -> INBillPayeeResolutionResult { INBillPayeeResolutionResult.needsValue() }
    func resolveBillPayee(for intent: INSearchForBillsIntent, completion: @escaping (INBillPayeeResolutionResult) -> Void) {
        completion(INBillPayeeResolutionResult.needsValue())
    }
    func resolveBillType(for intent: INSearchForBillsIntent) async -> INBillTypeResolutionResult { INBillTypeResolutionResult.needsValue() }
    func resolveBillType(for intent: INSearchForBillsIntent, completion: @escaping (INBillTypeResolutionResult) -> Void) {
        completion(INBillTypeResolutionResult.needsValue())
    }
    func resolveDueDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDueDateRange(for intent: INSearchForBillsIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolvePaymentDateRange(for intent: INSearchForBillsIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolvePaymentDateRange(for intent: INSearchForBillsIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveStatus(for intent: INSearchForBillsIntent) async -> INPaymentStatusResolutionResult { INPaymentStatusResolutionResult.needsValue() }
    func resolveStatus(for intent: INSearchForBillsIntent, completion: @escaping (INPaymentStatusResolutionResult) -> Void) {
        completion(INPaymentStatusResolutionResult.needsValue())
    }
}

public protocol INSearchForMediaIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse
    func handle(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse
    func confirm(intent: INSearchForMediaIntent, completion: @escaping (INSearchForMediaIntentResponse) -> Void)
    func handle(intent: INSearchForMediaIntent, completion: @escaping (INSearchForMediaIntentResponse) -> Void)
    func resolveMediaItems(for intent: INSearchForMediaIntent) async -> [INSearchForMediaMediaItemResolutionResult]
    func resolveMediaItems(for intent: INSearchForMediaIntent, with completion: @escaping ([INSearchForMediaMediaItemResolutionResult]) -> Void)
}

public extension INSearchForMediaIntentHandling {
    func confirm(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse { INSearchForMediaIntentResponse() }
    func handle(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse {
        INSearchForMediaIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchForMediaIntent, completion: @escaping (INSearchForMediaIntentResponse) -> Void) {
        completion(INSearchForMediaIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchForMediaIntent, completion: @escaping (INSearchForMediaIntentResponse) -> Void) {
        completion(INSearchForMediaIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveMediaItems(for intent: INSearchForMediaIntent) async -> [INSearchForMediaMediaItemResolutionResult] { [] }
    func resolveMediaItems(for intent: INSearchForMediaIntent, with completion: @escaping ([INSearchForMediaMediaItemResolutionResult]) -> Void) {
        completion([])
    }
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
    func resolveRecipients(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void)
    func resolveSenders(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void)
    func resolveSpeakableGroupNames(for intent: INSearchForMessagesIntent, with completion: @escaping ([INSpeakableStringResolutionResult]) -> Void)
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
    func resolveRecipients(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }
    func resolveSenders(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }
    func resolveSpeakableGroupNames(for intent: INSearchForMessagesIntent, with completion: @escaping ([INSpeakableStringResolutionResult]) -> Void) {
        completion([])
    }
}

public protocol INSearchForNotebookItemsIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse
    func handle(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse
    func confirm(intent: INSearchForNotebookItemsIntent, completion: @escaping (INSearchForNotebookItemsIntentResponse) -> Void)
    func handle(intent: INSearchForNotebookItemsIntent, completion: @escaping (INSearchForNotebookItemsIntentResponse) -> Void)
    func resolveContent(for intent: INSearchForNotebookItemsIntent) async -> INStringResolutionResult
    func resolveContent(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolveDateSearchType(for intent: INSearchForNotebookItemsIntent) async -> INDateSearchTypeResolutionResult
    func resolveDateSearchType(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INDateSearchTypeResolutionResult) -> Void)
    func resolveDateTime(for intent: INSearchForNotebookItemsIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDateTime(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveItemType(for intent: INSearchForNotebookItemsIntent) async -> INNotebookItemTypeResolutionResult
    func resolveItemType(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INNotebookItemTypeResolutionResult) -> Void)
    func resolveLocation(for intent: INSearchForNotebookItemsIntent) async -> INPlacemarkResolutionResult
    func resolveLocation(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INPlacemarkResolutionResult) -> Void)
    func resolveLocationSearchType(for intent: INSearchForNotebookItemsIntent) async -> INLocationSearchTypeResolutionResult
    func resolveLocationSearchType(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INLocationSearchTypeResolutionResult) -> Void)
    func resolveStatus(for intent: INSearchForNotebookItemsIntent) async -> INTaskStatusResolutionResult
    func resolveStatus(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INTaskStatusResolutionResult) -> Void)
    func resolveTaskPriority(for intent: INSearchForNotebookItemsIntent) async -> INTaskPriorityResolutionResult
    func resolveTaskPriority(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INTaskPriorityResolutionResult) -> Void)
    func resolveTemporalEventTriggerTypes(for intent: INSearchForNotebookItemsIntent) async -> INTemporalEventTriggerTypeOptionsResolutionResult
    func resolveTemporalEventTriggerTypes(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INTemporalEventTriggerTypeOptionsResolutionResult) -> Void)
    func resolveTitle(for intent: INSearchForNotebookItemsIntent) async -> INSpeakableStringResolutionResult
    func resolveTitle(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INSearchForNotebookItemsIntentHandling {
    func confirm(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse {
        INSearchForNotebookItemsIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSearchForNotebookItemsIntent) async -> INSearchForNotebookItemsIntentResponse {
        INSearchForNotebookItemsIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchForNotebookItemsIntent, completion: @escaping (INSearchForNotebookItemsIntentResponse) -> Void) {
        completion(INSearchForNotebookItemsIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchForNotebookItemsIntent, completion: @escaping (INSearchForNotebookItemsIntentResponse) -> Void) {
        completion(INSearchForNotebookItemsIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveContent(for intent: INSearchForNotebookItemsIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveContent(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveDateSearchType(for intent: INSearchForNotebookItemsIntent) async -> INDateSearchTypeResolutionResult { INDateSearchTypeResolutionResult.needsValue() }
    func resolveDateSearchType(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INDateSearchTypeResolutionResult) -> Void) {
        completion(INDateSearchTypeResolutionResult.needsValue())
    }
    func resolveDateTime(for intent: INSearchForNotebookItemsIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDateTime(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveItemType(for intent: INSearchForNotebookItemsIntent) async -> INNotebookItemTypeResolutionResult { INNotebookItemTypeResolutionResult.needsValue() }
    func resolveItemType(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INNotebookItemTypeResolutionResult) -> Void) {
        completion(INNotebookItemTypeResolutionResult.needsValue())
    }
    func resolveLocation(for intent: INSearchForNotebookItemsIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolveLocation(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        completion(INPlacemarkResolutionResult.needsValue())
    }
    func resolveLocationSearchType(for intent: INSearchForNotebookItemsIntent) async -> INLocationSearchTypeResolutionResult { INLocationSearchTypeResolutionResult.needsValue() }
    func resolveLocationSearchType(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INLocationSearchTypeResolutionResult) -> Void) {
        completion(INLocationSearchTypeResolutionResult.needsValue())
    }
    func resolveStatus(for intent: INSearchForNotebookItemsIntent) async -> INTaskStatusResolutionResult { INTaskStatusResolutionResult.needsValue() }
    func resolveStatus(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INTaskStatusResolutionResult) -> Void) {
        completion(INTaskStatusResolutionResult.needsValue())
    }
    func resolveTaskPriority(for intent: INSearchForNotebookItemsIntent) async -> INTaskPriorityResolutionResult { INTaskPriorityResolutionResult.needsValue() }
    func resolveTaskPriority(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INTaskPriorityResolutionResult) -> Void) {
        completion(INTaskPriorityResolutionResult.needsValue())
    }
    func resolveTemporalEventTriggerTypes(for intent: INSearchForNotebookItemsIntent) async -> INTemporalEventTriggerTypeOptionsResolutionResult { INTemporalEventTriggerTypeOptionsResolutionResult.needsValue() }
    func resolveTemporalEventTriggerTypes(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INTemporalEventTriggerTypeOptionsResolutionResult) -> Void) {
        completion(INTemporalEventTriggerTypeOptionsResolutionResult.needsValue())
    }
    func resolveTitle(for intent: INSearchForNotebookItemsIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTitle(for intent: INSearchForNotebookItemsIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INSearchForPhotosIntentHandling: NSObjectProtocol {
    func confirm(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse
    func handle(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse
    func confirm(intent: INSearchForPhotosIntent, completion: @escaping (INSearchForPhotosIntentResponse) -> Void)
    func handle(intent: INSearchForPhotosIntent, completion: @escaping (INSearchForPhotosIntentResponse) -> Void)
    func resolveAlbumName(for intent: INSearchForPhotosIntent) async -> INStringResolutionResult
    func resolveAlbumName(for intent: INSearchForPhotosIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolveDateCreated(for intent: INSearchForPhotosIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDateCreated(for intent: INSearchForPhotosIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveLocationCreated(for intent: INSearchForPhotosIntent) async -> INPlacemarkResolutionResult
    func resolveLocationCreated(for intent: INSearchForPhotosIntent, completion: @escaping (INPlacemarkResolutionResult) -> Void)
    func resolvePeopleInPhoto(for intent: INSearchForPhotosIntent) async -> [INPersonResolutionResult]
    func resolvePeopleInPhoto(for intent: INSearchForPhotosIntent, completion: @escaping ([INPersonResolutionResult]) -> Void)
    func resolveSearchTerms(for intent: INSearchForPhotosIntent) async -> [INStringResolutionResult]
    func resolveSearchTerms(for intent: INSearchForPhotosIntent, completion: @escaping ([INStringResolutionResult]) -> Void)
}

public extension INSearchForPhotosIntentHandling {
    func confirm(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse {
        INSearchForPhotosIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSearchForPhotosIntent) async -> INSearchForPhotosIntentResponse {
        INSearchForPhotosIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSearchForPhotosIntent, completion: @escaping (INSearchForPhotosIntentResponse) -> Void) {
        completion(INSearchForPhotosIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSearchForPhotosIntent, completion: @escaping (INSearchForPhotosIntentResponse) -> Void) {
        completion(INSearchForPhotosIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAlbumName(for intent: INSearchForPhotosIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveAlbumName(for intent: INSearchForPhotosIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveDateCreated(for intent: INSearchForPhotosIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDateCreated(for intent: INSearchForPhotosIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveLocationCreated(for intent: INSearchForPhotosIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolveLocationCreated(for intent: INSearchForPhotosIntent, completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        completion(INPlacemarkResolutionResult.needsValue())
    }
    func resolvePeopleInPhoto(for intent: INSearchForPhotosIntent) async -> [INPersonResolutionResult] { [] }
    func resolvePeopleInPhoto(for intent: INSearchForPhotosIntent, completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }
    func resolveSearchTerms(for intent: INSearchForPhotosIntent) async -> [INStringResolutionResult] { [] }
    func resolveSearchTerms(for intent: INSearchForPhotosIntent, completion: @escaping ([INStringResolutionResult]) -> Void) {
        completion([])
    }
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
    func confirm(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void)
    func handle(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void)
    func resolveCurrencyAmount(for intent: INSendPaymentIntent) async -> INSendPaymentCurrencyAmountResolutionResult
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, completion: @escaping (INSendPaymentCurrencyAmountResolutionResult) -> Void)
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void)
    func resolveNote(for intent: INSendPaymentIntent) async -> INStringResolutionResult
    func resolveNote(for intent: INSendPaymentIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolvePayee(for intent: INSendPaymentIntent) async -> INSendPaymentPayeeResolutionResult
    func resolvePayee(for intent: INSendPaymentIntent, completion: @escaping (INSendPaymentPayeeResolutionResult) -> Void)
    func resolvePayee(for intent: INSendPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void)
}

public extension INSendPaymentIntentHandling {
    func confirm(intent: INSendPaymentIntent) async -> INSendPaymentIntentResponse { INSendPaymentIntentResponse() }
    func handle(intent: INSendPaymentIntent) async -> INSendPaymentIntentResponse {
        INSendPaymentIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        completion(INSendPaymentIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCurrencyAmount(for intent: INSendPaymentIntent) async -> INSendPaymentCurrencyAmountResolutionResult { INSendPaymentCurrencyAmountResolutionResult.needsValue() }
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, completion: @escaping (INSendPaymentCurrencyAmountResolutionResult) -> Void) {
        completion(INSendPaymentCurrencyAmountResolutionResult.needsValue())
    }
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void) { completion(INCurrencyAmountResolutionResult.needsValue()) }
    func resolveNote(for intent: INSendPaymentIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveNote(for intent: INSendPaymentIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolvePayee(for intent: INSendPaymentIntent) async -> INSendPaymentPayeeResolutionResult { INSendPaymentPayeeResolutionResult.needsValue() }
    func resolvePayee(for intent: INSendPaymentIntent, completion: @escaping (INSendPaymentPayeeResolutionResult) -> Void) {
        completion(INSendPaymentPayeeResolutionResult.needsValue())
    }
    func resolvePayee(for intent: INSendPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void) { completion(INPersonResolutionResult.needsValue()) }
}

public protocol INSendRideFeedbackIntentHandling: NSObjectProtocol {
    func confirm(sendRideFeedback sendRideFeedbackIntent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse
    func confirm(sendRideFeedback sendRideFeedbackIntent: INSendRideFeedbackIntent, completion: @escaping (INSendRideFeedbackIntentResponse) -> Void)
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent, completion: @escaping (INSendRideFeedbackIntentResponse) -> Void)
}

public extension INSendRideFeedbackIntentHandling {
    func confirm(sendRideFeedback sendRideFeedbackIntent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse { INSendRideFeedbackIntentResponse() }
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent) async -> INSendRideFeedbackIntentResponse {
        INSendRideFeedbackIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(sendRideFeedback sendRideFeedbackIntent: INSendRideFeedbackIntent, completion: @escaping (INSendRideFeedbackIntentResponse) -> Void) {
        completion(INSendRideFeedbackIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent, completion: @escaping (INSendRideFeedbackIntentResponse) -> Void) {
        completion(INSendRideFeedbackIntentResponse(code: .failure, userActivity: nil))
    }
}

public protocol INSetAudioSourceInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse
    func handle(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse
    func confirm(intent: INSetAudioSourceInCarIntent, completion: @escaping (INSetAudioSourceInCarIntentResponse) -> Void)
    func handle(intent: INSetAudioSourceInCarIntent, completion: @escaping (INSetAudioSourceInCarIntentResponse) -> Void)
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent) async -> INCarAudioSourceResolutionResult
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent, with completion: @escaping (INCarAudioSourceResolutionResult) -> Void)
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent) async -> INRelativeReferenceResolutionResult
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent, with completion: @escaping (INRelativeReferenceResolutionResult) -> Void)
}

public extension INSetAudioSourceInCarIntentHandling {
    func confirm(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse { INSetAudioSourceInCarIntentResponse() }
    func handle(intent: INSetAudioSourceInCarIntent) async -> INSetAudioSourceInCarIntentResponse {
        INSetAudioSourceInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetAudioSourceInCarIntent, completion: @escaping (INSetAudioSourceInCarIntentResponse) -> Void) {
        completion(INSetAudioSourceInCarIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetAudioSourceInCarIntent, completion: @escaping (INSetAudioSourceInCarIntentResponse) -> Void) {
        completion(INSetAudioSourceInCarIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent) async -> INCarAudioSourceResolutionResult { INCarAudioSourceResolutionResult.needsValue() }
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent, with completion: @escaping (INCarAudioSourceResolutionResult) -> Void) {
        completion(INCarAudioSourceResolutionResult.needsValue())
    }
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent) async -> INRelativeReferenceResolutionResult { INRelativeReferenceResolutionResult.needsValue() }
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent, with completion: @escaping (INRelativeReferenceResolutionResult) -> Void) {
        completion(INRelativeReferenceResolutionResult.needsValue())
    }
}

public protocol INSetCarLockStatusIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse
    func handle(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse
    func confirm(intent: INSetCarLockStatusIntent, completion: @escaping (INSetCarLockStatusIntentResponse) -> Void)
    func handle(intent: INSetCarLockStatusIntent, completion: @escaping (INSetCarLockStatusIntentResponse) -> Void)
    func resolveCarName(for intent: INSetCarLockStatusIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INSetCarLockStatusIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveLocked(for intent: INSetCarLockStatusIntent) async -> INBooleanResolutionResult
    func resolveLocked(for intent: INSetCarLockStatusIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
}

public extension INSetCarLockStatusIntentHandling {
    func confirm(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse { INSetCarLockStatusIntentResponse() }
    func handle(intent: INSetCarLockStatusIntent) async -> INSetCarLockStatusIntentResponse {
        INSetCarLockStatusIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetCarLockStatusIntent, completion: @escaping (INSetCarLockStatusIntentResponse) -> Void) {
        completion(INSetCarLockStatusIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetCarLockStatusIntent, completion: @escaping (INSetCarLockStatusIntentResponse) -> Void) {
        completion(INSetCarLockStatusIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INSetCarLockStatusIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INSetCarLockStatusIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveLocked(for intent: INSetCarLockStatusIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveLocked(for intent: INSetCarLockStatusIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
}

public protocol INSetClimateSettingsInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse
    func handle(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse
    func confirm(intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSetClimateSettingsInCarIntentResponse) -> Void)
    func handle(intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSetClimateSettingsInCarIntentResponse) -> Void)
    func resolveAirCirculationMode(for intent: INSetClimateSettingsInCarIntent) async -> INCarAirCirculationModeResolutionResult
    func resolveAirCirculationMode(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INCarAirCirculationModeResolutionResult) -> Void)
    func resolveCarName(for intent: INSetClimateSettingsInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveClimateZone(for intent: INSetClimateSettingsInCarIntent) async -> INCarSeatResolutionResult
    func resolveClimateZone(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INCarSeatResolutionResult) -> Void)
    func resolveEnableAirConditioner(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableAirConditioner(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveEnableAutoMode(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableAutoMode(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveEnableClimateControl(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableClimateControl(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveEnableFan(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableFan(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveFanSpeedIndex(for intent: INSetClimateSettingsInCarIntent) async -> INIntegerResolutionResult
    func resolveFanSpeedIndex(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INIntegerResolutionResult) -> Void)
    func resolveFanSpeedPercentage(for intent: INSetClimateSettingsInCarIntent) async -> INDoubleResolutionResult
    func resolveFanSpeedPercentage(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INDoubleResolutionResult) -> Void)
    func resolveRelativeFanSpeedSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult
    func resolveRelativeFanSpeedSetting(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INRelativeSettingResolutionResult) -> Void)
    func resolveRelativeTemperatureSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult
    func resolveRelativeTemperatureSetting(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INRelativeSettingResolutionResult) -> Void)
    func resolveTemperature(for intent: INSetClimateSettingsInCarIntent) async -> INTemperatureResolutionResult
    func resolveTemperature(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INTemperatureResolutionResult) -> Void)
}

public extension INSetClimateSettingsInCarIntentHandling {
    func confirm(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse {
        INSetClimateSettingsInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSetClimateSettingsInCarIntent) async -> INSetClimateSettingsInCarIntentResponse {
        INSetClimateSettingsInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSetClimateSettingsInCarIntentResponse) -> Void) {
        completion(INSetClimateSettingsInCarIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSetClimateSettingsInCarIntentResponse) -> Void) {
        completion(INSetClimateSettingsInCarIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAirCirculationMode(for intent: INSetClimateSettingsInCarIntent) async -> INCarAirCirculationModeResolutionResult { INCarAirCirculationModeResolutionResult.needsValue() }
    func resolveAirCirculationMode(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INCarAirCirculationModeResolutionResult) -> Void) {
        completion(INCarAirCirculationModeResolutionResult.needsValue())
    }
    func resolveCarName(for intent: INSetClimateSettingsInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveClimateZone(for intent: INSetClimateSettingsInCarIntent) async -> INCarSeatResolutionResult { INCarSeatResolutionResult.needsValue() }
    func resolveClimateZone(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INCarSeatResolutionResult) -> Void) {
        completion(INCarSeatResolutionResult.needsValue())
    }
    func resolveEnableAirConditioner(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableAirConditioner(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveEnableAutoMode(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableAutoMode(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveEnableClimateControl(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableClimateControl(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveEnableFan(for intent: INSetClimateSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableFan(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveFanSpeedIndex(for intent: INSetClimateSettingsInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveFanSpeedIndex(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
    func resolveFanSpeedPercentage(for intent: INSetClimateSettingsInCarIntent) async -> INDoubleResolutionResult { INDoubleResolutionResult.needsValue() }
    func resolveFanSpeedPercentage(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INDoubleResolutionResult) -> Void) {
        completion(INDoubleResolutionResult.needsValue())
    }
    func resolveRelativeFanSpeedSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult { INRelativeSettingResolutionResult.needsValue() }
    func resolveRelativeFanSpeedSetting(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INRelativeSettingResolutionResult) -> Void) {
        completion(INRelativeSettingResolutionResult.needsValue())
    }
    func resolveRelativeTemperatureSetting(for intent: INSetClimateSettingsInCarIntent) async -> INRelativeSettingResolutionResult { INRelativeSettingResolutionResult.needsValue() }
    func resolveRelativeTemperatureSetting(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INRelativeSettingResolutionResult) -> Void) {
        completion(INRelativeSettingResolutionResult.needsValue())
    }
    func resolveTemperature(for intent: INSetClimateSettingsInCarIntent) async -> INTemperatureResolutionResult { INTemperatureResolutionResult.needsValue() }
    func resolveTemperature(for intent: INSetClimateSettingsInCarIntent, completion: @escaping (INTemperatureResolutionResult) -> Void) {
        completion(INTemperatureResolutionResult.needsValue())
    }
}

public protocol INSetDefrosterSettingsInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse
    func handle(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse
    func confirm(intent: INSetDefrosterSettingsInCarIntent, completion: @escaping (INSetDefrosterSettingsInCarIntentResponse) -> Void)
    func handle(intent: INSetDefrosterSettingsInCarIntent, completion: @escaping (INSetDefrosterSettingsInCarIntentResponse) -> Void)
    func resolveCarName(for intent: INSetDefrosterSettingsInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INSetDefrosterSettingsInCarIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveDefroster(for intent: INSetDefrosterSettingsInCarIntent) async -> INCarDefrosterResolutionResult
    func resolveDefroster(for intent: INSetDefrosterSettingsInCarIntent, with completion: @escaping (INCarDefrosterResolutionResult) -> Void)
    func resolveEnable(for intent: INSetDefrosterSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnable(for intent: INSetDefrosterSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
}

public extension INSetDefrosterSettingsInCarIntentHandling {
    func confirm(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse { INSetDefrosterSettingsInCarIntentResponse() }
    func handle(intent: INSetDefrosterSettingsInCarIntent) async -> INSetDefrosterSettingsInCarIntentResponse {
        INSetDefrosterSettingsInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetDefrosterSettingsInCarIntent, completion: @escaping (INSetDefrosterSettingsInCarIntentResponse) -> Void) {
        completion(INSetDefrosterSettingsInCarIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetDefrosterSettingsInCarIntent, completion: @escaping (INSetDefrosterSettingsInCarIntentResponse) -> Void) {
        completion(INSetDefrosterSettingsInCarIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INSetDefrosterSettingsInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INSetDefrosterSettingsInCarIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveDefroster(for intent: INSetDefrosterSettingsInCarIntent) async -> INCarDefrosterResolutionResult { INCarDefrosterResolutionResult.needsValue() }
    func resolveDefroster(for intent: INSetDefrosterSettingsInCarIntent, with completion: @escaping (INCarDefrosterResolutionResult) -> Void) {
        completion(INCarDefrosterResolutionResult.needsValue())
    }
    func resolveEnable(for intent: INSetDefrosterSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnable(for intent: INSetDefrosterSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
}

public protocol INSetMessageAttributeIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse
    func handle(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse
    func confirm(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void)
    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void)
    func resolveAttribute(for intent: INSetMessageAttributeIntent) async -> INMessageAttributeResolutionResult
    func resolveAttribute(for intent: INSetMessageAttributeIntent, with completion: @escaping (INMessageAttributeResolutionResult) -> Void)
}

public extension INSetMessageAttributeIntentHandling {
    func confirm(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse { INSetMessageAttributeIntentResponse() }
    func handle(intent: INSetMessageAttributeIntent) async -> INSetMessageAttributeIntentResponse {
        INSetMessageAttributeIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        completion(INSetMessageAttributeIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        completion(INSetMessageAttributeIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAttribute(for intent: INSetMessageAttributeIntent) async -> INMessageAttributeResolutionResult { INMessageAttributeResolutionResult.needsValue() }
    func resolveAttribute(for intent: INSetMessageAttributeIntent, with completion: @escaping (INMessageAttributeResolutionResult) -> Void) {
        completion(INMessageAttributeResolutionResult.needsValue())
    }
}

public protocol INSetProfileInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse
    func handle(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse
    func confirm(intent: INSetProfileInCarIntent, completion: @escaping (INSetProfileInCarIntentResponse) -> Void)
    func handle(intent: INSetProfileInCarIntent, completion: @escaping (INSetProfileInCarIntentResponse) -> Void)
    func resolveCarName(for intent: INSetProfileInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INSetProfileInCarIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveDefaultProfile(forSetProfileInCar intent: INSetProfileInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveProfileName(for intent: INSetProfileInCarIntent) async -> INStringResolutionResult
    func resolveProfileName(for intent: INSetProfileInCarIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolveProfileNumber(for intent: INSetProfileInCarIntent) async -> INIntegerResolutionResult
    func resolveProfileNumber(for intent: INSetProfileInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void)
}

public extension INSetProfileInCarIntentHandling {
    func confirm(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse { INSetProfileInCarIntentResponse() }
    func handle(intent: INSetProfileInCarIntent) async -> INSetProfileInCarIntentResponse {
        INSetProfileInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetProfileInCarIntent, completion: @escaping (INSetProfileInCarIntentResponse) -> Void) {
        completion(INSetProfileInCarIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetProfileInCarIntent, completion: @escaping (INSetProfileInCarIntentResponse) -> Void) {
        completion(INSetProfileInCarIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INSetProfileInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INSetProfileInCarIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveDefaultProfile(forSetProfileInCar intent: INSetProfileInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) { completion(INBooleanResolutionResult.needsValue()) }
    func resolveProfileName(for intent: INSetProfileInCarIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveProfileName(for intent: INSetProfileInCarIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveProfileNumber(for intent: INSetProfileInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveProfileNumber(for intent: INSetProfileInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
}

public protocol INSetRadioStationIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse
    func handle(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse
    func confirm(intent: INSetRadioStationIntent, completion: @escaping (INSetRadioStationIntentResponse) -> Void)
    func handle(intent: INSetRadioStationIntent, completion: @escaping (INSetRadioStationIntentResponse) -> Void)
    func resolveChannel(for intent: INSetRadioStationIntent) async -> INStringResolutionResult
    func resolveChannel(for intent: INSetRadioStationIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolveFrequency(for intent: INSetRadioStationIntent) async -> INDoubleResolutionResult
    func resolveFrequency(for intent: INSetRadioStationIntent, with completion: @escaping (INDoubleResolutionResult) -> Void)
    func resolvePresetNumber(for intent: INSetRadioStationIntent) async -> INIntegerResolutionResult
    func resolvePresetNumber(for intent: INSetRadioStationIntent, with completion: @escaping (INIntegerResolutionResult) -> Void)
    func resolveRadioType(for intent: INSetRadioStationIntent) async -> INRadioTypeResolutionResult
    func resolveRadioType(for intent: INSetRadioStationIntent, with completion: @escaping (INRadioTypeResolutionResult) -> Void)
    func resolveStationName(for intent: INSetRadioStationIntent) async -> INStringResolutionResult
    func resolveStationName(for intent: INSetRadioStationIntent, with completion: @escaping (INStringResolutionResult) -> Void)
}

public extension INSetRadioStationIntentHandling {
    func confirm(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse { INSetRadioStationIntentResponse() }
    func handle(intent: INSetRadioStationIntent) async -> INSetRadioStationIntentResponse {
        INSetRadioStationIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetRadioStationIntent, completion: @escaping (INSetRadioStationIntentResponse) -> Void) {
        completion(INSetRadioStationIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetRadioStationIntent, completion: @escaping (INSetRadioStationIntentResponse) -> Void) {
        completion(INSetRadioStationIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveChannel(for intent: INSetRadioStationIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveChannel(for intent: INSetRadioStationIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveFrequency(for intent: INSetRadioStationIntent) async -> INDoubleResolutionResult { INDoubleResolutionResult.needsValue() }
    func resolveFrequency(for intent: INSetRadioStationIntent, with completion: @escaping (INDoubleResolutionResult) -> Void) {
        completion(INDoubleResolutionResult.needsValue())
    }
    func resolvePresetNumber(for intent: INSetRadioStationIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolvePresetNumber(for intent: INSetRadioStationIntent, with completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
    func resolveRadioType(for intent: INSetRadioStationIntent) async -> INRadioTypeResolutionResult { INRadioTypeResolutionResult.needsValue() }
    func resolveRadioType(for intent: INSetRadioStationIntent, with completion: @escaping (INRadioTypeResolutionResult) -> Void) {
        completion(INRadioTypeResolutionResult.needsValue())
    }
    func resolveStationName(for intent: INSetRadioStationIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveStationName(for intent: INSetRadioStationIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
}

public protocol INSetSeatSettingsInCarIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse
    func handle(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse
    func confirm(intent: INSetSeatSettingsInCarIntent, completion: @escaping (INSetSeatSettingsInCarIntentResponse) -> Void)
    func handle(intent: INSetSeatSettingsInCarIntent, completion: @escaping (INSetSeatSettingsInCarIntentResponse) -> Void)
    func resolveCarName(for intent: INSetSeatSettingsInCarIntent) async -> INSpeakableStringResolutionResult
    func resolveCarName(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveEnableCooling(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableCooling(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveEnableHeating(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableHeating(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveEnableMassage(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult
    func resolveEnableMassage(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveLevel(for intent: INSetSeatSettingsInCarIntent) async -> INIntegerResolutionResult
    func resolveLevel(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void)
    func resolveRelativeLevelSetting(for intent: INSetSeatSettingsInCarIntent) async -> INRelativeSettingResolutionResult
    func resolveRelativeLevelSetting(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INRelativeSettingResolutionResult) -> Void)
    func resolveSeat(for intent: INSetSeatSettingsInCarIntent) async -> INCarSeatResolutionResult
    func resolveSeat(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INCarSeatResolutionResult) -> Void)
}

public extension INSetSeatSettingsInCarIntentHandling {
    func confirm(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse { INSetSeatSettingsInCarIntentResponse() }
    func handle(intent: INSetSeatSettingsInCarIntent) async -> INSetSeatSettingsInCarIntentResponse {
        INSetSeatSettingsInCarIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetSeatSettingsInCarIntent, completion: @escaping (INSetSeatSettingsInCarIntentResponse) -> Void) {
        completion(INSetSeatSettingsInCarIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetSeatSettingsInCarIntent, completion: @escaping (INSetSeatSettingsInCarIntentResponse) -> Void) {
        completion(INSetSeatSettingsInCarIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveCarName(for intent: INSetSeatSettingsInCarIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveCarName(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveEnableCooling(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableCooling(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveEnableHeating(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableHeating(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveEnableMassage(for intent: INSetSeatSettingsInCarIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveEnableMassage(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveLevel(for intent: INSetSeatSettingsInCarIntent) async -> INIntegerResolutionResult { INIntegerResolutionResult.needsValue() }
    func resolveLevel(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.needsValue())
    }
    func resolveRelativeLevelSetting(for intent: INSetSeatSettingsInCarIntent) async -> INRelativeSettingResolutionResult { INRelativeSettingResolutionResult.needsValue() }
    func resolveRelativeLevelSetting(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INRelativeSettingResolutionResult) -> Void) {
        completion(INRelativeSettingResolutionResult.needsValue())
    }
    func resolveSeat(for intent: INSetSeatSettingsInCarIntent) async -> INCarSeatResolutionResult { INCarSeatResolutionResult.needsValue() }
    func resolveSeat(for intent: INSetSeatSettingsInCarIntent, with completion: @escaping (INCarSeatResolutionResult) -> Void) {
        completion(INCarSeatResolutionResult.needsValue())
    }
}

public protocol INSetTaskAttributeIntentHandling: NSObjectProtocol {
    func confirm(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse
    func handle(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse
    func confirm(intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeIntentResponse) -> Void)
    func handle(intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeIntentResponse) -> Void)
    func resolvePriority(for intent: INSetTaskAttributeIntent) async -> INTaskPriorityResolutionResult
    func resolvePriority(for intent: INSetTaskAttributeIntent, completion: @escaping (INTaskPriorityResolutionResult) -> Void)
    func resolveSpatialEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSpatialEventTriggerResolutionResult
    func resolveSpatialEventTrigger(for intent: INSetTaskAttributeIntent, completion: @escaping (INSpatialEventTriggerResolutionResult) -> Void)
    func resolveStatus(for intent: INSetTaskAttributeIntent) async -> INTaskStatusResolutionResult
    func resolveStatus(for intent: INSetTaskAttributeIntent, completion: @escaping (INTaskStatusResolutionResult) -> Void)
    func resolveTargetTask(for intent: INSetTaskAttributeIntent) async -> INTaskResolutionResult
    func resolveTargetTask(for intent: INSetTaskAttributeIntent, completion: @escaping (INTaskResolutionResult) -> Void)
    func resolveTaskTitle(for intent: INSetTaskAttributeIntent) async -> INSpeakableStringResolutionResult
    func resolveTaskTitle(for intent: INSetTaskAttributeIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void)
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeTemporalEventTriggerResolutionResult
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeTemporalEventTriggerResolutionResult) -> Void)
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INTemporalEventTriggerResolutionResult
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent, with completion: @escaping (INTemporalEventTriggerResolutionResult) -> Void)
}

public extension INSetTaskAttributeIntentHandling {
    func confirm(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse {
        INSetTaskAttributeIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeIntentResponse {
        INSetTaskAttributeIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeIntentResponse) -> Void) {
        completion(INSetTaskAttributeIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeIntentResponse) -> Void) {
        completion(INSetTaskAttributeIntentResponse(code: .failure, userActivity: nil))
    }
    func resolvePriority(for intent: INSetTaskAttributeIntent) async -> INTaskPriorityResolutionResult { INTaskPriorityResolutionResult.needsValue() }
    func resolvePriority(for intent: INSetTaskAttributeIntent, completion: @escaping (INTaskPriorityResolutionResult) -> Void) {
        completion(INTaskPriorityResolutionResult.needsValue())
    }
    func resolveSpatialEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSpatialEventTriggerResolutionResult { INSpatialEventTriggerResolutionResult.needsValue() }
    func resolveSpatialEventTrigger(for intent: INSetTaskAttributeIntent, completion: @escaping (INSpatialEventTriggerResolutionResult) -> Void) {
        completion(INSpatialEventTriggerResolutionResult.needsValue())
    }
    func resolveStatus(for intent: INSetTaskAttributeIntent) async -> INTaskStatusResolutionResult { INTaskStatusResolutionResult.needsValue() }
    func resolveStatus(for intent: INSetTaskAttributeIntent, completion: @escaping (INTaskStatusResolutionResult) -> Void) {
        completion(INTaskStatusResolutionResult.needsValue())
    }
    func resolveTargetTask(for intent: INSetTaskAttributeIntent) async -> INTaskResolutionResult { INTaskResolutionResult.needsValue() }
    func resolveTargetTask(for intent: INSetTaskAttributeIntent, completion: @escaping (INTaskResolutionResult) -> Void) {
        completion(INTaskResolutionResult.needsValue())
    }
    func resolveTaskTitle(for intent: INSetTaskAttributeIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveTaskTitle(for intent: INSetTaskAttributeIntent, completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INSetTaskAttributeTemporalEventTriggerResolutionResult { INSetTaskAttributeTemporalEventTriggerResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeTemporalEventTriggerResolutionResult) -> Void) {
        completion(INSetTaskAttributeTemporalEventTriggerResolutionResult.needsValue())
    }
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent) async -> INTemporalEventTriggerResolutionResult { INTemporalEventTriggerResolutionResult.needsValue() }
    func resolveTemporalEventTrigger(for intent: INSetTaskAttributeIntent, with completion: @escaping (INTemporalEventTriggerResolutionResult) -> Void) {
        completion(INTemporalEventTriggerResolutionResult.needsValue())
    }
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
    func confirm(intent: INSnoozeTasksIntent, completion: @escaping (INSnoozeTasksIntentResponse) -> Void)
    func handle(intent: INSnoozeTasksIntent, completion: @escaping (INSnoozeTasksIntentResponse) -> Void)
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent) async -> INDateComponentsRangeResolutionResult
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent, with completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveTasks(for intent: INSnoozeTasksIntent) async -> [INSnoozeTasksTaskResolutionResult]
    func resolveTasks(for intent: INSnoozeTasksIntent, with completion: @escaping ([INSnoozeTasksTaskResolutionResult]) -> Void)
}

public extension INSnoozeTasksIntentHandling {
    func confirm(intent: INSnoozeTasksIntent) async -> INSnoozeTasksIntentResponse { INSnoozeTasksIntentResponse() }
    func handle(intent: INSnoozeTasksIntent) async -> INSnoozeTasksIntentResponse {
        INSnoozeTasksIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INSnoozeTasksIntent, completion: @escaping (INSnoozeTasksIntentResponse) -> Void) {
        completion(INSnoozeTasksIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INSnoozeTasksIntent, completion: @escaping (INSnoozeTasksIntentResponse) -> Void) {
        completion(INSnoozeTasksIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent, with completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveTasks(for intent: INSnoozeTasksIntent) async -> [INSnoozeTasksTaskResolutionResult] { [] }
    func resolveTasks(for intent: INSnoozeTasksIntent, with completion: @escaping ([INSnoozeTasksTaskResolutionResult]) -> Void) {
        completion([])
    }
}

public protocol INSpeakable: NSObjectProtocol {
    var spokenPhrase: String { get }
    var pronunciationHint: String? { get }
    var vocabularyIdentifier: String? { get }
    var identifier: String? { get }
    var alternativeSpeakableMatches: [INSpeakable]? { get }
}

public protocol INStartAudioCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse
    func handle(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse
    func confirm(intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void)
    func handle(intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void)
    func resolveContacts(for intent: INStartAudioCallIntent) async -> [INPersonResolutionResult]
    func resolveContacts(for intent: INStartAudioCallIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void)
    func resolveDestinationType(for intent: INStartAudioCallIntent) async -> INCallDestinationTypeResolutionResult
    func resolveDestinationType(for intent: INStartAudioCallIntent, with completion: @escaping (INCallDestinationTypeResolutionResult) -> Void)
}

public extension INStartAudioCallIntentHandling {
    func confirm(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse { INStartAudioCallIntentResponse() }
    func handle(intent: INStartAudioCallIntent) async -> INStartAudioCallIntentResponse {
        INStartAudioCallIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void) {
        completion(INStartAudioCallIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void) {
        completion(INStartAudioCallIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveContacts(for intent: INStartAudioCallIntent) async -> [INPersonResolutionResult] { [] }
    func resolveContacts(for intent: INStartAudioCallIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }
    func resolveDestinationType(for intent: INStartAudioCallIntent) async -> INCallDestinationTypeResolutionResult { INCallDestinationTypeResolutionResult.needsValue() }
    func resolveDestinationType(for intent: INStartAudioCallIntent, with completion: @escaping (INCallDestinationTypeResolutionResult) -> Void) {
        completion(INCallDestinationTypeResolutionResult.needsValue())
    }
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
    func confirm(intent: INStartPhotoPlaybackIntent, completion: @escaping (INStartPhotoPlaybackIntentResponse) -> Void)
    func handle(intent: INStartPhotoPlaybackIntent, completion: @escaping (INStartPhotoPlaybackIntentResponse) -> Void)
    func resolveAlbumName(for intent: INStartPhotoPlaybackIntent) async -> INStringResolutionResult
    func resolveAlbumName(for intent: INStartPhotoPlaybackIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolveDateCreated(for intent: INStartPhotoPlaybackIntent) async -> INDateComponentsRangeResolutionResult
    func resolveDateCreated(for intent: INStartPhotoPlaybackIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
    func resolveLocationCreated(for intent: INStartPhotoPlaybackIntent) async -> INPlacemarkResolutionResult
    func resolveLocationCreated(for intent: INStartPhotoPlaybackIntent, completion: @escaping (INPlacemarkResolutionResult) -> Void)
    func resolvePeopleInPhoto(for intent: INStartPhotoPlaybackIntent) async -> [INPersonResolutionResult]
    func resolvePeopleInPhoto(for intent: INStartPhotoPlaybackIntent, completion: @escaping ([INPersonResolutionResult]) -> Void)
}

public extension INStartPhotoPlaybackIntentHandling {
    func confirm(intent: INStartPhotoPlaybackIntent) async -> INStartPhotoPlaybackIntentResponse {
        INStartPhotoPlaybackIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INStartPhotoPlaybackIntent) async -> INStartPhotoPlaybackIntentResponse {
        INStartPhotoPlaybackIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INStartPhotoPlaybackIntent, completion: @escaping (INStartPhotoPlaybackIntentResponse) -> Void) {
        completion(INStartPhotoPlaybackIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INStartPhotoPlaybackIntent, completion: @escaping (INStartPhotoPlaybackIntentResponse) -> Void) {
        completion(INStartPhotoPlaybackIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAlbumName(for intent: INStartPhotoPlaybackIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveAlbumName(for intent: INStartPhotoPlaybackIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveDateCreated(for intent: INStartPhotoPlaybackIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveDateCreated(for intent: INStartPhotoPlaybackIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveLocationCreated(for intent: INStartPhotoPlaybackIntent) async -> INPlacemarkResolutionResult { INPlacemarkResolutionResult.needsValue() }
    func resolveLocationCreated(for intent: INStartPhotoPlaybackIntent, completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        completion(INPlacemarkResolutionResult.needsValue())
    }
    func resolvePeopleInPhoto(for intent: INStartPhotoPlaybackIntent) async -> [INPersonResolutionResult] { [] }
    func resolvePeopleInPhoto(for intent: INStartPhotoPlaybackIntent, completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }
}

public protocol INStartVideoCallIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse
    func handle(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse
    func confirm(intent: INStartVideoCallIntent, completion: @escaping (INStartVideoCallIntentResponse) -> Void)
    func handle(intent: INStartVideoCallIntent, completion: @escaping (INStartVideoCallIntentResponse) -> Void)
    func resolveContacts(for intent: INStartVideoCallIntent) async -> [INPersonResolutionResult]
    func resolveContacts(for intent: INStartVideoCallIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void)
}

public extension INStartVideoCallIntentHandling {
    func confirm(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse { INStartVideoCallIntentResponse() }
    func handle(intent: INStartVideoCallIntent) async -> INStartVideoCallIntentResponse {
        INStartVideoCallIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INStartVideoCallIntent, completion: @escaping (INStartVideoCallIntentResponse) -> Void) {
        completion(INStartVideoCallIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INStartVideoCallIntent, completion: @escaping (INStartVideoCallIntentResponse) -> Void) {
        completion(INStartVideoCallIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveContacts(for intent: INStartVideoCallIntent) async -> [INPersonResolutionResult] { [] }
    func resolveContacts(for intent: INStartVideoCallIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }
}

public protocol INStartWorkoutIntentHandling: NSObjectProtocol {
    func confirm(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse
    func handle(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse
    func confirm(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void)
    func handle(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void)
    func resolveGoalValue(for intent: INStartWorkoutIntent) async -> INDoubleResolutionResult
    func resolveGoalValue(for intent: INStartWorkoutIntent, with completion: @escaping (INDoubleResolutionResult) -> Void)
    func resolveIsOpenEnded(for intent: INStartWorkoutIntent) async -> INBooleanResolutionResult
    func resolveIsOpenEnded(for intent: INStartWorkoutIntent, with completion: @escaping (INBooleanResolutionResult) -> Void)
    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent) async -> INWorkoutGoalUnitTypeResolutionResult
    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutGoalUnitTypeResolutionResult) -> Void)
    func resolveWorkoutLocationType(for intent: INStartWorkoutIntent) async -> INWorkoutLocationTypeResolutionResult
    func resolveWorkoutLocationType(for intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutLocationTypeResolutionResult) -> Void)
    func resolveWorkoutName(for intent: INStartWorkoutIntent) async -> INSpeakableStringResolutionResult
    func resolveWorkoutName(for intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void)
}

public extension INStartWorkoutIntentHandling {
    func confirm(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse { INStartWorkoutIntentResponse() }
    func handle(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse {
        INStartWorkoutIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        completion(INStartWorkoutIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        completion(INStartWorkoutIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveGoalValue(for intent: INStartWorkoutIntent) async -> INDoubleResolutionResult { INDoubleResolutionResult.needsValue() }
    func resolveGoalValue(for intent: INStartWorkoutIntent, with completion: @escaping (INDoubleResolutionResult) -> Void) {
        completion(INDoubleResolutionResult.needsValue())
    }
    func resolveIsOpenEnded(for intent: INStartWorkoutIntent) async -> INBooleanResolutionResult { INBooleanResolutionResult.needsValue() }
    func resolveIsOpenEnded(for intent: INStartWorkoutIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.needsValue())
    }
    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent) async -> INWorkoutGoalUnitTypeResolutionResult { INWorkoutGoalUnitTypeResolutionResult.needsValue() }
    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutGoalUnitTypeResolutionResult) -> Void) {
        completion(INWorkoutGoalUnitTypeResolutionResult.needsValue())
    }
    func resolveWorkoutLocationType(for intent: INStartWorkoutIntent) async -> INWorkoutLocationTypeResolutionResult { INWorkoutLocationTypeResolutionResult.needsValue() }
    func resolveWorkoutLocationType(for intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutLocationTypeResolutionResult) -> Void) {
        completion(INWorkoutLocationTypeResolutionResult.needsValue())
    }
    func resolveWorkoutName(for intent: INStartWorkoutIntent) async -> INSpeakableStringResolutionResult { INSpeakableStringResolutionResult.needsValue() }
    func resolveWorkoutName(for intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

public protocol INTransferMoneyIntentHandling: NSObjectProtocol {
    func confirm(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse
    func handle(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse
    func confirm(intent: INTransferMoneyIntent, completion: @escaping (INTransferMoneyIntentResponse) -> Void)
    func handle(intent: INTransferMoneyIntent, completion: @escaping (INTransferMoneyIntentResponse) -> Void)
    func resolveFromAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult
    func resolveFromAccount(for intent: INTransferMoneyIntent, completion: @escaping (INPaymentAccountResolutionResult) -> Void)
    func resolveToAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult
    func resolveToAccount(for intent: INTransferMoneyIntent, completion: @escaping (INPaymentAccountResolutionResult) -> Void)
    func resolveTransactionAmount(for intent: INTransferMoneyIntent) async -> INPaymentAmountResolutionResult
    func resolveTransactionAmount(for intent: INTransferMoneyIntent, completion: @escaping (INPaymentAmountResolutionResult) -> Void)
    func resolveTransactionNote(for intent: INTransferMoneyIntent) async -> INStringResolutionResult
    func resolveTransactionNote(for intent: INTransferMoneyIntent, completion: @escaping (INStringResolutionResult) -> Void)
    func resolveTransactionScheduledDate(for intent: INTransferMoneyIntent) async -> INDateComponentsRangeResolutionResult
    func resolveTransactionScheduledDate(for intent: INTransferMoneyIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void)
}

public extension INTransferMoneyIntentHandling {
    func confirm(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse {
        INTransferMoneyIntentResponse(code: .failure, userActivity: nil)
    }
    func handle(intent: INTransferMoneyIntent) async -> INTransferMoneyIntentResponse {
        INTransferMoneyIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INTransferMoneyIntent, completion: @escaping (INTransferMoneyIntentResponse) -> Void) {
        completion(INTransferMoneyIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INTransferMoneyIntent, completion: @escaping (INTransferMoneyIntentResponse) -> Void) {
        completion(INTransferMoneyIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveFromAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult { INPaymentAccountResolutionResult.needsValue() }
    func resolveFromAccount(for intent: INTransferMoneyIntent, completion: @escaping (INPaymentAccountResolutionResult) -> Void) {
        completion(INPaymentAccountResolutionResult.needsValue())
    }
    func resolveToAccount(for intent: INTransferMoneyIntent) async -> INPaymentAccountResolutionResult { INPaymentAccountResolutionResult.needsValue() }
    func resolveToAccount(for intent: INTransferMoneyIntent, completion: @escaping (INPaymentAccountResolutionResult) -> Void) {
        completion(INPaymentAccountResolutionResult.needsValue())
    }
    func resolveTransactionAmount(for intent: INTransferMoneyIntent) async -> INPaymentAmountResolutionResult { INPaymentAmountResolutionResult.needsValue() }
    func resolveTransactionAmount(for intent: INTransferMoneyIntent, completion: @escaping (INPaymentAmountResolutionResult) -> Void) {
        completion(INPaymentAmountResolutionResult.needsValue())
    }
    func resolveTransactionNote(for intent: INTransferMoneyIntent) async -> INStringResolutionResult { INStringResolutionResult.needsValue() }
    func resolveTransactionNote(for intent: INTransferMoneyIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.needsValue())
    }
    func resolveTransactionScheduledDate(for intent: INTransferMoneyIntent) async -> INDateComponentsRangeResolutionResult { INDateComponentsRangeResolutionResult.needsValue() }
    func resolveTransactionScheduledDate(for intent: INTransferMoneyIntent, completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
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
    func confirm(intent: INUpdateMediaAffinityIntent, completion: @escaping (INUpdateMediaAffinityIntentResponse) -> Void)
    func handle(intent: INUpdateMediaAffinityIntent, completion: @escaping (INUpdateMediaAffinityIntentResponse) -> Void)
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent) async -> INMediaAffinityTypeResolutionResult
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent, with completion: @escaping (INMediaAffinityTypeResolutionResult) -> Void)
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent) async -> [INUpdateMediaAffinityMediaItemResolutionResult]
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent, with completion: @escaping ([INUpdateMediaAffinityMediaItemResolutionResult]) -> Void)
}

public extension INUpdateMediaAffinityIntentHandling {
    func confirm(intent: INUpdateMediaAffinityIntent) async -> INUpdateMediaAffinityIntentResponse { INUpdateMediaAffinityIntentResponse() }
    func handle(intent: INUpdateMediaAffinityIntent) async -> INUpdateMediaAffinityIntentResponse {
        INUpdateMediaAffinityIntentResponse(code: .failure, userActivity: nil)
    }
    func confirm(intent: INUpdateMediaAffinityIntent, completion: @escaping (INUpdateMediaAffinityIntentResponse) -> Void) {
        completion(INUpdateMediaAffinityIntentResponse(code: .ready, userActivity: nil))
    }
    func handle(intent: INUpdateMediaAffinityIntent, completion: @escaping (INUpdateMediaAffinityIntentResponse) -> Void) {
        completion(INUpdateMediaAffinityIntentResponse(code: .failure, userActivity: nil))
    }
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent) async -> INMediaAffinityTypeResolutionResult { INMediaAffinityTypeResolutionResult.needsValue() }
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent, with completion: @escaping (INMediaAffinityTypeResolutionResult) -> Void) {
        completion(INMediaAffinityTypeResolutionResult.needsValue())
    }
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent) async -> [INUpdateMediaAffinityMediaItemResolutionResult] { [] }
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent, with completion: @escaping ([INUpdateMediaAffinityMediaItemResolutionResult]) -> Void) {
        completion([])
    }
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
