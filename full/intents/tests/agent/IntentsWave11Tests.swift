import Foundation
@_spi(OpenIntentsHost) import Intents

private func wave11ArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
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

private func wave11Person(_ name: String = "Ada") -> INPerson {
    INPerson(
        personHandle: INPersonHandle(value: "ada@example.com", type: .emailAddress),
        nameComponents: nil,
        displayName: name,
        image: nil,
        contactIdentifier: "c-ada",
        customIdentifier: "custom-ada"
    )
}

private func wave11Range(startYear: Int = 2026, endYear: Int = 2026) -> INDateComponentsRange {
    var start = DateComponents()
    start.year = startYear
    start.month = 4
    var end = DateComponents()
    end.year = endYear
    end.month = 5
    return INDateComponentsRange(start: start, end: end)
}

func testBusTripPropertiesAndCoding() {
    let duration = wave11Range()
    let trip = INBusTrip(
        provider: "Open Transit",
        busName: "Coastal",
        busNumber: "42",
        tripDuration: duration,
        departurePlatform: "A1",
        arrivalPlatform: "B4"
    )
    precondition(trip.provider == "Open Transit")
    precondition(trip.busName == "Coastal")
    precondition(trip.busNumber == "42")
    precondition(trip.departurePlatform == "A1")
    precondition(trip.arrivalPlatform == "B4")
    precondition(trip.tripDuration?.startDateComponents?.year == 2026)
    let restored = wave11ArchiveRoundTrip(trip)
    precondition(restored.provider == "Open Transit")
    precondition(restored.busName == "Coastal")
    precondition(restored.busNumber == "42")
    precondition(restored.departurePlatform == "A1")
    precondition(restored.arrivalPlatform == "B4")
    precondition(INBusTrip.supportsSecureCoding)
}

func testTrainTripPropertiesAndCoding() {
    let duration = wave11Range()
    let trip = INTrainTrip(
        provider: "Open Rail",
        trainName: "Express",
        trainNumber: "ICE-9",
        tripDuration: duration,
        departurePlatform: "3",
        arrivalPlatform: "7"
    )
    precondition(trip.provider == "Open Rail")
    precondition(trip.trainName == "Express")
    precondition(trip.trainNumber == "ICE-9")
    precondition(trip.departurePlatform == "3")
    precondition(trip.arrivalPlatform == "7")
    precondition(trip.tripDuration?.endDateComponents?.year == 2026)
    let restored = wave11ArchiveRoundTrip(trip)
    precondition(restored.provider == "Open Rail")
    precondition(restored.trainName == "Express")
    precondition(restored.trainNumber == "ICE-9")
    precondition(restored.departurePlatform == "3")
    precondition(restored.arrivalPlatform == "7")
}

func testBoatTripPropertiesAndCoding() {
    let trip = INBoatTrip(
        provider: "Harbor Line",
        boatName: "Commuter",
        boatNumber: "F-12",
        tripDuration: wave11Range()
    )
    precondition(trip.provider == "Harbor Line")
    precondition(trip.boatName == "Commuter")
    precondition(trip.boatNumber == "F-12")
    precondition(trip.tripDuration?.startDateComponents?.month == 4)
    let restored = wave11ArchiveRoundTrip(trip)
    precondition(restored.provider == "Harbor Line")
    precondition(restored.boatName == "Commuter")
    precondition(restored.boatNumber == "F-12")
}

func testFlightPropertiesAndCoding() {
    let airline = INAirline(name: "Open Air", iataCode: "OA", icaoCode: "OPN")
    let origin = INAirport(name: "SFO", iataCode: "SFO", icaoCode: "KSFO")
    let dest = INAirport(name: "JFK", iataCode: "JFK", icaoCode: "KJFK")
    let departure = INAirportGate(airport: origin, terminal: "2", gate: "G12")
    let arrival = INAirportGate(airport: dest, terminal: "4", gate: "B8")
    let boarding = wave11Range(startYear: 2026, endYear: 2026)
    let duration = wave11Range(startYear: 2026, endYear: 2026)
    let flight = INFlight(
        airline: airline,
        flightNumber: "OA-100",
        boardingTime: boarding,
        flightDuration: duration,
        departureAirportGate: departure,
        arrivalAirportGate: arrival
    )
    precondition(flight.airline?.name == "Open Air")
    precondition(flight.flightNumber == "OA-100")
    precondition(flight.boardingTime?.startDateComponents?.year == 2026)
    precondition(flight.flightDuration?.endDateComponents?.year == 2026)
    precondition(flight.departureAirportGate?.gate == "G12")
    precondition(flight.arrivalAirportGate?.terminal == "4")
    let restored = wave11ArchiveRoundTrip(flight)
    precondition(restored.flightNumber == "OA-100")
    precondition(INFlight.supportsSecureCoding)
}

func testReservationActionAndBaseProperties() {
    let duration = wave11Range()
    let activity = NSUserActivity(activityType: "com.openuikit.intents.checkin")
    let action = INReservationAction(type: .checkIn, validDuration: duration, userActivity: activity)
    precondition(action.type == .checkIn)
    precondition(action.validDuration?.startDateComponents?.year == 2026)
    precondition(action.userActivity?.activityType == "com.openuikit.intents.checkin")
    let restoredAction = wave11ArchiveRoundTrip(action)
    precondition(restoredAction.type == .checkIn)
    precondition(INReservationAction.supportsSecureCoding)

    let reservation = INReservation()
    reservation.itemReference = INSpeakableString(spokenPhrase: "item-1")
    reservation.reservationNumber = "R-9"
    reservation.bookingTime = Date(timeIntervalSince1970: 1_700_000_000)
    reservation.reservationStatus = .confirmed
    reservation.reservationHolderName = "Ada"
    reservation.actions = [action]
    reservation.url = URL(string: "https://example.test/r/9")
    precondition(reservation.itemReference?.spokenPhrase == "item-1")
    precondition(reservation.reservationNumber == "R-9")
    precondition(reservation.bookingTime == Date(timeIntervalSince1970: 1_700_000_000))
    precondition(reservation.reservationStatus == .confirmed)
    precondition(reservation.reservationHolderName == "Ada")
    precondition(reservation.actions?.count == 1)
    precondition(reservation.url?.absoluteString == "https://example.test/r/9")
    let restored = wave11ArchiveRoundTrip(reservation)
    precondition(restored.reservationNumber == "R-9")
    precondition(restored.reservationHolderName == "Ada")
}

func testFlightReservationStoresBaseAndSeat() {
    let airline = INAirline(name: "Open Air", iataCode: "OA", icaoCode: "OPN")
    let origin = INAirport(name: "SFO", iataCode: "SFO", icaoCode: "KSFO")
    let dest = INAirport(name: "JFK", iataCode: "JFK", icaoCode: "KJFK")
    let flight = INFlight(
        airline: airline,
        flightNumber: "OA-7",
        boardingTime: nil,
        flightDuration: wave11Range(),
        departureAirportGate: INAirportGate(airport: origin, terminal: "1", gate: "A1"),
        arrivalAirportGate: INAirportGate(airport: dest, terminal: "2", gate: "C3")
    )
    let seat = INSeat(seatSection: "Cabin", seatRow: "12", seatNumber: "A", seatingType: "window")
    let booking = Date(timeIntervalSince1970: 1_710_000_000)
    let reservation = INFlightReservation(
        itemReference: INSpeakableString(spokenPhrase: "flight-ref"),
        reservationNumber: "FL-1",
        bookingTime: booking,
        reservationStatus: .confirmed,
        reservationHolderName: "Ada",
        actions: nil,
        url: URL(string: "https://example.test/fl/1"),
        reservedSeat: seat,
        flight: flight
    )
    precondition(reservation.flight?.flightNumber == "OA-7")
    precondition(reservation.reservedSeat?.seatNumber == "A")
    precondition(reservation.itemReference?.spokenPhrase == "flight-ref")
    precondition(reservation.reservationNumber == "FL-1")
    precondition(reservation.bookingTime == booking)
    precondition(reservation.reservationStatus == .confirmed)
    precondition(reservation.reservationHolderName == "Ada")
    precondition(reservation.url?.host == "example.test")
    let restored = wave11ArchiveRoundTrip(reservation)
    precondition(restored.reservationNumber == "FL-1")
}

func testBoatBusTrainAndTicketedReservations() {
    let item = INSpeakableString(spokenPhrase: "trip")
    let booking = Date(timeIntervalSince1970: 1_700_000_100)
    let boatTrip = INBoatTrip(provider: "Harbor", boatName: "Ferry", boatNumber: "1", tripDuration: wave11Range())
    let boat = INBoatReservation(
        itemReference: item,
        reservationNumber: "BOAT-1",
        bookingTime: booking,
        reservationStatus: .pending,
        reservationHolderName: "Ada",
        actions: nil,
        url: URL(string: "https://example.test/boat"),
        reservedSeat: INSeat(seatSection: "Deck", seatRow: "1", seatNumber: "2", seatingType: nil),
        boatTrip: boatTrip
    )
    precondition(boat.boatTrip?.boatName == "Ferry")
    precondition(boat.reservedSeat?.seatSection == "Deck")
    precondition(boat.reservationNumber == "BOAT-1")
    precondition(boat.reservationStatus == .pending)

    let busTrip = INBusTrip(
        provider: "Coach",
        busName: "Night",
        busNumber: "N1",
        tripDuration: wave11Range(),
        departurePlatform: "1",
        arrivalPlatform: "2"
    )
    let bus = INBusReservation(
        itemReference: item,
        reservationNumber: "BUS-1",
        bookingTime: booking,
        reservationStatus: .hold,
        reservationHolderName: "Ada",
        actions: nil,
        URL: URL(string: "https://example.test/bus"),
        reservedSeat: nil,
        busTrip: busTrip
    )
    precondition(bus.busTrip?.busNumber == "N1")
    precondition(bus.reservationNumber == "BUS-1")
    precondition(bus.url?.path == "/bus")

    let trainTrip = INTrainTrip(
        provider: "Rail",
        trainName: "Local",
        trainNumber: "L2",
        tripDuration: wave11Range(),
        departurePlatform: "A",
        arrivalPlatform: "B"
    )
    let train = INTrainReservation(
        itemReference: item,
        reservationNumber: "TR-1",
        bookingTime: booking,
        reservationStatus: .confirmed,
        reservationHolderName: "Ada",
        actions: nil,
        url: nil,
        reservedSeat: INSeat(seatSection: "Car 4", seatRow: "8", seatNumber: "C", seatingType: "aisle"),
        trainTrip: trainTrip
    )
    precondition(train.trainTrip?.trainName == "Local")
    precondition(train.reservedSeat?.seatRow == "8")
    precondition(train.reservationHolderName == "Ada")

    let event = INTicketedEvent(category: .movie, name: "Open Feature", eventDuration: wave11Range())
    precondition(event.category == .movie)
    precondition(event.name == "Open Feature")
    precondition(event.eventDuration?.startDateComponents?.year == 2026)
    let ticketed = INTicketedEventReservation(
        itemReference: item,
        reservationNumber: "EV-1",
        bookingTime: booking,
        reservationStatus: .confirmed,
        reservationHolderName: "Ada",
        actions: nil,
        url: URL(string: "https://example.test/event"),
        reservedSeat: INSeat(seatSection: "Orchestra", seatRow: "C", seatNumber: "14", seatingType: nil),
        event: event
    )
    precondition(ticketed.event?.name == "Open Feature")
    precondition(ticketed.reservedSeat?.seatNumber == "14")
    precondition(ticketed.reservationNumber == "EV-1")
    let restoredEvent = wave11ArchiveRoundTrip(event)
    precondition(restoredEvent.name == "Open Feature")
}

func testRentalCarReservationWithoutPlacemarks() {
    let car = INRentalCar(
        rentalCompanyName: "Open Cars",
        type: "compact",
        make: "Open",
        model: "Kit",
        rentalCarDescription: "A host-safe compact"
    )
    precondition(car.rentalCompanyName == "Open Cars")
    precondition(car.type == "compact")
    precondition(car.make == "Open")
    precondition(car.model == "Kit")
    precondition(car.rentalCarDescription == "A host-safe compact")
    let duration = wave11Range()
    let reservation = INRentalCarReservation(
        itemReference: INSpeakableString(spokenPhrase: "rental"),
        reservationNumber: "RC-3",
        bookingTime: Date(timeIntervalSince1970: 1_700_000_200),
        reservationStatus: .confirmed,
        reservationHolderName: "Ada",
        actions: nil,
        url: URL(string: "https://example.test/rental"),
        rentalCar: car,
        rentalDuration: duration
    )
    precondition(reservation.rentalCar?.make == "Open")
    precondition(reservation.rentalDuration?.startDateComponents?.year == 2026)
    precondition(reservation.reservationNumber == "RC-3")
    precondition(reservation.itemReference?.spokenPhrase == "rental")
    let restoredCar = wave11ArchiveRoundTrip(car)
    precondition(restoredCar.make == "Open")
    precondition(restoredCar.model == "Kit")
    precondition(restoredCar.type == "compact")
    precondition(restoredCar.rentalCarDescription == "A host-safe compact")
}

func testBalanceAmountPropertiesAndCoding() {
    let miles = INBalanceAmount(amount: NSDecimalNumber(value: 1200), balanceType: .miles)
    precondition(miles?.amount?.intValue == 1200)
    precondition(miles?.balanceType == .miles)
    let cash = INBalanceAmount(amount: NSDecimalNumber(value: 42), currencyCode: "USD")
    precondition(cash.amount?.intValue == 42)
    precondition(cash.currencyCode == "USD")
    let restoredMiles = wave11ArchiveRoundTrip(miles!)
    precondition(restoredMiles.balanceType == .miles)
    precondition(restoredMiles.amount?.intValue == 1200)
    let restoredCash = wave11ArchiveRoundTrip(cash)
    precondition(restoredCash.currencyCode == "USD")
}

func testCancelRideIntentResponseCodeFeeAndActivity() {
    let activity = NSUserActivity(activityType: "com.openuikit.intents.cancel-ride")
    let response = INCancelRideIntentResponse(code: .success, userActivity: activity)
    response.cancellationFee = INCurrencyAmount(amount: NSDecimalNumber(value: 5), currencyCode: "USD")
    var threshold = DateComponents()
    threshold.minute = 5
    response.cancellationFeeThreshold = threshold
    precondition(response.code == .success)
    precondition(response.userActivity?.activityType == "com.openuikit.intents.cancel-ride")
    precondition(response.cancellationFee?.amount?.intValue == 5)
    precondition(response.cancellationFee?.currencyCode == "USD")
    precondition(response.cancellationFeeThreshold?.minute == 5)
    let intent = INCancelRideIntent(rideIdentifier: "ride-9")
    precondition(intent.rideIdentifier == "ride-9")
}

func testDateComponentsRangeRecurrenceAndRelevance() {
    var start = DateComponents()
    start.year = 2026
    start.month = 9
    var end = DateComponents()
    end.year = 2026
    end.month = 10
    let rule = INRecurrenceRule(interval: 1, frequency: .weekly)
    let labeled = INDateComponentsRange(start: start, end: end, recurrenceRule: rule)
    precondition(labeled.startDateComponents?.month == 9)
    precondition(labeled.endDateComponents?.month == 10)
    precondition(labeled.recurrenceRule?.frequency == .weekly)
    precondition(labeled.recurrenceRule?.interval == 1)
    let unlabeled = INDateComponentsRange(startDateComponents: start, endDateComponents: end, recurrenceRule: rule)
    precondition(unlabeled.recurrenceRule?.frequency == .weekly)
    let restored = wave11ArchiveRoundTrip(labeled)
    precondition(restored.startDateComponents?.year == 2026)
    precondition(restored.endDateComponents?.year == 2026)

    let begin = Date(timeIntervalSince1970: 1_700_000_000)
    let finish = Date(timeIntervalSince1970: 1_700_086_400)
    let provider = INDateRelevanceProvider(startDate: begin, endDate: finish)
    precondition(provider.startDate == begin)
    precondition(provider.endDate == finish)
    let labeledProvider = INDateRelevanceProvider(start: begin, end: nil)
    precondition(labeledProvider.startDate == begin)
    precondition(labeledProvider.endDate == nil)
}

func testFileURLDataRemovedAndResolution() {
    let bytes = Data([0x49, 0x4e])
    let dataFile = INFile(data: bytes, filename: "note.bin", typeIdentifier: "public.data")
    dataFile.removedOnCompletion = true
    precondition(dataFile.data == bytes)
    precondition(dataFile.filename == "note.bin")
    precondition(dataFile.typeIdentifier == "public.data")
    precondition(dataFile.removedOnCompletion)
    let url = URL(string: "file:///tmp/openuikit-note.bin")!
    let urlFile = INFile.file(withFileURL: url, filename: "note.bin", typeIdentifier: "public.data")
    precondition(urlFile.fileURL == url)
    precondition(urlFile.filename == "note.bin")
    precondition(urlFile.typeIdentifier == "public.data")
    let classData = INFile.file(with: bytes, filename: "from-class.bin", typeIdentifier: "public.data")
    precondition(classData.data == bytes)
    precondition(classData.filename == "from-class.bin")
    let restored = wave11ArchiveRoundTrip(dataFile)
    precondition(restored.filename == "note.bin")
    precondition(restored.typeIdentifier == "public.data")
    precondition(restored.data == bytes)
    precondition(restored.removedOnCompletion)
    let restoredURL = wave11ArchiveRoundTrip(urlFile)
    precondition(restoredURL.fileURL == url)

    let success = INFileResolutionResult.success(with: dataFile)
    precondition(success.outcome == .success)
    let disambiguation = INFileResolutionResult.disambiguation(with: [dataFile, urlFile])
    precondition(disambiguation.outcome == .disambiguation)
    let confirm = INFileResolutionResult.confirmationRequired(with: dataFile)
    precondition(confirm.outcome == .confirmationRequired)
    let needs = INFileResolutionResult.needsValue()
    precondition(needs.outcome == .needsValue)
}

func testSendMessageDonationMetadataAndGroupInit() {
    let metadata = INSendMessageIntentDonationMetadata()
    metadata.mentionsCurrentUser = true
    metadata.notifyRecipientAnyway = true
    metadata.recipientCount = 3
    metadata.isReplyToCurrentUser = true
    precondition(metadata.mentionsCurrentUser)
    precondition(metadata.notifyRecipientAnyway)
    precondition(metadata.recipientCount == 3)
    precondition(metadata.isReplyToCurrentUser)
    let restored = wave11ArchiveRoundTrip(metadata)
    precondition(restored.mentionsCurrentUser)
    precondition(restored.notifyRecipientAnyway)
    precondition(restored.recipientCount == 3)
    precondition(restored.isReplyToCurrentUser)

    let person = wave11Person()
    let grouped = INSendMessageIntent(
        recipients: [person],
        content: "hello",
        groupName: "Team",
        serviceName: "iMessage",
        sender: person
    )
    precondition(grouped.groupName == "Team")
    precondition(grouped.content == "hello")
    let attachment = INSendMessageAttachment(audioMessageFile: INFile(data: Data([0x1]), filename: "a.m4a", typeIdentifier: "public.mpeg-4-audio"))
    let withAttachments = INSendMessageIntent(
        recipients: [person],
        outgoingMessageType: .outgoingMessageText,
        content: "voice",
        speakableGroupName: INSpeakableString(spokenPhrase: "Team"),
        conversationIdentifier: "c-1",
        serviceName: "iMessage",
        sender: person,
        attachments: [attachment]
    )
    precondition(withAttachments.attachments?.count == 1)
    precondition(withAttachments.attachments?.first?.audioMessageFile?.filename == "a.m4a")
}

func testSpeakableStringInitsAndProtocol() {
    let identified = INSpeakableString(identifier: "vocab.ada", spokenPhrase: "Ada", pronunciationHint: "AY-duh")
    precondition(identified.spokenPhrase == "Ada")
    precondition(identified.pronunciationHint == "AY-duh")
    precondition(identified.vocabularyIdentifier == "vocab.ada")
    precondition(identified.identifier == "vocab.ada")
    let vocab = INSpeakableString(vocabularyIdentifier: "vocab.grace", spokenPhrase: "Grace", pronunciationHint: nil)
    precondition(vocab.spokenPhrase == "Grace")
    precondition(vocab.vocabularyIdentifier == "vocab.grace")
    vocab.alternativeSpeakableMatches = [identified]
    let asSpeakable: any INSpeakable = vocab
    precondition(asSpeakable.spokenPhrase == "Grace")
    precondition(asSpeakable.pronunciationHint == nil)
    precondition(asSpeakable.vocabularyIdentifier == "vocab.grace")
    precondition(asSpeakable.identifier == "vocab.grace")
    precondition(asSpeakable.alternativeSpeakableMatches?.first?.spokenPhrase == "Ada")
}

func testPersonHandleLabelCatalog() {
    let labels: [(INPersonHandleLabel, String)] = [
        (.home, "home"),
        (.homeFax, "homeFax"),
        (.main, "main"),
        (.mobile, "mobile"),
        (.other, "other"),
        (.pager, "pager"),
        (.workFax, "workFax"),
        (.iPhone, "iPhone"),
        (.work, "work"),
        (.school, "school"),
    ]
    for (label, raw) in labels {
        precondition(label.rawValue == raw)
        precondition(INPersonHandleLabel(rawValue: raw) == label)
        precondition(INPersonHandleLabel(raw) == label)
        let handle = INPersonHandle(value: "value", type: .phoneNumber, label: label)
        precondition(handle.label == label)
    }
}

func testRideFareLineItemAndCarLockSnoozeOverlays() {
    let fare = INRideFareLineItem(title: "Base", price: NSDecimalNumber(value: 8), currencyCode: "USD")
    precondition(fare.title == "Base")
    precondition(fare.price?.intValue == 8)
    precondition(fare.currencyCode == "USD")
    let restored = wave11ArchiveRoundTrip(fare)
    precondition(restored.title == "Base")
    precondition(restored.currencyCode == "USD")

    let lock = INSetCarLockStatusIntent(locked: true, carName: INSpeakableString(spokenPhrase: "Roadster"))
    precondition(lock.locked == true)
    precondition(lock.carName?.spokenPhrase == "Roadster")

    let task = INTask(
        title: INSpeakableString(spokenPhrase: "Snooze me"),
        status: .notCompleted,
        taskType: .completable,
        spatialEventTrigger: nil,
        temporalEventTrigger: nil,
        createdDateComponents: nil,
        modifiedDateComponents: nil,
        identifier: "t-1"
    )
    let snooze = INSnoozeTasksIntent(tasks: [task], nextTriggerTime: wave11Range(), all: false)
    precondition(snooze.tasks?.first?.identifier == "t-1")
    precondition(snooze.nextTriggerTime?.startDateComponents?.year == 2026)
    precondition(snooze.all == false)

    let save = INSaveProfileInCarIntent(profileNumber: 3, profileLabel: "Ada")
    precondition(save.profileNumber == 3)
    precondition(save.profileLabel == "Ada")

    let lockResponse = INGetCarLockStatusIntentResponse(code: .success, userActivity: nil)
    lockResponse.locked = true
    precondition(lockResponse.code == .success)
    precondition(lockResponse.locked == true)
}

func testNoteRemainingPropertiesAndGuestReservationIntents() {
    var created = DateComponents()
    created.year = 2026
    var modified = DateComponents()
    modified.year = 2026
    modified.month = 9
    let note = INNote(
        title: INSpeakableString(spokenPhrase: "Errands"),
        contents: [INNoteContent()],
        groupName: INSpeakableString(spokenPhrase: "Personal"),
        createdDateComponents: created,
        modifiedDateComponents: modified,
        identifier: "note-11"
    )
    precondition(note.title?.spokenPhrase == "Errands")
    precondition(note.contents.count == 1)
    precondition(note.groupName?.spokenPhrase == "Personal")
    precondition(note.createdDateComponents?.year == 2026)
    precondition(note.modifiedDateComponents?.month == 9)

    let details = INGetReservationDetailsIntent(
        reservationContainerReference: INSpeakableString(spokenPhrase: "container"),
        reservationItemReferences: [INSpeakableString(spokenPhrase: "item")]
    )
    precondition(details.reservationContainerReference?.spokenPhrase == "container")
    precondition(details.reservationItemReferences?.first?.spokenPhrase == "item")
    let detailsResponse = INGetReservationDetailsIntentResponse(code: .success, userActivity: nil)
    detailsResponse.reservations = [INReservation()]
    precondition(detailsResponse.code == .success)
    precondition(detailsResponse.reservations?.count == 1)
    precondition(detailsResponse.userActivity == nil)

    let guestResponse = INGetRestaurantGuestIntentResponse(code: .success, userActivity: nil)
    guestResponse.guest = INRestaurantGuest(nameComponents: nil, phoneNumber: "555", emailAddress: "ada@example.com")
    guestResponse.guestDisplayPreferences = INRestaurantGuestDisplayPreferences()
    precondition(guestResponse.code == .success)
    precondition(guestResponse.guest?.phoneNumber == "555")
    precondition(guestResponse.guestDisplayPreferences != nil)
    _ = INGetRestaurantGuestIntent()
}

func testPaymentMethodApplePayAndRelevantShortcutFields() {
    let apple = INPaymentMethod.applePay()
    precondition(apple.type == .applePay)
    let method = INPaymentMethod(
        type: .checking,
        name: "Open Checking",
        identificationHint: "****42",
        icon: INImage(named: "card")
    )
    precondition(method.type == .checking)
    precondition(method.name == "Open Checking")
    precondition(method.identificationHint == "****42")
    precondition(method.icon?.namedImage == "card")

    let shortcut = INShortcut(intent: INIntent())
    let relevant = INRelevantShortcut(shortcut: shortcut)
    relevant.shortcutRole = .information
    relevant.watchTemplate = INDefaultCardTemplate(title: "Watch")
    relevant.relevanceProviders = [INDateRelevanceProvider(startDate: Date(timeIntervalSince1970: 1), endDate: nil)]
    precondition(relevant.shortcut === shortcut)
    precondition(relevant.shortcutRole == .information)
    precondition(relevant.watchTemplate?.title == "Watch")
    precondition(relevant.relevanceProviders.count == 1)
}

private final class Wave11ActivateHandler: NSObject, INActivateCarSignalIntentHandling {
    func handle(intent: INActivateCarSignalIntent, completion: @escaping (INActivateCarSignalIntentResponse) -> Void) {
        completion(INActivateCarSignalIntentResponse(code: .success, userActivity: nil))
    }
    func resolveCarName(for intent: INActivateCarSignalIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.success(with: intent.carName ?? INSpeakableString(spokenPhrase: "car")))
    }
    func resolveSignals(for intent: INActivateCarSignalIntent, with completion: @escaping (INCarSignalOptionsResolutionResult) -> Void) {
        completion(INCarSignalOptionsResolutionResult.success(with: intent.signals))
    }
}

private final class Wave11AnswerHandler: NSObject, INAnswerCallIntentHandling {
    func handle(intent: INAnswerCallIntent, completion: @escaping (INAnswerCallIntentResponse) -> Void) {
        completion(INAnswerCallIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave11AppendHandler: NSObject, INAppendToNoteIntentHandling {
    func handle(intent: INAppendToNoteIntent, completion: @escaping (INAppendToNoteIntentResponse) -> Void) {
        completion(INAppendToNoteIntentResponse(code: .success, userActivity: nil))
    }
    func resolveContent(for intent: INAppendToNoteIntent, with completion: @escaping (INNoteContentResolutionResult) -> Void) {
        completion(INNoteContentResolutionResult.needsValue())
    }
    func resolveTargetNote(for intent: INAppendToNoteIntent, with completion: @escaping (INNoteResolutionResult) -> Void) {
        completion(INNoteResolutionResult.needsValue())
    }
}

private final class Wave11CancelRideHandler: NSObject, INCancelRideIntentHandling {
    func handle(cancelRide intent: INCancelRideIntent, completion: @escaping (INCancelRideIntentResponse) -> Void) {
        completion(INCancelRideIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave11SendRideFeedbackHandler: NSObject, INSendRideFeedbackIntentHandling {
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent, completion: @escaping (INSendRideFeedbackIntentResponse) -> Void) {
        completion(INSendRideFeedbackIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave11SaveProfileHandler: NSObject, INSaveProfileInCarIntentHandling {
    func handle(intent: INSaveProfileInCarIntent, completion: @escaping (INSaveProfileInCarIntentResponse) -> Void) {
        completion(INSaveProfileInCarIntentResponse(code: .success, userActivity: nil))
    }
    func resolveProfileName(for intent: INSaveProfileInCarIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.success(with: intent.profileLabel ?? "Ada"))
    }
    func resolveProfileNumber(for intent: INSaveProfileInCarIntent, with completion: @escaping (INIntegerResolutionResult) -> Void) {
        completion(INIntegerResolutionResult.success(with: intent.profileNumber ?? 1))
    }
}

private final class Wave11AudioSourceHandler: NSObject, INSetAudioSourceInCarIntentHandling {
    func handle(intent: INSetAudioSourceInCarIntent, completion: @escaping (INSetAudioSourceInCarIntentResponse) -> Void) {
        completion(INSetAudioSourceInCarIntentResponse(code: .success, userActivity: nil))
    }
    func resolveAudioSource(for intent: INSetAudioSourceInCarIntent, with completion: @escaping (INCarAudioSourceResolutionResult) -> Void) {
        completion(INCarAudioSourceResolutionResult.success(with: intent.audioSource ?? .sourceAUX))
    }
    func resolveRelativeAudioSourceReference(for intent: INSetAudioSourceInCarIntent, with completion: @escaping (INRelativeReferenceResolutionResult) -> Void) {
        completion(INRelativeReferenceResolutionResult.success(with: intent.relativeAudioSourceReference ?? .next))
    }
}

private final class Wave11CarLockHandler: NSObject, INSetCarLockStatusIntentHandling {
    func handle(intent: INSetCarLockStatusIntent, completion: @escaping (INSetCarLockStatusIntentResponse) -> Void) {
        completion(INSetCarLockStatusIntentResponse(code: .success, userActivity: nil))
    }
    func resolveCarName(for intent: INSetCarLockStatusIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
    func resolveLocked(for intent: INSetCarLockStatusIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.success(with: intent.locked ?? true))
    }
}

private final class Wave11SnoozeHandler: NSObject, INSnoozeTasksIntentHandling {
    func handle(intent: INSnoozeTasksIntent, completion: @escaping (INSnoozeTasksIntentResponse) -> Void) {
        completion(INSnoozeTasksIntentResponse(code: .success, userActivity: nil))
    }
    func resolveNextTriggerTime(for intent: INSnoozeTasksIntent, with completion: @escaping (INDateComponentsRangeResolutionResult) -> Void) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
    func resolveTasks(for intent: INSnoozeTasksIntent, with completion: @escaping ([INSnoozeTasksTaskResolutionResult]) -> Void) {
        completion([])
    }
}

private final class Wave11AudioCallHandler: NSObject, INStartAudioCallIntentHandling {
    func handle(intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void) {
        completion(INStartAudioCallIntentResponse(code: .ready, userActivity: nil))
    }
    func resolveContacts(for intent: INStartAudioCallIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion((intent.contacts ?? []).map { INPersonResolutionResult.success(with: $0) })
    }
    func resolveDestinationType(for intent: INStartAudioCallIntent, with completion: @escaping (INCallDestinationTypeResolutionResult) -> Void) {
        completion(INCallDestinationTypeResolutionResult.success(with: intent.destinationType ?? .normal))
    }
}

private final class Wave11AffinityHandler: NSObject, INUpdateMediaAffinityIntentHandling {
    func handle(intent: INUpdateMediaAffinityIntent, completion: @escaping (INUpdateMediaAffinityIntentResponse) -> Void) {
        completion(INUpdateMediaAffinityIntentResponse(code: .success, userActivity: nil))
    }
    func resolveAffinityType(for intent: INUpdateMediaAffinityIntent, with completion: @escaping (INMediaAffinityTypeResolutionResult) -> Void) {
        completion(INMediaAffinityTypeResolutionResult.success(with: intent.affinityType ?? .like))
    }
    func resolveMediaItems(for intent: INUpdateMediaAffinityIntent, with completion: @escaping ([INUpdateMediaAffinityMediaItemResolutionResult]) -> Void) {
        completion([])
    }
}

private final class Wave11EditHandler: NSObject, INEditMessageIntentHandling {
    func handle(intent: INEditMessageIntent, completion: @escaping (INEditMessageIntentResponse) -> Void) {
        completion(INEditMessageIntentResponse(code: .success, userActivity: nil))
    }
    func resolveEditedContent(for intent: INEditMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.success(with: intent.editedContent ?? ""))
    }
}

private final class Wave11MessageAttributeHandler: NSObject, INSetMessageAttributeIntentHandling {
    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        completion(INSetMessageAttributeIntentResponse(code: .success, userActivity: nil))
    }
    func resolveAttribute(for intent: INSetMessageAttributeIntent, with completion: @escaping (INMessageAttributeResolutionResult) -> Void) {
        completion(INMessageAttributeResolutionResult.success(with: intent.attribute ?? .read))
    }
}

private final class Wave11SearchMediaHandler: NSObject, INSearchForMediaIntentHandling {
    func handle(intent: INSearchForMediaIntent, completion: @escaping (INSearchForMediaIntentResponse) -> Void) {
        completion(INSearchForMediaIntentResponse(code: .success, userActivity: nil))
    }
    func resolveMediaItems(for intent: INSearchForMediaIntent, with completion: @escaping ([INSearchForMediaMediaItemResolutionResult]) -> Void) {
        completion([])
    }
}

private final class Wave11VisualCodeHandler: NSObject, INGetVisualCodeIntentHandling {
    func handle(intent: INGetVisualCodeIntent, completion: @escaping (INGetVisualCodeIntentResponse) -> Void) {
        completion(INGetVisualCodeIntentResponse(code: .success, userActivity: nil))
    }
    func resolveVisualCodeType(for intent: INGetVisualCodeIntent, with completion: @escaping (INVisualCodeTypeResolutionResult) -> Void) {
        completion(INVisualCodeTypeResolutionResult.success(with: intent.visualCodeType ?? .contact))
    }
}

private final class Wave11CancelWorkoutHandler: NSObject, INCancelWorkoutIntentHandling {
    func handle(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        completion(INCancelWorkoutIntentResponse(code: .success, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INCancelWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

private final class Wave11EndWorkoutHandler: NSObject, INEndWorkoutIntentHandling {
    func handle(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        completion(INEndWorkoutIntentResponse(code: .success, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INEndWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

private final class Wave11PauseWorkoutHandler: NSObject, INPauseWorkoutIntentHandling {
    func handle(intent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        completion(INPauseWorkoutIntentResponse(code: .success, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INPauseWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

private final class Wave11ResumeWorkoutHandler: NSObject, INResumeWorkoutIntentHandling {
    func handle(intent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        completion(INResumeWorkoutIntentResponse(code: .success, userActivity: nil))
    }
    func resolveWorkoutName(for intent: INResumeWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

private final class Wave11GetCarLockHandler: NSObject, INGetCarLockStatusIntentHandling {
    func handle(intent: INGetCarLockStatusIntent, completion: @escaping (INGetCarLockStatusIntentResponse) -> Void) {
        let response = INGetCarLockStatusIntentResponse(code: .success, userActivity: nil)
        response.locked = true
        completion(response)
    }
    func resolveCarName(for intent: INGetCarLockStatusIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        completion(INSpeakableStringResolutionResult.needsValue())
    }
}

private final class Wave11VideoCallHandler: NSObject, INStartVideoCallIntentHandling {
    func handle(intent: INStartVideoCallIntent, completion: @escaping (INStartVideoCallIntentResponse) -> Void) {
        completion(INStartVideoCallIntentResponse(code: .ready, userActivity: nil))
    }
    func resolveContacts(for intent: INStartVideoCallIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion((intent.contacts ?? []).map { INPersonResolutionResult.success(with: $0) })
    }
}

func testActivateCarSignalIntentAndDispatch() {
    let intent = INActivateCarSignalIntent(carName: INSpeakableString(spokenPhrase: "Roadster"), signals: [.audible, .visible])
    precondition(intent.carName?.spokenPhrase == "Roadster")
    precondition(intent.signals.contains(.audible))
    let response = INActivateCarSignalIntentResponse(code: .success, userActivity: nil)
    response.signals = [.visible]
    precondition(response.code == .success)
    precondition(response.signals.contains(.visible))
    let handled = INHostIntentDispatcher.handle(intent, handler: Wave11ActivateHandler()) as? INActivateCarSignalIntentResponse
    precondition(handled?.code == .success)
    _ = INHostIntentDispatcher.confirm(intent, handler: Wave11ActivateHandler())
    let resolved = INHostIntentDispatcher.resolve(intent, handler: Wave11ActivateHandler())
    precondition(!resolved.isEmpty)
}

func testAnswerAppendAndCancelRideDispatch() {
    let answer = INAnswerCallIntent(audioRoute: .speakerphoneAudioRoute, callIdentifier: "call-1")
    precondition(answer.audioRoute == .speakerphoneAudioRoute)
    precondition(answer.callIdentifier == "call-1")
    let answerResponse = INAnswerCallIntentResponse(code: .success, userActivity: nil)
    precondition(answerResponse.code == .success)
    let answered = INHostIntentDispatcher.handle(answer, handler: Wave11AnswerHandler()) as? INAnswerCallIntentResponse
    precondition(answered?.code == .success)
    _ = INHostIntentDispatcher.confirm(answer, handler: Wave11AnswerHandler())

    let append = INAppendToNoteIntent(targetNote: INNote(), content: INNoteContent())
    precondition(append.targetNote != nil)
    precondition(append.content != nil)
    let appended = INHostIntentDispatcher.handle(append, handler: Wave11AppendHandler()) as? INAppendToNoteIntentResponse
    precondition(appended?.code == .success)
    _ = INHostIntentDispatcher.confirm(append, handler: Wave11AppendHandler())
    _ = INHostIntentDispatcher.resolve(append, handler: Wave11AppendHandler())

    let cancel = INCancelRideIntent(rideIdentifier: "ride-2")
    let canceled = INHostIntentDispatcher.handle(cancel, handler: Wave11CancelRideHandler()) as? INCancelRideIntentResponse
    precondition(canceled?.code == .success)
    _ = INHostIntentDispatcher.confirm(cancel, handler: Wave11CancelRideHandler())
}

func testSaveProfileAudioSourceLockAndSnoozeDispatch() {
    let save = INSaveProfileInCarIntent(profileNumber: 2, profileLabel: "Ada")
    let saved = INHostIntentDispatcher.handle(save, handler: Wave11SaveProfileHandler()) as? INSaveProfileInCarIntentResponse
    precondition(saved?.code == .success)
    _ = INHostIntentDispatcher.confirm(save, handler: Wave11SaveProfileHandler())
    _ = INHostIntentDispatcher.resolve(save, handler: Wave11SaveProfileHandler())

    let audio = INSetAudioSourceInCarIntent(audioSource: .sourceRadio, relativeAudioSourceReference: .next)
    precondition(audio.audioSource == .sourceRadio)
    precondition(audio.relativeAudioSourceReference == .next)
    let audioHandled = INHostIntentDispatcher.handle(audio, handler: Wave11AudioSourceHandler()) as? INSetAudioSourceInCarIntentResponse
    precondition(audioHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(audio, handler: Wave11AudioSourceHandler())
    _ = INHostIntentDispatcher.resolve(audio, handler: Wave11AudioSourceHandler())

    let lock = INSetCarLockStatusIntent(locked: false, carName: INSpeakableString(spokenPhrase: "Kit"))
    let locked = INHostIntentDispatcher.handle(lock, handler: Wave11CarLockHandler()) as? INSetCarLockStatusIntentResponse
    precondition(locked?.code == .success)
    _ = INHostIntentDispatcher.confirm(lock, handler: Wave11CarLockHandler())
    _ = INHostIntentDispatcher.resolve(lock, handler: Wave11CarLockHandler())

    let snooze = INSnoozeTasksIntent(tasks: [], nextTriggerTime: wave11Range(), all: true)
    let snoozed = INHostIntentDispatcher.handle(snooze, handler: Wave11SnoozeHandler()) as? INSnoozeTasksIntentResponse
    precondition(snoozed?.code == .success)
    _ = INHostIntentDispatcher.confirm(snooze, handler: Wave11SnoozeHandler())
    _ = INHostIntentDispatcher.resolve(snooze, handler: Wave11SnoozeHandler())
}

func testStartAudioCallAffinityAndRideFeedbackDispatch() {
    let call = INStartAudioCallIntent(destinationType: .normal, contacts: [wave11Person()])
    precondition(call.destinationType == .normal)
    precondition(call.contacts?.count == 1)
    let callResponse = INStartAudioCallIntentResponse(code: .ready, userActivity: nil)
    precondition(callResponse.code == .ready)
    let handled = INHostIntentDispatcher.handle(call, handler: Wave11AudioCallHandler()) as? INStartAudioCallIntentResponse
    precondition(handled?.code == .ready)
    _ = INHostIntentDispatcher.confirm(call, handler: Wave11AudioCallHandler())
    _ = INHostIntentDispatcher.resolve(call, handler: Wave11AudioCallHandler())

    let affinity = INUpdateMediaAffinityIntent(mediaItems: nil, mediaSearch: nil, affinityType: .like)
    precondition(affinity.affinityType == .like)
    let affinityHandled = INHostIntentDispatcher.handle(affinity, handler: Wave11AffinityHandler()) as? INUpdateMediaAffinityIntentResponse
    precondition(affinityHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(affinity, handler: Wave11AffinityHandler())
    _ = INHostIntentDispatcher.resolve(affinity, handler: Wave11AffinityHandler())

    let feedback = INSendRideFeedbackIntent(rideIdentifier: "ride-3")
    feedback.rating = NSNumber(value: 5)
    feedback.tip = INCurrencyAmount(amount: NSDecimalNumber(value: 2), currencyCode: "USD")
    precondition(feedback.rideIdentifier == "ride-3")
    precondition(feedback.rating?.intValue == 5)
    precondition(feedback.tip?.currencyCode == "USD")
    let feedbackHandled = INHostIntentDispatcher.handle(feedback, handler: Wave11SendRideFeedbackHandler()) as? INSendRideFeedbackIntentResponse
    precondition(feedbackHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(feedback, handler: Wave11SendRideFeedbackHandler())
}

func testEditMessageAttributeSearchMediaAndVisualCodeDispatch() {
    let edit = INEditMessageIntent(messageIdentifier: "m-1", editedContent: "updated")
    precondition(edit.messageIdentifier == "m-1")
    precondition(edit.editedContent == "updated")
    let edited = INHostIntentDispatcher.handle(edit, handler: Wave11EditHandler()) as? INEditMessageIntentResponse
    precondition(edited?.code == .success)
    _ = INHostIntentDispatcher.confirm(edit, handler: Wave11EditHandler())
    _ = INHostIntentDispatcher.resolve(edit, handler: Wave11EditHandler())

    let attribute = INSetMessageAttributeIntent(identifiers: ["m-1"], attribute: .read)
    precondition(attribute.identifiers == ["m-1"])
    precondition(attribute.attribute == .read)
    let attributed = INHostIntentDispatcher.handle(attribute, handler: Wave11MessageAttributeHandler()) as? INSetMessageAttributeIntentResponse
    precondition(attributed?.code == .success)
    _ = INHostIntentDispatcher.confirm(attribute, handler: Wave11MessageAttributeHandler())
    _ = INHostIntentDispatcher.resolve(attribute, handler: Wave11MessageAttributeHandler())

    let search = INSearchForMediaIntent(mediaItems: nil, mediaSearch: nil)
    let searched = INHostIntentDispatcher.handle(search, handler: Wave11SearchMediaHandler()) as? INSearchForMediaIntentResponse
    precondition(searched?.code == .success)
    _ = INHostIntentDispatcher.confirm(search, handler: Wave11SearchMediaHandler())
    _ = INHostIntentDispatcher.resolve(search, handler: Wave11SearchMediaHandler())

    let visual = INGetVisualCodeIntent(visualCodeType: .contact)
    precondition(visual.visualCodeType == .contact)
    let visualHandled = INHostIntentDispatcher.handle(visual, handler: Wave11VisualCodeHandler()) as? INGetVisualCodeIntentResponse
    precondition(visualHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(visual, handler: Wave11VisualCodeHandler())
    _ = INHostIntentDispatcher.resolve(visual, handler: Wave11VisualCodeHandler())
}

func testWorkoutAndVideoCallAndGetCarLockDispatch() {
    let name = INSpeakableString(spokenPhrase: "Run")
    let cancelHandled = INHostIntentDispatcher.handle(INCancelWorkoutIntent(workoutName: name), handler: Wave11CancelWorkoutHandler()) as? INCancelWorkoutIntentResponse
    precondition(cancelHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INCancelWorkoutIntent(workoutName: name), handler: Wave11CancelWorkoutHandler())
    _ = INHostIntentDispatcher.resolve(INCancelWorkoutIntent(workoutName: name), handler: Wave11CancelWorkoutHandler())

    let endHandled = INHostIntentDispatcher.handle(INEndWorkoutIntent(workoutName: name), handler: Wave11EndWorkoutHandler()) as? INEndWorkoutIntentResponse
    precondition(endHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INEndWorkoutIntent(workoutName: name), handler: Wave11EndWorkoutHandler())
    _ = INHostIntentDispatcher.resolve(INEndWorkoutIntent(workoutName: name), handler: Wave11EndWorkoutHandler())

    let pauseHandled = INHostIntentDispatcher.handle(INPauseWorkoutIntent(workoutName: name), handler: Wave11PauseWorkoutHandler()) as? INPauseWorkoutIntentResponse
    precondition(pauseHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INPauseWorkoutIntent(workoutName: name), handler: Wave11PauseWorkoutHandler())
    _ = INHostIntentDispatcher.resolve(INPauseWorkoutIntent(workoutName: name), handler: Wave11PauseWorkoutHandler())

    let resumeHandled = INHostIntentDispatcher.handle(INResumeWorkoutIntent(workoutName: name), handler: Wave11ResumeWorkoutHandler()) as? INResumeWorkoutIntentResponse
    precondition(resumeHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INResumeWorkoutIntent(workoutName: name), handler: Wave11ResumeWorkoutHandler())
    _ = INHostIntentDispatcher.resolve(INResumeWorkoutIntent(workoutName: name), handler: Wave11ResumeWorkoutHandler())

    let lockIntent = INGetCarLockStatusIntent(carName: INSpeakableString(spokenPhrase: "Kit"))
    let lockHandled = INHostIntentDispatcher.handle(lockIntent, handler: Wave11GetCarLockHandler()) as? INGetCarLockStatusIntentResponse
    precondition(lockHandled?.code == .success)
    precondition(lockHandled?.locked == true)
    _ = INHostIntentDispatcher.confirm(lockIntent, handler: Wave11GetCarLockHandler())
    _ = INHostIntentDispatcher.resolve(lockIntent, handler: Wave11GetCarLockHandler())

    let video = INStartVideoCallIntent(contacts: [wave11Person()])
    precondition(video.contacts?.count == 1)
    let videoHandled = INHostIntentDispatcher.handle(video, handler: Wave11VideoCallHandler()) as? INStartVideoCallIntentResponse
    precondition(videoHandled?.code == .ready)
    _ = INHostIntentDispatcher.confirm(video, handler: Wave11VideoCallHandler())
    _ = INHostIntentDispatcher.resolve(video, handler: Wave11VideoCallHandler())
}
