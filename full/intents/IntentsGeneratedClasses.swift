// Generated Intents classes. Members that need CoreLocation/Contacts/EventKit/CoreGraphics
// types are omitted (coverage: deferred). Remaining members are source-compatible stubs
// or fail-closed. Existing operational types stay in Intents.swift.

open class INAccountTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with accountTypeToConfirm: INAccountType) -> Self { self.init() as! Self }
    open class func success(with resolvedAccountType: INAccountType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INActivateCarSignalIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var signals: INCarSignalOptions = []
    public init(carName: INSpeakableString?, signals: INCarSignalOptions = []) {
        super.init()
    }
}

open class INActivateCarSignalIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INActivateCarSignalIntentResponseCode?
    open var signals: INCarSignalOptions = []
    public init(code: INActivateCarSignalIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INAddMediaIntent: INIntent, @unchecked Sendable {
    open var mediaDestination: INMediaDestination? = nil
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    public init(mediaItems: [INMediaItem]?, mediaSearch: INMediaSearch?, mediaDestination: INMediaDestination?) {
        super.init()
    }
}

open class INAddMediaIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INAddMediaIntentResponseCode?
    public init(code: INAddMediaIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INAddMediaMediaDestinationResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INAddMediaMediaDestinationUnsupportedReason) -> Self { self.init() as! Self }
    public init(mediaDestinationResolutionResult: INMediaDestinationResolutionResult) {
        super.init()
    }
}

open class INAddMediaMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INAddMediaMediaItemResolutionResult] { [] }
    open class func unsupported(forReason reason: INAddMediaMediaItemUnsupportedReason) -> Self { self.init() as! Self }
    public init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        super.init()
    }
}

open class INAddTasksIntent: INIntent, @unchecked Sendable {
    open var priority: INTaskPriority?
    open var spatialEventTrigger: INSpatialEventTrigger? = nil
    open var targetTaskList: INTaskList? = nil
    open var taskTitles: [INSpeakableString]? = nil
    open var temporalEventTrigger: INTemporalEventTrigger? = nil
    public init(targetTaskList: INTaskList?, taskTitles: [INSpeakableString]?, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?) {
        super.init()
    }
    public init(targetTaskList: INTaskList?, taskTitles: [INSpeakableString]?, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?, priority: INTaskPriority) {
        super.init()
    }
}

open class INAddTasksIntentResponse: INIntentResponse, @unchecked Sendable {
    open var addedTasks: [INTask]? = nil
    open var code: INAddTasksIntentResponseCode?
    open var modifiedTaskList: INTaskList? = nil
    public init(code: INAddTasksIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INAddTasksTargetTaskListResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskListToConfirm: INTaskList?, forReason reason: INAddTasksTargetTaskListConfirmationReason) -> Self { self.init() as! Self }
    public init(taskListResolutionResult: INTaskListResolutionResult) {
        super.init()
    }
}

open class INAddTasksTemporalEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INAddTasksTemporalEventTriggerUnsupportedReason) -> Self { self.init() as! Self }
    public init(temporalEventTriggerResolutionResult: INTemporalEventTriggerResolutionResult) {
        super.init()
    }
}

open class INAirline: NSObject, @unchecked Sendable {
    open var iataCode: String? = nil
    open var icaoCode: String? = nil
    open var name: String? = nil
    public init(name: String?, iataCode: String?, icaoCode: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INAirport: NSObject, @unchecked Sendable {
    open var iataCode: String? = nil
    open var icaoCode: String? = nil
    open var name: String? = nil
    public init(name: String?, iataCode: String?, icaoCode: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INAirportGate: NSObject, @unchecked Sendable {
    open var airport: INAirport?
    open var gate: String? = nil
    open var terminal: String? = nil
    public init(airport: INAirport, terminal: String?, gate: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INAnswerCallIntent: INIntent, @unchecked Sendable {
    open var audioRoute: INCallAudioRoute?
    open var callIdentifier: String? = nil
    public init(audioRoute: INCallAudioRoute, callIdentifier: String?) {
        super.init()
    }
}

open class INAnswerCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var callRecords: [INCallRecord]? = nil
    open var code: INAnswerCallIntentResponseCode?
    public init(code: INAnswerCallIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INAppendToNoteIntent: INIntent, @unchecked Sendable {
    open var content: INNoteContent? = nil
    open var targetNote: INNote? = nil
    public init(targetNote: INNote?, content: INNoteContent?) {
        super.init()
    }
}

open class INAppendToNoteIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INAppendToNoteIntentResponseCode?
    open var note: INNote? = nil
    public init(code: INAppendToNoteIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INBalanceAmount: NSObject, @unchecked Sendable {
    open var amount: NSDecimalNumber? = nil
    open var balanceType: INBalanceType?
    open var currencyCode: String? = nil
    public init?(amount: NSDecimalNumber, balanceType: INBalanceType) {
        super.init()
    }
    public init(amount: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INBalanceTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with balanceTypeToConfirm: INBalanceType) -> Self { self.init() as! Self }
    open class func success(with resolvedBalanceType: INBalanceType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INBillDetails: NSObject, @unchecked Sendable {
    open var amountDue: INCurrencyAmount? = nil
    open var billPayee: INBillPayee? = nil
    open var billType: INBillType?
    open var dueDate: DateComponents? = nil
    open var lateFee: INCurrencyAmount? = nil
    open var minimumDue: INCurrencyAmount? = nil
    open var paymentDate: DateComponents? = nil
    open var paymentStatus: INPaymentStatus?
    public init?(billType: INBillType, paymentStatus: INPaymentStatus, billPayee: INBillPayee?, amountDue: INCurrencyAmount?, minimumDue: INCurrencyAmount?, lateFee: INCurrencyAmount?, dueDate: DateComponents?, paymentDate: DateComponents?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INBillPayee: NSObject, @unchecked Sendable {
    open var accountNumber: String? = nil
    open var nickname: INSpeakableString? = nil
    open var organizationName: INSpeakableString? = nil
    public init?(nickname: INSpeakableString, number: String?, organizationName: INSpeakableString?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INBillPayeeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with billPayeeToConfirm: INBillPayee?) -> Self { self.init() as! Self }
    open class func disambiguation(with billPayeesToDisambiguate: [INBillPayee]) -> Self { self.init() as! Self }
    open class func success(with resolvedBillPayee: INBillPayee) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INBillTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with billTypeToConfirm: INBillType) -> Self { self.init() as! Self }
    open class func success(with resolvedBillType: INBillType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INBoatReservation: NSObject, @unchecked Sendable {
    open var boatTrip: INBoatTrip? = nil
    open var reservedSeat: INSeat? = nil
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, boatTrip: INBoatTrip?) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, boatTrip: INBoatTrip?) {
        super.init()
    }
}

open class INBoatTrip: NSObject, @unchecked Sendable {
    open var boatName: String? = nil
    open var boatNumber: String? = nil
    open var provider: String? = nil
    open var tripDuration: INDateComponentsRange?
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INBookRestaurantReservationIntent: INIntent, @unchecked Sendable {
    open var bookingDateComponents: DateComponents?
    open var bookingIdentifier: String? = nil
    open var guest: INRestaurantGuest? = nil
    open var guestProvidedSpecialRequestText: String? = nil
    open var partySize: Int = 0
    open var restaurant: INRestaurant?
    open var selectedOffer: INRestaurantOffer? = nil
    public init(restaurant: INRestaurant, booking bookingDateComponents: DateComponents, partySize: Int, bookingIdentifier: String?, guest: INRestaurantGuest?, selectedOffer: INRestaurantOffer?, guestProvidedSpecialRequestText: String?) {
        super.init()
    }
    public init(restaurant: INRestaurant, bookingDateComponents: DateComponents, partySize: Int, bookingIdentifier: String?, guest: INRestaurantGuest?, selectedOffer: INRestaurantOffer?, guestProvidedSpecialRequestText: String?) {
        super.init()
    }
}

open class INBookRestaurantReservationIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INBookRestaurantReservationIntentCode?
    open var userBooking: INRestaurantReservationUserBooking? = nil
    public init(code: INBookRestaurantReservationIntentCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INBusReservation: NSObject, @unchecked Sendable {
    open var busTrip: INBusTrip?
    open var reservedSeat: INSeat? = nil
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, busTrip: INBusTrip?) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, busTrip: INBusTrip?) {
        super.init()
    }
}

open class INBusTrip: NSObject, @unchecked Sendable {
    open var arrivalPlatform: String? = nil
    open var busName: String? = nil
    open var busNumber: String? = nil
    open var departurePlatform: String? = nil
    open var provider: String? = nil
    open var tripDuration: INDateComponentsRange?
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INCallCapabilityResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callCapabilityToConfirm: INCallCapability) -> Self { self.init() as! Self }
    open class func success(with resolvedCallCapability: INCallCapability) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCallDestinationTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callDestinationTypeToConfirm: INCallDestinationType) -> Self { self.init() as! Self }
    open class func success(with resolvedCallDestinationType: INCallDestinationType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCallGroup: NSObject, @unchecked Sendable {
    open var groupId: String? = nil
    open var groupName: String? = nil
    public init(groupName: String?, groupId: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INCallRecord: NSObject, @unchecked Sendable {
    open var callCapability: INCallCapability?
    open var callRecordType: INCallRecordType?
    open var caller: INPerson? = nil
    open var dateCreated: Date? = nil
    open var identifier: String = ""
    open var participants: [INPerson]? = nil
    open var callDuration: Double? = nil
    open var numberOfCalls: Int? = nil
    open var unseen: Bool? = nil
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INCallRecordFilter: NSObject, @unchecked Sendable {
    open var callCapability: INCallCapability?
    open var callTypes: INCallRecordTypeOptions = []
    open var participants: [INPerson]? = nil
    public init(participants: [INPerson]?, callTypes: INCallRecordTypeOptions = [], callCapability: INCallCapability) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INCallRecordResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callRecordToConfirm: INCallRecord?) -> Self { self.init() as! Self }
    open class func disambiguation(with callRecordsToDisambiguate: [INCallRecord]) -> Self { self.init() as! Self }
    open class func success(with resolvedCallRecord: INCallRecord) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCallRecordTypeOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callRecordTypeOptionsToConfirm: INCallRecordTypeOptions = []) -> Self { self.init() as! Self }
    open class func success(with resolvedCallRecordTypeOptions: INCallRecordTypeOptions = []) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCallRecordTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callRecordTypeToConfirm: INCallRecordType) -> Self { self.init() as! Self }
    open class func success(with resolvedCallRecordType: INCallRecordType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCancelRideIntent: INIntent, @unchecked Sendable {
    open var rideIdentifier: String = ""
    public init(rideIdentifier: String) {
        super.init()
    }
}

open class INCancelRideIntentResponse: INIntentResponse, @unchecked Sendable {
    open var cancellationFee: INCurrencyAmount? = nil
    open var cancellationFeeThreshold: DateComponents? = nil
    open var code: INCancelRideIntentResponseCode?
    public init(code: INCancelRideIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INCancelWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public init(workoutName: INSpeakableString?) {
        super.init()
    }
}

open class INCancelWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INCancelWorkoutIntentResponseCode?
    public init(code: INCancelWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INCar: NSObject, @unchecked Sendable {
    public struct ChargingConnectorType: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let ccs1 = ChargingConnectorType(rawValue: "ccs1")
        public static let ccs2 = ChargingConnectorType(rawValue: "ccs2")
        public static let chaDeMo = ChargingConnectorType(rawValue: "chaDeMo")
        public static let gbtAC = ChargingConnectorType(rawValue: "gbtAC")
        public static let gbtDC = ChargingConnectorType(rawValue: "gbtDC")
        public static let j1772 = ChargingConnectorType(rawValue: "j1772")
        public static let mennekes = ChargingConnectorType(rawValue: "mennekes")
        public static let nacsAC = ChargingConnectorType(rawValue: "nacsAC")
        public static let nacsDC = ChargingConnectorType(rawValue: "nacsDC")
        public static let tesla = ChargingConnectorType(rawValue: "tesla")
    }

    open class HeadUnit: NSObject, @unchecked Sendable {
        public init(bluetoothIdentifier: String?, iAP2Identifier: String?) {
            super.init()
        }
        open var bluetoothIdentifier: String? = nil
        open var iAP2Identifier: String? = nil
        public init?(coder: NSCoder) {
            return nil
        }
        public override init() { super.init() }
    }

    open func maximumPower(for chargingConnectorType: INCar.ChargingConnectorType) -> Measurement<UnitPower>? { nil }
    open func setMaximumPower(_ power: Measurement<UnitPower>, for chargingConnectorType: INCar.ChargingConnectorType) { }
    open var carIdentifier: String = ""
    open var displayName: String? = nil
    open var headUnit: INCar.HeadUnit? = nil
    open var make: String? = nil
    open var model: String? = nil
    open var supportedChargingConnectors: [INCar.ChargingConnectorType] = []
    open var year: String? = nil
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INCarAirCirculationModeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carAirCirculationModeToConfirm: INCarAirCirculationMode) -> Self { self.init() as! Self }
    open class func success(with resolvedCarAirCirculationMode: INCarAirCirculationMode) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCarAudioSourceResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carAudioSourceToConfirm: INCarAudioSource) -> Self { self.init() as! Self }
    open class func success(with resolvedCarAudioSource: INCarAudioSource) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCarDefrosterResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carDefrosterToConfirm: INCarDefroster) -> Self { self.init() as! Self }
    open class func success(with resolvedCarDefroster: INCarDefroster) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCarSeatResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carSeatToConfirm: INCarSeat) -> Self { self.init() as! Self }
    open class func success(with resolvedCarSeat: INCarSeat) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCarSignalOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carSignalOptionsToConfirm: INCarSignalOptions = []) -> Self { self.init() as! Self }
    open class func success(with resolvedCarSignalOptions: INCarSignalOptions = []) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INCreateNoteIntent: INIntent, @unchecked Sendable {
    open var content: INNoteContent? = nil
    open var groupName: INSpeakableString? = nil
    open var title: INSpeakableString? = nil
    public init(title: INSpeakableString?, content: INNoteContent?, groupName: INSpeakableString?) {
        super.init()
    }
}

open class INCreateNoteIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INCreateNoteIntentResponseCode?
    open var createdNote: INNote? = nil
    public init(code: INCreateNoteIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INCreateTaskListIntent: INIntent, @unchecked Sendable {
    open var groupName: INSpeakableString? = nil
    open var taskTitles: [INSpeakableString]? = nil
    open var title: INSpeakableString? = nil
    public init(title: INSpeakableString?, taskTitles: [INSpeakableString]?, groupName: INSpeakableString?) {
        super.init()
    }
}

open class INCreateTaskListIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INCreateTaskListIntentResponseCode?
    open var createdTaskList: INTaskList? = nil
    public init(code: INCreateTaskListIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INCurrencyAmount: NSObject, @unchecked Sendable {
    open var amount: NSDecimalNumber? = nil
    open var currencyCode: String? = nil
    public init(amount: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INCurrencyAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with currencyAmountToConfirm: INCurrencyAmount?) -> Self { self.init() as! Self }
    open class func disambiguation(with currencyAmountsToDisambiguate: [INCurrencyAmount]) -> Self { self.init() as! Self }
    open class func success(with resolvedCurrencyAmount: INCurrencyAmount) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INDailyRoutineRelevanceProvider: NSObject, @unchecked Sendable {
    public enum Situation: Int, Hashable, Sendable {
        case activeWorkout = 8
        case commute = 6
        case evening = 1
        case gym = 5
        case headphonesConnected = 7
        case home = 2
        case morning = 0
        case physicalActivityIncomplete = 9
        case school = 4
        case work = 3
    }

    open var situation: INDailyRoutineRelevanceProvider.Situation?
    public init(situation: INDailyRoutineRelevanceProvider.Situation) {
        super.init()
    }
}

open class INDateComponentsRange: NSObject, @unchecked Sendable {
    open var endDateComponents: DateComponents? = nil
    open var recurrenceRule: INRecurrenceRule? = nil
    open var startDateComponents: DateComponents? = nil
    public init(start startDateComponents: DateComponents?, end endDateComponents: DateComponents?) {
        super.init()
    }
    public init(startDateComponents: DateComponents?, endDateComponents: DateComponents?) {
        super.init()
    }
    public init(start startDateComponents: DateComponents?, end endDateComponents: DateComponents?, recurrenceRule: INRecurrenceRule?) {
        super.init()
    }
    public init(startDateComponents: DateComponents?, endDateComponents: DateComponents?, recurrenceRule: INRecurrenceRule?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INDateComponentsRangeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with dateComponentsRangeToConfirm: INDateComponentsRange?) -> Self { self.init() as! Self }
    open class func disambiguation(with dateComponentsRangesToDisambiguate: [INDateComponentsRange]) -> Self { self.init() as! Self }
    open class func success(with resolvedDateComponentsRange: INDateComponentsRange) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INDateComponentsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with dateComponentsToConfirm: DateComponents?) -> Self { self.init() as! Self }
    open class func disambiguation(with dateComponentsToDisambiguate: [DateComponents]) -> Self { self.init() as! Self }
    open class func success(with resolvedDateComponents: DateComponents) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INDateRelevanceProvider: NSObject, @unchecked Sendable {
    open var endDate: Date? = nil
    open var startDate: Date?
    public init(start startDate: Date, end endDate: Date?) {
        super.init()
    }
    public init(startDate: Date, endDate: Date?) {
        super.init()
    }
}

open class INDateSearchTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with dateSearchTypeToConfirm: INDateSearchType) -> Self { self.init() as! Self }
    open class func success(with resolvedDateSearchType: INDateSearchType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INDefaultCardTemplate: NSObject, @unchecked Sendable {
    open var image: INImage? = nil
    open var subtitle: String? = nil
    open var title: String = ""
    public init(title: String) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INDeleteTasksIntent: INIntent, @unchecked Sendable {
    open var taskList: INTaskList? = nil
    open var tasks: [INTask]? = nil
    open var all: Bool? = nil
    public override init() { super.init() }
}

open class INDeleteTasksIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INDeleteTasksIntentResponseCode?
    open var deletedTasks: [INTask]? = nil
    public init(code: INDeleteTasksIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INDeleteTasksTaskListResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INDeleteTasksTaskListUnsupportedReason) -> Self { self.init() as! Self }
    public init(taskListResolutionResult: INTaskListResolutionResult) {
        super.init()
    }
}

open class INDeleteTasksTaskResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INDeleteTasksTaskUnsupportedReason) -> Self { self.init() as! Self }
    public init(taskResolutionResult: INTaskResolutionResult) {
        super.init()
    }
}

open class INEditMessageIntent: INIntent, @unchecked Sendable {
    open var editedContent: String? = nil
    open var messageIdentifier: String? = nil
    public init(messageIdentifier: String?, editedContent: String?) {
        super.init()
    }
}

open class INEditMessageIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INEditMessageIntentResponseCode?
    public init(code: INEditMessageIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INEndWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public init(workoutName: INSpeakableString?) {
        super.init()
    }
}

open class INEndWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INEndWorkoutIntentResponseCode?
    public init(code: INEndWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INEnergyResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with energyToConfirm: Measurement<UnitEnergy>?) -> Self { self.init() as! Self }
    open class func disambiguation(with energyToDisambiguate: [Measurement<UnitEnergy>]) -> Self { self.init() as! Self }
    open class func success(with resolvedEnergy: Measurement<UnitEnergy>) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INFile: NSObject, @unchecked Sendable {
    open var data: Data?
    open var fileURL: URL? = nil
    open var filename: String = ""
    open var removedOnCompletion: Bool = false
    open var typeIdentifier: String? = nil
    public init(data: Data, filename: String, typeIdentifier: String?) {
        super.init()
    }
    public init(fileURL: URL, filename: String?, typeIdentifier: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INFileResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with fileToConfirm: INFile?) -> Self { self.init() as! Self }
    open class func disambiguation(with filesToDisambiguate: [INFile]) -> Self { self.init() as! Self }
    open class func success(with resolvedFile: INFile) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INFlight: NSObject, @unchecked Sendable {
    open var airline: INAirline?
    open var arrivalAirportGate: INAirportGate?
    open var boardingTime: INDateComponentsRange? = nil
    open var departureAirportGate: INAirportGate?
    open var flightDuration: INDateComponentsRange?
    open var flightNumber: String = ""
    public init(airline: INAirline, flightNumber: String, boardingTime: INDateComponentsRange?, flightDuration: INDateComponentsRange, departureAirportGate: INAirportGate, arrivalAirportGate: INAirportGate) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INFlightReservation: NSObject, @unchecked Sendable {
    open var flight: INFlight?
    open var reservedSeat: INSeat? = nil
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, flight: INFlight) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, flight: INFlight) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, reservedSeat: INSeat?, flight: INFlight) {
        super.init()
    }
}

open class INGetAvailableRestaurantReservationBookingDefaultsIntent: INIntent, @unchecked Sendable {
    open var restaurant: INRestaurant? = nil
    public init(restaurant: INRestaurant?) {
        super.init()
    }
}

open class INGetAvailableRestaurantReservationBookingDefaultsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode?
    open var defaultBookingDate: Date?
    open var defaultPartySize: Int = 0
    open var maximumPartySize: NSNumber? = nil
    open var minimumPartySize: NSNumber? = nil
    open var providerImage: INImage?
    public init(defaultPartySize: Int, defaultBooking defaultBookingDate: Date, code: INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
    public init(defaultPartySize: Int, defaultBookingDate: Date, code: INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetAvailableRestaurantReservationBookingsIntent: INIntent, @unchecked Sendable {
    open var earliestBookingDateForResults: Date? = nil
    open var latestBookingDateForResults: Date? = nil
    open var maximumNumberOfResults: NSNumber? = nil
    open var partySize: Int = 0
    open var preferredBookingDateComponents: DateComponents? = nil
    open var restaurant: INRestaurant?
    public init(restaurant: INRestaurant, partySize: Int, preferredBooking preferredBookingDateComponents: DateComponents?, maximumNumberOfResults: NSNumber?, earliestBookingDateForResults: Date?, latestBookingDateForResults: Date?) {
        super.init()
    }
    public init(restaurant: INRestaurant, partySize: Int, preferredBookingDateComponents: DateComponents?, maximumNumberOfResults: NSNumber?, earliestBookingDateForResults: Date?, latestBookingDateForResults: Date?) {
        super.init()
    }
}

open class INGetAvailableRestaurantReservationBookingsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var availableBookings: [INRestaurantReservationBooking] = []
    open var code: INGetAvailableRestaurantReservationBookingsIntentCode?
    open var localizedBookingAdvisementText: String? = nil
    open var localizedRestaurantDescriptionText: String? = nil
    open var termsAndConditions: INTermsAndConditions? = nil
    public init(availableBookings: [INRestaurantReservationBooking], code: INGetAvailableRestaurantReservationBookingsIntentCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetCarLockStatusIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    public init(carName: INSpeakableString?) {
        super.init()
    }
}

open class INGetCarLockStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetCarLockStatusIntentResponseCode?
    open var locked: Bool? = nil
    public init(code: INGetCarLockStatusIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetCarPowerLevelStatusIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    public init(carName: INSpeakableString?) {
        super.init()
    }
}

open class INGetCarPowerLevelStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var activeConnector: INCar.ChargingConnectorType? = nil
    open var carIdentifier: String? = nil
    open var chargingFormulaArguments: [String : Any]? = nil
    open var code: INGetCarPowerLevelStatusIntentResponseCode?
    open var consumptionFormulaArguments: [String : Any]? = nil
    open var currentBatteryCapacity: Measurement<UnitEnergy>? = nil
    open var dateOfLastStateUpdate: DateComponents? = nil
    open var distanceRemaining: Measurement<UnitLength>? = nil
    open var distanceRemainingElectric: Measurement<UnitLength>? = nil
    open var distanceRemainingFuel: Measurement<UnitLength>? = nil
    open var maximumBatteryCapacity: Measurement<UnitEnergy>? = nil
    open var maximumDistance: Measurement<UnitLength>? = nil
    open var maximumDistanceElectric: Measurement<UnitLength>? = nil
    open var maximumDistanceFuel: Measurement<UnitLength>? = nil
    open var minimumBatteryCapacity: Measurement<UnitEnergy>? = nil
    open var minutesToFull: Int? = nil
    open var fuelPercentRemaining: Float? = nil
    open var chargePercentRemaining: Float? = nil
    open var charging: Bool? = nil
    public init(code: INGetCarPowerLevelStatusIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetReservationDetailsIntent: INIntent, @unchecked Sendable {
    open var reservationContainerReference: INSpeakableString? = nil
    open var reservationItemReferences: [INSpeakableString]? = nil
    public init(reservationContainerReference: INSpeakableString?, reservationItemReferences: [INSpeakableString]?) {
        super.init()
    }
}

open class INGetReservationDetailsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetReservationDetailsIntentResponseCode?
    open var reservations: [INReservation]? = nil
    public init(code: INGetReservationDetailsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetRestaurantGuestIntent: INIntent, @unchecked Sendable {
    public override init() { super.init() }
}

open class INGetRestaurantGuestIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetRestaurantGuestIntentResponseCode?
    open var guest: INRestaurantGuest? = nil
    open var guestDisplayPreferences: INRestaurantGuestDisplayPreferences? = nil
    public init(code: INGetRestaurantGuestIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetRideStatusIntent: INIntent, @unchecked Sendable {
    public init() {
        super.init()
    }
}

open class INGetRideStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetRideStatusIntentResponseCode?
    open var rideStatus: INRideStatus? = nil
    public init(code: INGetRideStatusIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetUserCurrentRestaurantReservationBookingsIntent: INIntent, @unchecked Sendable {
    open var earliestBookingDateForResults: Date? = nil
    open var maximumNumberOfResults: NSNumber? = nil
    open var reservationIdentifier: String? = nil
    open var restaurant: INRestaurant? = nil
    public init(restaurant: INRestaurant?, reservationIdentifier: String?, maximumNumberOfResults: NSNumber?, earliestBookingDateForResults: Date?) {
        super.init()
    }
}

open class INGetUserCurrentRestaurantReservationBookingsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetUserCurrentRestaurantReservationBookingsIntentResponseCode?
    open var userCurrentBookings: [INRestaurantReservationUserBooking] = []
    public init(userCurrentBookings: [INRestaurantReservationUserBooking], code: INGetUserCurrentRestaurantReservationBookingsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INGetVisualCodeIntent: INIntent, @unchecked Sendable {
    open var visualCodeType: INVisualCodeType?
    public init(visualCodeType: INVisualCodeType) {
        super.init()
    }
}

open class INGetVisualCodeIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetVisualCodeIntentResponseCode?
    open var visualCodeImage: INImage? = nil
    public init(code: INGetVisualCodeIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INHangUpCallIntent: INIntent, @unchecked Sendable {
    open var callIdentifier: String? = nil
    public init(callIdentifier: String?) {
        super.init()
    }
}

open class INHangUpCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INHangUpCallIntentResponseCode?
    public init(code: INHangUpCallIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INImageNoteContent: NSObject, @unchecked Sendable {
    open var image: INImage? = nil
    public init(image: INImage) {
        super.init()
    }
}

extension INIntent {
    open func setImage<Value>(_ image: INImage?, forParameterNamed parameterName: KeyPath<Self, Value>) { }
    open func image<Value>(forParameterNamed parameterName: KeyPath<Self, Value>) -> INImage? { nil }
}

open class INIntentDonationMetadata: NSObject, @unchecked Sendable {
    public init?(coder: NSCoder) {
        return nil
    }
}

extension INInteraction {
    open func parameterValue(for parameter: INParameter) -> Any? { nil }
    open var dateInterval: DateInterval? = nil
    open var groupIdentifier: String? = nil
    open var intentHandlingStatus: INIntentHandlingStatus?
}

open class INLengthResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with lengthToConfirm: Measurement<UnitLength>?) -> Self { self.init() as! Self }
    open class func disambiguation(with lengthsToDisambiguate: [Measurement<UnitLength>]) -> Self { self.init() as! Self }
    open class func success(with resolvedLength: Measurement<UnitLength>) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INListCarsIntent: INIntent, @unchecked Sendable {
    public init() {
        super.init()
    }
}

open class INListCarsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var cars: [INCar]? = nil
    open var code: INListCarsIntentResponseCode?
    public init(code: INListCarsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INListRideOptionsIntent: INIntent, @unchecked Sendable {
    public override init() { super.init() }
}

open class INListRideOptionsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INListRideOptionsIntentResponseCode = []
    open var expirationDate: Date? = nil
    open var paymentMethods: [INPaymentMethod]? = nil
    open var rideOptions: [INRideOption]? = nil
    public init(code: INListRideOptionsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INLocationRelevanceProvider: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

open class INLocationSearchTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with locationSearchTypeToConfirm: INLocationSearchType) -> Self { self.init() as! Self }
    open class func success(with resolvedLocationSearchType: INLocationSearchType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INLodgingReservation: INReservation, @unchecked Sendable {
    open var reservationDuration: INDateComponentsRange?
    open var numberOfAdults: Int? = nil
    open var numberOfChildren: Int? = nil
    public override init() { super.init() }
}

open class INMassResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with massToConfirm: Measurement<UnitMass>?) -> Self { self.init() as! Self }
    open class func disambiguation(with massToDisambiguate: [Measurement<UnitMass>]) -> Self { self.init() as! Self }
    open class func success(with resolvedMass: Measurement<UnitMass>) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INMediaAffinityTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with mediaAffinityTypeToConfirm: INMediaAffinityType) -> Self { self.init() as! Self }
    open class func success(with resolvedMediaAffinityType: INMediaAffinityType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INMediaDestinationReference: NSObject, @unchecked Sendable {
    open class func library() -> Self { self.init() as! Self }
    open class func playlistDestination(withName playlistName: String) -> Self { self.init() as! Self }
    open var mediaDestinationType: INMediaDestinationType?
    open var playlistName: String? = nil
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INMediaDestinationResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with mediaDestinationToConfirm: INMediaDestination?) -> Self { self.init() as! Self }
    open class func disambiguation(with mediaDestinationsToDisambiguate: [INMediaDestination]) -> Self { self.init() as! Self }
    open class func success(with resolvedMediaDestination: INMediaDestination) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

extension INMediaItem {
    open var artist: String? = nil
}

open class INMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with mediaItemToConfirm: INMediaItem?) -> Self { self.init() as! Self }
    open class func disambiguation(with mediaItemsToDisambiguate: [INMediaItem]) -> Self { self.init() as! Self }
    open class func success(with resolvedMediaItem: INMediaItem) -> Self { self.init() as! Self }
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INMediaItemResolutionResult] { [] }
    public override init() { super.init() }
}

extension INMediaSearch {
    open var activityNames: [String]? = nil
    open var genreNames: [String]? = nil
    open var mediaIdentifier: String? = nil
    open var mediaType: INMediaItemType?
    open var moodNames: [String]? = nil
    open var reference: INMediaReference?
    open var releaseDate: INDateComponentsRange? = nil
    open var sortOrder: INMediaSortOrder?
}

open class INMediaUserContext: INUserContext, @unchecked Sendable {
    public enum SubscriptionStatus: Int, Hashable, Sendable {
        case notSubscribed = 1
        case subscribed = 2
        case unknown = 0
    }

    open var subscriptionStatus: INMediaUserContext.SubscriptionStatus?
    open var numberOfLibraryItems: Int? = nil
    public init() {
        super.init()
    }
}

open class INMessage: NSObject, @unchecked Sendable {
    open var attachmentFiles: [INFile]? = nil
    open var audioMessageFile: INFile? = nil
    open var content: String? = nil
    open var conversationIdentifier: String? = nil
    open var dateSent: Date? = nil
    open var groupName: INSpeakableString? = nil
    open var identifier: String = ""
    open var linkMetadata: INMessageLinkMetadata? = nil
    open var messageType: INMessageType?
    open var numberOfAttachments: NSNumber? = nil
    open var reaction: INMessageReaction? = nil
    open var recipients: [INPerson]? = nil
    open var sender: INPerson? = nil
    open var serviceName: String? = nil
    open var sticker: INSticker? = nil
    public init(identifier: String, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType, serviceName: String?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType, serviceName: String?, attachmentFiles: [INFile]?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType, serviceName: String?, audioMessageFile: INFile?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, linkMetadata: INMessageLinkMetadata?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, messageType: INMessageType, numberOfAttachments: NSNumber?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, messageType: INMessageType, referencedMessage: INMessage?, reaction: INMessageReaction?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, messageType: INMessageType, referencedMessage: INMessage?, sticker: INSticker?, reaction: INMessageReaction?) {
        super.init()
    }
    public init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, messageType: INMessageType) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INMessageAttributeOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with messageAttributeOptionsToConfirm: INMessageAttributeOptions = []) -> Self { self.init() as! Self }
    open class func success(with resolvedMessageAttributeOptions: INMessageAttributeOptions = []) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INMessageAttributeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with messageAttributeToConfirm: INMessageAttribute) -> Self { self.init() as! Self }
    open class func success(with resolvedMessageAttribute: INMessageAttribute) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INMessageLinkMetadata: NSObject, @unchecked Sendable {
    open var linkURL: URL? = nil
    open var openGraphType: String? = nil
    open var siteName: String? = nil
    open var summary: String? = nil
    open var title: String? = nil
    public init(siteName: String?, summary: String?, title: String?, openGraphType: String?, linkURL: URL?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INMessageReaction: NSObject, @unchecked Sendable {
    open var emoji: String? = nil
    open var reactionDescription: String? = nil
    open var reactionType: INMessageReactionType?
    public init(reactionType: INMessageReactionType, reactionDescription: String?, emoji: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INNote: NSObject, @unchecked Sendable {
    open var contents: [INNoteContent] = []
    open var createdDateComponents: DateComponents? = nil
    open var groupName: INSpeakableString? = nil
    open var identifier: String? = nil
    open var modifiedDateComponents: DateComponents? = nil
    open var title: INSpeakableString?
    public init(title: INSpeakableString, contents: [INNoteContent], groupName: INSpeakableString?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INNoteContent: NSObject, @unchecked Sendable {
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INNoteContentResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with noteContentToConfirm: INNoteContent?) -> Self { self.init() as! Self }
    open class func disambiguation(with noteContentsToDisambiguate: [INNoteContent]) -> Self { self.init() as! Self }
    open class func success(with resolvedNoteContent: INNoteContent) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INNoteContentTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with noteContentTypeToConfirm: INNoteContentType) -> Self { self.init() as! Self }
    open class func success(with resolvedNoteContentType: INNoteContentType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INNoteResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with noteToConfirm: INNote?) -> Self { self.init() as! Self }
    open class func disambiguation(with notesToDisambiguate: [INNote]) -> Self { self.init() as! Self }
    open class func success(with resolvedNote: INNote) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INNotebookItemTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with notebookItemTypeToConfirm: INNotebookItemType) -> Self { self.init() as! Self }
    open class func success(with resolvedNotebookItemType: INNotebookItemType) -> Self { self.init() as! Self }
    class @nonobjc static func disambiguation(with notebookItemTypesToDisambiguate: [INNotebookItemType]) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

extension INObject {
    open var displayImage: INImage? = nil
    open var subtitleString: String? = nil
}

extension INObjectCollection {
    open var allItems: [ObjectType] = []
    open var usesIndexedCollation: Bool = false
}

open class INOutgoingMessageTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with outgoingMessageTypeToConfirm: INOutgoingMessageType) -> Self { self.init() as! Self }
    open class func success(with resolvedOutgoingMessageType: INOutgoingMessageType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INParameter: NSObject, @unchecked Sendable {
    open func index(forSubKeyPath subKeyPath: String) -> Int { 0 }
    open func isEqual(to parameter: INParameter) -> Bool { false }
    open func setIndex(_ index: Int, forSubKeyPath subKeyPath: String) { }
    open var parameterClass: AnyClass?
    open var parameterKeyPath: String = ""
    public init(for aClass: AnyClass, keyPath: String) {
        super.init()
    }
    public init(forClass aClass: AnyClass, keyPath: String) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INPauseWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public init(workoutName: INSpeakableString?) {
        super.init()
    }
}

open class INPauseWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INPauseWorkoutIntentResponseCode?
    public init(code: INPauseWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INPayBillIntent: INIntent, @unchecked Sendable {
    open var billPayee: INBillPayee? = nil
    open var billType: INBillType?
    open var dueDate: INDateComponentsRange? = nil
    open var fromAccount: INPaymentAccount? = nil
    open var transactionAmount: INPaymentAmount? = nil
    open var transactionNote: String? = nil
    open var transactionScheduledDate: INDateComponentsRange? = nil
    public init(billPayee: INBillPayee?, from fromAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?, billType: INBillType, dueDate: INDateComponentsRange?) {
        super.init()
    }
    public init(billPayee: INBillPayee?, fromAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?, billType: INBillType, dueDate: INDateComponentsRange?) {
        super.init()
    }
}

open class INPayBillIntentResponse: INIntentResponse, @unchecked Sendable {
    open var billDetails: INBillDetails? = nil
    open var code: INPayBillIntentResponseCode?
    open var fromAccount: INPaymentAccount? = nil
    open var transactionAmount: INPaymentAmount? = nil
    open var transactionNote: String? = nil
    open var transactionScheduledDate: INDateComponentsRange? = nil
    public init(code: INPayBillIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INPaymentAccount: NSObject, @unchecked Sendable {
    open var accountNumber: String? = nil
    open var accountType: INAccountType?
    open var balance: INBalanceAmount? = nil
    open var nickname: INSpeakableString? = nil
    open var organizationName: INSpeakableString? = nil
    open var secondaryBalance: INBalanceAmount? = nil
    public init?(nickname: INSpeakableString, number: String?, accountType: INAccountType, organizationName: INSpeakableString?) {
        super.init()
    }
    public init(nickname: INSpeakableString, number: String?, accountType: INAccountType, organizationName: INSpeakableString?, balance: INBalanceAmount?, secondaryBalance: INBalanceAmount?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INPaymentAccountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentAccountToConfirm: INPaymentAccount?) -> Self { self.init() as! Self }
    open class func disambiguation(with paymentAccountsToDisambiguate: [INPaymentAccount]) -> Self { self.init() as! Self }
    open class func success(with resolvedPaymentAccount: INPaymentAccount) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INPaymentAmount: NSObject, @unchecked Sendable {
    open var amount: INCurrencyAmount? = nil
    open var amountType: INAmountType?
    public init(amountType: INAmountType, amount: INCurrencyAmount) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INPaymentAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentAmountToConfirm: INPaymentAmount?) -> Self { self.init() as! Self }
    open class func disambiguation(with paymentAmountsToDisambiguate: [INPaymentAmount]) -> Self { self.init() as! Self }
    open class func success(with resolvedPaymentAmount: INPaymentAmount) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INPaymentMethod: NSObject, @unchecked Sendable {
    open class func applePay() -> Self { self.init() as! Self }
    open var icon: INImage? = nil
    open var identificationHint: String? = nil
    open var name: String? = nil
    open var type: INPaymentMethodType?
    public init(type: INPaymentMethodType, name: String?, identificationHint: String?, icon: INImage?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INPaymentMethodResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentMethodToConfirm: INPaymentMethod?) -> Self { self.init() as! Self }
    open class func disambiguation(with paymentMethodsToDisambiguate: [INPaymentMethod]) -> Self { self.init() as! Self }
    open class func success(with resolvedPaymentMethod: INPaymentMethod) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INPaymentRecord: NSObject, @unchecked Sendable {
    open var currencyAmount: INCurrencyAmount? = nil
    open var feeAmount: INCurrencyAmount? = nil
    open var note: String? = nil
    open var payee: INPerson? = nil
    open var payer: INPerson? = nil
    open var paymentMethod: INPaymentMethod? = nil
    open var status: INPaymentStatus?
    public init?(payee: INPerson?, payer: INPerson?, currencyAmount: INCurrencyAmount?, paymentMethod: INPaymentMethod?, note: String?, status: INPaymentStatus) {
        super.init()
    }
    public init?(payee: INPerson?, payer: INPerson?, currencyAmount: INCurrencyAmount?, paymentMethod: INPaymentMethod?, note: String?, status: INPaymentStatus, feeAmount: INCurrencyAmount?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INPaymentStatusResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentStatusToConfirm: INPaymentStatus) -> Self { self.init() as! Self }
    open class func success(with resolvedPaymentStatus: INPaymentStatus) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

extension INPerson {
    open var isContactSuggestion: Bool = false
    open var handle: String? = nil
    open var isMe: Bool = false
    open var relationship: INPersonRelationship? = nil
    open var siriMatches: [INPerson]? = nil
}

open class INPlacemarkResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    public override init() { super.init() }
}

open class INPlayMediaIntent: INIntent, @unchecked Sendable {
    open var mediaContainer: INMediaItem? = nil
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    open var playbackQueueLocation: INPlaybackQueueLocation?
    open var playbackRepeatMode: INPlaybackRepeatMode?
    open var playShuffled: Bool? = nil
    open var playbackSpeed: Double? = nil
    open var resumePlayback: Bool? = nil
    public override init() { super.init() }
}

open class INPlayMediaIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INPlayMediaIntentResponseCode?
    open var nowPlayingInfo: [String : Any]? = nil
    public init(code: INPlayMediaIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INPlayMediaMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INPlayMediaMediaItemResolutionResult] { [] }
    open class func unsupported(forReason reason: INPlayMediaMediaItemUnsupportedReason) -> Self { self.init() as! Self }
    public init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        super.init()
    }
}

open class INPlayMediaPlaybackSpeedResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INPlayMediaPlaybackSpeedUnsupportedReason) -> Self { self.init() as! Self }
    public init(doubleResolutionResult: INDoubleResolutionResult) {
        super.init()
    }
}

open class INPlaybackQueueLocationResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with playbackQueueLocationToConfirm: INPlaybackQueueLocation) -> Self { self.init() as! Self }
    open class func success(with resolvedPlaybackQueueLocation: INPlaybackQueueLocation) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INPlaybackRepeatModeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with playbackRepeatModeToConfirm: INPlaybackRepeatMode) -> Self { self.init() as! Self }
    open class func success(with resolvedPlaybackRepeatMode: INPlaybackRepeatMode) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INPreferences: NSObject, @unchecked Sendable {
    open class func requestSiriAuthorization(_ handler: @escaping (INSiriAuthorizationStatus) -> Void) { }
    open class func siriAuthorizationStatus() -> INSiriAuthorizationStatus { fatalError("Intents.INPreferences.siriAuthorizationStatus is fail-closed on Linux") }
    open class func siriLanguageCode() -> String { "" }
    public override init() { super.init() }
}

open class INPriceRange: NSObject, @unchecked Sendable {
    open var currencyCode: String = ""
    open var maximumPrice: NSDecimalNumber? = nil
    open var minimumPrice: NSDecimalNumber? = nil
    public init(maximumPrice: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init(minimumPrice: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init(price: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init(firstPrice: NSDecimalNumber, secondPrice: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init(rangeBetweenPrice firstPrice: NSDecimalNumber, andPrice secondPrice: NSDecimalNumber, currencyCode: String) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRadioTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with radioTypeToConfirm: INRadioType) -> Self { self.init() as! Self }
    open class func success(with resolvedRadioType: INRadioType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INRecurrenceRule: NSObject, @unchecked Sendable {
    open var frequency: INRecurrenceFrequency?
    open var interval: Int = 0
    open var weeklyRecurrenceDays: INDayOfWeekOptions = []
    public init(interval: Int, frequency: INRecurrenceFrequency) {
        super.init()
    }
    public init(interval: Int, frequency: INRecurrenceFrequency, weeklyRecurrenceDays: INDayOfWeekOptions = []) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRelativeReferenceResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with relativeReferenceToConfirm: INRelativeReference) -> Self { self.init() as! Self }
    open class func success(with resolvedRelativeReference: INRelativeReference) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INRelativeSettingResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with relativeSettingToConfirm: INRelativeSetting) -> Self { self.init() as! Self }
    open class func success(with resolvedRelativeSetting: INRelativeSetting) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INRelevanceProvider: NSObject, @unchecked Sendable {
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRelevantShortcut: NSObject, @unchecked Sendable {
    open var relevanceProviders: [INRelevanceProvider] = []
    open var shortcut: INShortcut?
    open var shortcutRole: INRelevantShortcutRole?
    open var watchTemplate: INDefaultCardTemplate? = nil
    open var widgetKind: String? = nil
    public init(shortcut: INShortcut) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRelevantShortcutStore: NSObject, @unchecked Sendable {
    public class var default: INRelevantShortcutStore { fatalError("Intents.INRelevantShortcutStore.default is not available on this Linux host") }
    open func setRelevantShortcuts(_ shortcuts: [INRelevantShortcut]) async throws { }
    public override init() { super.init() }
}

open class INRentalCar: NSObject, @unchecked Sendable {
    open var make: String? = nil
    open var model: String? = nil
    open var rentalCarDescription: String? = nil
    open var rentalCompanyName: String = ""
    open var type: String? = nil
    public init(rentalCompanyName: String, type: String?, make: String?, model: String?, rentalCarDescription: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRentalCarReservation: NSObject, @unchecked Sendable {
    open var rentalCar: INRentalCar?
    open var rentalDuration: INDateComponentsRange?
    public override init() { super.init() }
}

open class INRequestPaymentCurrencyAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INRequestPaymentCurrencyAmountUnsupportedReason) -> Self { self.init() as! Self }
    public init(currencyAmountResolutionResult: INCurrencyAmountResolutionResult) {
        super.init()
    }
}

open class INRequestPaymentIntent: INIntent, @unchecked Sendable {
    open var currencyAmount: INCurrencyAmount? = nil
    open var note: String? = nil
    open var payer: INPerson? = nil
    public init(payer: INPerson?, currencyAmount: INCurrencyAmount?, note: String?) {
        super.init()
    }
}

open class INRequestPaymentIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INRequestPaymentIntentResponseCode?
    open var paymentRecord: INPaymentRecord? = nil
    public init(code: INRequestPaymentIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INRequestPaymentPayerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INRequestPaymentPayerUnsupportedReason) -> Self { self.init() as! Self }
    public init(personResolutionResult: INPersonResolutionResult) {
        super.init()
    }
}

open class INRequestRideIntent: INIntent, @unchecked Sendable {
    open var paymentMethod: INPaymentMethod? = nil
    open var rideOptionName: INSpeakableString? = nil
    open var scheduledPickupTime: INDateComponentsRange? = nil
    open var partySize: Int? = nil
    public override init() { super.init() }
}

open class INRequestRideIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INRequestRideIntentResponseCode?
    open var rideStatus: INRideStatus? = nil
    public init(code: INRequestRideIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INReservation: NSObject, @unchecked Sendable {
    open var url: URL? = nil
    open var actions: [INReservationAction]? = nil
    open var bookingTime: Date? = nil
    open var itemReference: INSpeakableString?
    open var reservationHolderName: String? = nil
    open var reservationNumber: String? = nil
    open var reservationStatus: INReservationStatus?
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INReservationAction: NSObject, @unchecked Sendable {
    open var type: INReservationActionType?
    open var userActivity: NSUserActivity?
    open var validDuration: INDateComponentsRange?
    public init(type: INReservationActionType, validDuration: INDateComponentsRange, userActivity: NSUserActivity) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRestaurant: NSObject, @unchecked Sendable {
    open var name: String = ""
    open var restaurantIdentifier: String = ""
    open var vendorIdentifier: String = ""
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRestaurantGuest: NSObject, @unchecked Sendable {
    open var emailAddress: String? = nil
    open var phoneNumber: String? = nil
    public init(nameComponents: PersonNameComponents?, phoneNumber: String?, emailAddress: String?) {
        super.init()
    }
}

open class INRestaurantGuestDisplayPreferences: NSObject, @unchecked Sendable {
    open var emailAddressEditable: Bool = false
    open var emailAddressFieldShouldBeDisplayed: Bool = false
    open var nameEditable: Bool = false
    open var nameFieldFirstNameOptional: Bool = false
    open var nameFieldLastNameOptional: Bool = false
    open var nameFieldShouldBeDisplayed: Bool = false
    open var phoneNumberEditable: Bool = false
    open var phoneNumberFieldShouldBeDisplayed: Bool = false
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRestaurantGuestResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with restaurantGuestToConfirm: INRestaurantGuest?) -> Self { self.init() as! Self }
    open class func disambiguation(with restaurantGuestsToDisambiguate: [INRestaurantGuest]) -> Self { self.init() as! Self }
    open class func success(with resolvedRestaurantGuest: INRestaurantGuest) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INRestaurantOffer: NSObject, @unchecked Sendable {
    open var offerDetailText: String = ""
    open var offerIdentifier: String = ""
    open var offerTitleText: String = ""
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRestaurantReservation: INReservation, @unchecked Sendable {
    open var reservationDuration: INDateComponentsRange?
    open var partySize: Int? = nil
    public override init() { super.init() }
}

open class INRestaurantReservationBooking: NSObject, @unchecked Sendable {
    open var isBookingAvailable: Bool = false
    open var bookingDate: Date?
    open var bookingDescription: String? = nil
    open var bookingIdentifier: String = ""
    open var offers: [INRestaurantOffer]? = nil
    open var partySize: Int = 0
    open var requiresEmailAddress: Bool = false
    open var requiresManualRequest: Bool = false
    open var requiresName: Bool = false
    open var requiresPhoneNumber: Bool = false
    open var restaurant: INRestaurant?
    public init(restaurant: INRestaurant, booking bookingDate: Date, partySize: Int, bookingIdentifier: String) {
        super.init()
    }
    public init(restaurant: INRestaurant, bookingDate: Date, partySize: Int, bookingIdentifier: String) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRestaurantReservationUserBooking: NSObject, @unchecked Sendable {
    open var advisementText: String? = nil
    open var dateStatusModified: Date?
    open var guest: INRestaurantGuest?
    open var guestProvidedSpecialRequestText: String? = nil
    open var selectedOffer: INRestaurantOffer? = nil
    open var status: INRestaurantReservationUserBookingStatus?
    public init(restaurant: INRestaurant, booking bookingDate: Date, partySize: Int, bookingIdentifier: String, guest: INRestaurantGuest, status: INRestaurantReservationUserBookingStatus, dateStatusModified: Date) {
        super.init()
    }
    public init(restaurant: INRestaurant, bookingDate: Date, partySize: Int, bookingIdentifier: String, guest: INRestaurantGuest, status: INRestaurantReservationUserBookingStatus, dateStatusModified: Date) {
        super.init()
    }
}

open class INRestaurantResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with restaurantToConfirm: INRestaurant?) -> Self { self.init() as! Self }
    open class func disambiguation(with restaurantsToDisambiguate: [INRestaurant]) -> Self { self.init() as! Self }
    open class func success(with resolvedRestaurant: INRestaurant) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INResumeWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public init(workoutName: INSpeakableString?) {
        super.init()
    }
}

open class INResumeWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INResumeWorkoutIntentResponseCode?
    public init(code: INResumeWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INRideCompletionStatus: NSObject, @unchecked Sendable {
    open class func canceledByService() -> Self { self.init() as! Self }
    open class func canceledByUser() -> Self { self.init() as! Self }
    open class func canceledMissedPickup() -> Self { self.init() as! Self }
    open class func completed() -> Self { self.init() as! Self }
    open class func completed(feedbackType: INRideFeedbackTypeOptions = []) -> Self { self.init() as! Self }
    open class func completed(outstanding outstandingPaymentAmount: INCurrencyAmount) -> Self { self.init() as! Self }
    open class func completed(settled settledPaymentAmount: INCurrencyAmount) -> Self { self.init() as! Self }
    open var isCanceled: Bool = false
    open var isCompleted: Bool = false
    open var completionUserActivity: NSUserActivity? = nil
    open var defaultTippingOptions: Set<INCurrencyAmount>? = nil
    open var feedbackType: INRideFeedbackTypeOptions = []
    open var isMissedPickup: Bool = false
    open var isOutstanding: Bool = false
    open var paymentAmount: INCurrencyAmount? = nil
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRideDriver: NSObject, @unchecked Sendable {
    open var phoneNumber: String? = nil
    open var rating: String? = nil
    public init(handle: String, displayName: String?, image: INImage?, rating: String?, phoneNumber: String?) {
        super.init()
    }
    public init(handle: String, nameComponents: PersonNameComponents, image: INImage?, rating: String?, phoneNumber: String?) {
        super.init()
    }
    public init(personHandle: INPersonHandle, nameComponents: PersonNameComponents?, displayName: String?, image: INImage?, rating: String?, phoneNumber: String?) {
        super.init()
    }
    public init(phoneNumber: String, nameComponents: PersonNameComponents?, displayName: String?, image: INImage?, rating: String?) {
        super.init()
    }
}

open class INRideFareLineItem: NSObject, @unchecked Sendable {
    open var currencyCode: String!?
    open var price: NSDecimalNumber!?
    open var title: String!?
    public init!(title: String!, price: NSDecimalNumber!, currencyCode: String!) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRideOption: NSObject, @unchecked Sendable {
    open var availablePartySizeOptions: [INRidePartySizeOption]? = nil
    open var availablePartySizeOptionsSelectionPrompt: String? = nil
    open var disclaimerMessage: String? = nil
    open var estimatedPickupDate: Date?
    open var fareLineItems: [INRideFareLineItem]? = nil
    open var identifier: String? = nil
    open var name: String = ""
    open var priceRange: INPriceRange? = nil
    open var specialPricing: String? = nil
    open var specialPricingBadgeImage: INImage? = nil
    open var userActivityForBookingInApplication: NSUserActivity? = nil
    open var usesMeteredFare: Bool? = nil
    open var usesMeteredFare: NSNumber? = nil
    public init?(coder decoder: NSCoder) {
        return nil
    }
    public init(name: String, estimatedPickupDate: Date) {
        super.init()
    }
}

open class INRidePartySizeOption: NSObject, @unchecked Sendable {
    open var partySizeRange: NSRange?
    open var priceRange: INPriceRange? = nil
    open var sizeDescription: String = ""
    public init(partySizeRange: NSRange, sizeDescription: String, priceRange: INPriceRange?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRideStatus: NSObject, @unchecked Sendable {
    open var additionalActionActivities: [NSUserActivity]? = nil
    open var completionStatus: INRideCompletionStatus? = nil
    open var driver: INRideDriver? = nil
    open var estimatedDropOffDate: Date? = nil
    open var estimatedPickupDate: Date? = nil
    open var estimatedPickupEndDate: Date? = nil
    open var phase: INRidePhase?
    open var rideIdentifier: String? = nil
    open var rideOption: INRideOption? = nil
    open var scheduledPickupTime: INDateComponentsRange? = nil
    open var userActivityForCancelingInApplication: NSUserActivity? = nil
    open var vehicle: INRideVehicle? = nil
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INRideVehicle: NSObject, @unchecked Sendable {
    open var manufacturer: String? = nil
    open var mapAnnotationImage: INImage? = nil
    open var model: String? = nil
    open var registrationPlate: String? = nil
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INSaveProfileInCarIntent: INIntent, @unchecked Sendable {
    open var profileLabel: String? = nil
    open var profileName: String? = nil
    open var profileNumber: Int? = nil
    public override init() { super.init() }
}

open class INSaveProfileInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSaveProfileInCarIntentResponseCode?
    public init(code: INSaveProfileInCarIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchCallHistoryIntent: INIntent, @unchecked Sendable {
    open var callCapabilities: INCallCapabilityOptions = []
    open var callType: INCallRecordType?
    open var callTypes: INCallRecordTypeOptions = []
    open var dateCreated: INDateComponentsRange? = nil
    open var recipient: INPerson? = nil
    open var unseen: Bool? = nil
    public init(call callType: INCallRecordType, dateCreated: INDateComponentsRange?, recipient: INPerson?, callCapabilities: INCallCapabilityOptions = []) {
        super.init()
    }
}

open class INSearchCallHistoryIntentResponse: INIntentResponse, @unchecked Sendable {
    open var callRecords: [INCallRecord]? = nil
    open var code: INSearchCallHistoryIntentResponseCode?
    public init(code: INSearchCallHistoryIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchForAccountsIntent: INIntent, @unchecked Sendable {
    open var accountNickname: INSpeakableString? = nil
    open var accountType: INAccountType?
    open var organizationName: INSpeakableString? = nil
    open var requestedBalanceType: INBalanceType?
    public init(accountNickname: INSpeakableString?, accountType: INAccountType, organizationName: INSpeakableString?, requestedBalanceType: INBalanceType) {
        super.init()
    }
}

open class INSearchForAccountsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var accounts: [INPaymentAccount]? = nil
    open var code: INSearchForAccountsIntentResponseCode?
    public init(code: INSearchForAccountsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchForBillsIntent: INIntent, @unchecked Sendable {
    open var billPayee: INBillPayee? = nil
    open var billType: INBillType?
    open var dueDateRange: INDateComponentsRange? = nil
    open var paymentDateRange: INDateComponentsRange? = nil
    open var status: INPaymentStatus?
    public init(billPayee: INBillPayee?, paymentDateRange: INDateComponentsRange?, billType: INBillType, status: INPaymentStatus, dueDateRange: INDateComponentsRange?) {
        super.init()
    }
}

open class INSearchForBillsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var bills: [INBillDetails]? = nil
    open var code: INSearchForBillsIntentResponseCode?
    public init(code: INSearchForBillsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchForMediaIntent: INIntent, @unchecked Sendable {
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    public init(mediaItems: [INMediaItem]?, mediaSearch: INMediaSearch?) {
        super.init()
    }
}

open class INSearchForMediaIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForMediaIntentResponseCode?
    open var mediaItems: [INMediaItem]? = nil
    public init(code: INSearchForMediaIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchForMediaMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INSearchForMediaMediaItemResolutionResult] { [] }
    open class func unsupported(forReason reason: INSearchForMediaMediaItemUnsupportedReason) -> Self { self.init() as! Self }
    public init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        super.init()
    }
}

open class INSearchForMessagesIntent: INIntent, @unchecked Sendable {
    open var attributes: INMessageAttributeOptions = []
    open var conversationIdentifiers: [String]? = nil
    open var conversationIdentifiersOperator: INConditionalOperator?
    open var dateTimeRange: INDateComponentsRange? = nil
    open var groupNames: [String]? = nil
    open var groupNamesOperator: INConditionalOperator?
    open var identifiers: [String]? = nil
    open var identifiersOperator: INConditionalOperator?
    open var notificationIdentifiers: [String]? = nil
    open var notificationIdentifiersOperator: INConditionalOperator?
    open var recipients: [INPerson]? = nil
    open var recipientsOperator: INConditionalOperator?
    open var searchTerms: [String]? = nil
    open var searchTermsOperator: INConditionalOperator?
    open var senders: [INPerson]? = nil
    open var sendersOperator: INConditionalOperator?
    open var speakableGroupNames: [INSpeakableString]? = nil
    open var speakableGroupNamesOperator: INConditionalOperator?
    public init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTime dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, groupNames: [String]?) {
        super.init()
    }
    public init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTime dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, speakableGroupNames: [INSpeakableString]?) {
        super.init()
    }
    public init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTime dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, speakableGroupNames: [INSpeakableString]?, conversationIdentifiers: [String]?) {
        super.init()
    }
    public init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, speakableGroupNames: [INSpeakableString]?, conversationIdentifiers: [String]?) {
        super.init()
    }
}

open class INSearchForMessagesIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForMessagesIntentResponseCode?
    open var messages: [INMessage]? = nil
    public init(code: INSearchForMessagesIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchForNotebookItemsIntent: INIntent, @unchecked Sendable {
    open var content: String? = nil
    open var dateSearchType: INDateSearchType?
    open var dateTime: INDateComponentsRange? = nil
    open var itemType: INNotebookItemType?
    open var locationSearchType: INLocationSearchType?
    open var notebookItemIdentifier: String? = nil
    open var status: INTaskStatus?
    open var taskPriority: INTaskPriority?
    open var temporalEventTriggerTypes: INTemporalEventTriggerTypeOptions = []
    open var title: INSpeakableString? = nil
    public override init() { super.init() }
}

open class INSearchForNotebookItemsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForNotebookItemsIntentResponseCode?
    open var notes: [INNote]? = nil
    open var sortType: INSortType?
    open var taskLists: [INTaskList]? = nil
    open var tasks: [INTask]? = nil
    public init(code: INSearchForNotebookItemsIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSearchForPhotosIntent: INIntent, @unchecked Sendable {
    open var albumName: String? = nil
    open var dateCreated: INDateComponentsRange? = nil
    open var excludedAttributes: INPhotoAttributeOptions = []
    open var includedAttributes: INPhotoAttributeOptions = []
    open var peopleInPhoto: [INPerson]? = nil
    open var peopleInPhotoOperator: INConditionalOperator?
    open var searchTerms: [String]? = nil
    open var searchTermsOperator: INConditionalOperator?
    public override init() { super.init() }
}

open class INSearchForPhotosIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForPhotosIntentResponseCode?
    open var searchResultsCount: Int? = nil
    public init(code: INSearchForPhotosIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSeat: NSObject, @unchecked Sendable {
    open var seatNumber: String? = nil
    open var seatRow: String? = nil
    open var seatSection: String? = nil
    open var seatingType: String? = nil
    public init(seatSection: String?, seatRow: String?, seatNumber: String?, seatingType: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INSendMessageAttachment: NSObject, @unchecked Sendable {
    open var audioMessageFile: INFile? = nil
    public init(audioMessageFile: INFile) {
        super.init()
    }
}

open class INSendMessageIntent: INIntent, @unchecked Sendable {
    open var attachments: [INSendMessageAttachment]? = nil
    open var content: String? = nil
    open var conversationIdentifier: String? = nil
    open var groupName: String? = nil
    open var outgoingMessageType: INOutgoingMessageType?
    open var recipients: [INPerson]? = nil
    open var sender: INPerson? = nil
    open var serviceName: String? = nil
    open var speakableGroupName: INSpeakableString? = nil
    public init(recipients: [INPerson]?, content: String?, groupName: String?, serviceName: String?, sender: INPerson?) {
        super.init()
    }
    public init(recipients: [INPerson]?, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?) {
        super.init()
    }
    public init(recipients: [INPerson]?, outgoingMessageType: INOutgoingMessageType, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?) {
        super.init()
    }
    public init(recipients: [INPerson]?, outgoingMessageType: INOutgoingMessageType, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?, attachments: [INSendMessageAttachment]?) {
        super.init()
    }
}

open class INSendMessageIntentDonationMetadata: NSObject, @unchecked Sendable {
    open var mentionsCurrentUser: Bool = false
    open var notifyRecipientAnyway: Bool = false
    open var recipientCount: Int = 0
    open var isReplyToCurrentUser: Bool = false
    public init() {
        super.init()
    }
}

open class INSendMessageIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSendMessageIntentResponseCode?
    open var sentMessage: INMessage? = nil
    open var sentMessages: [INMessage]? = nil
    public init(code: INSendMessageIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSendMessageRecipientResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSendMessageRecipientUnsupportedReason) -> Self { self.init() as! Self }
    public init(personResolutionResult: INPersonResolutionResult) {
        super.init()
    }
}

open class INSendPaymentCurrencyAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSendPaymentCurrencyAmountUnsupportedReason) -> Self { self.init() as! Self }
    public init(currencyAmountResolutionResult: INCurrencyAmountResolutionResult) {
        super.init()
    }
}

open class INSendPaymentIntent: INIntent, @unchecked Sendable {
    open var currencyAmount: INCurrencyAmount? = nil
    open var note: String? = nil
    open var payee: INPerson? = nil
    public init(payee: INPerson?, currencyAmount: INCurrencyAmount?, note: String?) {
        super.init()
    }
}

open class INSendPaymentIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSendPaymentIntentResponseCode?
    open var paymentRecord: INPaymentRecord? = nil
    public init(code: INSendPaymentIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSendPaymentPayeeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSendPaymentPayeeUnsupportedReason) -> Self { self.init() as! Self }
    public init(personResolutionResult: INPersonResolutionResult) {
        super.init()
    }
}

open class INSendRideFeedbackIntent: INIntent, @unchecked Sendable {
    open var rating: NSNumber? = nil
    open var rideIdentifier: String = ""
    open var tip: INCurrencyAmount? = nil
    public init(rideIdentifier: String) {
        super.init()
    }
}

open class INSendRideFeedbackIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSendRideFeedbackIntentResponseCode?
    public init(code: INSendRideFeedbackIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetAudioSourceInCarIntent: INIntent, @unchecked Sendable {
    open var audioSource: INCarAudioSource?
    open var relativeAudioSourceReference: INRelativeReference?
    public init(audioSource: INCarAudioSource, relativeAudioSourceReference: INRelativeReference) {
        super.init()
    }
}

open class INSetAudioSourceInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetAudioSourceInCarIntentResponseCode?
    public init(code: INSetAudioSourceInCarIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetCarLockStatusIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var locked: Bool? = nil
    public override init() { super.init() }
}

open class INSetCarLockStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetCarLockStatusIntentResponseCode?
    public init(code: INSetCarLockStatusIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetClimateSettingsInCarIntent: INIntent, @unchecked Sendable {
    open var airCirculationMode: INCarAirCirculationMode?
    open var carName: INSpeakableString? = nil
    open var climateZone: INCarSeat?
    open var relativeFanSpeedSetting: INRelativeSetting?
    open var relativeTemperatureSetting: INRelativeSetting?
    open var temperature: Measurement<UnitTemperature>? = nil
    open var enableClimateControl: Bool? = nil
    open var fanSpeedIndex: Int? = nil
    open var enableAutoMode: Bool? = nil
    open var fanSpeedPercentage: Double? = nil
    open var enableAirConditioner: Bool? = nil
    open var enableFan: Bool? = nil
    public override init() { super.init() }
}

open class INSetClimateSettingsInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetClimateSettingsInCarIntentResponseCode?
    public init(code: INSetClimateSettingsInCarIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetDefrosterSettingsInCarIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var defroster: INCarDefroster?
    open var enable: Bool? = nil
    public override init() { super.init() }
}

open class INSetDefrosterSettingsInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetDefrosterSettingsInCarIntentResponseCode?
    public init(code: INSetDefrosterSettingsInCarIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetMessageAttributeIntent: INIntent, @unchecked Sendable {
    open var attribute: INMessageAttribute?
    open var identifiers: [String]? = nil
    public init(identifiers: [String]?, attribute: INMessageAttribute) {
        super.init()
    }
}

open class INSetMessageAttributeIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetMessageAttributeIntentResponseCode?
    public init(code: INSetMessageAttributeIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetProfileInCarIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var profileLabel: String? = nil
    open var profileName: String? = nil
    open var defaultProfile: Int? = nil
    open var isDefaultProfile: Bool? = nil
    open var profileNumber: Int? = nil
    public init(defaultProfile: Int?) {
        super.init()
    }
    public init(profileName: String?, defaultProfile: Int?) {
        super.init()
    }
    public init(profileLabel: String?, defaultProfile: Int?) {
        super.init()
    }
    public init(profileLabel: String?, isDefaultProfile: Bool?) {
        super.init()
    }
    public init(profileLabel: String?) {
        super.init()
    }
    public init(profileNumber: Int?, defaultProfile: Int?) {
        super.init()
    }
    public init(profileNumber: Int?, profileName: String?, defaultProfile: Int?) {
        super.init()
    }
    public init(profileNumber: Int? = nil, profileName: String? = nil, isDefaultProfile: Bool? = nil, carName: INSpeakableString? = nil) {
        super.init()
    }
    public init(profileNumber: Int?, profileLabel: String?, defaultProfile: Int?) {
        super.init()
    }
    public init(profileNumber: Int?, profileLabel: String?, isDefaultProfile: Bool?) {
        super.init()
    }
    public init(profileNumber: Int?, profileLabel: String?) {
        super.init()
    }
}

open class INSetProfileInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetProfileInCarIntentResponseCode?
    public init(code: INSetProfileInCarIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetRadioStationIntent: INIntent, @unchecked Sendable {
    open var channel: String? = nil
    open var radioType: INRadioType?
    open var stationName: String? = nil
    open var presetNumber: Int? = nil
    open var frequency: Double? = nil
    public override init() { super.init() }
}

open class INSetRadioStationIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetRadioStationIntentResponseCode?
    public init(code: INSetRadioStationIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetSeatSettingsInCarIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var relativeLevelSetting: INRelativeSetting?
    open var seat: INCarSeat?
    open var enableCooling: Bool? = nil
    open var enableHeating: Bool? = nil
    open var enableMassage: Bool? = nil
    open var level: Int? = nil
    public override init() { super.init() }
}

open class INSetSeatSettingsInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetSeatSettingsInCarIntentResponseCode?
    public init(code: INSetSeatSettingsInCarIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetTaskAttributeIntent: INIntent, @unchecked Sendable {
    open var priority: INTaskPriority?
    open var spatialEventTrigger: INSpatialEventTrigger? = nil
    open var status: INTaskStatus?
    open var targetTask: INTask? = nil
    open var taskTitle: INSpeakableString? = nil
    open var temporalEventTrigger: INTemporalEventTrigger? = nil
    public init(targetTask: INTask?, status: INTaskStatus, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?) {
        super.init()
    }
    public init(targetTask: INTask?, taskTitle: INSpeakableString?, status: INTaskStatus, priority: INTaskPriority, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?) {
        super.init()
    }
}

open class INSetTaskAttributeIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetTaskAttributeIntentResponseCode?
    open var modifiedTask: INTask? = nil
    public init(code: INSetTaskAttributeIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSetTaskAttributeTemporalEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSetTaskAttributeTemporalEventTriggerUnsupportedReason) -> Self { self.init() as! Self }
    public init(temporalEventTriggerResolutionResult: INTemporalEventTriggerResolutionResult) {
        super.init()
    }
}

open class INShareFocusStatusIntent: INIntent, @unchecked Sendable {
    open var focusStatus: INFocusStatus? = nil
    public init(focusStatus: INFocusStatus?) {
        super.init()
    }
}

open class INShareFocusStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INShareFocusStatusIntentResponseCode?
    public init(code: INShareFocusStatusIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INShortcutReference: NSObject, @unchecked Sendable {
    open var intent: INIntent? = nil
    open var userActivity: NSUserActivity? = nil
    public init?(intent: INIntent) {
        super.init()
    }
    public init(userActivity: NSUserActivity) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INSnoozeTasksIntent: INIntent, @unchecked Sendable {
    open var nextTriggerTime: INDateComponentsRange? = nil
    open var tasks: [INTask]? = nil
    open var all: Bool? = nil
    public override init() { super.init() }
}

open class INSnoozeTasksIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSnoozeTasksIntentResponseCode?
    open var snoozedTasks: [INTask]? = nil
    public init(code: INSnoozeTasksIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSnoozeTasksTaskResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSnoozeTasksTaskUnsupportedReason) -> Self { self.init() as! Self }
    public init(taskResolutionResult: INTaskResolutionResult) {
        super.init()
    }
}

open class INSpatialEventTrigger: NSObject, @unchecked Sendable {
    open var event: INSpatialEvent?
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INSpatialEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with spatialEventTriggerToConfirm: INSpatialEventTrigger?) -> Self { self.init() as! Self }
    open class func disambiguation(with spatialEventTriggersToDisambiguate: [INSpatialEventTrigger]) -> Self { self.init() as! Self }
    open class func success(with resolvedSpatialEventTrigger: INSpatialEventTrigger) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INSpeakableStringResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with stringToConfirm: INSpeakableString?) -> Self { self.init() as! Self }
    open class func disambiguation(with stringsToDisambiguate: [INSpeakableString]) -> Self { self.init() as! Self }
    open class func success(with resolvedString: INSpeakableString) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INSpeedResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with speedToConfirm: Measurement<UnitSpeed>?) -> Self { self.init() as! Self }
    open class func disambiguation(with speedToDisambiguate: [Measurement<UnitSpeed>]) -> Self { self.init() as! Self }
    open class func success(with resolvedSpeed: Measurement<UnitSpeed>) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INStartAudioCallIntent: INIntent, @unchecked Sendable {
    open var contacts: [INPerson]? = nil
    open var destinationType: INCallDestinationType?
    public init(contacts: [INPerson]?) {
        super.init()
    }
    public init(destinationType: INCallDestinationType, contacts: [INPerson]?) {
        super.init()
    }
}

open class INStartAudioCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartAudioCallIntentResponseCode?
    public init(code: INStartAudioCallIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INStartCallCallCapabilityResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INStartCallCallCapabilityUnsupportedReason) -> Self { self.init() as! Self }
    public init(callCapabilityResolutionResult: INCallCapabilityResolutionResult) {
        super.init()
    }
}

open class INStartCallCallRecordToCallBackResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INStartCallCallRecordToCallBackUnsupportedReason) -> Self { self.init() as! Self }
    public init(callRecordResolutionResult: INCallRecordResolutionResult) {
        super.init()
    }
}

open class INStartCallContactResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INStartCallContactUnsupportedReason) -> Self { self.init() as! Self }
    public init(personResolutionResult: INPersonResolutionResult) {
        super.init()
    }
}

open class INStartCallIntent: INIntent, @unchecked Sendable {
    open var audioRoute: INCallAudioRoute?
    open var callCapability: INCallCapability?
    open var callRecordFilter: INCallRecordFilter? = nil
    open var callRecordToCallBack: INCallRecord? = nil
    open var contacts: [INPerson]? = nil
    open var destinationType: INCallDestinationType?
    open var recordTypeForRedialing: INCallRecordType?
    public init(audioRoute: INCallAudioRoute, destinationType: INCallDestinationType, contacts: [INPerson]?, recordTypeForRedialing: INCallRecordType, callCapability: INCallCapability) {
        super.init()
    }
    public init(callRecordFilter: INCallRecordFilter?, callRecordToCallBack: INCallRecord?, audioRoute: INCallAudioRoute, destinationType: INCallDestinationType, contacts: [INPerson]?, callCapability: INCallCapability) {
        super.init()
    }
}

open class INStartCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartCallIntentResponseCode?
    public init(code: INStartCallIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INStartPhotoPlaybackIntent: INIntent, @unchecked Sendable {
    open var albumName: String? = nil
    open var dateCreated: INDateComponentsRange? = nil
    open var excludedAttributes: INPhotoAttributeOptions = []
    open var includedAttributes: INPhotoAttributeOptions = []
    open var peopleInPhoto: [INPerson]? = nil
    open var peopleInPhotoOperator: INConditionalOperator?
    open var searchTerms: [String]? = nil
    open var searchTermsOperator: INConditionalOperator?
    public override init() { super.init() }
}

open class INStartPhotoPlaybackIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartPhotoPlaybackIntentResponseCode?
    open var searchResultsCount: Int? = nil
    public init(code: INStartPhotoPlaybackIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INStartVideoCallIntent: INIntent, @unchecked Sendable {
    open var contacts: [INPerson]? = nil
    public init(contacts: [INPerson]?) {
        super.init()
    }
}

open class INStartVideoCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartVideoCallIntentResponseCode?
    public init(code: INStartVideoCallIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INStartWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutGoalUnitType: INWorkoutGoalUnitType?
    open var workoutLocationType: INWorkoutLocationType?
    open var workoutName: INSpeakableString? = nil
    open var isOpenEnded: Bool? = nil
    open var goalValue: Double? = nil
    public override init() { super.init() }
}

open class INStartWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartWorkoutIntentResponseCode?
    public init(code: INStartWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INSticker: NSObject, @unchecked Sendable {
    public enum StickerType: Int, Hashable, Sendable {
        case emoji = 1
        case generic = 2
        case unknown = 0
    }

    open var emoji: String? = nil
    open var type: INSticker.StickerType?
    public init(type: INSticker.StickerType, emoji: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTask: NSObject, @unchecked Sendable {
    open var createdDateComponents: DateComponents? = nil
    open var identifier: String? = nil
    open var modifiedDateComponents: DateComponents? = nil
    open var priority: INTaskPriority?
    open var spatialEventTrigger: INSpatialEventTrigger? = nil
    open var status: INTaskStatus?
    open var taskType: INTaskType?
    open var temporalEventTrigger: INTemporalEventTrigger? = nil
    open var title: INSpeakableString?
    public init(title: INSpeakableString, status: INTaskStatus, taskType: INTaskType, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?) {
        super.init()
    }
    public init(title: INSpeakableString, status: INTaskStatus, taskType: INTaskType, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?, priority: INTaskPriority) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTaskList: NSObject, @unchecked Sendable {
    open var createdDateComponents: DateComponents? = nil
    open var groupName: INSpeakableString? = nil
    open var identifier: String? = nil
    open var modifiedDateComponents: DateComponents? = nil
    open var tasks: [INTask] = []
    open var title: INSpeakableString?
    public init(title: INSpeakableString, tasks: [INTask], groupName: INSpeakableString?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTaskListResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskListToConfirm: INTaskList?) -> Self { self.init() as! Self }
    open class func disambiguation(with taskListsToDisambiguate: [INTaskList]) -> Self { self.init() as! Self }
    open class func success(with resolvedTaskList: INTaskList) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTaskPriorityResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskPriorityToConfirm: INTaskPriority) -> Self { self.init() as! Self }
    open class func success(with resolvedTaskPriority: INTaskPriority) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTaskResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskToConfirm: INTask?) -> Self { self.init() as! Self }
    open class func disambiguation(with tasksToDisambiguate: [INTask]) -> Self { self.init() as! Self }
    open class func success(with resolvedTask: INTask) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTaskStatusResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskStatusToConfirm: INTaskStatus) -> Self { self.init() as! Self }
    open class func success(with resolvedTaskStatus: INTaskStatus) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTemperatureResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with temperatureToConfirm: Measurement<UnitTemperature>?) -> Self { self.init() as! Self }
    open class func disambiguation(with temperaturesToDisambiguate: [Measurement<UnitTemperature>]) -> Self { self.init() as! Self }
    open class func success(with resolvedTemperature: Measurement<UnitTemperature>) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTemporalEventTrigger: NSObject, @unchecked Sendable {
    open var dateComponentsRange: INDateComponentsRange?
    public init(dateComponentsRange: INDateComponentsRange) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTemporalEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with temporalEventTriggerToConfirm: INTemporalEventTrigger?) -> Self { self.init() as! Self }
    open class func disambiguation(with temporalEventTriggersToDisambiguate: [INTemporalEventTrigger]) -> Self { self.init() as! Self }
    open class func success(with resolvedTemporalEventTrigger: INTemporalEventTrigger) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTemporalEventTriggerTypeOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with temporalEventTriggerTypeOptionsToConfirm: INTemporalEventTriggerTypeOptions = []) -> Self { self.init() as! Self }
    open class func success(with resolvedTemporalEventTriggerTypeOptions: INTemporalEventTriggerTypeOptions = []) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTermsAndConditions: NSObject, @unchecked Sendable {
    open var localizedTermsAndConditionsText: String = ""
    open var privacyPolicyURL: URL? = nil
    open var termsAndConditionsURL: URL? = nil
    public init(localizedTermsAndConditionsText: String, privacyPolicyURL: URL?, termsAndConditionsURL: URL?) {
        super.init()
    }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTextNoteContent: NSObject, @unchecked Sendable {
    open var text: String? = nil
    public init(text: String) {
        super.init()
    }
}

open class INTicketedEvent: NSObject, @unchecked Sendable {
    open var category: INTicketedEventCategory?
    open var eventDuration: INDateComponentsRange?
    open var name: String = ""
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTicketedEventReservation: NSObject, @unchecked Sendable {
    open var event: INTicketedEvent?
    open var reservedSeat: INSeat? = nil
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, event: INTicketedEvent) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, event: INTicketedEvent) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, reservedSeat: INSeat?, event: INTicketedEvent) {
        super.init()
    }
}

open class INTimeIntervalResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with timeIntervalToConfirm: TimeInterval) -> Self { self.init() as! Self }
    open class func success(with resolvedTimeInterval: TimeInterval) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INTrainReservation: NSObject, @unchecked Sendable {
    open var reservedSeat: INSeat? = nil
    open var trainTrip: INTrainTrip?
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, trainTrip: INTrainTrip) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, trainTrip: INTrainTrip) {
        super.init()
    }
    public init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, reservedSeat: INSeat?, trainTrip: INTrainTrip) {
        super.init()
    }
}

open class INTrainTrip: NSObject, @unchecked Sendable {
    open var arrivalPlatform: String? = nil
    open var departurePlatform: String? = nil
    open var provider: String? = nil
    open var trainName: String? = nil
    open var trainNumber: String? = nil
    open var tripDuration: INDateComponentsRange?
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INTransferMoneyIntent: INIntent, @unchecked Sendable {
    open var fromAccount: INPaymentAccount? = nil
    open var toAccount: INPaymentAccount? = nil
    open var transactionAmount: INPaymentAmount? = nil
    open var transactionNote: String? = nil
    open var transactionScheduledDate: INDateComponentsRange? = nil
    public init(from fromAccount: INPaymentAccount?, to toAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?) {
        super.init()
    }
    public init(fromAccount: INPaymentAccount?, toAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?) {
        super.init()
    }
}

open class INTransferMoneyIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INTransferMoneyIntentResponseCode?
    open var fromAccount: INPaymentAccount? = nil
    open var toAccount: INPaymentAccount? = nil
    open var transactionAmount: INPaymentAmount? = nil
    open var transactionNote: String? = nil
    open var transactionScheduledDate: INDateComponentsRange? = nil
    open var transferFee: INCurrencyAmount? = nil
    public init(code: INTransferMoneyIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INURLResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with urlToConfirm: URL?) -> Self { self.init() as! Self }
    open class func disambiguation(with urlsToDisambiguate: [URL]) -> Self { self.init() as! Self }
    open class func success(with resolvedURL: URL) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INUnsendMessagesIntent: INIntent, @unchecked Sendable {
    open var messageIdentifiers: [String]? = nil
    public init(messageIdentifiers: [String]?) {
        super.init()
    }
}

open class INUnsendMessagesIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INUnsendMessagesIntentResponseCode?
    public init(code: INUnsendMessagesIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INUpcomingMediaManager: NSObject, @unchecked Sendable {
    public class var shared: INUpcomingMediaManager { fatalError("Intents.INUpcomingMediaManager.shared is not available on this Linux host") }
    open func setPredictionMode(_ mode: INUpcomingMediaPredictionMode, for type: INMediaItemType) { }
    open func setSuggestedMediaIntents(_ intents: NSOrderedSet) { }
    public override init() { super.init() }
}

open class INUpdateMediaAffinityIntent: INIntent, @unchecked Sendable {
    open var affinityType: INMediaAffinityType?
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    public init(mediaItems: [INMediaItem]?, mediaSearch: INMediaSearch?, affinityType: INMediaAffinityType) {
        super.init()
    }
}

open class INUpdateMediaAffinityIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INUpdateMediaAffinityIntentResponseCode?
    public init(code: INUpdateMediaAffinityIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
    }
}

open class INUpdateMediaAffinityMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INUpdateMediaAffinityMediaItemResolutionResult] { [] }
    open class func unsupported(forReason reason: INUpdateMediaAffinityMediaItemUnsupportedReason) -> Self { self.init() as! Self }
    public init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        super.init()
    }
}

open class INUserContext: NSObject, @unchecked Sendable {
    open func becomeCurrent() { }
    public init?(coder: NSCoder) {
        return nil
    }
}

open class INVisualCodeTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with visualCodeTypeToConfirm: INVisualCodeType) -> Self { self.init() as! Self }
    open class func success(with resolvedVisualCodeType: INVisualCodeType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INVocabulary: NSObject, @unchecked Sendable {
    open class func shared() -> Self { self.init() as! Self }
    open func removeAllVocabularyStrings() { }
    open func setVocabulary(_ vocabulary: NSOrderedSet, of type: INVocabularyStringType) { }
    open func setVocabularyStrings(_ vocabulary: NSOrderedSet, of type: INVocabularyStringType) { }
    public override init() { super.init() }
}

extension INVoiceShortcutCenter {
    open func allVoiceShortcuts() async throws -> [INVoiceShortcut] { [] }
}

open class INVolumeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with volumeToConfirm: Measurement<UnitVolume>?) -> Self { self.init() as! Self }
    open class func disambiguation(with volumeToDisambiguate: [Measurement<UnitVolume>]) -> Self { self.init() as! Self }
    open class func success(with resolvedVolume: Measurement<UnitVolume>) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INWorkoutGoalUnitTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with workoutGoalUnitTypeToConfirm: INWorkoutGoalUnitType) -> Self { self.init() as! Self }
    open class func success(with resolvedWorkoutGoalUnitType: INWorkoutGoalUnitType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}

open class INWorkoutLocationTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with workoutLocationTypeToConfirm: INWorkoutLocationType) -> Self { self.init() as! Self }
    open class func success(with resolvedWorkoutLocationType: INWorkoutLocationType) -> Self { self.init() as! Self }
    public override init() { super.init() }
}
