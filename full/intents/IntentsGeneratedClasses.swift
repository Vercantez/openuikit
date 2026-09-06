import Synchronization

// Generated Intents classes. Members that need CoreLocation/Contacts/EventKit/CoreGraphics
// types are omitted (coverage: deferred). Remaining members are source-compatible stubs
// or fail-closed. Existing operational types stay in Intents.swift.

open class INAccountTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with accountTypeToConfirm: INAccountType) -> Self { self.init(outcome: .confirmationRequired, value: accountTypeToConfirm) }
    open class func success(with resolvedAccountType: INAccountType) -> Self { self.init(outcome: .success, value: resolvedAccountType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INActivateCarSignalIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var signals: INCarSignalOptions = []
    public required override init() { super.init() }
    public convenience init(carName: INSpeakableString?, signals: INCarSignalOptions = []) {
        self.init()
        self.carName = carName
        self.signals = signals
    }
}

open class INActivateCarSignalIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INActivateCarSignalIntentResponseCode?
    open var signals: INCarSignalOptions = []
    public required override init() { super.init() }
    public convenience init(code: INActivateCarSignalIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INAddMediaIntent: INIntent, @unchecked Sendable {
    open var mediaDestination: INMediaDestination? = nil
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    public required override init() { super.init() }
    public convenience init(mediaItems: [INMediaItem]?, mediaSearch: INMediaSearch?, mediaDestination: INMediaDestination?) {
        self.init()
        self.mediaItems = mediaItems
        self.mediaSearch = mediaSearch
        self.mediaDestination = mediaDestination
    }
}

open class INAddMediaIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INAddMediaIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INAddMediaIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INAddMediaMediaDestinationResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INAddMediaMediaDestinationUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(mediaDestinationResolutionResult: INMediaDestinationResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INAddMediaMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INAddMediaMediaItemResolutionResult] { resolvedMediaItems.map { self.init(outcome: .success, value: $0) } }
    open class func unsupported(forReason reason: INAddMediaMediaItemUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INAddTasksIntent: INIntent, @unchecked Sendable {
    open var priority: INTaskPriority?
    open var spatialEventTrigger: INSpatialEventTrigger? = nil
    open var targetTaskList: INTaskList? = nil
    open var taskTitles: [INSpeakableString]? = nil
    open var temporalEventTrigger: INTemporalEventTrigger? = nil
    public required override init() { super.init() }
    public convenience init(targetTaskList: INTaskList?, taskTitles: [INSpeakableString]?, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?) {
        self.init()
        self.targetTaskList = targetTaskList
        self.taskTitles = taskTitles
        self.spatialEventTrigger = spatialEventTrigger
        self.temporalEventTrigger = temporalEventTrigger
    }
    public convenience init(targetTaskList: INTaskList?, taskTitles: [INSpeakableString]?, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?, priority: INTaskPriority) {
        self.init()
        self.targetTaskList = targetTaskList
        self.taskTitles = taskTitles
        self.spatialEventTrigger = spatialEventTrigger
        self.temporalEventTrigger = temporalEventTrigger
        self.priority = priority
    }
}

open class INAddTasksIntentResponse: INIntentResponse, @unchecked Sendable {
    open var addedTasks: [INTask]? = nil
    open var code: INAddTasksIntentResponseCode?
    open var modifiedTaskList: INTaskList? = nil
    public required override init() { super.init() }
    public convenience init(code: INAddTasksIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INAddTasksTargetTaskListResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskListToConfirm: INTaskList?, forReason reason: INAddTasksTargetTaskListConfirmationReason) -> Self { self.init(outcome: .confirmationRequired, value: taskListToConfirm) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(taskListResolutionResult: INTaskListResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INAddTasksTemporalEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INAddTasksTemporalEventTriggerUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(temporalEventTriggerResolutionResult: INTemporalEventTriggerResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INAirline: NSObject, @unchecked Sendable {
    open var iataCode: String? = nil
    open var icaoCode: String? = nil
    open var name: String? = nil
    public required override init() { super.init() }
    public convenience init(name: String?, iataCode: String?, icaoCode: String?) {
        self.init()
        self.name = name
        self.iataCode = iataCode
        self.icaoCode = icaoCode
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INAirport: NSObject, @unchecked Sendable {
    open var iataCode: String? = nil
    open var icaoCode: String? = nil
    open var name: String? = nil
    public required override init() { super.init() }
    public convenience init(name: String?, iataCode: String?, icaoCode: String?) {
        self.init()
        self.name = name
        self.iataCode = iataCode
        self.icaoCode = icaoCode
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INAirportGate: NSObject, @unchecked Sendable {
    open var airport: INAirport?
    open var gate: String? = nil
    open var terminal: String? = nil
    public required override init() { super.init() }
    public convenience init(airport: INAirport, terminal: String?, gate: String?) {
        self.init()
        self.airport = airport
        self.terminal = terminal
        self.gate = gate
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INAnswerCallIntent: INIntent, @unchecked Sendable {
    open var audioRoute: INCallAudioRoute?
    open var callIdentifier: String? = nil
    public required override init() { super.init() }
    public convenience init(audioRoute: INCallAudioRoute, callIdentifier: String?) {
        self.init()
        self.audioRoute = audioRoute
        self.callIdentifier = callIdentifier
    }
}

open class INAnswerCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var callRecords: [INCallRecord]? = nil
    open var code: INAnswerCallIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INAnswerCallIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INAppendToNoteIntent: INIntent, @unchecked Sendable {
    open var content: INNoteContent? = nil
    open var targetNote: INNote? = nil
    public required override init() { super.init() }
    public convenience init(targetNote: INNote?, content: INNoteContent?) {
        self.init()
        self.targetNote = targetNote
        self.content = content
    }
}

open class INAppendToNoteIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INAppendToNoteIntentResponseCode?
    open var note: INNote? = nil
    public required override init() { super.init() }
    public convenience init(code: INAppendToNoteIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INBalanceAmount: NSObject, @unchecked Sendable {
    open var amount: NSDecimalNumber? = nil
    open var balanceType: INBalanceType?
    open var currencyCode: String? = nil
    public required override init() { super.init() }
    public convenience init?(amount: NSDecimalNumber, balanceType: INBalanceType) {
        self.init()
        self.amount = amount
        self.balanceType = balanceType
    }
    public convenience init(amount: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.amount = amount
        self.currencyCode = currencyCode
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INBalanceTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with balanceTypeToConfirm: INBalanceType) -> Self { self.init(outcome: .confirmationRequired, value: balanceTypeToConfirm) }
    open class func success(with resolvedBalanceType: INBalanceType) -> Self { self.init(outcome: .success, value: resolvedBalanceType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
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
    public required override init() { super.init() }
    public convenience init?(billType: INBillType, paymentStatus: INPaymentStatus, billPayee: INBillPayee?, amountDue: INCurrencyAmount?, minimumDue: INCurrencyAmount?, lateFee: INCurrencyAmount?, dueDate: DateComponents?, paymentDate: DateComponents?) {
        self.init()
        self.billType = billType
        self.paymentStatus = paymentStatus
        self.billPayee = billPayee
        self.amountDue = amountDue
        self.minimumDue = minimumDue
        self.lateFee = lateFee
        self.dueDate = dueDate
        self.paymentDate = paymentDate
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INBillPayee: NSObject, @unchecked Sendable {
    open var accountNumber: String? = nil
    open var nickname: INSpeakableString? = nil
    open var organizationName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init?(nickname: INSpeakableString, number: String?, organizationName: INSpeakableString?) {
        self.init()
        self.nickname = nickname
        self.organizationName = organizationName
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INBillPayeeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with billPayeeToConfirm: INBillPayee?) -> Self { self.init(outcome: .confirmationRequired, value: billPayeeToConfirm) }
    open class func disambiguation(with billPayeesToDisambiguate: [INBillPayee]) -> Self { self.init(outcome: .disambiguation, value: billPayeesToDisambiguate) }
    open class func success(with resolvedBillPayee: INBillPayee) -> Self { self.init(outcome: .success, value: resolvedBillPayee) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INBillTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with billTypeToConfirm: INBillType) -> Self { self.init(outcome: .confirmationRequired, value: billTypeToConfirm) }
    open class func success(with resolvedBillType: INBillType) -> Self { self.init(outcome: .success, value: resolvedBillType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INBoatReservation: NSObject, @unchecked Sendable {
    open var boatTrip: INBoatTrip? = nil
    open var reservedSeat: INSeat? = nil
    public required override init() { super.init() }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, boatTrip: INBoatTrip?) {
        self.init()
        self.reservedSeat = reservedSeat
        self.boatTrip = boatTrip
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, boatTrip: INBoatTrip?) {
        self.init()
        self.reservedSeat = reservedSeat
        self.boatTrip = boatTrip
    }
}

open class INBoatTrip: NSObject, @unchecked Sendable {
    open var boatName: String? = nil
    open var boatNumber: String? = nil
    open var provider: String? = nil
    open var tripDuration: INDateComponentsRange?
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
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
    public required override init() { super.init() }
    public convenience init(restaurant: INRestaurant, booking bookingDateComponents: DateComponents, partySize: Int, bookingIdentifier: String?, guest: INRestaurantGuest?, selectedOffer: INRestaurantOffer?, guestProvidedSpecialRequestText: String?) {
        self.init()
        self.restaurant = restaurant
        self.bookingDateComponents = bookingDateComponents
        self.partySize = partySize
        self.bookingIdentifier = bookingIdentifier
        self.guest = guest
        self.selectedOffer = selectedOffer
        self.guestProvidedSpecialRequestText = guestProvidedSpecialRequestText
    }
    public convenience init(restaurant: INRestaurant, bookingDateComponents: DateComponents, partySize: Int, bookingIdentifier: String?, guest: INRestaurantGuest?, selectedOffer: INRestaurantOffer?, guestProvidedSpecialRequestText: String?) {
        self.init()
        self.restaurant = restaurant
        self.bookingDateComponents = bookingDateComponents
        self.partySize = partySize
        self.bookingIdentifier = bookingIdentifier
        self.guest = guest
        self.selectedOffer = selectedOffer
        self.guestProvidedSpecialRequestText = guestProvidedSpecialRequestText
    }
}

open class INBookRestaurantReservationIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INBookRestaurantReservationIntentCode?
    open var userBooking: INRestaurantReservationUserBooking? = nil
    public required override init() { super.init() }
    public convenience init(code: INBookRestaurantReservationIntentCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INBusReservation: NSObject, @unchecked Sendable {
    open var busTrip: INBusTrip?
    open var reservedSeat: INSeat? = nil
    public required override init() { super.init() }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, busTrip: INBusTrip?) {
        self.init()
        self.reservedSeat = reservedSeat
        self.busTrip = busTrip
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, busTrip: INBusTrip?) {
        self.init()
        self.reservedSeat = reservedSeat
        self.busTrip = busTrip
    }
}

open class INBusTrip: NSObject, @unchecked Sendable {
    open var arrivalPlatform: String? = nil
    open var busName: String? = nil
    open var busNumber: String? = nil
    open var departurePlatform: String? = nil
    open var provider: String? = nil
    open var tripDuration: INDateComponentsRange?
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INCallCapabilityResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callCapabilityToConfirm: INCallCapability) -> Self { self.init(outcome: .confirmationRequired, value: callCapabilityToConfirm) }
    open class func success(with resolvedCallCapability: INCallCapability) -> Self { self.init(outcome: .success, value: resolvedCallCapability) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCallDestinationTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callDestinationTypeToConfirm: INCallDestinationType) -> Self { self.init(outcome: .confirmationRequired, value: callDestinationTypeToConfirm) }
    open class func success(with resolvedCallDestinationType: INCallDestinationType) -> Self { self.init(outcome: .success, value: resolvedCallDestinationType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCallGroup: NSObject, @unchecked Sendable {
    open var groupId: String? = nil
    open var groupName: String? = nil
    public required override init() { super.init() }
    public convenience init(groupName: String?, groupId: String?) {
        self.init()
        self.groupName = groupName
        self.groupId = groupId
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INCallRecord: NSObject, @unchecked Sendable {
    open var callCapability: INCallCapability = .unknown
    open var callRecordType: INCallRecordType = .unknown
    open var caller: INPerson? = nil
    open var dateCreated: Date? = nil
    open var identifier: String = ""
    open var participants: [INPerson]? = nil
    open var callDuration: Double? = nil
    open var unseen: Bool? = nil
    open var numberOfCalls: Int? = nil
    public required override init() { super.init() }
    public convenience init(
        identifier: String,
        dateCreated: Date? = nil,
        caller: INPerson? = nil,
        callRecordType: INCallRecordType = .unknown,
        callCapability: INCallCapability = .unknown,
        callDuration: Double? = nil,
        unseen: Bool? = nil,
        numberOfCalls: Int? = nil
    ) {
        self.init()
        self.identifier = identifier
        self.dateCreated = dateCreated
        self.caller = caller
        self.callRecordType = callRecordType
        self.callCapability = callCapability
        self.callDuration = callDuration
        self.unseen = unseen
        self.numberOfCalls = numberOfCalls
    }
    public required convenience init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? else {
            return nil
        }
        self.init()
        self.identifier = identifier
        if coder.containsValue(forKey: "callRecordType") {
            self.callRecordType = INCallRecordType(rawValue: Int(coder.decodeInt64(forKey: "callRecordType"))) ?? .unknown
        }
        if coder.containsValue(forKey: "callCapability") {
            self.callCapability = INCallCapability(rawValue: Int(coder.decodeInt64(forKey: "callCapability"))) ?? .unknown
        }
    }
}


open class INCallRecordFilter: NSObject, @unchecked Sendable {
    open var callCapability: INCallCapability = .unknown
    open var callTypes: INCallRecordTypeOptions = []
    open var participants: [INPerson]? = nil
    public required override init() { super.init() }
    public convenience init(participants: [INPerson]?, callTypes: INCallRecordTypeOptions = [], callCapability: INCallCapability) {
        self.init()
        self.participants = participants
        self.callTypes = callTypes
        self.callCapability = callCapability
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}


open class INCallRecordResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callRecordToConfirm: INCallRecord?) -> Self { self.init(outcome: .confirmationRequired, value: callRecordToConfirm) }
    open class func disambiguation(with callRecordsToDisambiguate: [INCallRecord]) -> Self { self.init(outcome: .disambiguation, value: callRecordsToDisambiguate) }
    open class func success(with resolvedCallRecord: INCallRecord) -> Self { self.init(outcome: .success, value: resolvedCallRecord) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCallRecordTypeOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callRecordTypeOptionsToConfirm: INCallRecordTypeOptions = []) -> Self { self.init(outcome: .confirmationRequired, value: callRecordTypeOptionsToConfirm) }
    open class func success(with resolvedCallRecordTypeOptions: INCallRecordTypeOptions = []) -> Self { self.init(outcome: .success, value: resolvedCallRecordTypeOptions) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCallRecordTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with callRecordTypeToConfirm: INCallRecordType) -> Self { self.init(outcome: .confirmationRequired, value: callRecordTypeToConfirm) }
    open class func success(with resolvedCallRecordType: INCallRecordType) -> Self { self.init(outcome: .success, value: resolvedCallRecordType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCancelRideIntent: INIntent, @unchecked Sendable {
    open var rideIdentifier: String = ""
    public required override init() { super.init() }
    public convenience init(rideIdentifier: String) {
        self.init()
        self.rideIdentifier = rideIdentifier
    }
}

open class INCancelRideIntentResponse: INIntentResponse, @unchecked Sendable {
    open var cancellationFee: INCurrencyAmount? = nil
    open var cancellationFeeThreshold: DateComponents? = nil
    open var code: INCancelRideIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INCancelRideIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INCancelWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(workoutName: INSpeakableString?) {
        self.init()
        self.workoutName = workoutName
    }
}

open class INCancelWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INCancelWorkoutIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INCancelWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INCarHeadUnit: NSObject, @unchecked Sendable {
    public convenience init(bluetoothIdentifier: String?, iAP2Identifier: String?) {
        self.init()
        self.bluetoothIdentifier = bluetoothIdentifier
        self.iAP2Identifier = iAP2Identifier
    }
    open var bluetoothIdentifier: String? = nil
    open var iAP2Identifier: String? = nil
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
    public required override init() { super.init() }
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

    public typealias HeadUnit = INCarHeadUnit

    open func maximumPower(for chargingConnectorType: INCar.ChargingConnectorType) -> Measurement<UnitPower>? { nil }
    open func setMaximumPower(_ power: Measurement<UnitPower>, for chargingConnectorType: INCar.ChargingConnectorType) { }
    open var carIdentifier: String = ""
    open var displayName: String? = nil
    open var headUnit: INCar.HeadUnit? = nil
    open var make: String? = nil
    open var model: String? = nil
    open var supportedChargingConnectors: [INCar.ChargingConnectorType] = []
    open var year: String? = nil
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INCarAirCirculationModeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carAirCirculationModeToConfirm: INCarAirCirculationMode) -> Self { self.init(outcome: .confirmationRequired, value: carAirCirculationModeToConfirm) }
    open class func success(with resolvedCarAirCirculationMode: INCarAirCirculationMode) -> Self { self.init(outcome: .success, value: resolvedCarAirCirculationMode) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCarAudioSourceResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carAudioSourceToConfirm: INCarAudioSource) -> Self { self.init(outcome: .confirmationRequired, value: carAudioSourceToConfirm) }
    open class func success(with resolvedCarAudioSource: INCarAudioSource) -> Self { self.init(outcome: .success, value: resolvedCarAudioSource) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCarDefrosterResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carDefrosterToConfirm: INCarDefroster) -> Self { self.init(outcome: .confirmationRequired, value: carDefrosterToConfirm) }
    open class func success(with resolvedCarDefroster: INCarDefroster) -> Self { self.init(outcome: .success, value: resolvedCarDefroster) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCarSeatResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carSeatToConfirm: INCarSeat) -> Self { self.init(outcome: .confirmationRequired, value: carSeatToConfirm) }
    open class func success(with resolvedCarSeat: INCarSeat) -> Self { self.init(outcome: .success, value: resolvedCarSeat) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCarSignalOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with carSignalOptionsToConfirm: INCarSignalOptions = []) -> Self { self.init(outcome: .confirmationRequired, value: carSignalOptionsToConfirm) }
    open class func success(with resolvedCarSignalOptions: INCarSignalOptions = []) -> Self { self.init(outcome: .success, value: resolvedCarSignalOptions) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INCreateNoteIntent: INIntent, @unchecked Sendable {
    open var content: INNoteContent? = nil
    open var groupName: INSpeakableString? = nil
    open var title: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(title: INSpeakableString?, content: INNoteContent?, groupName: INSpeakableString?) {
        self.init()
        self.title = title
        self.content = content
        self.groupName = groupName
    }
}

open class INCreateNoteIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INCreateNoteIntentResponseCode?
    open var createdNote: INNote? = nil
    public required override init() { super.init() }
    public convenience init(code: INCreateNoteIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INCreateTaskListIntent: INIntent, @unchecked Sendable {
    open var groupName: INSpeakableString? = nil
    open var taskTitles: [INSpeakableString]? = nil
    open var title: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(title: INSpeakableString?, taskTitles: [INSpeakableString]?, groupName: INSpeakableString?) {
        self.init()
        self.title = title
        self.taskTitles = taskTitles
        self.groupName = groupName
    }
}

open class INCreateTaskListIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INCreateTaskListIntentResponseCode?
    open var createdTaskList: INTaskList? = nil
    public required override init() { super.init() }
    public convenience init(code: INCreateTaskListIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INCurrencyAmount: NSObject, @unchecked Sendable {
    open var amount: NSDecimalNumber? = nil
    open var currencyCode: String? = nil
    public required override init() { super.init() }
    public convenience init(amount: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.amount = amount
        self.currencyCode = currencyCode
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INCurrencyAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with currencyAmountToConfirm: INCurrencyAmount?) -> Self { self.init(outcome: .confirmationRequired, value: currencyAmountToConfirm) }
    open class func disambiguation(with currencyAmountsToDisambiguate: [INCurrencyAmount]) -> Self { self.init(outcome: .disambiguation, value: currencyAmountsToDisambiguate) }
    open class func success(with resolvedCurrencyAmount: INCurrencyAmount) -> Self { self.init(outcome: .success, value: resolvedCurrencyAmount) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
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
    public required override init() { super.init() }
    public convenience init(situation: INDailyRoutineRelevanceProvider.Situation) {
        self.init()
        self.situation = situation
    }
}

open class INDateComponentsRange: NSObject, @unchecked Sendable {
    open var endDateComponents: DateComponents? = nil
    open var recurrenceRule: INRecurrenceRule? = nil
    open var startDateComponents: DateComponents? = nil
    public required override init() { super.init() }
    public convenience init(start startDateComponents: DateComponents?, end endDateComponents: DateComponents?) {
        self.init()
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
    }
    public convenience init(startDateComponents: DateComponents?, endDateComponents: DateComponents?) {
        self.init()
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
    }
    public convenience init(start startDateComponents: DateComponents?, end endDateComponents: DateComponents?, recurrenceRule: INRecurrenceRule?) {
        self.init()
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
        self.recurrenceRule = recurrenceRule
    }
    public convenience init(startDateComponents: DateComponents?, endDateComponents: DateComponents?, recurrenceRule: INRecurrenceRule?) {
        self.init()
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
        self.recurrenceRule = recurrenceRule
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}


open class INDateComponentsRangeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with dateComponentsRangeToConfirm: INDateComponentsRange?) -> Self { self.init(outcome: .confirmationRequired, value: dateComponentsRangeToConfirm) }
    open class func disambiguation(with dateComponentsRangesToDisambiguate: [INDateComponentsRange]) -> Self { self.init(outcome: .disambiguation, value: dateComponentsRangesToDisambiguate) }
    open class func success(with resolvedDateComponentsRange: INDateComponentsRange) -> Self { self.init(outcome: .success, value: resolvedDateComponentsRange) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INDateComponentsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with dateComponentsToConfirm: DateComponents?) -> Self { self.init(outcome: .confirmationRequired, value: dateComponentsToConfirm) }
    open class func disambiguation(with dateComponentsToDisambiguate: [DateComponents]) -> Self { self.init(outcome: .disambiguation, value: dateComponentsToDisambiguate) }
    open class func success(with resolvedDateComponents: DateComponents) -> Self { self.init(outcome: .success, value: resolvedDateComponents) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INDateRelevanceProvider: NSObject, @unchecked Sendable {
    open var endDate: Date? = nil
    open var startDate: Date?
    public required override init() { super.init() }
    public convenience init(start startDate: Date, end endDate: Date?) {
        self.init()
        self.startDate = startDate
        self.endDate = endDate
    }
    public convenience init(startDate: Date, endDate: Date?) {
        self.init()
        self.startDate = startDate
        self.endDate = endDate
    }
}

open class INDateSearchTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with dateSearchTypeToConfirm: INDateSearchType) -> Self { self.init(outcome: .confirmationRequired, value: dateSearchTypeToConfirm) }
    open class func success(with resolvedDateSearchType: INDateSearchType) -> Self { self.init(outcome: .success, value: resolvedDateSearchType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INDefaultCardTemplate: NSObject, @unchecked Sendable {
    open var image: INImage? = nil
    open var subtitle: String? = nil
    open var title: String = ""
    public required override init() { super.init() }
    public convenience init(title: String) {
        self.init()
        self.title = title
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}


open class INDeleteTasksIntent: INIntent, @unchecked Sendable {
    open var taskList: INTaskList? = nil
    open var tasks: [INTask]? = nil
    public required override init() { super.init() }
}

open class INDeleteTasksIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INDeleteTasksIntentResponseCode?
    open var deletedTasks: [INTask]? = nil
    public required override init() { super.init() }
    public convenience init(code: INDeleteTasksIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INDeleteTasksTaskListResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INDeleteTasksTaskListUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(taskListResolutionResult: INTaskListResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INDeleteTasksTaskResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INDeleteTasksTaskUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(taskResolutionResult: INTaskResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INEditMessageIntent: INIntent, @unchecked Sendable {
    open var editedContent: String? = nil
    open var messageIdentifier: String? = nil
    public required override init() { super.init() }
    public convenience init(messageIdentifier: String?, editedContent: String?) {
        self.init()
        self.messageIdentifier = messageIdentifier
        self.editedContent = editedContent
    }
}

open class INEditMessageIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INEditMessageIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INEditMessageIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INEndWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(workoutName: INSpeakableString?) {
        self.init()
        self.workoutName = workoutName
    }
}

open class INEndWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INEndWorkoutIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INEndWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INEnergyResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with energyToConfirm: Measurement<UnitEnergy>?) -> Self { self.init(outcome: .confirmationRequired, value: energyToConfirm) }
    open class func disambiguation(with energyToDisambiguate: [Measurement<UnitEnergy>]) -> Self { self.init(outcome: .disambiguation, value: energyToDisambiguate) }
    open class func success(with resolvedEnergy: Measurement<UnitEnergy>) -> Self { self.init(outcome: .success, value: resolvedEnergy) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INFile: NSObject, @unchecked Sendable {
    open var data: Data?
    open var fileURL: URL? = nil
    open var filename: String = ""
    open var removedOnCompletion: Bool = false
    open var typeIdentifier: String? = nil
    public required override init() { super.init() }
    public convenience init(data: Data, filename: String, typeIdentifier: String?) {
        self.init()
        self.data = data
        self.filename = filename
        self.typeIdentifier = typeIdentifier
    }
    public convenience init(fileURL: URL, filename: String?, typeIdentifier: String?) {
        self.init()
        self.fileURL = fileURL
        self.filename = filename ?? ""
        self.typeIdentifier = typeIdentifier
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INFileResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with fileToConfirm: INFile?) -> Self { self.init(outcome: .confirmationRequired, value: fileToConfirm) }
    open class func disambiguation(with filesToDisambiguate: [INFile]) -> Self { self.init(outcome: .disambiguation, value: filesToDisambiguate) }
    open class func success(with resolvedFile: INFile) -> Self { self.init(outcome: .success, value: resolvedFile) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INFlight: NSObject, @unchecked Sendable {
    open var airline: INAirline?
    open var arrivalAirportGate: INAirportGate?
    open var boardingTime: INDateComponentsRange? = nil
    open var departureAirportGate: INAirportGate?
    open var flightDuration: INDateComponentsRange?
    open var flightNumber: String = ""
    public required override init() { super.init() }
    public convenience init(airline: INAirline, flightNumber: String, boardingTime: INDateComponentsRange?, flightDuration: INDateComponentsRange, departureAirportGate: INAirportGate, arrivalAirportGate: INAirportGate) {
        self.init()
        self.airline = airline
        self.flightNumber = flightNumber
        self.boardingTime = boardingTime
        self.flightDuration = flightDuration
        self.departureAirportGate = departureAirportGate
        self.arrivalAirportGate = arrivalAirportGate
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INFlightReservation: NSObject, @unchecked Sendable {
    open var flight: INFlight?
    open var reservedSeat: INSeat? = nil
    public required override init() { super.init() }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, flight: INFlight) {
        self.init()
        self.reservedSeat = reservedSeat
        self.flight = flight
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, flight: INFlight) {
        self.init()
        self.reservedSeat = reservedSeat
        self.flight = flight
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, reservedSeat: INSeat?, flight: INFlight) {
        self.init()
        self.reservedSeat = reservedSeat
        self.flight = flight
    }
}

open class INGetAvailableRestaurantReservationBookingDefaultsIntent: INIntent, @unchecked Sendable {
    open var restaurant: INRestaurant? = nil
    public required override init() { super.init() }
    public convenience init(restaurant: INRestaurant?) {
        self.init()
        self.restaurant = restaurant
    }
}

open class INGetAvailableRestaurantReservationBookingDefaultsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode?
    open var defaultBookingDate: Date?
    open var defaultPartySize: Int = 0
    open var maximumPartySize: NSNumber? = nil
    open var minimumPartySize: NSNumber? = nil
    open var providerImage: INImage?
    public required override init() { super.init() }
    public convenience init(defaultPartySize: Int, defaultBooking defaultBookingDate: Date, code: INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.defaultPartySize = defaultPartySize
        self.defaultBookingDate = defaultBookingDate
        self.code = code
        self.userActivity = userActivity
    }
    public convenience init(defaultPartySize: Int, defaultBookingDate: Date, code: INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.defaultPartySize = defaultPartySize
        self.defaultBookingDate = defaultBookingDate
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetAvailableRestaurantReservationBookingsIntent: INIntent, @unchecked Sendable {
    open var earliestBookingDateForResults: Date? = nil
    open var latestBookingDateForResults: Date? = nil
    open var maximumNumberOfResults: NSNumber? = nil
    open var partySize: Int = 0
    open var preferredBookingDateComponents: DateComponents? = nil
    open var restaurant: INRestaurant?
    public required override init() { super.init() }
    public convenience init(restaurant: INRestaurant, partySize: Int, preferredBooking preferredBookingDateComponents: DateComponents?, maximumNumberOfResults: NSNumber?, earliestBookingDateForResults: Date?, latestBookingDateForResults: Date?) {
        self.init()
        self.restaurant = restaurant
        self.partySize = partySize
        self.preferredBookingDateComponents = preferredBookingDateComponents
        self.maximumNumberOfResults = maximumNumberOfResults
        self.earliestBookingDateForResults = earliestBookingDateForResults
        self.latestBookingDateForResults = latestBookingDateForResults
    }
    public convenience init(restaurant: INRestaurant, partySize: Int, preferredBookingDateComponents: DateComponents?, maximumNumberOfResults: NSNumber?, earliestBookingDateForResults: Date?, latestBookingDateForResults: Date?) {
        self.init()
        self.restaurant = restaurant
        self.partySize = partySize
        self.preferredBookingDateComponents = preferredBookingDateComponents
        self.maximumNumberOfResults = maximumNumberOfResults
        self.earliestBookingDateForResults = earliestBookingDateForResults
        self.latestBookingDateForResults = latestBookingDateForResults
    }
}

open class INGetAvailableRestaurantReservationBookingsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var availableBookings: [INRestaurantReservationBooking] = []
    open var code: INGetAvailableRestaurantReservationBookingsIntentCode?
    open var localizedBookingAdvisementText: String? = nil
    open var localizedRestaurantDescriptionText: String? = nil
    open var termsAndConditions: INTermsAndConditions? = nil
    public required override init() { super.init() }
    public convenience init(availableBookings: [INRestaurantReservationBooking], code: INGetAvailableRestaurantReservationBookingsIntentCode, userActivity: NSUserActivity?) {
        self.init()
        self.availableBookings = availableBookings
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetCarLockStatusIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(carName: INSpeakableString?) {
        self.init()
        self.carName = carName
    }
}

open class INGetCarLockStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetCarLockStatusIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INGetCarLockStatusIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetCarPowerLevelStatusIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(carName: INSpeakableString?) {
        self.init()
        self.carName = carName
    }
}

open class INGetCarPowerLevelStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var activeConnector: INCar.ChargingConnectorType? = nil
    open var carIdentifier: String? = nil
    open var charging: Bool? = nil
    open var chargePercentRemaining: Float? = nil
    open var chargingFormulaArguments: [String : Any]? = nil
    open var code: INGetCarPowerLevelStatusIntentResponseCode?
    open var fuelPercentRemaining: Float? = nil
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
    public required override init() { super.init() }
    public convenience init(code: INGetCarPowerLevelStatusIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetReservationDetailsIntent: INIntent, @unchecked Sendable {
    open var reservationContainerReference: INSpeakableString? = nil
    open var reservationItemReferences: [INSpeakableString]? = nil
    public required override init() { super.init() }
    public convenience init(reservationContainerReference: INSpeakableString?, reservationItemReferences: [INSpeakableString]?) {
        self.init()
        self.reservationContainerReference = reservationContainerReference
        self.reservationItemReferences = reservationItemReferences
    }
}

open class INGetReservationDetailsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetReservationDetailsIntentResponseCode?
    open var reservations: [INReservation]? = nil
    public required override init() { super.init() }
    public convenience init(code: INGetReservationDetailsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetRestaurantGuestIntent: INIntent, @unchecked Sendable {
    public required override init() { super.init() }
}

open class INGetRestaurantGuestIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetRestaurantGuestIntentResponseCode?
    open var guest: INRestaurantGuest? = nil
    open var guestDisplayPreferences: INRestaurantGuestDisplayPreferences? = nil
    public required override init() { super.init() }
    public convenience init(code: INGetRestaurantGuestIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetRideStatusIntent: INIntent, @unchecked Sendable {
    public required override init() { super.init() }
}

open class INGetRideStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetRideStatusIntentResponseCode?
    open var rideStatus: INRideStatus? = nil
    public required override init() { super.init() }
    public convenience init(code: INGetRideStatusIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetUserCurrentRestaurantReservationBookingsIntent: INIntent, @unchecked Sendable {
    open var earliestBookingDateForResults: Date? = nil
    open var maximumNumberOfResults: NSNumber? = nil
    open var reservationIdentifier: String? = nil
    open var restaurant: INRestaurant? = nil
    public required override init() { super.init() }
    public convenience init(restaurant: INRestaurant?, reservationIdentifier: String?, maximumNumberOfResults: NSNumber?, earliestBookingDateForResults: Date?) {
        self.init()
        self.restaurant = restaurant
        self.reservationIdentifier = reservationIdentifier
        self.maximumNumberOfResults = maximumNumberOfResults
        self.earliestBookingDateForResults = earliestBookingDateForResults
    }
}

open class INGetUserCurrentRestaurantReservationBookingsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetUserCurrentRestaurantReservationBookingsIntentResponseCode?
    open var userCurrentBookings: [INRestaurantReservationUserBooking] = []
    public required override init() { super.init() }
    public convenience init(userCurrentBookings: [INRestaurantReservationUserBooking], code: INGetUserCurrentRestaurantReservationBookingsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.userCurrentBookings = userCurrentBookings
        self.code = code
        self.userActivity = userActivity
    }
}

open class INGetVisualCodeIntent: INIntent, @unchecked Sendable {
    open var visualCodeType: INVisualCodeType?
    public required override init() { super.init() }
    public convenience init(visualCodeType: INVisualCodeType) {
        self.init()
        self.visualCodeType = visualCodeType
    }
}

open class INGetVisualCodeIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INGetVisualCodeIntentResponseCode?
    open var visualCodeImage: INImage? = nil
    public required override init() { super.init() }
    public convenience init(code: INGetVisualCodeIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INHangUpCallIntent: INIntent, @unchecked Sendable {
    open var callIdentifier: String? = nil
    public required override init() { super.init() }
    public convenience init(callIdentifier: String?) {
        self.init()
        self.callIdentifier = callIdentifier
    }
}

open class INHangUpCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INHangUpCallIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INHangUpCallIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INImageNoteContent: NSObject, @unchecked Sendable {
    open var image: INImage? = nil
    public required override init() { super.init() }
    public convenience init(image: INImage) {
        self.init()
        self.image = image
    }
}

open class INIntentDonationMetadata: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}




open class INLengthResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with lengthToConfirm: Measurement<UnitLength>?) -> Self { self.init(outcome: .confirmationRequired, value: lengthToConfirm) }
    open class func disambiguation(with lengthsToDisambiguate: [Measurement<UnitLength>]) -> Self { self.init(outcome: .disambiguation, value: lengthsToDisambiguate) }
    open class func success(with resolvedLength: Measurement<UnitLength>) -> Self { self.init(outcome: .success, value: resolvedLength) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INListCarsIntent: INIntent, @unchecked Sendable {
    public required override init() { super.init() }
}

open class INListCarsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var cars: [INCar]? = nil
    open var code: INListCarsIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INListCarsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INListRideOptionsIntent: INIntent, @unchecked Sendable {
    public required override init() { super.init() }
}

open class INListRideOptionsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INListRideOptionsIntentResponseCode?
    open var expirationDate: Date? = nil
    open var paymentMethods: [INPaymentMethod]? = nil
    open var rideOptions: [INRideOption]? = nil
    public required override init() { super.init() }
    public convenience init(code: INListRideOptionsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INLocationRelevanceProvider: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
}

open class INLocationSearchTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with locationSearchTypeToConfirm: INLocationSearchType) -> Self { self.init(outcome: .confirmationRequired, value: locationSearchTypeToConfirm) }
    open class func success(with resolvedLocationSearchType: INLocationSearchType) -> Self { self.init(outcome: .success, value: resolvedLocationSearchType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INLodgingReservation: INReservation, @unchecked Sendable {
    open var reservationDuration: INDateComponentsRange?
    public required init() { super.init() }
}

open class INMassResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with massToConfirm: Measurement<UnitMass>?) -> Self { self.init(outcome: .confirmationRequired, value: massToConfirm) }
    open class func disambiguation(with massToDisambiguate: [Measurement<UnitMass>]) -> Self { self.init(outcome: .disambiguation, value: massToDisambiguate) }
    open class func success(with resolvedMass: Measurement<UnitMass>) -> Self { self.init(outcome: .success, value: resolvedMass) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INMediaAffinityTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with mediaAffinityTypeToConfirm: INMediaAffinityType) -> Self { self.init(outcome: .confirmationRequired, value: mediaAffinityTypeToConfirm) }
    open class func success(with resolvedMediaAffinityType: INMediaAffinityType) -> Self { self.init(outcome: .success, value: resolvedMediaAffinityType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INMediaDestinationReference: NSObject, @unchecked Sendable {
    open class func library() -> Self { self.init() }
    open class func playlistDestination(withName playlistName: String) -> Self { self.init() }
    open var mediaDestinationType: INMediaDestinationType?
    open var playlistName: String? = nil
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INMediaDestinationResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with mediaDestinationToConfirm: INMediaDestination?) -> Self { self.init(outcome: .confirmationRequired, value: mediaDestinationToConfirm) }
    open class func disambiguation(with mediaDestinationsToDisambiguate: [INMediaDestination]) -> Self { self.init(outcome: .disambiguation, value: mediaDestinationsToDisambiguate) }
    open class func success(with resolvedMediaDestination: INMediaDestination) -> Self { self.init(outcome: .success, value: resolvedMediaDestination) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}




open class INMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with mediaItemToConfirm: INMediaItem?) -> Self { self.init(outcome: .confirmationRequired, value: mediaItemToConfirm) }
    open class func disambiguation(with mediaItemsToDisambiguate: [INMediaItem]) -> Self { self.init(outcome: .disambiguation, value: mediaItemsToDisambiguate) }
    open class func success(with resolvedMediaItem: INMediaItem) -> Self { self.init(outcome: .success, value: resolvedMediaItem) }
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INMediaItemResolutionResult] { resolvedMediaItems.map { self.init(outcome: .success, value: $0) } }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}




open class INMediaUserContext: INUserContext, @unchecked Sendable {
    public enum SubscriptionStatus: Int, Hashable, Sendable {
        case notSubscribed = 1
        case subscribed = 2
        case unknown = 0
    }

    open var subscriptionStatus: INMediaUserContext.SubscriptionStatus?
    public required init() { super.init() }
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
    public required override init() { super.init() }
    public convenience init(identifier: String, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?) {
        self.init()
        self.identifier = identifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.messageType = messageType
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType, serviceName: String?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.messageType = messageType
        self.serviceName = serviceName
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType, serviceName: String?, attachmentFiles: [INFile]?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.messageType = messageType
        self.serviceName = serviceName
        self.attachmentFiles = attachmentFiles
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, messageType: INMessageType, serviceName: String?, audioMessageFile: INFile?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.messageType = messageType
        self.serviceName = serviceName
        self.audioMessageFile = audioMessageFile
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, linkMetadata: INMessageLinkMetadata?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.serviceName = serviceName
        self.linkMetadata = linkMetadata
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, messageType: INMessageType, numberOfAttachments: NSNumber?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.serviceName = serviceName
        self.messageType = messageType
        self.numberOfAttachments = numberOfAttachments
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, messageType: INMessageType, referencedMessage: INMessage?, reaction: INMessageReaction?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.serviceName = serviceName
        self.messageType = messageType
        self.reaction = reaction
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, groupName: INSpeakableString?, serviceName: String?, messageType: INMessageType, referencedMessage: INMessage?, sticker: INSticker?, reaction: INMessageReaction?) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.groupName = groupName
        self.serviceName = serviceName
        self.messageType = messageType
        self.sticker = sticker
        self.reaction = reaction
    }
    public convenience init(identifier: String, conversationIdentifier: String?, content: String?, dateSent: Date?, sender: INPerson?, recipients: [INPerson]?, messageType: INMessageType) {
        self.init()
        self.identifier = identifier
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.dateSent = dateSent
        self.sender = sender
        self.recipients = recipients
        self.messageType = messageType
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INMessageAttributeOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with messageAttributeOptionsToConfirm: INMessageAttributeOptions = []) -> Self { self.init(outcome: .confirmationRequired, value: messageAttributeOptionsToConfirm) }
    open class func success(with resolvedMessageAttributeOptions: INMessageAttributeOptions = []) -> Self { self.init(outcome: .success, value: resolvedMessageAttributeOptions) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INMessageAttributeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with messageAttributeToConfirm: INMessageAttribute) -> Self { self.init(outcome: .confirmationRequired, value: messageAttributeToConfirm) }
    open class func success(with resolvedMessageAttribute: INMessageAttribute) -> Self { self.init(outcome: .success, value: resolvedMessageAttribute) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INMessageLinkMetadata: NSObject, @unchecked Sendable {
    open var linkURL: URL? = nil
    open var openGraphType: String? = nil
    open var siteName: String? = nil
    open var summary: String? = nil
    open var title: String? = nil
    public required override init() { super.init() }
    public convenience init(siteName: String?, summary: String?, title: String?, openGraphType: String?, linkURL: URL?) {
        self.init()
        self.siteName = siteName
        self.summary = summary
        self.title = title
        self.openGraphType = openGraphType
        self.linkURL = linkURL
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INMessageReaction: NSObject, @unchecked Sendable {
    open var emoji: String? = nil
    open var reactionDescription: String? = nil
    open var reactionType: INMessageReactionType?
    public required override init() { super.init() }
    public convenience init(reactionType: INMessageReactionType, reactionDescription: String?, emoji: String?) {
        self.init()
        self.reactionType = reactionType
        self.reactionDescription = reactionDescription
        self.emoji = emoji
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INNote: NSObject, @unchecked Sendable {
    open var contents: [INNoteContent] = []
    open var createdDateComponents: DateComponents? = nil
    open var groupName: INSpeakableString? = nil
    open var identifier: String? = nil
    open var modifiedDateComponents: DateComponents? = nil
    open var title: INSpeakableString?
    public required override init() { super.init() }
    public convenience init(title: INSpeakableString, contents: [INNoteContent], groupName: INSpeakableString?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?) {
        self.init()
        self.title = title
        self.contents = contents
        self.groupName = groupName
        self.createdDateComponents = createdDateComponents
        self.modifiedDateComponents = modifiedDateComponents
        self.identifier = identifier
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INNoteContent: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INNoteContentResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with noteContentToConfirm: INNoteContent?) -> Self { self.init(outcome: .confirmationRequired, value: noteContentToConfirm) }
    open class func disambiguation(with noteContentsToDisambiguate: [INNoteContent]) -> Self { self.init(outcome: .disambiguation, value: noteContentsToDisambiguate) }
    open class func success(with resolvedNoteContent: INNoteContent) -> Self { self.init(outcome: .success, value: resolvedNoteContent) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INNoteContentTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with noteContentTypeToConfirm: INNoteContentType) -> Self { self.init(outcome: .confirmationRequired, value: noteContentTypeToConfirm) }
    open class func success(with resolvedNoteContentType: INNoteContentType) -> Self { self.init(outcome: .success, value: resolvedNoteContentType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INNoteResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with noteToConfirm: INNote?) -> Self { self.init(outcome: .confirmationRequired, value: noteToConfirm) }
    open class func disambiguation(with notesToDisambiguate: [INNote]) -> Self { self.init(outcome: .disambiguation, value: notesToDisambiguate) }
    open class func success(with resolvedNote: INNote) -> Self { self.init(outcome: .success, value: resolvedNote) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INNotebookItemTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with notebookItemTypeToConfirm: INNotebookItemType) -> Self { self.init(outcome: .confirmationRequired, value: notebookItemTypeToConfirm) }
    open class func success(with resolvedNotebookItemType: INNotebookItemType) -> Self { self.init(outcome: .success, value: resolvedNotebookItemType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

extension INObject {
    public var displayImage: INImage? {
        get { nil }
        set { _ = newValue }
    }
    public var subtitleString: String? {
        get { nil }
        set { _ = newValue }
    }
}

extension INObjectCollection {
    public var usesIndexedCollation: Bool {
        get { false }
        set { _ = newValue }
    }
}

open class INOutgoingMessageTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with outgoingMessageTypeToConfirm: INOutgoingMessageType) -> Self { self.init(outcome: .confirmationRequired, value: outgoingMessageTypeToConfirm) }
    open class func success(with resolvedOutgoingMessageType: INOutgoingMessageType) -> Self { self.init(outcome: .success, value: resolvedOutgoingMessageType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INParameter: NSObject, @unchecked Sendable {
    private var indexes: [String: Int] = [:]
    open var parameterClass: AnyClass = INIntent.self
    open var parameterKeyPath: String = ""
    public required override init() { super.init() }
    public convenience init(for aClass: AnyClass, keyPath: String) {
        self.init()
        self.parameterClass = aClass
        self.parameterKeyPath = keyPath
    }
    public convenience init(forClass aClass: AnyClass, keyPath: String) {
        self.init(for: aClass, keyPath: keyPath)
    }
    open func index(forSubKeyPath subKeyPath: String) -> Int {
        indexes[subKeyPath] ?? NSNotFound
    }
    open func setIndex(_ index: Int, forSubKeyPath subKeyPath: String) {
        indexes[subKeyPath] = index
    }
    open func isEqual(to parameter: INParameter) -> Bool {
        parameterClass == parameter.parameterClass && parameterKeyPath == parameter.parameterKeyPath
    }
    public required convenience init?(coder: NSCoder) {
        let path = coder.decodeObject(of: NSString.self, forKey: "parameterKeyPath") as String? ?? ""
        self.init(for: INIntent.self, keyPath: path)
    }
}


open class INPauseWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(workoutName: INSpeakableString?) {
        self.init()
        self.workoutName = workoutName
    }
}

open class INPauseWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INPauseWorkoutIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INPauseWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
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
    public required override init() { super.init() }
    public convenience init(billPayee: INBillPayee?, from fromAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?, billType: INBillType, dueDate: INDateComponentsRange?) {
        self.init()
        self.billPayee = billPayee
        self.fromAccount = fromAccount
        self.transactionAmount = transactionAmount
        self.transactionScheduledDate = transactionScheduledDate
        self.transactionNote = transactionNote
        self.billType = billType
        self.dueDate = dueDate
    }
    public convenience init(billPayee: INBillPayee?, fromAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?, billType: INBillType, dueDate: INDateComponentsRange?) {
        self.init()
        self.billPayee = billPayee
        self.fromAccount = fromAccount
        self.transactionAmount = transactionAmount
        self.transactionScheduledDate = transactionScheduledDate
        self.transactionNote = transactionNote
        self.billType = billType
        self.dueDate = dueDate
    }
}

open class INPayBillIntentResponse: INIntentResponse, @unchecked Sendable {
    open var billDetails: INBillDetails? = nil
    open var code: INPayBillIntentResponseCode?
    open var fromAccount: INPaymentAccount? = nil
    open var transactionAmount: INPaymentAmount? = nil
    open var transactionNote: String? = nil
    open var transactionScheduledDate: INDateComponentsRange? = nil
    public required override init() { super.init() }
    public convenience init(code: INPayBillIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INPaymentAccount: NSObject, @unchecked Sendable {
    open var accountNumber: String? = nil
    open var accountType: INAccountType?
    open var balance: INBalanceAmount? = nil
    open var nickname: INSpeakableString? = nil
    open var organizationName: INSpeakableString? = nil
    open var secondaryBalance: INBalanceAmount? = nil
    public required override init() { super.init() }
    public convenience init?(nickname: INSpeakableString, number: String?, accountType: INAccountType, organizationName: INSpeakableString?) {
        self.init()
        self.nickname = nickname
        self.accountNumber = number
        self.accountType = accountType
        self.organizationName = organizationName
    }
    public convenience init(nickname: INSpeakableString, number: String?, accountType: INAccountType, organizationName: INSpeakableString?, balance: INBalanceAmount?, secondaryBalance: INBalanceAmount?) {
        self.init()
        self.nickname = nickname
        self.accountNumber = number
        self.accountType = accountType
        self.organizationName = organizationName
        self.balance = balance
        self.secondaryBalance = secondaryBalance
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INPaymentAccountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentAccountToConfirm: INPaymentAccount?) -> Self { self.init(outcome: .confirmationRequired, value: paymentAccountToConfirm) }
    open class func disambiguation(with paymentAccountsToDisambiguate: [INPaymentAccount]) -> Self { self.init(outcome: .disambiguation, value: paymentAccountsToDisambiguate) }
    open class func success(with resolvedPaymentAccount: INPaymentAccount) -> Self { self.init(outcome: .success, value: resolvedPaymentAccount) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INPaymentAmount: NSObject, @unchecked Sendable {
    open var amount: INCurrencyAmount? = nil
    open var amountType: INAmountType?
    public required override init() { super.init() }
    public convenience init(amountType: INAmountType, amount: INCurrencyAmount) {
        self.init()
        self.amountType = amountType
        self.amount = amount
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INPaymentAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentAmountToConfirm: INPaymentAmount?) -> Self { self.init(outcome: .confirmationRequired, value: paymentAmountToConfirm) }
    open class func disambiguation(with paymentAmountsToDisambiguate: [INPaymentAmount]) -> Self { self.init(outcome: .disambiguation, value: paymentAmountsToDisambiguate) }
    open class func success(with resolvedPaymentAmount: INPaymentAmount) -> Self { self.init(outcome: .success, value: resolvedPaymentAmount) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INPaymentMethod: NSObject, @unchecked Sendable {
    open class func applePay() -> Self { self.init() }
    open var icon: INImage? = nil
    open var identificationHint: String? = nil
    open var name: String? = nil
    open var type: INPaymentMethodType?
    public required override init() { super.init() }
    public convenience init(type: INPaymentMethodType, name: String?, identificationHint: String?, icon: INImage?) {
        self.init()
        self.type = type
        self.name = name
        self.identificationHint = identificationHint
        self.icon = icon
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INPaymentMethodResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentMethodToConfirm: INPaymentMethod?) -> Self { self.init(outcome: .confirmationRequired, value: paymentMethodToConfirm) }
    open class func disambiguation(with paymentMethodsToDisambiguate: [INPaymentMethod]) -> Self { self.init(outcome: .disambiguation, value: paymentMethodsToDisambiguate) }
    open class func success(with resolvedPaymentMethod: INPaymentMethod) -> Self { self.init(outcome: .success, value: resolvedPaymentMethod) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INPaymentRecord: NSObject, @unchecked Sendable {
    open var currencyAmount: INCurrencyAmount? = nil
    open var feeAmount: INCurrencyAmount? = nil
    open var note: String? = nil
    open var payee: INPerson? = nil
    open var payer: INPerson? = nil
    open var paymentMethod: INPaymentMethod? = nil
    open var status: INPaymentStatus?
    public required override init() { super.init() }
    public convenience init?(payee: INPerson?, payer: INPerson?, currencyAmount: INCurrencyAmount?, paymentMethod: INPaymentMethod?, note: String?, status: INPaymentStatus) {
        self.init()
        self.payee = payee
        self.payer = payer
        self.currencyAmount = currencyAmount
        self.paymentMethod = paymentMethod
        self.note = note
        self.status = status
    }
    public convenience init?(payee: INPerson?, payer: INPerson?, currencyAmount: INCurrencyAmount?, paymentMethod: INPaymentMethod?, note: String?, status: INPaymentStatus, feeAmount: INCurrencyAmount?) {
        self.init()
        self.payee = payee
        self.payer = payer
        self.currencyAmount = currencyAmount
        self.paymentMethod = paymentMethod
        self.note = note
        self.status = status
        self.feeAmount = feeAmount
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INPaymentStatusResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with paymentStatusToConfirm: INPaymentStatus) -> Self { self.init(outcome: .confirmationRequired, value: paymentStatusToConfirm) }
    open class func success(with resolvedPaymentStatus: INPaymentStatus) -> Self { self.init(outcome: .success, value: resolvedPaymentStatus) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}




open class INPlacemarkResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INPlayMediaIntent: INIntent, @unchecked Sendable {
    open var mediaContainer: INMediaItem? = nil
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    open var playbackQueueLocation: INPlaybackQueueLocation = .unknown
    open var playbackRepeatMode: INPlaybackRepeatMode = .unknown
    open var playShuffled: Bool? = nil
    open var resumePlayback: Bool? = nil
    open var playbackSpeed: Double? = nil
    public required override init() { super.init() }
    public convenience init(
        mediaItems: [INMediaItem]? = nil,
        mediaContainer: INMediaItem? = nil,
        playShuffled: Bool? = nil,
        playbackRepeatMode: INPlaybackRepeatMode = .unknown,
        resumePlayback: Bool? = nil,
        playbackQueueLocation: INPlaybackQueueLocation = .unknown,
        playbackSpeed: Double? = nil,
        mediaSearch: INMediaSearch? = nil
    ) {
        self.init()
        self.mediaItems = mediaItems
        self.mediaContainer = mediaContainer
        self.playShuffled = playShuffled
        self.playbackRepeatMode = playbackRepeatMode
        self.resumePlayback = resumePlayback
        self.playbackQueueLocation = playbackQueueLocation
        self.playbackSpeed = playbackSpeed
        self.mediaSearch = mediaSearch
    }
}


open class INPlayMediaIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INPlayMediaIntentResponseCode = .unspecified
    open var nowPlayingInfo: [String : Any]? = nil
    public required override init() { super.init() }
    public convenience init(code: INPlayMediaIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}


open class INPlayMediaMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INPlayMediaMediaItemResolutionResult] { resolvedMediaItems.map { self.init(outcome: .success, value: $0) } }
    open class func unsupported(forReason reason: INPlayMediaMediaItemUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INPlayMediaPlaybackSpeedResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INPlayMediaPlaybackSpeedUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(doubleResolutionResult: INDoubleResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INPlaybackQueueLocationResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with playbackQueueLocationToConfirm: INPlaybackQueueLocation) -> Self { self.init(outcome: .confirmationRequired, value: playbackQueueLocationToConfirm) }
    open class func success(with resolvedPlaybackQueueLocation: INPlaybackQueueLocation) -> Self { self.init(outcome: .success, value: resolvedPlaybackQueueLocation) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INPlaybackRepeatModeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with playbackRepeatModeToConfirm: INPlaybackRepeatMode) -> Self { self.init(outcome: .confirmationRequired, value: playbackRepeatModeToConfirm) }
    open class func success(with resolvedPlaybackRepeatMode: INPlaybackRepeatMode) -> Self { self.init(outcome: .success, value: resolvedPlaybackRepeatMode) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INPreferences: NSObject, @unchecked Sendable {
    // Apple: INSiriAuthorizationStatus.denied is "The user denied
    // authorization for the app to use Siri"; .restricted is ineligibility
    // because of active restrictions (see INFocusStatusAuthorizationStatus).
    // Linux has no Siri prompt or account, so the host stays .denied and
    // invokes the request handler synchronously with that status.
    open class func requestSiriAuthorization(_ handler: @escaping (INSiriAuthorizationStatus) -> Void) {
        handler(.denied)
    }
    open class func siriAuthorizationStatus() -> INSiriAuthorizationStatus { .denied }
    open class func siriLanguageCode() -> String { "" }
    public required override init() { super.init() }
}


open class INPriceRange: NSObject, @unchecked Sendable {
    open var currencyCode: String = ""
    open var maximumPrice: NSDecimalNumber? = nil
    open var minimumPrice: NSDecimalNumber? = nil
    public required override init() { super.init() }
    public convenience init(maximumPrice: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.maximumPrice = maximumPrice
        self.currencyCode = currencyCode
    }
    public convenience init(minimumPrice: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.minimumPrice = minimumPrice
        self.currencyCode = currencyCode
    }
    public convenience init(price: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.currencyCode = currencyCode
    }
    public convenience init(firstPrice: NSDecimalNumber, secondPrice: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.currencyCode = currencyCode
    }
    public convenience init(rangeBetweenPrice firstPrice: NSDecimalNumber, andPrice secondPrice: NSDecimalNumber, currencyCode: String) {
        self.init()
        self.currencyCode = currencyCode
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRadioTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with radioTypeToConfirm: INRadioType) -> Self { self.init(outcome: .confirmationRequired, value: radioTypeToConfirm) }
    open class func success(with resolvedRadioType: INRadioType) -> Self { self.init(outcome: .success, value: resolvedRadioType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INRecurrenceRule: NSObject, @unchecked Sendable {
    open var frequency: INRecurrenceFrequency?
    open var interval: Int = 0
    open var weeklyRecurrenceDays: INDayOfWeekOptions = []
    public required override init() { super.init() }
    public convenience init(interval: Int, frequency: INRecurrenceFrequency) {
        self.init()
        self.interval = interval
        self.frequency = frequency
    }
    public convenience init(interval: Int, frequency: INRecurrenceFrequency, weeklyRecurrenceDays: INDayOfWeekOptions = []) {
        self.init()
        self.interval = interval
        self.frequency = frequency
        self.weeklyRecurrenceDays = weeklyRecurrenceDays
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRelativeReferenceResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with relativeReferenceToConfirm: INRelativeReference) -> Self { self.init(outcome: .confirmationRequired, value: relativeReferenceToConfirm) }
    open class func success(with resolvedRelativeReference: INRelativeReference) -> Self { self.init(outcome: .success, value: resolvedRelativeReference) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INRelativeSettingResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with relativeSettingToConfirm: INRelativeSetting) -> Self { self.init(outcome: .confirmationRequired, value: relativeSettingToConfirm) }
    open class func success(with resolvedRelativeSetting: INRelativeSetting) -> Self { self.init(outcome: .success, value: resolvedRelativeSetting) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INRelevanceProvider: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRelevantShortcut: NSObject, @unchecked Sendable {
    open var relevanceProviders: [INRelevanceProvider] = []
    open var shortcut: INShortcut
    open var shortcutRole: INRelevantShortcutRole = .action
    open var watchTemplate: INDefaultCardTemplate? = nil
    open var widgetKind: String? = nil
    public init(shortcut: INShortcut) {
        self.shortcut = shortcut
        super.init()
    }
    public required convenience init?(coder: NSCoder) {
        guard let shortcut = coder.decodeObject(of: INShortcut.self, forKey: "shortcut") else {
            return nil
        }
        self.init(shortcut: shortcut)
        widgetKind = coder.decodeObject(of: NSString.self, forKey: "widgetKind") as String?
    }
}


open class INRelevantShortcutStore: NSObject, @unchecked Sendable {
    public static let `default` = INRelevantShortcutStore()
    private let state = Mutex<[INRelevantShortcut]>([])
    public required override init() { super.init() }
    open func setRelevantShortcuts(_ shortcuts: [INRelevantShortcut]) async throws {
        state.withLock { $0 = shortcuts }
    }
    open func setRelevantShortcuts(_ shortcuts: [INRelevantShortcut], completion: ((Error?) -> Void)? = nil) {
        state.withLock { $0 = shortcuts }
        completion?(nil)
    }
    @_spi(OpenIntentsHost)
    public var storedShortcuts: [INRelevantShortcut] {
        state.withLock { $0 }
    }
}


open class INRentalCar: NSObject, @unchecked Sendable {
    open var make: String? = nil
    open var model: String? = nil
    open var rentalCarDescription: String? = nil
    open var rentalCompanyName: String = ""
    open var type: String? = nil
    public required override init() { super.init() }
    public convenience init(rentalCompanyName: String, type: String?, make: String?, model: String?, rentalCarDescription: String?) {
        self.init()
        self.rentalCompanyName = rentalCompanyName
        self.type = type
        self.make = make
        self.model = model
        self.rentalCarDescription = rentalCarDescription
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRentalCarReservation: NSObject, @unchecked Sendable {
    open var rentalCar: INRentalCar?
    open var rentalDuration: INDateComponentsRange?
    public required override init() { super.init() }
}

open class INRequestPaymentCurrencyAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INRequestPaymentCurrencyAmountUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(currencyAmountResolutionResult: INCurrencyAmountResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INRequestPaymentIntent: INIntent, @unchecked Sendable {
    open var currencyAmount: INCurrencyAmount? = nil
    open var note: String? = nil
    open var payer: INPerson? = nil
    public required override init() { super.init() }
    public convenience init(payer: INPerson?, currencyAmount: INCurrencyAmount?, note: String?) {
        self.init()
        self.payer = payer
        self.currencyAmount = currencyAmount
        self.note = note
    }
}

open class INRequestPaymentIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INRequestPaymentIntentResponseCode?
    open var paymentRecord: INPaymentRecord? = nil
    public required override init() { super.init() }
    public convenience init(code: INRequestPaymentIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INRequestPaymentPayerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INRequestPaymentPayerUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(personResolutionResult: INPersonResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INRequestRideIntent: INIntent, @unchecked Sendable {
    open var paymentMethod: INPaymentMethod? = nil
    open var rideOptionName: INSpeakableString? = nil
    open var scheduledPickupTime: INDateComponentsRange? = nil
    public required override init() { super.init() }
}

open class INRequestRideIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INRequestRideIntentResponseCode?
    open var rideStatus: INRideStatus? = nil
    public required override init() { super.init() }
    public convenience init(code: INRequestRideIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
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
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INReservationAction: NSObject, @unchecked Sendable {
    open var type: INReservationActionType?
    open var userActivity: NSUserActivity?
    open var validDuration: INDateComponentsRange?
    public required override init() { super.init() }
    public convenience init(type: INReservationActionType, validDuration: INDateComponentsRange, userActivity: NSUserActivity) {
        self.init()
        self.type = type
        self.validDuration = validDuration
        self.userActivity = userActivity
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRestaurant: NSObject, @unchecked Sendable {
    open var name: String = ""
    open var restaurantIdentifier: String = ""
    open var vendorIdentifier: String = ""
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRestaurantGuest: NSObject, @unchecked Sendable {
    open var emailAddress: String? = nil
    open var phoneNumber: String? = nil
    public required override init() { super.init() }
    public convenience init(nameComponents: PersonNameComponents?, phoneNumber: String?, emailAddress: String?) {
        self.init()
        self.phoneNumber = phoneNumber
        self.emailAddress = emailAddress
        _ = nameComponents
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
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
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRestaurantGuestResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with restaurantGuestToConfirm: INRestaurantGuest?) -> Self { self.init(outcome: .confirmationRequired, value: restaurantGuestToConfirm) }
    open class func disambiguation(with restaurantGuestsToDisambiguate: [INRestaurantGuest]) -> Self { self.init(outcome: .disambiguation, value: restaurantGuestsToDisambiguate) }
    open class func success(with resolvedRestaurantGuest: INRestaurantGuest) -> Self { self.init(outcome: .success, value: resolvedRestaurantGuest) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INRestaurantOffer: NSObject, @unchecked Sendable {
    open var offerDetailText: String = ""
    open var offerIdentifier: String = ""
    open var offerTitleText: String = ""
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRestaurantReservation: INReservation, @unchecked Sendable {
    open var reservationDuration: INDateComponentsRange?
    public required init() { super.init() }
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
    public required override init() { super.init() }
    public convenience init(restaurant: INRestaurant, booking bookingDate: Date, partySize: Int, bookingIdentifier: String) {
        self.init()
        self.restaurant = restaurant
        self.bookingDate = bookingDate
        self.partySize = partySize
        self.bookingIdentifier = bookingIdentifier
    }
    public convenience init(restaurant: INRestaurant, bookingDate: Date, partySize: Int, bookingIdentifier: String) {
        self.init()
        self.restaurant = restaurant
        self.bookingDate = bookingDate
        self.partySize = partySize
        self.bookingIdentifier = bookingIdentifier
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRestaurantReservationUserBooking: NSObject, @unchecked Sendable {
    open var advisementText: String? = nil
    open var dateStatusModified: Date?
    open var guest: INRestaurantGuest?
    open var guestProvidedSpecialRequestText: String? = nil
    open var selectedOffer: INRestaurantOffer? = nil
    open var status: INRestaurantReservationUserBookingStatus?
    public required override init() { super.init() }
    open var restaurant: INRestaurant?
    open var bookingDate: Date?
    open var partySize: Int = 0
    open var bookingIdentifier: String?

    public convenience init(restaurant: INRestaurant, booking bookingDate: Date, partySize: Int, bookingIdentifier: String, guest: INRestaurantGuest, status: INRestaurantReservationUserBookingStatus, dateStatusModified: Date) {
        self.init()
        self.restaurant = restaurant
        self.bookingDate = bookingDate
        self.partySize = partySize
        self.bookingIdentifier = bookingIdentifier
        self.guest = guest
        self.status = status
        self.dateStatusModified = dateStatusModified
    }
    public convenience init(restaurant: INRestaurant, bookingDate: Date, partySize: Int, bookingIdentifier: String, guest: INRestaurantGuest, status: INRestaurantReservationUserBookingStatus, dateStatusModified: Date) {
        self.init()
        self.restaurant = restaurant
        self.bookingDate = bookingDate
        self.partySize = partySize
        self.bookingIdentifier = bookingIdentifier
        self.guest = guest
        self.status = status
        self.dateStatusModified = dateStatusModified
    }
}

open class INRestaurantResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with restaurantToConfirm: INRestaurant?) -> Self { self.init(outcome: .confirmationRequired, value: restaurantToConfirm) }
    open class func disambiguation(with restaurantsToDisambiguate: [INRestaurant]) -> Self { self.init(outcome: .disambiguation, value: restaurantsToDisambiguate) }
    open class func success(with resolvedRestaurant: INRestaurant) -> Self { self.init(outcome: .success, value: resolvedRestaurant) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INResumeWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(workoutName: INSpeakableString?) {
        self.init()
        self.workoutName = workoutName
    }
}

open class INResumeWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INResumeWorkoutIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INResumeWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INRideCompletionStatus: NSObject, @unchecked Sendable {
    open class func canceledByService() -> Self {
        let value = self.init()
        value.isCanceled = true
        return value
    }
    open class func canceledByUser() -> Self {
        let value = self.init()
        value.isCanceled = true
        return value
    }
    open class func canceledMissedPickup() -> Self {
        let value = self.init()
        value.isCanceled = true
        value.isMissedPickup = true
        return value
    }
    open class func completed() -> Self {
        let value = self.init()
        value.isCompleted = true
        return value
    }
    open var isCanceled: Bool = false
    open var isCompleted: Bool = false
    open var completionUserActivity: NSUserActivity? = nil
    open var defaultTippingOptions: Set<INCurrencyAmount>? = nil
    open var feedbackType: INRideFeedbackTypeOptions = []
    open var isMissedPickup: Bool = false
    open var isOutstanding: Bool = false
    open var paymentAmount: INCurrencyAmount? = nil
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRideDriver: NSObject, @unchecked Sendable {
    open var phoneNumber: String? = nil
    open var rating: String? = nil
    public required override init() { super.init() }
    public convenience init(handle: String, displayName: String?, image: INImage?, rating: String?, phoneNumber: String?) {
        self.init()
        self.rating = rating
        self.phoneNumber = phoneNumber
        _ = handle
        _ = displayName
        _ = image
    }
    public convenience init(handle: String, nameComponents: PersonNameComponents, image: INImage?, rating: String?, phoneNumber: String?) {
        self.init()
        self.rating = rating
        self.phoneNumber = phoneNumber
        _ = handle
        _ = nameComponents
        _ = image
    }
    public convenience init(personHandle: INPersonHandle, nameComponents: PersonNameComponents?, displayName: String?, image: INImage?, rating: String?, phoneNumber: String?) {
        self.init()
        self.rating = rating
        self.phoneNumber = phoneNumber
        _ = personHandle
        _ = nameComponents
        _ = displayName
        _ = image
    }
    public convenience init(phoneNumber: String, nameComponents: PersonNameComponents?, displayName: String?, image: INImage?, rating: String?) {
        self.init()
        self.phoneNumber = phoneNumber
        self.rating = rating
        _ = nameComponents
        _ = displayName
        _ = image
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRideFareLineItem: NSObject, @unchecked Sendable {
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
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
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
    public convenience init(name: String, estimatedPickupDate: Date) {
        self.init()
        self.name = name
        self.estimatedPickupDate = estimatedPickupDate
    }
}

open class INRidePartySizeOption: NSObject, @unchecked Sendable {
    open var partySizeRange: NSRange?
    open var priceRange: INPriceRange? = nil
    open var sizeDescription: String = ""
    public required override init() { super.init() }
    public convenience init(partySizeRange: NSRange, sizeDescription: String, priceRange: INPriceRange?) {
        self.init()
        self.partySizeRange = partySizeRange
        self.sizeDescription = sizeDescription
        self.priceRange = priceRange
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
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
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INRideVehicle: NSObject, @unchecked Sendable {
    open var manufacturer: String? = nil
    open var mapAnnotationImage: INImage? = nil
    open var model: String? = nil
    open var registrationPlate: String? = nil
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INSaveProfileInCarIntent: INIntent, @unchecked Sendable {
    open var profileLabel: String? = nil
    open var profileName: String? = nil
    public required override init() { super.init() }
}

open class INSaveProfileInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSaveProfileInCarIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSaveProfileInCarIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSearchCallHistoryIntent: INIntent, @unchecked Sendable {
    open var callCapabilities: INCallCapabilityOptions = []
    open var callType: INCallRecordType?
    open var callTypes: INCallRecordTypeOptions = []
    open var dateCreated: INDateComponentsRange? = nil
    open var recipient: INPerson? = nil
    public required override init() { super.init() }
    public convenience init(call callType: INCallRecordType, dateCreated: INDateComponentsRange?, recipient: INPerson?, callCapabilities: INCallCapabilityOptions = []) {
        self.init()
        self.callType = callType
        self.dateCreated = dateCreated
        self.recipient = recipient
        self.callCapabilities = callCapabilities
    }
}

open class INSearchCallHistoryIntentResponse: INIntentResponse, @unchecked Sendable {
    open var callRecords: [INCallRecord]? = nil
    open var code: INSearchCallHistoryIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSearchCallHistoryIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSearchForAccountsIntent: INIntent, @unchecked Sendable {
    open var accountNickname: INSpeakableString? = nil
    open var accountType: INAccountType?
    open var organizationName: INSpeakableString? = nil
    open var requestedBalanceType: INBalanceType?
    public required override init() { super.init() }
    public convenience init(accountNickname: INSpeakableString?, accountType: INAccountType, organizationName: INSpeakableString?, requestedBalanceType: INBalanceType) {
        self.init()
        self.accountNickname = accountNickname
        self.accountType = accountType
        self.organizationName = organizationName
        self.requestedBalanceType = requestedBalanceType
    }
}

open class INSearchForAccountsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var accounts: [INPaymentAccount]? = nil
    open var code: INSearchForAccountsIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSearchForAccountsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSearchForBillsIntent: INIntent, @unchecked Sendable {
    open var billPayee: INBillPayee? = nil
    open var billType: INBillType?
    open var dueDateRange: INDateComponentsRange? = nil
    open var paymentDateRange: INDateComponentsRange? = nil
    open var status: INPaymentStatus?
    public required override init() { super.init() }
    public convenience init(billPayee: INBillPayee?, paymentDateRange: INDateComponentsRange?, billType: INBillType, status: INPaymentStatus, dueDateRange: INDateComponentsRange?) {
        self.init()
        self.billPayee = billPayee
        self.paymentDateRange = paymentDateRange
        self.billType = billType
        self.status = status
        self.dueDateRange = dueDateRange
    }
}

open class INSearchForBillsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var bills: [INBillDetails]? = nil
    open var code: INSearchForBillsIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSearchForBillsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSearchForMediaIntent: INIntent, @unchecked Sendable {
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    public required override init() { super.init() }
    public convenience init(mediaItems: [INMediaItem]?, mediaSearch: INMediaSearch?) {
        self.init()
        self.mediaItems = mediaItems
        self.mediaSearch = mediaSearch
    }
}

open class INSearchForMediaIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForMediaIntentResponseCode?
    open var mediaItems: [INMediaItem]? = nil
    public required override init() { super.init() }
    public convenience init(code: INSearchForMediaIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSearchForMediaMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INSearchForMediaMediaItemResolutionResult] { resolvedMediaItems.map { self.init(outcome: .success, value: $0) } }
    open class func unsupported(forReason reason: INSearchForMediaMediaItemUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INSearchForMessagesIntent: INIntent, @unchecked Sendable {
    open var attributes: INMessageAttributeOptions = []
    open var conversationIdentifiers: [String]? = nil
    open var conversationIdentifiersOperator: INConditionalOperator = .all
    open var dateTimeRange: INDateComponentsRange? = nil
    open var groupNames: [String]? = nil
    open var groupNamesOperator: INConditionalOperator = .all
    open var identifiers: [String]? = nil
    open var identifiersOperator: INConditionalOperator = .all
    open var notificationIdentifiers: [String]? = nil
    open var notificationIdentifiersOperator: INConditionalOperator = .all
    open var recipients: [INPerson]? = nil
    open var recipientsOperator: INConditionalOperator = .all
    open var searchTerms: [String]? = nil
    open var searchTermsOperator: INConditionalOperator = .all
    open var senders: [INPerson]? = nil
    open var sendersOperator: INConditionalOperator = .all
    open var speakableGroupNames: [INSpeakableString]? = nil
    open var speakableGroupNamesOperator: INConditionalOperator = .all
    public required override init() { super.init() }
    public convenience init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTime dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, groupNames: [String]?) {
        self.init()
        self.recipients = recipients
        self.senders = senders
        self.searchTerms = searchTerms
        self.attributes = attributes
        self.dateTimeRange = dateTimeRange
        self.identifiers = identifiers
        self.notificationIdentifiers = notificationIdentifiers
        self.groupNames = groupNames
    }
    public convenience init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTime dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, speakableGroupNames: [INSpeakableString]?) {
        self.init()
        self.recipients = recipients
        self.senders = senders
        self.searchTerms = searchTerms
        self.attributes = attributes
        self.dateTimeRange = dateTimeRange
        self.identifiers = identifiers
        self.notificationIdentifiers = notificationIdentifiers
        self.speakableGroupNames = speakableGroupNames
    }
    public convenience init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTime dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, speakableGroupNames: [INSpeakableString]?, conversationIdentifiers: [String]?) {
        self.init()
        self.recipients = recipients
        self.senders = senders
        self.searchTerms = searchTerms
        self.attributes = attributes
        self.dateTimeRange = dateTimeRange
        self.identifiers = identifiers
        self.notificationIdentifiers = notificationIdentifiers
        self.speakableGroupNames = speakableGroupNames
        self.conversationIdentifiers = conversationIdentifiers
    }
    public convenience init(recipients: [INPerson]?, senders: [INPerson]?, searchTerms: [String]?, attributes: INMessageAttributeOptions = [], dateTimeRange: INDateComponentsRange?, identifiers: [String]?, notificationIdentifiers: [String]?, speakableGroupNames: [INSpeakableString]?, conversationIdentifiers: [String]?) {
        self.init()
        self.recipients = recipients
        self.senders = senders
        self.searchTerms = searchTerms
        self.attributes = attributes
        self.dateTimeRange = dateTimeRange
        self.identifiers = identifiers
        self.notificationIdentifiers = notificationIdentifiers
        self.speakableGroupNames = speakableGroupNames
        self.conversationIdentifiers = conversationIdentifiers
    }
}


open class INSearchForMessagesIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForMessagesIntentResponseCode = .unspecified
    open var messages: [INMessage]? = nil
    public required override init() { super.init() }
    public convenience init(code: INSearchForMessagesIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
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
    public required override init() { super.init() }
}

open class INSearchForNotebookItemsIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForNotebookItemsIntentResponseCode?
    open var notes: [INNote]? = nil
    open var sortType: INSortType?
    open var taskLists: [INTaskList]? = nil
    open var tasks: [INTask]? = nil
    public required override init() { super.init() }
    public convenience init(code: INSearchForNotebookItemsIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
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
    public required override init() { super.init() }
}

open class INSearchForPhotosIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSearchForPhotosIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSearchForPhotosIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSeat: NSObject, @unchecked Sendable {
    open var seatNumber: String? = nil
    open var seatRow: String? = nil
    open var seatSection: String? = nil
    open var seatingType: String? = nil
    public required override init() { super.init() }
    public convenience init(seatSection: String?, seatRow: String?, seatNumber: String?, seatingType: String?) {
        self.init()
        self.seatSection = seatSection
        self.seatRow = seatRow
        self.seatNumber = seatNumber
        self.seatingType = seatingType
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INSendMessageAttachment: NSObject, @unchecked Sendable {
    open var audioMessageFile: INFile? = nil
    public required override init() { super.init() }
    public convenience init(audioMessageFile: INFile) {
        self.init()
        self.audioMessageFile = audioMessageFile
    }
}

open class INSendMessageIntent: INIntent, @unchecked Sendable {
    open var attachments: [INSendMessageAttachment]? = nil
    open var content: String? = nil
    open var conversationIdentifier: String? = nil
    open var groupName: String? = nil
    open var outgoingMessageType: INOutgoingMessageType = .unknown
    open var recipients: [INPerson]? = nil
    open var sender: INPerson? = nil
    open var serviceName: String? = nil
    open var speakableGroupName: INSpeakableString? = nil
    public required override init() { super.init() }
    public convenience init(recipients: [INPerson]?, content: String?, groupName: String?, serviceName: String?, sender: INPerson?) {
        self.init()
        self.recipients = recipients
        self.content = content
        self.groupName = groupName
        self.serviceName = serviceName
        self.sender = sender
    }
    public convenience init(recipients: [INPerson]?, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?) {
        self.init()
        self.recipients = recipients
        self.content = content
        self.speakableGroupName = speakableGroupName
        self.conversationIdentifier = conversationIdentifier
        self.serviceName = serviceName
        self.sender = sender
    }
    public convenience init(recipients: [INPerson]?, outgoingMessageType: INOutgoingMessageType, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?) {
        self.init()
        self.recipients = recipients
        self.outgoingMessageType = outgoingMessageType
        self.content = content
        self.speakableGroupName = speakableGroupName
        self.conversationIdentifier = conversationIdentifier
        self.serviceName = serviceName
        self.sender = sender
    }
    public convenience init(recipients: [INPerson]?, outgoingMessageType: INOutgoingMessageType, content: String?, speakableGroupName: INSpeakableString?, conversationIdentifier: String?, serviceName: String?, sender: INPerson?, attachments: [INSendMessageAttachment]?) {
        self.init()
        self.recipients = recipients
        self.outgoingMessageType = outgoingMessageType
        self.content = content
        self.speakableGroupName = speakableGroupName
        self.conversationIdentifier = conversationIdentifier
        self.serviceName = serviceName
        self.sender = sender
        self.attachments = attachments
    }
}


open class INSendMessageIntentDonationMetadata: NSObject, @unchecked Sendable {
    open var mentionsCurrentUser: Bool = false
    open var notifyRecipientAnyway: Bool = false
    open var recipientCount: Int = 0
    open var isReplyToCurrentUser: Bool = false
    public required override init() { super.init() }
}

open class INSendMessageIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSendMessageIntentResponseCode = .unspecified
    open var sentMessage: INMessage? = nil
    open var sentMessages: [INMessage]? = nil
    public required override init() { super.init() }
    public convenience init(code: INSendMessageIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}


open class INSendMessageRecipientResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSendMessageRecipientUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(personResolutionResult: INPersonResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INSendPaymentCurrencyAmountResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSendPaymentCurrencyAmountUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(currencyAmountResolutionResult: INCurrencyAmountResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INSendPaymentIntent: INIntent, @unchecked Sendable {
    open var currencyAmount: INCurrencyAmount? = nil
    open var note: String? = nil
    open var payee: INPerson? = nil
    public required override init() { super.init() }
    public convenience init(payee: INPerson?, currencyAmount: INCurrencyAmount?, note: String?) {
        self.init()
        self.payee = payee
        self.currencyAmount = currencyAmount
        self.note = note
    }
}

open class INSendPaymentIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSendPaymentIntentResponseCode?
    open var paymentRecord: INPaymentRecord? = nil
    public required override init() { super.init() }
    public convenience init(code: INSendPaymentIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSendPaymentPayeeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSendPaymentPayeeUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(personResolutionResult: INPersonResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INSendRideFeedbackIntent: INIntent, @unchecked Sendable {
    open var rating: NSNumber? = nil
    open var rideIdentifier: String = ""
    open var tip: INCurrencyAmount? = nil
    public required override init() { super.init() }
    public convenience init(rideIdentifier: String) {
        self.init()
        self.rideIdentifier = rideIdentifier
    }
}

open class INSendRideFeedbackIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSendRideFeedbackIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSendRideFeedbackIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetAudioSourceInCarIntent: INIntent, @unchecked Sendable {
    open var audioSource: INCarAudioSource?
    open var relativeAudioSourceReference: INRelativeReference?
    public required override init() { super.init() }
    public convenience init(audioSource: INCarAudioSource, relativeAudioSourceReference: INRelativeReference) {
        self.init()
        self.audioSource = audioSource
        self.relativeAudioSourceReference = relativeAudioSourceReference
    }
}

open class INSetAudioSourceInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetAudioSourceInCarIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetAudioSourceInCarIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetCarLockStatusIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    public required override init() { super.init() }
}

open class INSetCarLockStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetCarLockStatusIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetCarLockStatusIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetClimateSettingsInCarIntent: INIntent, @unchecked Sendable {
    open var airCirculationMode: INCarAirCirculationMode?
    open var carName: INSpeakableString? = nil
    open var climateZone: INCarSeat?
    open var relativeFanSpeedSetting: INRelativeSetting?
    open var relativeTemperatureSetting: INRelativeSetting?
    open var temperature: Measurement<UnitTemperature>? = nil
    @nonobjc public var enableFan: Bool? = nil
    @nonobjc public var enableAirConditioner: Bool? = nil
    @nonobjc public var enableClimateControl: Bool? = nil
    @nonobjc public var enableAutoMode: Bool? = nil
    @nonobjc public var fanSpeedIndex: Int? = nil
    @nonobjc public var fanSpeedPercentage: Double? = nil
    public required override init() { super.init() }

    @nonobjc
    public convenience init(
        enableFan: Bool? = nil,
        enableAirConditioner: Bool? = nil,
        enableClimateControl: Bool? = nil,
        enableAutoMode: Bool? = nil,
        airCirculationMode: INCarAirCirculationMode = .unknown,
        fanSpeedIndex: Int? = nil,
        fanSpeedPercentage: Double? = nil,
        relativeFanSpeedSetting: INRelativeSetting = .unknown,
        temperature: Measurement<UnitTemperature>? = nil,
        relativeTemperatureSetting: INRelativeSetting = .unknown,
        climateZone: INCarSeat = .unknown,
        carName: INSpeakableString? = nil
    ) {
        self.init()
        self.enableFan = enableFan
        self.enableAirConditioner = enableAirConditioner
        self.enableClimateControl = enableClimateControl
        self.enableAutoMode = enableAutoMode
        self.airCirculationMode = airCirculationMode
        self.fanSpeedIndex = fanSpeedIndex
        self.fanSpeedPercentage = fanSpeedPercentage
        self.relativeFanSpeedSetting = relativeFanSpeedSetting
        self.temperature = temperature
        self.relativeTemperatureSetting = relativeTemperatureSetting
        self.climateZone = climateZone
        self.carName = carName
    }
}

open class INSetClimateSettingsInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetClimateSettingsInCarIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetClimateSettingsInCarIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetDefrosterSettingsInCarIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var defroster: INCarDefroster?
    public required override init() { super.init() }
}

open class INSetDefrosterSettingsInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetDefrosterSettingsInCarIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetDefrosterSettingsInCarIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetMessageAttributeIntent: INIntent, @unchecked Sendable {
    open var attribute: INMessageAttribute?
    open var identifiers: [String]? = nil
    public required override init() { super.init() }
    public convenience init(identifiers: [String]?, attribute: INMessageAttribute) {
        self.init()
        self.identifiers = identifiers
        self.attribute = attribute
    }
}

open class INSetMessageAttributeIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetMessageAttributeIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetMessageAttributeIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetProfileInCarIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var profileLabel: String? = nil
    open var profileName: String? = nil
    open var defaultProfile: Int? = nil
    open var isDefaultProfile: Bool? = nil
    open var profileNumber: Int? = nil
    public required override init() { super.init() }
    public convenience init(defaultProfile: Int?) {
        self.init()
        self.defaultProfile = defaultProfile
    }
    public convenience init(profileName: String?, defaultProfile: Int?) {
        self.init()
        self.profileName = profileName
        self.defaultProfile = defaultProfile
    }
    public convenience init(profileLabel: String?, defaultProfile: Int?) {
        self.init()
        self.profileLabel = profileLabel
        self.defaultProfile = defaultProfile
    }
    public convenience init(profileLabel: String?, isDefaultProfile: Bool?) {
        self.init()
        self.profileLabel = profileLabel
        self.isDefaultProfile = isDefaultProfile
    }
    public convenience init(profileLabel: String?) {
        self.init()
        self.profileLabel = profileLabel
    }
    public convenience init(profileNumber: Int?, defaultProfile: Int?) {
        self.init()
        self.profileNumber = profileNumber
        self.defaultProfile = defaultProfile
    }
    public convenience init(profileNumber: Int?, profileName: String?, defaultProfile: Int?) {
        self.init()
        self.profileNumber = profileNumber
        self.profileName = profileName
        self.defaultProfile = defaultProfile
    }
    public convenience init(profileNumber: Int? = nil, profileName: String? = nil, isDefaultProfile: Bool? = nil, carName: INSpeakableString? = nil) {
        self.init()
        self.profileNumber = profileNumber
        self.profileName = profileName
        self.isDefaultProfile = isDefaultProfile
        self.carName = carName
    }
    public convenience init(profileNumber: Int?, profileLabel: String?, defaultProfile: Int?) {
        self.init()
        self.profileNumber = profileNumber
        self.profileLabel = profileLabel
        self.defaultProfile = defaultProfile
    }
    public convenience init(profileNumber: Int?, profileLabel: String?, isDefaultProfile: Bool?) {
        self.init()
        self.profileNumber = profileNumber
        self.profileLabel = profileLabel
        self.isDefaultProfile = isDefaultProfile
    }
    public convenience init(profileNumber: Int?, profileLabel: String?) {
        self.init()
        self.profileNumber = profileNumber
        self.profileLabel = profileLabel
    }
}

open class INSetProfileInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetProfileInCarIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetProfileInCarIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetRadioStationIntent: INIntent, @unchecked Sendable {
    open var channel: String? = nil
    open var radioType: INRadioType?
    open var stationName: String? = nil
    public required override init() { super.init() }
}

open class INSetRadioStationIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetRadioStationIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetRadioStationIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetSeatSettingsInCarIntent: INIntent, @unchecked Sendable {
    open var carName: INSpeakableString? = nil
    open var relativeLevelSetting: INRelativeSetting?
    open var seat: INCarSeat?
    public required override init() { super.init() }
}

open class INSetSeatSettingsInCarIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetSeatSettingsInCarIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INSetSeatSettingsInCarIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetTaskAttributeIntent: INIntent, @unchecked Sendable {
    open var priority: INTaskPriority?
    open var spatialEventTrigger: INSpatialEventTrigger? = nil
    open var status: INTaskStatus?
    open var targetTask: INTask? = nil
    open var taskTitle: INSpeakableString? = nil
    open var temporalEventTrigger: INTemporalEventTrigger? = nil
    public required override init() { super.init() }
    public convenience init(targetTask: INTask?, status: INTaskStatus, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?) {
        self.init()
        self.targetTask = targetTask
        self.status = status
        self.spatialEventTrigger = spatialEventTrigger
        self.temporalEventTrigger = temporalEventTrigger
    }
    public convenience init(targetTask: INTask?, taskTitle: INSpeakableString?, status: INTaskStatus, priority: INTaskPriority, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?) {
        self.init()
        self.targetTask = targetTask
        self.taskTitle = taskTitle
        self.status = status
        self.priority = priority
        self.spatialEventTrigger = spatialEventTrigger
        self.temporalEventTrigger = temporalEventTrigger
    }
}

open class INSetTaskAttributeIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSetTaskAttributeIntentResponseCode?
    open var modifiedTask: INTask? = nil
    public required override init() { super.init() }
    public convenience init(code: INSetTaskAttributeIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSetTaskAttributeTemporalEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSetTaskAttributeTemporalEventTriggerUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(temporalEventTriggerResolutionResult: INTemporalEventTriggerResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INShareFocusStatusIntent: INIntent, @unchecked Sendable {
    open var focusStatus: INFocusStatus? = nil
    public required override init() { super.init() }
    public convenience init(focusStatus: INFocusStatus?) {
        self.init()
        self.focusStatus = focusStatus
    }
}

open class INShareFocusStatusIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INShareFocusStatusIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INShareFocusStatusIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INShortcutReference: NSObject, @unchecked Sendable {
    open var intent: INIntent? = nil
    open var userActivity: NSUserActivity? = nil
    public required override init() { super.init() }
    public convenience init?(intent: INIntent) {
        self.init()
        self.intent = intent
    }
    public convenience init(userActivity: NSUserActivity) {
        self.init()
        self.userActivity = userActivity
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INSnoozeTasksIntent: INIntent, @unchecked Sendable {
    open var nextTriggerTime: INDateComponentsRange? = nil
    open var tasks: [INTask]? = nil
    public required override init() { super.init() }
}

open class INSnoozeTasksIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INSnoozeTasksIntentResponseCode?
    open var snoozedTasks: [INTask]? = nil
    public required override init() { super.init() }
    public convenience init(code: INSnoozeTasksIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INSnoozeTasksTaskResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INSnoozeTasksTaskUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(taskResolutionResult: INTaskResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INSpatialEventTrigger: NSObject, @unchecked Sendable {
    open var event: INSpatialEvent?
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INSpatialEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with spatialEventTriggerToConfirm: INSpatialEventTrigger?) -> Self { self.init(outcome: .confirmationRequired, value: spatialEventTriggerToConfirm) }
    open class func disambiguation(with spatialEventTriggersToDisambiguate: [INSpatialEventTrigger]) -> Self { self.init(outcome: .disambiguation, value: spatialEventTriggersToDisambiguate) }
    open class func success(with resolvedSpatialEventTrigger: INSpatialEventTrigger) -> Self { self.init(outcome: .success, value: resolvedSpatialEventTrigger) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INSpeakableStringResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with stringToConfirm: INSpeakableString?) -> Self { self.init(outcome: .confirmationRequired, value: stringToConfirm) }
    open class func disambiguation(with stringsToDisambiguate: [INSpeakableString]) -> Self { self.init(outcome: .disambiguation, value: stringsToDisambiguate) }
    open class func success(with resolvedString: INSpeakableString) -> Self { self.init(outcome: .success, value: resolvedString) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INSpeedResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with speedToConfirm: Measurement<UnitSpeed>?) -> Self { self.init(outcome: .confirmationRequired, value: speedToConfirm) }
    open class func disambiguation(with speedToDisambiguate: [Measurement<UnitSpeed>]) -> Self { self.init(outcome: .disambiguation, value: speedToDisambiguate) }
    open class func success(with resolvedSpeed: Measurement<UnitSpeed>) -> Self { self.init(outcome: .success, value: resolvedSpeed) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INStartAudioCallIntent: INIntent, @unchecked Sendable {
    open var contacts: [INPerson]? = nil
    open var destinationType: INCallDestinationType?
    public required override init() { super.init() }
    public convenience init(contacts: [INPerson]?) {
        self.init()
        self.contacts = contacts
    }
    public convenience init(destinationType: INCallDestinationType, contacts: [INPerson]?) {
        self.init()
        self.destinationType = destinationType
        self.contacts = contacts
    }
}

open class INStartAudioCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartAudioCallIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INStartAudioCallIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INStartCallCallCapabilityResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INStartCallCallCapabilityUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(callCapabilityResolutionResult: INCallCapabilityResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INStartCallCallRecordToCallBackResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INStartCallCallRecordToCallBackUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(callRecordResolutionResult: INCallRecordResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INStartCallContactResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func unsupported(forReason reason: INStartCallContactUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(personResolutionResult: INPersonResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INStartCallIntent: INIntent, @unchecked Sendable {
    open var audioRoute: INCallAudioRoute = .unknown
    open var callCapability: INCallCapability = .unknown
    open var callRecordFilter: INCallRecordFilter? = nil
    open var callRecordToCallBack: INCallRecord? = nil
    open var contacts: [INPerson]? = nil
    open var destinationType: INCallDestinationType = .unknown
    open var recordTypeForRedialing: INCallRecordType = .unknown
    public required override init() { super.init() }
    public convenience init(audioRoute: INCallAudioRoute, destinationType: INCallDestinationType, contacts: [INPerson]?, recordTypeForRedialing: INCallRecordType, callCapability: INCallCapability) {
        self.init()
        self.audioRoute = audioRoute
        self.destinationType = destinationType
        self.contacts = contacts
        self.recordTypeForRedialing = recordTypeForRedialing
        self.callCapability = callCapability
    }
    public convenience init(callRecordFilter: INCallRecordFilter?, callRecordToCallBack: INCallRecord?, audioRoute: INCallAudioRoute, destinationType: INCallDestinationType, contacts: [INPerson]?, callCapability: INCallCapability) {
        self.init()
        self.callRecordFilter = callRecordFilter
        self.callRecordToCallBack = callRecordToCallBack
        self.audioRoute = audioRoute
        self.destinationType = destinationType
        self.contacts = contacts
        self.callCapability = callCapability
    }
}


open class INStartCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartCallIntentResponseCode = .unspecified
    public required override init() { super.init() }
    public convenience init(code: INStartCallIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
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
    public required override init() { super.init() }
}

open class INStartPhotoPlaybackIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartPhotoPlaybackIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INStartPhotoPlaybackIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INStartVideoCallIntent: INIntent, @unchecked Sendable {
    open var contacts: [INPerson]? = nil
    public required override init() { super.init() }
    public convenience init(contacts: [INPerson]?) {
        self.init()
        self.contacts = contacts
    }
}

open class INStartVideoCallIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartVideoCallIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INStartVideoCallIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INStartWorkoutIntent: INIntent, @unchecked Sendable {
    open var workoutGoalUnitType: INWorkoutGoalUnitType?
    open var workoutLocationType: INWorkoutLocationType?
    open var workoutName: INSpeakableString? = nil
    public required override init() { super.init() }
}

open class INStartWorkoutIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INStartWorkoutIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INStartWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
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
    public required override init() { super.init() }
    public convenience init(type: INSticker.StickerType, emoji: String?) {
        self.init()
        self.type = type
        self.emoji = emoji
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
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
    public required override init() { super.init() }
    public convenience init(title: INSpeakableString, status: INTaskStatus, taskType: INTaskType, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?) {
        self.init()
        self.title = title
        self.status = status
        self.taskType = taskType
        self.spatialEventTrigger = spatialEventTrigger
        self.temporalEventTrigger = temporalEventTrigger
        self.createdDateComponents = createdDateComponents
        self.modifiedDateComponents = modifiedDateComponents
        self.identifier = identifier
    }
    public convenience init(title: INSpeakableString, status: INTaskStatus, taskType: INTaskType, spatialEventTrigger: INSpatialEventTrigger?, temporalEventTrigger: INTemporalEventTrigger?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?, priority: INTaskPriority) {
        self.init()
        self.title = title
        self.status = status
        self.taskType = taskType
        self.spatialEventTrigger = spatialEventTrigger
        self.temporalEventTrigger = temporalEventTrigger
        self.createdDateComponents = createdDateComponents
        self.modifiedDateComponents = modifiedDateComponents
        self.identifier = identifier
        self.priority = priority
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INTaskList: NSObject, @unchecked Sendable {
    open var createdDateComponents: DateComponents? = nil
    open var groupName: INSpeakableString? = nil
    open var identifier: String? = nil
    open var modifiedDateComponents: DateComponents? = nil
    open var tasks: [INTask] = []
    open var title: INSpeakableString?
    public required override init() { super.init() }
    public convenience init(title: INSpeakableString, tasks: [INTask], groupName: INSpeakableString?, createdDateComponents: DateComponents?, modifiedDateComponents: DateComponents?, identifier: String?) {
        self.init()
        self.title = title
        self.tasks = tasks
        self.groupName = groupName
        self.createdDateComponents = createdDateComponents
        self.modifiedDateComponents = modifiedDateComponents
        self.identifier = identifier
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INTaskListResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskListToConfirm: INTaskList?) -> Self { self.init(outcome: .confirmationRequired, value: taskListToConfirm) }
    open class func disambiguation(with taskListsToDisambiguate: [INTaskList]) -> Self { self.init(outcome: .disambiguation, value: taskListsToDisambiguate) }
    open class func success(with resolvedTaskList: INTaskList) -> Self { self.init(outcome: .success, value: resolvedTaskList) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTaskPriorityResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskPriorityToConfirm: INTaskPriority) -> Self { self.init(outcome: .confirmationRequired, value: taskPriorityToConfirm) }
    open class func success(with resolvedTaskPriority: INTaskPriority) -> Self { self.init(outcome: .success, value: resolvedTaskPriority) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTaskResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskToConfirm: INTask?) -> Self { self.init(outcome: .confirmationRequired, value: taskToConfirm) }
    open class func disambiguation(with tasksToDisambiguate: [INTask]) -> Self { self.init(outcome: .disambiguation, value: tasksToDisambiguate) }
    open class func success(with resolvedTask: INTask) -> Self { self.init(outcome: .success, value: resolvedTask) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTaskStatusResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with taskStatusToConfirm: INTaskStatus) -> Self { self.init(outcome: .confirmationRequired, value: taskStatusToConfirm) }
    open class func success(with resolvedTaskStatus: INTaskStatus) -> Self { self.init(outcome: .success, value: resolvedTaskStatus) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTemperatureResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with temperatureToConfirm: Measurement<UnitTemperature>?) -> Self { self.init(outcome: .confirmationRequired, value: temperatureToConfirm) }
    open class func disambiguation(with temperaturesToDisambiguate: [Measurement<UnitTemperature>]) -> Self { self.init(outcome: .disambiguation, value: temperaturesToDisambiguate) }
    open class func success(with resolvedTemperature: Measurement<UnitTemperature>) -> Self { self.init(outcome: .success, value: resolvedTemperature) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTemporalEventTrigger: NSObject, @unchecked Sendable {
    open var dateComponentsRange: INDateComponentsRange?
    public required override init() { super.init() }
    public convenience init(dateComponentsRange: INDateComponentsRange) {
        self.init()
        self.dateComponentsRange = dateComponentsRange
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INTemporalEventTriggerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with temporalEventTriggerToConfirm: INTemporalEventTrigger?) -> Self { self.init(outcome: .confirmationRequired, value: temporalEventTriggerToConfirm) }
    open class func disambiguation(with temporalEventTriggersToDisambiguate: [INTemporalEventTrigger]) -> Self { self.init(outcome: .disambiguation, value: temporalEventTriggersToDisambiguate) }
    open class func success(with resolvedTemporalEventTrigger: INTemporalEventTrigger) -> Self { self.init(outcome: .success, value: resolvedTemporalEventTrigger) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTemporalEventTriggerTypeOptionsResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with temporalEventTriggerTypeOptionsToConfirm: INTemporalEventTriggerTypeOptions = []) -> Self { self.init(outcome: .confirmationRequired, value: temporalEventTriggerTypeOptionsToConfirm) }
    open class func success(with resolvedTemporalEventTriggerTypeOptions: INTemporalEventTriggerTypeOptions = []) -> Self { self.init(outcome: .success, value: resolvedTemporalEventTriggerTypeOptions) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTermsAndConditions: NSObject, @unchecked Sendable {
    open var localizedTermsAndConditionsText: String = ""
    open var privacyPolicyURL: URL? = nil
    open var termsAndConditionsURL: URL? = nil
    public required override init() { super.init() }
    public convenience init(localizedTermsAndConditionsText: String, privacyPolicyURL: URL?, termsAndConditionsURL: URL?) {
        self.init()
        self.localizedTermsAndConditionsText = localizedTermsAndConditionsText
        self.privacyPolicyURL = privacyPolicyURL
        self.termsAndConditionsURL = termsAndConditionsURL
    }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INTextNoteContent: NSObject, @unchecked Sendable {
    open var text: String? = nil
    public required override init() { super.init() }
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
}

open class INTicketedEvent: NSObject, @unchecked Sendable {
    open var category: INTicketedEventCategory?
    open var eventDuration: INDateComponentsRange?
    open var name: String = ""
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INTicketedEventReservation: NSObject, @unchecked Sendable {
    open var event: INTicketedEvent?
    open var reservedSeat: INSeat? = nil
    public required override init() { super.init() }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, event: INTicketedEvent) {
        self.init()
        self.reservedSeat = reservedSeat
        self.event = event
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, event: INTicketedEvent) {
        self.init()
        self.reservedSeat = reservedSeat
        self.event = event
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, reservedSeat: INSeat?, event: INTicketedEvent) {
        self.init()
        self.reservedSeat = reservedSeat
        self.event = event
    }
}

open class INTimeIntervalResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with timeIntervalToConfirm: TimeInterval) -> Self { self.init(outcome: .confirmationRequired, value: timeIntervalToConfirm) }
    open class func success(with resolvedTimeInterval: TimeInterval) -> Self { self.init(outcome: .success, value: resolvedTimeInterval) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INTrainReservation: NSObject, @unchecked Sendable {
    open var reservedSeat: INSeat? = nil
    open var trainTrip: INTrainTrip?
    public required override init() { super.init() }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, url URL: URL?, reservedSeat: INSeat?, trainTrip: INTrainTrip) {
        self.init()
        self.reservedSeat = reservedSeat
        self.trainTrip = trainTrip
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, URL: URL?, reservedSeat: INSeat?, trainTrip: INTrainTrip) {
        self.init()
        self.reservedSeat = reservedSeat
        self.trainTrip = trainTrip
    }
    public convenience init(itemReference: INSpeakableString, reservationNumber: String?, bookingTime: Date?, reservationStatus: INReservationStatus, reservationHolderName: String?, actions: [INReservationAction]?, reservedSeat: INSeat?, trainTrip: INTrainTrip) {
        self.init()
        self.reservedSeat = reservedSeat
        self.trainTrip = trainTrip
    }
}

open class INTrainTrip: NSObject, @unchecked Sendable {
    open var arrivalPlatform: String? = nil
    open var departurePlatform: String? = nil
    open var provider: String? = nil
    open var trainName: String? = nil
    open var trainNumber: String? = nil
    open var tripDuration: INDateComponentsRange?
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INTransferMoneyIntent: INIntent, @unchecked Sendable {
    open var fromAccount: INPaymentAccount? = nil
    open var toAccount: INPaymentAccount? = nil
    open var transactionAmount: INPaymentAmount? = nil
    open var transactionNote: String? = nil
    open var transactionScheduledDate: INDateComponentsRange? = nil
    public required override init() { super.init() }
    public convenience init(from fromAccount: INPaymentAccount?, to toAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?) {
        self.init()
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.transactionAmount = transactionAmount
        self.transactionScheduledDate = transactionScheduledDate
        self.transactionNote = transactionNote
    }
    public convenience init(fromAccount: INPaymentAccount?, toAccount: INPaymentAccount?, transactionAmount: INPaymentAmount?, transactionScheduledDate: INDateComponentsRange?, transactionNote: String?) {
        self.init()
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.transactionAmount = transactionAmount
        self.transactionScheduledDate = transactionScheduledDate
        self.transactionNote = transactionNote
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
    public required override init() { super.init() }
    public convenience init(code: INTransferMoneyIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INURLResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with urlToConfirm: URL?) -> Self { self.init(outcome: .confirmationRequired, value: urlToConfirm) }
    open class func disambiguation(with urlsToDisambiguate: [URL]) -> Self { self.init(outcome: .disambiguation, value: urlsToDisambiguate) }
    open class func success(with resolvedURL: URL) -> Self { self.init(outcome: .success, value: resolvedURL) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INUnsendMessagesIntent: INIntent, @unchecked Sendable {
    open var messageIdentifiers: [String]? = nil
    public required override init() { super.init() }
    public convenience init(messageIdentifiers: [String]?) {
        self.init()
        self.messageIdentifiers = messageIdentifiers
    }
}

open class INUnsendMessagesIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INUnsendMessagesIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INUnsendMessagesIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INUpcomingMediaManager: NSObject, @unchecked Sendable {
    public static var shared: INUpcomingMediaManager { fatalError("Intents.INUpcomingMediaManager.shared is unavailable on this Linux host") }
    open func setPredictionMode(_ mode: INUpcomingMediaPredictionMode, for type: INMediaItemType) { }
    open func setSuggestedMediaIntents(_ intents: NSOrderedSet) { }
    public required override init() { super.init() }
}

open class INUpdateMediaAffinityIntent: INIntent, @unchecked Sendable {
    open var affinityType: INMediaAffinityType?
    open var mediaItems: [INMediaItem]? = nil
    open var mediaSearch: INMediaSearch? = nil
    public required override init() { super.init() }
    public convenience init(mediaItems: [INMediaItem]?, mediaSearch: INMediaSearch?, affinityType: INMediaAffinityType) {
        self.init()
        self.mediaItems = mediaItems
        self.mediaSearch = mediaSearch
        self.affinityType = affinityType
    }
}

open class INUpdateMediaAffinityIntentResponse: INIntentResponse, @unchecked Sendable {
    open var code: INUpdateMediaAffinityIntentResponseCode?
    public required override init() { super.init() }
    public convenience init(code: INUpdateMediaAffinityIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

open class INUpdateMediaAffinityMediaItemResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func successes(with resolvedMediaItems: [INMediaItem]) -> [INUpdateMediaAffinityMediaItemResolutionResult] { resolvedMediaItems.map { self.init(outcome: .success, value: $0) } }
    open class func unsupported(forReason reason: INUpdateMediaAffinityMediaItemUnsupportedReason) -> Self { self.init(outcome: .unsupported, value: reason) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
    public convenience init(mediaItemResolutionResult: INMediaItemResolutionResult) {
        self.init(outcome: .needsValue, value: nil)
    }
}

open class INUserContext: NSObject, @unchecked Sendable {
    open func becomeCurrent() { }
    public required override init() { super.init() }
    public required convenience init?(coder: NSCoder) {
        self.init()
        inLinuxApplyCoder(self, coder)
    }
}

open class INVisualCodeTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with visualCodeTypeToConfirm: INVisualCodeType) -> Self { self.init(outcome: .confirmationRequired, value: visualCodeTypeToConfirm) }
    open class func success(with resolvedVisualCodeType: INVisualCodeType) -> Self { self.init(outcome: .success, value: resolvedVisualCodeType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INVocabulary: NSObject, @unchecked Sendable {
    private static let sharedInstance = INVocabulary()
    private static let store = Mutex<[INVocabularyStringType: [String]]>([:])

    open class func shared() -> Self {
        unsafeDowncast(sharedInstance, to: Self.self)
    }

    open func removeAllVocabularyStrings() {
        Self.store.withLock { $0.removeAll(keepingCapacity: false) }
    }

    open func setVocabulary(_ vocabulary: NSOrderedSet, of type: INVocabularyStringType) {
        setVocabularyStrings(vocabulary, of: type)
    }

    open func setVocabularyStrings(_ vocabulary: NSOrderedSet, of type: INVocabularyStringType) {
        let values = vocabulary.array.compactMap { $0 as? String }
        Self.store.withLock { $0[type] = values }
    }

    @_spi(OpenIntentsHost)
    public func strings(of type: INVocabularyStringType) -> [String] {
        Self.store.withLock { $0[type] ?? [] }
    }

    public required override init() { super.init() }
}

open class INVolumeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with volumeToConfirm: Measurement<UnitVolume>?) -> Self { self.init(outcome: .confirmationRequired, value: volumeToConfirm) }
    open class func disambiguation(with volumeToDisambiguate: [Measurement<UnitVolume>]) -> Self { self.init(outcome: .disambiguation, value: volumeToDisambiguate) }
    open class func success(with resolvedVolume: Measurement<UnitVolume>) -> Self { self.init(outcome: .success, value: resolvedVolume) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INWorkoutGoalUnitTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with workoutGoalUnitTypeToConfirm: INWorkoutGoalUnitType) -> Self { self.init(outcome: .confirmationRequired, value: workoutGoalUnitTypeToConfirm) }
    open class func success(with resolvedWorkoutGoalUnitType: INWorkoutGoalUnitType) -> Self { self.init(outcome: .success, value: resolvedWorkoutGoalUnitType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}

open class INWorkoutLocationTypeResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func confirmationRequired(with workoutLocationTypeToConfirm: INWorkoutLocationType) -> Self { self.init(outcome: .confirmationRequired, value: workoutLocationTypeToConfirm) }
    open class func success(with resolvedWorkoutLocationType: INWorkoutLocationType) -> Self { self.init(outcome: .success, value: resolvedWorkoutLocationType) }
    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        super.init(outcome: outcome, value: value)
    }
}
