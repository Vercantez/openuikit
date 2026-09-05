// Linux NSSecureCoding overlays for generated Intents value types.
// Archive keys are OpenUIKit identifiers, not Apple's keyed-archive layout.

func inLinuxEncodeStrings(_ coder: NSCoder, _ pairs: [(String, String?)]) {
    coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    for (key, value) in pairs {
        if let value {
            coder.encode(value as NSString, forKey: key)
        }
    }
}

func inLinuxApplyCoder(_ object: NSObject, _ coder: NSCoder) {
    if let value = object as? INAirline {
        value.name = inDecodeString(coder, "name")
        value.iataCode = inDecodeString(coder, "iataCode")
        value.icaoCode = inDecodeString(coder, "icaoCode")
        return
    }
    if let value = object as? INAirport {
        value.name = inDecodeString(coder, "name")
        value.iataCode = inDecodeString(coder, "iataCode")
        value.icaoCode = inDecodeString(coder, "icaoCode")
        return
    }
    if let value = object as? INAirportGate {
        value.gate = inDecodeString(coder, "gate")
        value.terminal = inDecodeString(coder, "terminal")
        return
    }
    if let value = object as? INBillPayee {
        value.accountNumber = inDecodeString(coder, "accountNumber")
        return
    }
    if let value = object as? INCallGroup {
        value.groupId = inDecodeString(coder, "groupId")
        value.groupName = inDecodeString(coder, "groupName")
        return
    }
    if let value = object as? INCar {
        value.make = inDecodeString(coder, "make")
        value.model = inDecodeString(coder, "model")
        value.year = inDecodeString(coder, "year")
        if let decoded = inDecodeString(coder, "carIdentifier") { value.carIdentifier = decoded }
        value.displayName = inDecodeString(coder, "displayName")
        return
    }
    if let value = object as? INCarHeadUnit {
        value.bluetoothIdentifier = inDecodeString(coder, "bluetoothIdentifier")
        value.iAP2Identifier = inDecodeString(coder, "iAP2Identifier")
        return
    }
    if let value = object as? INCurrencyAmount {
        value.currencyCode = inDecodeString(coder, "currencyCode")
        return
    }
    if let value = object as? INDefaultCardTemplate {
        if let decoded = inDecodeString(coder, "title") { value.title = decoded }
        value.subtitle = inDecodeString(coder, "subtitle")
        return
    }
    if let value = object as? INFile {
        if let decoded = inDecodeString(coder, "filename") { value.filename = decoded }
        value.typeIdentifier = inDecodeString(coder, "typeIdentifier")
        if let data = inDecodeData(coder, "data") { value.data = data }
        return
    }
    if let value = object as? INFlight {
        if let decoded = inDecodeString(coder, "flightNumber") { value.flightNumber = decoded }
        return
    }
    if let value = object as? INMessage {
        if let decoded = inDecodeString(coder, "identifier") { value.identifier = decoded }
        value.content = inDecodeString(coder, "content")
        value.conversationIdentifier = inDecodeString(coder, "conversationIdentifier")
        value.serviceName = inDecodeString(coder, "serviceName")
        return
    }
    if let value = object as? INMessageLinkMetadata {
        value.siteName = inDecodeString(coder, "siteName")
        value.summary = inDecodeString(coder, "summary")
        value.title = inDecodeString(coder, "title")
        value.openGraphType = inDecodeString(coder, "openGraphType")
        return
    }
    if let value = object as? INMessageReaction {
        value.emoji = inDecodeString(coder, "emoji")
        value.reactionDescription = inDecodeString(coder, "reactionDescription")
        return
    }
    if let value = object as? INPaymentMethod {
        value.name = inDecodeString(coder, "name")
        value.identificationHint = inDecodeString(coder, "identificationHint")
        return
    }
    if let value = object as? INRentalCar {
        value.make = inDecodeString(coder, "make")
        value.model = inDecodeString(coder, "model")
        value.rentalCarDescription = inDecodeString(coder, "rentalCarDescription")
        if let decoded = inDecodeString(coder, "rentalCompanyName") { value.rentalCompanyName = decoded }
        value.type = inDecodeString(coder, "type")
        return
    }
    if let value = object as? INReservation {
        value.reservationHolderName = inDecodeString(coder, "reservationHolderName")
        value.reservationNumber = inDecodeString(coder, "reservationNumber")
        return
    }
    if let value = object as? INRestaurant {
        if let decoded = inDecodeString(coder, "name") { value.name = decoded }
        if let decoded = inDecodeString(coder, "restaurantIdentifier") { value.restaurantIdentifier = decoded }
        if let decoded = inDecodeString(coder, "vendorIdentifier") { value.vendorIdentifier = decoded }
        return
    }
    if let value = object as? INRestaurantOffer {
        if let decoded = inDecodeString(coder, "offerDetailText") { value.offerDetailText = decoded }
        if let decoded = inDecodeString(coder, "offerIdentifier") { value.offerIdentifier = decoded }
        if let decoded = inDecodeString(coder, "offerTitleText") { value.offerTitleText = decoded }
        return
    }
    if let value = object as? INRideCompletionStatus {
        if coder.containsValue(forKey: "isCanceled") { value.isCanceled = coder.decodeBool(forKey: "isCanceled") }
        if coder.containsValue(forKey: "isCompleted") { value.isCompleted = coder.decodeBool(forKey: "isCompleted") }
        if coder.containsValue(forKey: "isMissedPickup") { value.isMissedPickup = coder.decodeBool(forKey: "isMissedPickup") }
        return
    }
    if let value = object as? INRideOption {
        if let decoded = inDecodeString(coder, "name") { value.name = decoded }
        return
    }
    if let value = object as? INRidePartySizeOption {
        if let decoded = inDecodeString(coder, "sizeDescription") { value.sizeDescription = decoded }
        return
    }
    if let value = object as? INRideStatus {
        value.rideIdentifier = inDecodeString(coder, "rideIdentifier")
        return
    }
    if let value = object as? INRideVehicle {
        value.manufacturer = inDecodeString(coder, "manufacturer")
        value.model = inDecodeString(coder, "model")
        value.registrationPlate = inDecodeString(coder, "registrationPlate")
        return
    }
    if let value = object as? INSeat {
        value.seatNumber = inDecodeString(coder, "seatNumber")
        value.seatRow = inDecodeString(coder, "seatRow")
        value.seatSection = inDecodeString(coder, "seatSection")
        value.seatingType = inDecodeString(coder, "seatingType")
        return
    }
    if let value = object as? INSticker {
        value.emoji = inDecodeString(coder, "emoji")
        return
    }
    if let value = object as? INTermsAndConditions {
        if let decoded = inDecodeString(coder, "localizedTermsAndConditionsText") {
            value.localizedTermsAndConditionsText = decoded
        }
        return
    }
    if let value = object as? INTrainTrip {
        value.trainNumber = inDecodeString(coder, "trainNumber")
        return
    }
    if let value = object as? INDateComponentsRange {
        if coder.containsValue(forKey: "startYear") {
            var start = DateComponents()
            start.year = Int(coder.decodeInt64(forKey: "startYear"))
            value.startDateComponents = start
        }
        if coder.containsValue(forKey: "endYear") {
            var end = DateComponents()
            end.year = Int(coder.decodeInt64(forKey: "endYear"))
            value.endDateComponents = end
        }
        return
    }
    if let value = object as? INRestaurantReservationBooking {
        value.bookingDescription = inDecodeString(coder, "bookingDescription")
        return
    }
}

extension INAirline: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("name", name), ("iataCode", iataCode), ("icaoCode", icaoCode)])
    }
}

extension INAirport: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("name", name), ("iataCode", iataCode), ("icaoCode", icaoCode)])
    }
}

extension INAirportGate: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("gate", gate), ("terminal", terminal)])
    }
}

extension INBalanceAmount: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INBillDetails: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INBillPayee: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("accountNumber", accountNumber)])
    }
}

extension INBoatTrip: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INBusTrip: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INCallGroup: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("groupId", groupId), ("groupName", groupName)])
    }
}

extension INCallRecord: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("identifier", identifier)])
        coder.encode(Int64(callRecordType.rawValue), forKey: "callRecordType")
        coder.encode(Int64(callCapability.rawValue), forKey: "callCapability")
    }
}

extension INCallRecordFilter: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(Int64(callCapability.rawValue), forKey: "callCapability")
    }
}

extension INCar: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("carIdentifier", carIdentifier),
            ("displayName", displayName),
            ("make", make),
            ("model", model),
            ("year", year),
        ])
    }
}

extension INCarHeadUnit: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("bluetoothIdentifier", bluetoothIdentifier),
            ("iAP2Identifier", iAP2Identifier),
        ])
    }
}

extension INCurrencyAmount: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("currencyCode", currencyCode)])
    }
}

extension INDateComponentsRange: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        if let start = startDateComponents?.year {
            coder.encode(Int64(start), forKey: "startYear")
        }
        if let end = endDateComponents?.year {
            coder.encode(Int64(end), forKey: "endYear")
        }
    }
}

extension INDefaultCardTemplate: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("title", title), ("subtitle", subtitle)])
    }
}

extension INFile: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("filename", filename), ("typeIdentifier", typeIdentifier)])
        coder.encode(data as NSData?, forKey: "data")
    }
}

extension INFlight: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("flightNumber", flightNumber)])
    }
}

extension INIntentDonationMetadata: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INMessage: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("identifier", identifier),
            ("content", content),
            ("conversationIdentifier", conversationIdentifier),
            ("serviceName", serviceName),
        ])
    }
}

extension INMessageLinkMetadata: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("siteName", siteName),
            ("summary", summary),
            ("title", title),
            ("openGraphType", openGraphType),
        ])
    }
}

extension INMessageReaction: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("emoji", emoji), ("reactionDescription", reactionDescription)])
    }
}

extension INNote: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INNoteContent: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INParameter: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("parameterKeyPath", parameterKeyPath)])
    }
}

extension INPaymentAccount: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INPaymentAmount: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INPaymentMethod: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("name", name), ("identificationHint", identificationHint)])
    }
}

extension INPaymentRecord: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INPriceRange: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INRecurrenceRule: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INRelevanceProvider: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INRelevantShortcut: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(shortcut, forKey: "shortcut")
        inLinuxEncodeStrings(coder, [("widgetKind", widgetKind)])
    }
}

extension INRentalCar: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("make", make),
            ("model", model),
            ("rentalCarDescription", rentalCarDescription),
            ("rentalCompanyName", rentalCompanyName),
            ("type", type),
        ])
    }
}

extension INReservation: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("reservationHolderName", reservationHolderName),
            ("reservationNumber", reservationNumber),
        ])
    }
}

extension INReservationAction: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INRestaurant: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("name", name),
            ("restaurantIdentifier", restaurantIdentifier),
            ("vendorIdentifier", vendorIdentifier),
        ])
    }
}

extension INRestaurantGuestDisplayPreferences: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INRestaurantOffer: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("offerDetailText", offerDetailText),
            ("offerIdentifier", offerIdentifier),
            ("offerTitleText", offerTitleText),
        ])
    }
}

extension INRestaurantReservationBooking: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(bookingDescription as NSString?, forKey: "bookingDescription")
    }
}

extension INRideOption: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("name", name)])
    }
}

extension INRideCompletionStatus: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
        coder.encode(isCanceled, forKey: "isCanceled")
        coder.encode(isCompleted, forKey: "isCompleted")
        coder.encode(isMissedPickup, forKey: "isMissedPickup")
    }
}

extension INRideFareLineItem: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INRidePartySizeOption: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("sizeDescription", sizeDescription)])
    }
}

extension INRideStatus: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("rideIdentifier", rideIdentifier)])
    }
}

extension INRideVehicle: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("manufacturer", manufacturer),
            ("model", model),
            ("registrationPlate", registrationPlate),
        ])
    }
}

extension INSeat: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [
            ("seatNumber", seatNumber),
            ("seatRow", seatRow),
            ("seatSection", seatSection),
            ("seatingType", seatingType),
        ])
    }
}

extension INSpatialEventTrigger: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INSticker: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("emoji", emoji)])
    }
}

extension INTask: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INTaskList: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INTemporalEventTrigger: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INTermsAndConditions: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("localizedTermsAndConditionsText", localizedTermsAndConditionsText)])
    }
}

extension INTicketedEvent: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}

extension INTrainTrip: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        inLinuxEncodeStrings(coder, [("trainNumber", trainNumber)])
    }
}

extension INUserContext: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public func encode(with coder: NSCoder) {
        coder.encode(INPortableArchive.version, forKey: INPortableArchive.versionKey)
    }
}
