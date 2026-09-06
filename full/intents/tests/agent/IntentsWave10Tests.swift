import Foundation
@_spi(OpenIntentsHost) import Intents

private func wave10ArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
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

private func wave10Person(_ name: String = "Ada") -> INPerson {
    INPerson(
        personHandle: INPersonHandle(value: "ada@example.com", type: .emailAddress),
        nameComponents: nil,
        displayName: name,
        image: nil,
        contactIdentifier: "c-ada",
        customIdentifier: "custom-ada"
    )
}

private func wave10ExerciseOptionSet<T: OptionSet>(_ first: T, _ second: T)
where T.RawValue: FixedWidthInteger, T.Element == T, T.ArrayLiteralElement == T {
    precondition(T().isEmpty)
    var working = first
    working.formUnion(second)
    let inserted = working.insert(second)
    _ = inserted.inserted
    _ = inserted.memberAfterInsert
    precondition(working.contains(first))
    precondition(working.contains(second))
    let removed = working.remove(second)
    precondition(removed != nil)
    _ = working.update(with: second)
    let union = first.union(second)
    precondition(union.contains(first) && union.contains(second))
    precondition(union.intersection(first).contains(first))
    _ = first.symmetricDifference(second)
    var form = first
    form.formUnion(second)
    form.formIntersection(first)
    form.formSymmetricDifference(second)
    precondition(first.isSubset(of: union))
    precondition(union.isSuperset(of: first))
    precondition(first.isDisjoint(with: T()) || first.isEmpty)
    _ = union.subtracting(second)
    var subtractInPlace = union
    subtractInPlace.subtract(second)
    _ = first.isStrictSubset(of: union)
    _ = union.isStrictSuperset(of: first)
    let fromSequence = T([first, second])
    precondition(fromSequence.contains(first))
    let fromLiteral: T = [first, second]
    precondition(fromLiteral.contains(second))
}

func testObjectInitsPropertiesAndCoding() {
    let image = INImage(named: "glyph")
    let spoken = INSpeakableString(vocabularyIdentifier: nil, spokenPhrase: "Ada", pronunciationHint: "AY-duh")
    let withHint = INObject(identifier: "obj-1", displayString: "Ada", pronunciationHint: "AY-duh")
    precondition(withHint.identifier == "obj-1")
    precondition(withHint.displayString == "Ada")
    precondition(withHint.pronunciationHint == "AY-duh")
    let withSubtitle = INObject(
        identifier: "obj-2",
        displayString: "Ada",
        subtitleString: "Mathematician",
        displayImage: image
    )
    precondition(withSubtitle.subtitleString == "Mathematician")
    precondition(withSubtitle.displayImage?.namedImage == "glyph")
    let full = INObject(
        identifier: "obj-3",
        displayString: "Ada",
        pronunciationHint: "AY-duh",
        subtitleString: "Countess",
        displayImage: image
    )
    full.alternativeSpeakableMatches = [spoken]
    precondition(full.alternativeSpeakableMatches?.first?.spokenPhrase == "Ada")
    let labeled = INObject(identifier: "obj-4", displayString: "Labeled")
    precondition(labeled.displayString == "Labeled")
    let restored = wave10ArchiveRoundTrip(full)
    precondition(restored.identifier == "obj-3")
    precondition(restored.displayString == "Ada")
    precondition(restored.pronunciationHint == "AY-duh")
    precondition(restored.subtitleString == "Countess")
    precondition(INObject.supportsSecureCoding)
}

func testRestaurantReservationBookingPropertiesAndCoding() {
    let restaurant = INRestaurant()
    restaurant.name = "Cafe Open"
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let booking = INRestaurantReservationBooking(
        restaurant: restaurant,
        bookingDate: date,
        partySize: 4,
        bookingIdentifier: "book-1"
    )
    booking.isBookingAvailable = true
    booking.requiresEmailAddress = true
    booking.requiresManualRequest = false
    booking.requiresName = true
    booking.requiresPhoneNumber = true
    booking.offers = []
    precondition(booking.restaurant?.name == "Cafe Open")
    precondition(booking.bookingDate == date)
    precondition(booking.partySize == 4)
    precondition(booking.bookingIdentifier == "book-1")
    precondition(booking.isBookingAvailable)
    precondition(booking.requiresEmailAddress)
    precondition(!booking.requiresManualRequest)
    precondition(booking.requiresName)
    precondition(booking.requiresPhoneNumber)
    precondition(booking.offers?.isEmpty == true)
    let restored = wave10ArchiveRoundTrip(booking)
    precondition(restored.bookingIdentifier == "book-1")
    precondition(restored.partySize == 4)
    precondition(restored.isBookingAvailable)
    precondition(restored.requiresEmailAddress)
    precondition(restored.requiresName)
    precondition(restored.requiresPhoneNumber)
}

func testSearchForMessagesRemainingProperties() {
    let person = wave10Person()
    var start = DateComponents()
    start.year = 2026
    let range = INDateComponentsRange(start: start, end: nil)
    let withGroups = INSearchForMessagesIntent(
        recipients: [person],
        senders: [person],
        searchTerms: ["hello"],
        attributes: [.unread],
        dateTimeRange: range,
        identifiers: ["m1"],
        notificationIdentifiers: ["n1"],
        groupNames: ["Team"]
    )
    precondition(withGroups.dateTimeRange?.startDateComponents?.year == 2026)
    precondition(withGroups.groupNames == ["Team"])
    precondition(withGroups.recipientsOperator == .all)
    precondition(withGroups.sendersOperator == .all)
    precondition(withGroups.searchTermsOperator == .all)
    precondition(withGroups.identifiersOperator == .all)
    precondition(withGroups.notificationIdentifiersOperator == .all)
    precondition(withGroups.groupNamesOperator == .all)
    precondition(withGroups.speakableGroupNamesOperator == .all)
    precondition(withGroups.conversationIdentifiersOperator == .all)
    let spoken = INSpeakableString(spokenPhrase: "Team")
    let withSpeakable = INSearchForMessagesIntent(
        recipients: [person],
        senders: [person],
        searchTerms: ["ping"],
        attributes: [.read],
        dateTimeRange: range,
        identifiers: ["m2"],
        notificationIdentifiers: ["n2"],
        speakableGroupNames: [spoken]
    )
    precondition(withSpeakable.speakableGroupNames?.first?.spokenPhrase == "Team")
    precondition(withSpeakable.dateTimeRange?.startDateComponents?.year == 2026)
}

func testSetProfileInCarIntentPropertiesAndResponse() {
    let carName = INSpeakableString(spokenPhrase: "Blue Car")
    let numbered = INSetProfileInCarIntent(
        profileNumber: 2,
        profileName: "Ada",
        isDefaultProfile: true,
        carName: carName
    )
    precondition(numbered.profileNumber == 2)
    precondition(numbered.profileName == "Ada")
    precondition(numbered.isDefaultProfile == true)
    precondition(numbered.carName?.spokenPhrase == "Blue Car")
    let labeled = INSetProfileInCarIntent(profileLabel: "Work", isDefaultProfile: false)
    precondition(labeled.profileLabel == "Work")
    let defaultOnly = INSetProfileInCarIntent(defaultProfile: 1)
    precondition(defaultOnly.defaultProfile == 1)
    let namedDefault = INSetProfileInCarIntent(profileName: "Home", defaultProfile: 0)
    precondition(namedDefault.profileName == "Home")
    let labelDefault = INSetProfileInCarIntent(profileLabel: "Gym", defaultProfile: 3)
    precondition(labelDefault.profileLabel == "Gym")
    let labelOnly = INSetProfileInCarIntent(profileLabel: "Night")
    precondition(labelOnly.profileLabel == "Night")
    let numberDefault = INSetProfileInCarIntent(profileNumber: 4, defaultProfile: 1)
    precondition(numberDefault.profileNumber == 4)
    let numberName = INSetProfileInCarIntent(profileNumber: 5, profileName: "Sport", defaultProfile: 0)
    precondition(numberName.profileName == "Sport")
    let numberLabelDefault = INSetProfileInCarIntent(profileNumber: 6, profileLabel: "Eco", defaultProfile: 1)
    precondition(numberLabelDefault.profileLabel == "Eco")
    let numberLabelFlag = INSetProfileInCarIntent(profileNumber: 7, profileLabel: "Snow", isDefaultProfile: true)
    precondition(numberLabelFlag.isDefaultProfile == true)
    let numberLabel = INSetProfileInCarIntent(profileNumber: 8, profileLabel: "Track")
    precondition(numberLabel.profileNumber == 8)
    let activity = NSUserActivity(activityType: "com.openuikit.intents.profile")
    let response = INSetProfileInCarIntentResponse(code: .success, userActivity: activity)
    precondition(response.code == .success)
    precondition(response.userActivity?.activityType == "com.openuikit.intents.profile")
}

func testDailyRoutineSituationProvider() {
    let situations: [INDailyRoutineRelevanceProvider.Situation] = [
        .morning, .evening, .home, .work, .school, .gym, .commute,
        .headphonesConnected, .activeWorkout, .physicalActivityIncomplete
    ]
    precondition(INDailyRoutineRelevanceProvider.Situation.morning.rawValue == 0)
    precondition(INDailyRoutineRelevanceProvider.Situation.evening.rawValue == 1)
    precondition(INDailyRoutineRelevanceProvider.Situation.home.rawValue == 2)
    precondition(INDailyRoutineRelevanceProvider.Situation.work.rawValue == 3)
    precondition(INDailyRoutineRelevanceProvider.Situation.school.rawValue == 4)
    precondition(INDailyRoutineRelevanceProvider.Situation.gym.rawValue == 5)
    precondition(INDailyRoutineRelevanceProvider.Situation.commute.rawValue == 6)
    precondition(INDailyRoutineRelevanceProvider.Situation.headphonesConnected.rawValue == 7)
    precondition(INDailyRoutineRelevanceProvider.Situation.activeWorkout.rawValue == 8)
    precondition(INDailyRoutineRelevanceProvider.Situation.physicalActivityIncomplete.rawValue == 9)
    for situation in situations {
        let provider = INDailyRoutineRelevanceProvider(situation: situation)
        precondition(provider.situation == situation)
        precondition(INDailyRoutineRelevanceProvider.Situation(rawValue: situation.rawValue) == situation)
    }
}

func testMediaDestinationReferenceAndResolution() {
    let libraryRef = INMediaDestinationReference.libraryDestination()
    precondition(libraryRef.mediaDestinationType == .library)
    let playlistRef = INMediaDestinationReference.playlistDestination(withName: "Favorites")
    precondition(playlistRef.playlistName == "Favorites")
    precondition(playlistRef.mediaDestinationType == .playlist)
    let restored = wave10ArchiveRoundTrip(playlistRef)
    precondition(restored.playlistName == "Favorites")
    let library = INMediaDestination.library
    precondition(library.description == "library")
    precondition(library.debugDescription == "library")
    _ = INMediaDestination.ReferenceType.self
    let success = INMediaDestinationResolutionResult.success(with: library)
    precondition(success.outcome == .success)
    let disambiguation = INMediaDestinationResolutionResult.disambiguation(with: [library, .playlist("Mix")])
    precondition(disambiguation.outcome == .disambiguation)
    let confirm = INMediaDestinationResolutionResult.confirmationRequired(with: library)
    precondition(confirm.outcome == .confirmationRequired)
}

func testRideCompletionStatusFactories() {
    let canceledUser = INRideCompletionStatus.canceledByUser()
    precondition(canceledUser.isCanceled)
    let missed = INRideCompletionStatus.canceledMissedPickup()
    precondition(missed.isCanceled)
    precondition(missed.isMissedPickup)
    let amount = INCurrencyAmount(amount: NSDecimalNumber(value: 12), currencyCode: "USD")
    let outstandingFeedback = INRideCompletionStatus.completed(outstandingFeedbackType: [.tip])
    precondition(outstandingFeedback.isCompleted)
    precondition(outstandingFeedback.isOutstanding)
    precondition(outstandingFeedback.feedbackType.contains(.tip))
    let outstandingPay = INRideCompletionStatus.completed(outstandingPaymentAmount: amount)
    precondition(outstandingPay.paymentAmount?.currencyCode == "USD")
    precondition(outstandingPay.isOutstanding)
    let settled = INRideCompletionStatus.completed(settledPaymentAmount: amount)
    precondition(settled.paymentAmount?.currencyCode == "USD")
    precondition(!settled.isOutstanding)
    let activity = NSUserActivity(activityType: "com.openuikit.intents.ride")
    settled.completionUserActivity = activity
    settled.defaultTippingOptions = []
    precondition(settled.completionUserActivity?.activityType == "com.openuikit.intents.ride")
    precondition(settled.defaultTippingOptions?.isEmpty == true)
    let restored = wave10ArchiveRoundTrip(missed)
    precondition(restored.isCanceled)
    precondition(restored.isMissedPickup)
}

func testCarChargingConnectorsAndPower() {
    let types: [INCar.ChargingConnectorType] = [
        .ccs1, .ccs2, .chaDeMo, .gbtAC, .gbtDC, .j1772, .mennekes, .nacsAC, .nacsDC, .tesla
    ]
    precondition(INCar.ChargingConnectorType.ccs1.rawValue == "ccs1")
    precondition(INCar.ChargingConnectorType(rawValue: "tesla") == .tesla)
    let car = INCar()
    car.carIdentifier = "vin-1"
    car.displayName = "Open Car"
    car.make = "Open"
    car.model = "One"
    car.year = "2026"
    car.supportedChargingConnectors = types
    let head = INCarHeadUnit(bluetoothIdentifier: "bt", iAP2Identifier: "iap")
    car.headUnit = head
    let power = Measurement(value: 150, unit: UnitPower.kilowatts)
    car.setMaximumPower(power, for: .ccs1)
    precondition(car.maximumPower(for: .ccs1)?.value == 150)
    precondition(car.carIdentifier == "vin-1")
    precondition(car.displayName == "Open Car")
    precondition(car.model == "One")
    precondition(car.year == "2026")
    precondition(car.supportedChargingConnectors.count == 10)
    precondition(car.headUnit?.bluetoothIdentifier == "bt")
    let restored = wave10ArchiveRoundTrip(car)
    precondition(restored.carIdentifier == "vin-1")
    precondition(restored.model == "One")
}

func testCallRecordRemainingProperties() {
    let person = wave10Person()
    let created = Date(timeIntervalSince1970: 100)
    let record = INCallRecord(
        identifier: "call-10",
        dateCreated: created,
        caller: person,
        callRecordType: .outgoing,
        callCapability: .audioCall,
        callDuration: 12.5,
        unseen: true,
        numberOfCalls: 2
    )
    record.participants = [person]
    precondition(record.callCapability == .audioCall)
    precondition(record.callRecordType == .outgoing)
    precondition(record.caller?.displayName == "Ada")
    precondition(record.dateCreated == created)
    precondition(record.participants?.count == 1)
}

func testPlayMediaIntentRemainingProperties() {
    let media = INMediaItem(identifier: "s1", title: "Song", type: .song, artwork: nil)
    let search = INMediaSearch(mediaType: .song, mediaName: "Song")
    let play = INPlayMediaIntent(
        mediaItems: [media],
        mediaContainer: media,
        playShuffled: false,
        playbackRepeatMode: .all,
        resumePlayback: true,
        playbackQueueLocation: .now,
        playbackSpeed: 1.25,
        mediaSearch: search
    )
    precondition(play.mediaContainer?.identifier == "s1")
    precondition(play.mediaItems?.count == 1)
    precondition(play.mediaSearch?.mediaName == "Song")
    precondition(play.playbackQueueLocation == .now)
    precondition(play.playbackRepeatMode == .all)
    let activity = NSUserActivity(activityType: "com.openuikit.intents.play")
    let response = INPlayMediaIntentResponse(code: .success, userActivity: activity)
    response.nowPlayingInfo = ["title": "Song"]
    precondition(response.code == .success)
    precondition(response.nowPlayingInfo?["title"] as? String == "Song")
    precondition(response.userActivity?.activityType == "com.openuikit.intents.play")
}

func testAddMediaIntentProperties() {
    let media = INMediaItem(identifier: "s1", title: "Song", type: .song, artwork: nil)
    let search = INMediaSearch(mediaType: .song, mediaName: "Song")
    let intent = INAddMediaIntent(
        mediaItems: [media],
        mediaSearch: search,
        mediaDestination: .playlist("Favorites")
    )
    precondition(intent.mediaItems?.count == 1)
    precondition(intent.mediaSearch?.mediaName == "Song")
    precondition(intent.mediaDestination?.playlistName == "Favorites")
    let activity = NSUserActivity(activityType: "com.openuikit.intents.add-media")
    let response = INAddMediaIntentResponse(code: .success, userActivity: activity)
    precondition(response.code == .success)
    precondition(response.userActivity?.activityType == "com.openuikit.intents.add-media")
    let successes = INAddMediaMediaItemResolutionResult.successes(with: [media])
    precondition(successes.count == 1)
    precondition(successes[0].outcome == .success)
    let unsupported = INAddMediaMediaItemResolutionResult.unsupported(forReason: .loginRequired)
    precondition(unsupported.outcome == .unsupported)
    let wrapped = INAddMediaMediaItemResolutionResult(mediaItemResolutionResult: INMediaItemResolutionResult.needsValue())
    precondition(wrapped.outcome == .needsValue)
}

func testPaymentRecordAndPriceRange() {
    let person = wave10Person()
    let amount = INCurrencyAmount(amount: NSDecimalNumber(value: 20), currencyCode: "USD")
    let fee = INCurrencyAmount(amount: NSDecimalNumber(value: 1), currencyCode: "USD")
    let method = INPaymentMethod(type: .credit, name: "Visa", identificationHint: "4242", icon: nil)
    let record = INPaymentRecord(
        payee: person,
        payer: person,
        currencyAmount: amount,
        paymentMethod: method,
        note: "lunch",
        status: .completed,
        feeAmount: fee
    )
    precondition(record?.payee?.displayName == "Ada")
    precondition(record?.payer?.displayName == "Ada")
    precondition(record?.currencyAmount?.currencyCode == "USD")
    precondition(record?.paymentMethod?.name == "Visa")
    precondition(record?.note == "lunch")
    precondition(record?.status == .completed)
    precondition(record?.feeAmount?.currencyCode == "USD")
    let withoutFee = INPaymentRecord(
        payee: person,
        payer: person,
        currencyAmount: amount,
        paymentMethod: method,
        note: "tip",
        status: .pending
    )
    precondition(withoutFee?.note == "tip")
    let maxOnly = INPriceRange(maximumPrice: NSDecimalNumber(value: 30), currencyCode: "USD")
    precondition(maxOnly.maximumPrice == NSDecimalNumber(value: 30))
    precondition(maxOnly.currencyCode == "USD")
    let minOnly = INPriceRange(minimumPrice: NSDecimalNumber(value: 5), currencyCode: "USD")
    precondition(minOnly.minimumPrice == NSDecimalNumber(value: 5))
    let exact = INPriceRange(price: NSDecimalNumber(value: 12), currencyCode: "EUR")
    precondition(exact.minimumPrice == NSDecimalNumber(value: 12))
    precondition(exact.maximumPrice == NSDecimalNumber(value: 12))
    let between = INPriceRange(rangeBetweenPrice: NSDecimalNumber(value: 8), andPrice: NSDecimalNumber(value: 22), currencyCode: "GBP")
    precondition(between.minimumPrice == NSDecimalNumber(value: 8))
    precondition(between.maximumPrice == NSDecimalNumber(value: 22))
    let restored = wave10ArchiveRoundTrip(maxOnly)
    precondition(restored.currencyCode == "USD")
}

func testParameterClassMethodAndIndexes() {
    let parameter = INParameter.parameter(forClass: INIntent.self, keyPath: "identifier")
    precondition(parameter.parameterClass == INIntent.self)
    precondition(parameter.parameterKeyPath == "identifier")
    parameter.setIndex(2, forSubKeyPath: "recipients")
    precondition(parameter.index(forSubKeyPath: "recipients") == 2)
    let other = INParameter(forClass: INIntent.self, keyPath: "identifier")
    precondition(parameter.isEqual(to: other))
}

func testCreateNoteAndTaskListIntents() {
    let title = INSpeakableString(spokenPhrase: "Groceries")
    let content = INNoteContent()
    let group = INSpeakableString(spokenPhrase: "Home")
    let note = INCreateNoteIntent(title: title, content: content, groupName: group)
    precondition(note.title?.spokenPhrase == "Groceries")
    precondition(note.groupName?.spokenPhrase == "Home")
    precondition(note.content != nil)
    let noteResponse = INCreateNoteIntentResponse(code: .success, userActivity: nil)
    precondition(noteResponse.code == .success)
    let list = INCreateTaskListIntent(title: title, taskTitles: [title], groupName: group)
    precondition(list.title?.spokenPhrase == "Groceries")
    precondition(list.taskTitles?.count == 1)
    precondition(list.groupName?.spokenPhrase == "Home")
    let delete = INDeleteTasksIntent(taskList: INTaskList(), tasks: [INTask()])
    precondition(delete.taskList != nil)
    precondition(delete.tasks?.count == 1)
}

func testReservationDefaultsAndAvailabilityIntents() {
    let restaurant = INRestaurant()
    restaurant.name = "Cafe"
    let defaultsIntent = INGetAvailableRestaurantReservationBookingDefaultsIntent(restaurant: restaurant)
    precondition(defaultsIntent.restaurant?.name == "Cafe")
    let date = Date(timeIntervalSince1970: 1_700_000_100)
    let defaultsResponse = INGetAvailableRestaurantReservationBookingDefaultsIntentResponse(
        defaultPartySize: 2,
        defaultBookingDate: date,
        code: .success,
        userActivity: nil
    )
    defaultsResponse.maximumPartySize = NSNumber(value: 8)
    defaultsResponse.minimumPartySize = NSNumber(value: 1)
    defaultsResponse.providerImage = INImage(named: "mark")
    precondition(defaultsResponse.code == .success)
    precondition(defaultsResponse.defaultPartySize == 2)
    precondition(defaultsResponse.defaultBookingDate == date)
    precondition(defaultsResponse.maximumPartySize?.intValue == 8)
    precondition(defaultsResponse.minimumPartySize?.intValue == 1)
    precondition(defaultsResponse.providerImage?.namedImage == "mark")
    var preferred = DateComponents()
    preferred.hour = 19
    let bookings = INGetAvailableRestaurantReservationBookingsIntent(
        restaurant: restaurant,
        partySize: 3,
        preferredBookingDateComponents: preferred,
        maximumNumberOfResults: NSNumber(value: 10),
        earliestBookingDateForResults: date,
        latestBookingDateForResults: date.addingTimeInterval(3600)
    )
    precondition(bookings.partySize == 3)
    precondition(bookings.preferredBookingDateComponents?.hour == 19)
    precondition(bookings.maximumNumberOfResults?.intValue == 10)
    precondition(bookings.earliestBookingDateForResults == date)
    precondition(bookings.latestBookingDateForResults != nil)
    precondition(bookings.restaurant?.name == "Cafe")
    let booking = INRestaurantReservationBooking(
        restaurant: restaurant,
        bookingDate: date,
        partySize: 3,
        bookingIdentifier: "slot"
    )
    let bookingsResponse = INGetAvailableRestaurantReservationBookingsIntentResponse(
        availableBookings: [booking],
        code: .success,
        userActivity: nil
    )
    bookingsResponse.localizedBookingAdvisementText = "busy"
    bookingsResponse.localizedRestaurantDescriptionText = "bistro"
    bookingsResponse.termsAndConditions = INTermsAndConditions(
        localizedTermsAndConditionsText: "terms",
        privacyPolicyURL: nil,
        termsAndConditionsURL: nil
    )
    precondition(bookingsResponse.availableBookings.count == 1)
    precondition(bookingsResponse.code == .success)
    precondition(bookingsResponse.localizedBookingAdvisementText == "busy")
    precondition(bookingsResponse.localizedRestaurantDescriptionText == "bistro")
    precondition(bookingsResponse.termsAndConditions?.localizedTermsAndConditionsText == "terms")
    let current = INGetUserCurrentRestaurantReservationBookingsIntent(
        restaurant: restaurant,
        reservationIdentifier: "res-1",
        maximumNumberOfResults: NSNumber(value: 5),
        earliestBookingDateForResults: date
    )
    precondition(current.reservationIdentifier == "res-1")
    precondition(current.maximumNumberOfResults?.intValue == 5)
    precondition(current.earliestBookingDateForResults == date)
    precondition(current.restaurant?.name == "Cafe")
    let currentResponse = INGetUserCurrentRestaurantReservationBookingsIntentResponse(
        userCurrentBookings: [],
        code: .success,
        userActivity: nil
    )
    precondition(currentResponse.userCurrentBookings.isEmpty)
    precondition(currentResponse.code == .success)
}

func testSeatRadioWorkoutAndDefrosterIntents() {
    let carName = INSpeakableString(spokenPhrase: "Blue")
    let seat = INSetSeatSettingsInCarIntent(
        enableHeating: true,
        enableCooling: false,
        enableMassage: true,
        seat: .driver,
        level: 3,
        relativeLevel: .higher,
        carName: carName
    )
    precondition(seat.enableHeating == true)
    precondition(seat.enableCooling == false)
    precondition(seat.enableMassage == true)
    precondition(seat.seat == .driver)
    precondition(seat.level == 3)
    precondition(seat.relativeLevelSetting == .higher)
    precondition(seat.carName?.spokenPhrase == "Blue")
    let seatResponse = INSetSeatSettingsInCarIntentResponse(code: .success, userActivity: nil)
    precondition(seatResponse.code == .success)
    let radio = INSetRadioStationIntent(
        radioType: .FM,
        frequency: 101.1,
        stationName: "OpenFM",
        channel: "3",
        presetNumber: 2
    )
    precondition(radio.radioType == .FM)
    precondition(radio.frequency == 101.1)
    precondition(radio.stationName == "OpenFM")
    precondition(radio.channel == "3")
    precondition(radio.presetNumber == 2)
    let radioResponse = INSetRadioStationIntentResponse(code: .success, userActivity: nil)
    precondition(radioResponse.code == .success)
    let workout = INStartWorkoutIntent(
        workoutName: INSpeakableString(spokenPhrase: "Run"),
        goalValue: 5,
        workoutGoalUnitType: .mile,
        workoutLocationType: .outdoor,
        isOpenEnded: false
    )
    precondition(workout.workoutName?.spokenPhrase == "Run")
    precondition(workout.goalValue == 5)
    precondition(workout.workoutGoalUnitType == .mile)
    precondition(workout.workoutLocationType == .outdoor)
    precondition(workout.isOpenEnded == false)
    let workoutResponse = INStartWorkoutIntentResponse(code: .continueInApp, userActivity: nil)
    precondition(workoutResponse.code == .continueInApp)
    let defroster = INSetDefrosterSettingsInCarIntent(enable: true, defroster: .front, carName: carName)
    precondition(defroster.enable == true)
    precondition(defroster.defroster == .front)
    precondition(defroster.carName?.spokenPhrase == "Blue")
    let defrosterResponse = INSetDefrosterSettingsInCarIntentResponse(code: .success, userActivity: nil)
    precondition(defrosterResponse.code == .success)
}

func testRequestAndSendPaymentIntentProperties() {
    let person = wave10Person()
    let amount = INCurrencyAmount(amount: NSDecimalNumber(value: 9), currencyCode: "USD")
    let request = INRequestPaymentIntent(payer: person, currencyAmount: amount, note: "coffee")
    precondition(request.payer?.displayName == "Ada")
    precondition(request.currencyAmount?.currencyCode == "USD")
    precondition(request.note == "coffee")
    let requestResponse = INRequestPaymentIntentResponse(code: .success, userActivity: nil)
    precondition(requestResponse.code == .success)
    let send = INSendPaymentIntent(payee: person, currencyAmount: amount, note: "thanks")
    precondition(send.payee?.displayName == "Ada")
    precondition(send.note == "thanks")
    let sendResponse = INSendPaymentIntentResponse(code: .success, userActivity: nil)
    precondition(sendResponse.code == .success)
}

func testRecurrenceRuleConstruction() {
    let daily = INRecurrenceRule(interval: 1, frequency: .daily)
    precondition(daily.interval == 1)
    precondition(daily.frequency == .daily)
    let weekly = INRecurrenceRule(interval: 2, frequency: .weekly, weeklyRecurrenceDays: [.monday, .friday])
    precondition(weekly.weeklyRecurrenceDays.contains(.monday))
}

func testMediaDestinationOverlayDescriptions() {
    let library = INMediaDestination.library
    precondition(library.description == "library")
    precondition(library.debugDescription.contains("library"))
    let playlist = INMediaDestination.playlist("Mix")
    precondition(playlist.description == "playlist:Mix")
}

func testOptionSetAlgebraCallRecordType() {
    wave10ExerciseOptionSet(INCallRecordTypeOptions.outgoing, .missed)
    let success = INCallRecordTypeOptionsResolutionResult.success(with: [.outgoing, .missed])
    precondition(success.outcome == .success)
    let confirm = INCallRecordTypeOptionsResolutionResult.confirmationRequired(with: [.voicemail])
    precondition(confirm.outcome == .confirmationRequired)
}

func testOptionSetAlgebraCarSignal() {
    wave10ExerciseOptionSet(INCarSignalOptions.audible, .visible)
}

func testOptionSetAlgebraDayOfWeek() {
    wave10ExerciseOptionSet(INDayOfWeekOptions.monday, .friday)
}

func testOptionSetAlgebraMessageAttribute() {
    wave10ExerciseOptionSet(INMessageAttributeOptions.read, .unread)
}

func testOptionSetAlgebraPhotoAttribute() {
    wave10ExerciseOptionSet(INPhotoAttributeOptions.photo, .video)
}

func testOptionSetAlgebraRideFeedback() {
    wave10ExerciseOptionSet(INRideFeedbackTypeOptions.rate, .tip)
}

func testOptionSetAlgebraShortcutAvailability() {
    wave10ExerciseOptionSet(INShortcutAvailabilityOptions.sleepMusic, .sleepReading)
}

func testOptionSetAlgebraTemporalEventTrigger() {
    wave10ExerciseOptionSet(INTemporalEventTriggerTypeOptions.notScheduled, .scheduledRecurring)
    let success = INTemporalEventTriggerTypeOptionsResolutionResult.success(with: [.scheduledRecurring])
    precondition(success.outcome == .success)
    let confirm = INTemporalEventTriggerTypeOptionsResolutionResult.confirmationRequired(with: [.notScheduled])
    precondition(confirm.outcome == .confirmationRequired)
}

func testOptionSetAlgebraCallCapability() {
    wave10ExerciseOptionSet(INCallCapabilityOptions.audioCall, .videoCall)
}

func testNotebookWorkoutRecipientResolutionResults() {
    let notebookSuccess = INNotebookItemTypeResolutionResult.success(with: .note)
    precondition(notebookSuccess.outcome == .success)
    let notebookConfirm = INNotebookItemTypeResolutionResult.confirmationRequired(with: .task)
    precondition(notebookConfirm.outcome == .confirmationRequired)
    let notebookDisambiguation = INNotebookItemTypeResolutionResult.disambiguation(with: [.note, .taskList])
    precondition(notebookDisambiguation.outcome == .disambiguation)
    let recipientUnsupported = INSendMessageRecipientResolutionResult.unsupported(forReason: .noAccount)
    precondition(recipientUnsupported.outcome == .unsupported)
    let recipientWrapped = INSendMessageRecipientResolutionResult(personResolutionResult: INPersonResolutionResult.needsValue())
    precondition(recipientWrapped.outcome == .needsValue)
    let goalSuccess = INWorkoutGoalUnitTypeResolutionResult.success(with: .mile)
    precondition(goalSuccess.outcome == .success)
    let goalConfirm = INWorkoutGoalUnitTypeResolutionResult.confirmationRequired(with: .minute)
    precondition(goalConfirm.outcome == .confirmationRequired)
    let locationSuccess = INWorkoutLocationTypeResolutionResult.success(with: .outdoor)
    precondition(locationSuccess.outcome == .success)
    let locationConfirm = INWorkoutLocationTypeResolutionResult.confirmationRequired(with: .indoor)
    precondition(locationConfirm.outcome == .confirmationRequired)
}

private final class Wave10ProfileHandler: NSObject, INSetProfileInCarIntentHandling {
    func handle(intent: INSetProfileInCarIntent, completion: @escaping (INSetProfileInCarIntentResponse) -> Void) {
        completion(INSetProfileInCarIntentResponse(code: .success, userActivity: nil))
    }
    func resolveProfileName(for intent: INSetProfileInCarIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.success(with: intent.profileName ?? ""))
    }
}

private final class Wave10PlayHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
        completion(INPlayMediaIntentResponse(code: .success, userActivity: nil))
    }
    func resolvePlayShuffled(for intent: INPlayMediaIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.success(with: intent.playShuffled ?? false))
    }
}

private final class Wave10RequestPaymentHandler: NSObject, INRequestPaymentIntentHandling {
    func handle(intent: INRequestPaymentIntent, completion: @escaping (INRequestPaymentIntentResponse) -> Void) {
        completion(INRequestPaymentIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10SendPaymentHandler: NSObject, INSendPaymentIntentHandling {
    func handle(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        completion(INSendPaymentIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10SeatHandler: NSObject, INSetSeatSettingsInCarIntentHandling {
    func handle(intent: INSetSeatSettingsInCarIntent, completion: @escaping (INSetSeatSettingsInCarIntentResponse) -> Void) {
        completion(INSetSeatSettingsInCarIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10RadioHandler: NSObject, INSetRadioStationIntentHandling {
    func handle(intent: INSetRadioStationIntent, completion: @escaping (INSetRadioStationIntentResponse) -> Void) {
        completion(INSetRadioStationIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10WorkoutHandler: NSObject, INStartWorkoutIntentHandling {
    func handle(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        completion(INStartWorkoutIntentResponse(code: .continueInApp, userActivity: nil))
    }
}

private final class Wave10NoteHandler: NSObject, INCreateNoteIntentHandling {
    func handle(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Void) {
        completion(INCreateNoteIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10TaskListHandler: NSObject, INCreateTaskListIntentHandling {
    func handle(intent: INCreateTaskListIntent, completion: @escaping (INCreateTaskListIntentResponse) -> Void) {
        completion(INCreateTaskListIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10DeleteTasksHandler: NSObject, INDeleteTasksIntentHandling {
    func handle(intent: INDeleteTasksIntent, completion: @escaping (INDeleteTasksIntentResponse) -> Void) {
        completion(INDeleteTasksIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10DefrosterHandler: NSObject, INSetDefrosterSettingsInCarIntentHandling {
    func handle(intent: INSetDefrosterSettingsInCarIntent, completion: @escaping (INSetDefrosterSettingsInCarIntentResponse) -> Void) {
        completion(INSetDefrosterSettingsInCarIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10DefaultsHandler: NSObject, INGetAvailableRestaurantReservationBookingDefaultsIntentHandling {
    func handle(
        getAvailableRestaurantReservationBookingDefaults intent: INGetAvailableRestaurantReservationBookingDefaultsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingDefaultsIntentResponse) -> Void
    ) {
        completion(INGetAvailableRestaurantReservationBookingDefaultsIntentResponse())
    }
}

private final class Wave10BookingsHandler: NSObject, INGetAvailableRestaurantReservationBookingsIntentHandling {
    func handle(
        getAvailableRestaurantReservationBookings intent: INGetAvailableRestaurantReservationBookingsIntent,
        completion: @escaping (INGetAvailableRestaurantReservationBookingsIntentResponse) -> Void
    ) {
        completion(INGetAvailableRestaurantReservationBookingsIntentResponse())
    }
}

private final class Wave10CurrentBookingsHandler: NSObject, INGetUserCurrentRestaurantReservationBookingsIntentHandling {
    func handle(
        getUserCurrentRestaurantReservationBookings intent: INGetUserCurrentRestaurantReservationBookingsIntent,
        completion: @escaping (INGetUserCurrentRestaurantReservationBookingsIntentResponse) -> Void
    ) {
        completion(INGetUserCurrentRestaurantReservationBookingsIntentResponse())
    }
}

private final class Wave10AddMediaHandler: NSObject, INAddMediaIntentHandling {
    func handle(intent: INAddMediaIntent, completion: @escaping (INAddMediaIntentResponse) -> Void) {
        completion(INAddMediaIntentResponse(code: .success, userActivity: nil))
    }
}

private final class Wave10SearchMessagesHandler: NSObject, INSearchForMessagesIntentHandling {
    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        completion(INSearchForMessagesIntentResponse(code: .success, userActivity: nil))
    }
    func resolveRecipients(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion((intent.recipients ?? []).map { INPersonResolutionResult.success(with: $0) })
    }
    func resolveSenders(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion((intent.senders ?? []).map { INPersonResolutionResult.success(with: $0) })
    }
    func resolveSpeakableGroupNames(for intent: INSearchForMessagesIntent, with completion: @escaping ([INSpeakableStringResolutionResult]) -> Void) {
        completion((intent.speakableGroupNames ?? []).map { INSpeakableStringResolutionResult.success(with: $0) })
    }
    func resolveGroupNames(for intent: INSearchForMessagesIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
        completion((intent.groupNames ?? []).map { INStringResolutionResult.success(with: $0) })
    }
}

func testSetProfileHandlerDispatch() {
    let handler = Wave10ProfileHandler()
    let intent = INSetProfileInCarIntent(profileName: "Ada", defaultProfile: 1)
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INSetProfileInCarIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INSetProfileInCarIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(!resolved.isEmpty)
}

func testPlayMediaHandlerDispatch() {
    let handler = Wave10PlayHandler()
    let intent = INPlayMediaIntent()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INPlayMediaIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INPlayMediaIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(!resolved.isEmpty)
}

func testRequestPaymentHandlerDispatch() {
    let handler = Wave10RequestPaymentHandler()
    let intent = INRequestPaymentIntent()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INRequestPaymentIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INRequestPaymentIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(!resolved.isEmpty)
}

func testSendPaymentHandlerDispatch() {
    let handler = Wave10SendPaymentHandler()
    let intent = INSendPaymentIntent()
    let handled = INHostIntentDispatcher.handle(intent, handler: handler) as? INSendPaymentIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(intent, handler: handler) as? INSendPaymentIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(intent, handler: handler)
    precondition(!resolved.isEmpty)
}

func testSeatRadioWorkoutDefrosterDispatch() {
    let seatHandled = INHostIntentDispatcher.handle(INSetSeatSettingsInCarIntent(), handler: Wave10SeatHandler()) as? INSetSeatSettingsInCarIntentResponse
    precondition(seatHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INSetSeatSettingsInCarIntent(), handler: Wave10SeatHandler())
    _ = INHostIntentDispatcher.resolve(INSetSeatSettingsInCarIntent(), handler: Wave10SeatHandler())
    let radioHandled = INHostIntentDispatcher.handle(INSetRadioStationIntent(), handler: Wave10RadioHandler()) as? INSetRadioStationIntentResponse
    precondition(radioHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INSetRadioStationIntent(), handler: Wave10RadioHandler())
    _ = INHostIntentDispatcher.resolve(INSetRadioStationIntent(), handler: Wave10RadioHandler())
    let workoutHandled = INHostIntentDispatcher.handle(INStartWorkoutIntent(), handler: Wave10WorkoutHandler()) as? INStartWorkoutIntentResponse
    precondition(workoutHandled?.code == .continueInApp)
    _ = INHostIntentDispatcher.confirm(INStartWorkoutIntent(), handler: Wave10WorkoutHandler())
    _ = INHostIntentDispatcher.resolve(INStartWorkoutIntent(), handler: Wave10WorkoutHandler())
    let defrosterHandled = INHostIntentDispatcher.handle(INSetDefrosterSettingsInCarIntent(), handler: Wave10DefrosterHandler()) as? INSetDefrosterSettingsInCarIntentResponse
    precondition(defrosterHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INSetDefrosterSettingsInCarIntent(), handler: Wave10DefrosterHandler())
    _ = INHostIntentDispatcher.resolve(INSetDefrosterSettingsInCarIntent(), handler: Wave10DefrosterHandler())
}

func testNoteTaskListDeleteAndRestaurantDispatch() {
    let noteHandled = INHostIntentDispatcher.handle(INCreateNoteIntent(), handler: Wave10NoteHandler()) as? INCreateNoteIntentResponse
    precondition(noteHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INCreateNoteIntent(), handler: Wave10NoteHandler())
    _ = INHostIntentDispatcher.resolve(INCreateNoteIntent(), handler: Wave10NoteHandler())
    let listHandled = INHostIntentDispatcher.handle(INCreateTaskListIntent(), handler: Wave10TaskListHandler()) as? INCreateTaskListIntentResponse
    precondition(listHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INCreateTaskListIntent(), handler: Wave10TaskListHandler())
    _ = INHostIntentDispatcher.resolve(INCreateTaskListIntent(), handler: Wave10TaskListHandler())
    let deleteHandled = INHostIntentDispatcher.handle(INDeleteTasksIntent(), handler: Wave10DeleteTasksHandler()) as? INDeleteTasksIntentResponse
    precondition(deleteHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(INDeleteTasksIntent(), handler: Wave10DeleteTasksHandler())
    _ = INHostIntentDispatcher.resolve(INDeleteTasksIntent(), handler: Wave10DeleteTasksHandler())
    let defaultsHandled = INHostIntentDispatcher.handle(
        INGetAvailableRestaurantReservationBookingDefaultsIntent(),
        handler: Wave10DefaultsHandler()
    )
    _ = defaultsHandled
    _ = INHostIntentDispatcher.confirm(
        INGetAvailableRestaurantReservationBookingDefaultsIntent(),
        handler: Wave10DefaultsHandler()
    )
    _ = INHostIntentDispatcher.resolve(
        INGetAvailableRestaurantReservationBookingDefaultsIntent(),
        handler: Wave10DefaultsHandler()
    )
    let restaurant = INRestaurant()
    restaurant.name = "Cafe"
    let bookingsIntent = INGetAvailableRestaurantReservationBookingsIntent(
        restaurant: restaurant,
        partySize: 2,
        preferredBookingDateComponents: nil,
        maximumNumberOfResults: nil,
        earliestBookingDateForResults: nil,
        latestBookingDateForResults: nil
    )
    _ = INHostIntentDispatcher.handle(bookingsIntent, handler: Wave10BookingsHandler())
    _ = INHostIntentDispatcher.confirm(bookingsIntent, handler: Wave10BookingsHandler())
    _ = INHostIntentDispatcher.resolve(bookingsIntent, handler: Wave10BookingsHandler())
    let currentIntent = INGetUserCurrentRestaurantReservationBookingsIntent(
        restaurant: restaurant,
        reservationIdentifier: "res-1",
        maximumNumberOfResults: NSNumber(value: 5),
        earliestBookingDateForResults: nil
    )
    _ = INHostIntentDispatcher.handle(currentIntent, handler: Wave10CurrentBookingsHandler())
    _ = INHostIntentDispatcher.confirm(currentIntent, handler: Wave10CurrentBookingsHandler())
    _ = INHostIntentDispatcher.resolve(currentIntent, handler: Wave10CurrentBookingsHandler())
    let addMedia = INAddMediaIntent()
    let addHandled = INHostIntentDispatcher.handle(addMedia, handler: Wave10AddMediaHandler()) as? INAddMediaIntentResponse
    precondition(addHandled?.code == .success)
    _ = INHostIntentDispatcher.confirm(addMedia, handler: Wave10AddMediaHandler())
    _ = INHostIntentDispatcher.resolve(addMedia, handler: Wave10AddMediaHandler())
}

func testSearchForMessagesRemainingResolveDispatch() {
    let person = wave10Person()
    let intent = INSearchForMessagesIntent(
        recipients: [person],
        senders: [person],
        searchTerms: ["hi"],
        attributes: [.unread],
        dateTimeRange: nil,
        identifiers: nil,
        notificationIdentifiers: nil,
        groupNames: ["Team"]
    )
    let resolved = INHostIntentDispatcher.resolve(intent, handler: Wave10SearchMessagesHandler())
    precondition(resolved.count >= 4)
}
