import Foundation
@_spi(OpenIntentsHost) import Intents

private func depthArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
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

private final class DepthSendHandler: NSObject, INSendMessageIntentHandling {
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        completion(INSendMessageIntentResponse(code: .success, userActivity: nil))
    }

    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        completion(INSendMessageIntentResponse(code: .ready, userActivity: nil))
    }

    func resolveContent(for intent: INSendMessageIntent, completion: @escaping (INStringResolutionResult) -> Void) {
        completion(INStringResolutionResult.success(with: intent.content ?? ""))
    }

    func resolveSpeakableGroupName(
        for intent: INSendMessageIntent,
        completion: @escaping (INSpeakableStringResolutionResult) -> Void
    ) {
        if let name = intent.speakableGroupName {
            completion(INSpeakableStringResolutionResult.success(with: name))
        } else {
            completion(INSpeakableStringResolutionResult.notRequired())
        }
    }
}

private final class DepthSearchHandler: NSObject, INSearchForMessagesIntentHandling {
    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        let response = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)
        response.messages = []
        completion(response)
    }

    func confirm(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        completion(INSearchForMessagesIntentResponse(code: .ready, userActivity: nil))
    }

    func resolveAttributes(
        for intent: INSearchForMessagesIntent,
        completion: @escaping (INMessageAttributeOptionsResolutionResult) -> Void
    ) {
        completion(INMessageAttributeOptionsResolutionResult.success(with: intent.attributes))
    }

    func resolveDateTimeRange(
        for intent: INSearchForMessagesIntent,
        completion: @escaping (INDateComponentsRangeResolutionResult) -> Void
    ) {
        completion(INDateComponentsRangeResolutionResult.needsValue())
    }
}

private final class DepthStartCallHandler: NSObject, INStartCallIntentHandling {
    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        completion(INStartCallIntentResponse(code: .continueInApp, userActivity: nil))
    }

    func confirm(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        completion(INStartCallIntentResponse(code: .ready, userActivity: nil))
    }

    func resolveCallCapability(
        for intent: INStartCallIntent,
        completion: @escaping (INStartCallCallCapabilityResolutionResult) -> Void
    ) {
        completion(
            INStartCallCallCapabilityResolutionResult(
                callCapabilityResolutionResult: .success(with: intent.callCapability)
            )
        )
    }

    func resolveDestinationType(
        for intent: INStartCallIntent,
        completion: @escaping (INCallDestinationTypeResolutionResult) -> Void
    ) {
        completion(INCallDestinationTypeResolutionResult.success(with: intent.destinationType))
    }
}

private final class DepthCarPowerHandler: NSObject, INGetCarPowerLevelStatusIntentHandling {
    func handle(intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INGetCarPowerLevelStatusIntentResponse) -> Void) {
        let response = INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil)
        response.carIdentifier = "none"
        completion(response)
    }

    func confirm(intent: INGetCarPowerLevelStatusIntent, completion: @escaping (INGetCarPowerLevelStatusIntentResponse) -> Void) {
        completion(INGetCarPowerLevelStatusIntentResponse(code: .ready, userActivity: nil))
    }

    func resolveCarName(
        for intent: INGetCarPowerLevelStatusIntent,
        completion: @escaping (INSpeakableStringResolutionResult) -> Void
    ) {
        if let name = intent.carName {
            completion(INSpeakableStringResolutionResult.success(with: name))
        } else {
            completion(INSpeakableStringResolutionResult.needsValue())
        }
    }
}

private final class DepthRideStatusHandler: NSObject, INGetRideStatusIntentHandling {
    func handle(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        completion(INGetRideStatusIntentResponse(code: .failure, userActivity: nil))
    }

    func confirm(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        completion(INGetRideStatusIntentResponse(code: .ready, userActivity: nil))
    }
}

private final class DepthListRideHandler: NSObject, INListRideOptionsIntentHandling {
    func handle(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        completion(INListRideOptionsIntentResponse(code: .failure, userActivity: nil))
    }

    func confirm(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        completion(INListRideOptionsIntentResponse(code: .ready, userActivity: nil))
    }
}

private final class DepthRequestRideHandler: NSObject, INRequestRideIntentHandling {
    func handle(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        completion(INRequestRideIntentResponse(code: .failure, userActivity: nil))
    }

    func confirm(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        completion(INRequestRideIntentResponse(code: .ready, userActivity: nil))
    }

    func resolvePartySize(
        for intent: INRequestRideIntent,
        completion: @escaping (INIntegerResolutionResult) -> Void
    ) {
        completion(INIntegerResolutionResult.needsValue())
    }

    func resolveRideOptionName(
        for intent: INRequestRideIntent,
        completion: @escaping (INSpeakableStringResolutionResult) -> Void
    ) {
        if let name = intent.rideOptionName {
            completion(INSpeakableStringResolutionResult.success(with: name))
        } else {
            completion(INSpeakableStringResolutionResult.needsValue())
        }
    }

    func resolveScheduledPickupTime(
        for intent: INRequestRideIntent,
        completion: @escaping (INDateComponentsRangeResolutionResult) -> Void
    ) {
        completion(INDateComponentsRangeResolutionResult.notRequired())
    }
}

func testVocabularySetAndRemove() {
    let vocabulary = INVocabulary.shared()
    vocabulary.removeAllVocabularyStrings()
    vocabulary.setVocabularyStrings(NSOrderedSet(array: ["Ada", "Lin"]), of: .contactName)
    precondition(vocabulary.strings(of: .contactName) == ["Ada", "Lin"])
    vocabulary.setVocabulary(NSOrderedSet(array: ["Library"]), of: .contactGroupName)
    precondition(vocabulary.strings(of: .contactGroupName) == ["Library"])
    vocabulary.removeAllVocabularyStrings()
    precondition(vocabulary.strings(of: .contactName).isEmpty)
    precondition(INVocabulary.shared() === vocabulary)
}

func testResolutionResultExactCodes() {
    precondition(INIntentResolutionResultOutcome.needsValue.rawValue == 0)
    precondition(INIntentResolutionResultOutcome.notRequired.rawValue == 1)
    precondition(INIntentResolutionResultOutcome.unsupported.rawValue == 2)
    precondition(INIntentResolutionResultOutcome.success.rawValue == 3)
    precondition(INIntentResolutionResultOutcome.disambiguation.rawValue == 4)
    precondition(INIntentResolutionResultOutcome.confirmationRequired.rawValue == 5)

    let stringSuccess = INStringResolutionResult.success(with: "portable")
    precondition(stringSuccess.outcome == .success)
    precondition(stringSuccess.linuxOutcomeCode == 3)
    precondition(stringSuccess.resolvedValue as? String == "portable")
    let stringDisambiguate = INStringResolutionResult.disambiguation(with: ["a", "b"])
    precondition(stringDisambiguate.outcome == .disambiguation)
    precondition(stringDisambiguate.linuxOutcomeCode == 4)
    let stringConfirm = INStringResolutionResult.confirmationRequired(with: "maybe")
    precondition(stringConfirm.outcome == .confirmationRequired)
    let stringNeeds = INStringResolutionResult.needsValue()
    precondition(stringNeeds.outcome == .needsValue)
    let stringUnsupported = INStringResolutionResult.unsupported()
    precondition(stringUnsupported.outcome == .unsupported)
    let stringNotRequired = INStringResolutionResult.notRequired()
    precondition(stringNotRequired.outcome == .notRequired)

    let integerSuccess = INIntegerResolutionResult.success(with: 7)
    precondition(integerSuccess.outcome == .success)
    precondition(integerSuccess.resolvedValue as? Int == 7)
    let integerConfirm = INIntegerResolutionResult.confirmationRequired(with: Optional<Int>.some(8))
    precondition(integerConfirm.outcome == .confirmationRequired)
    precondition(integerConfirm.resolvedValue as? Int == 8)
    precondition(INIntegerResolutionResult.needsValue().outcome == .needsValue)
    precondition(INIntegerResolutionResult.unsupported().outcome == .unsupported)
    precondition(INIntegerResolutionResult.notRequired().outcome == .notRequired)
    precondition(INIntentResolutionResult.needsValue().outcome == .needsValue)
    precondition(INIntentResolutionResult.notRequired().outcome == .notRequired)
    precondition(INIntentResolutionResult.unsupported().outcome == .unsupported)

    var start = DateComponents()
    start.year = 2026
    var end = DateComponents()
    end.year = 2027
    let range = INDateComponentsRange(start: start, end: end)
    let rangeSuccess = INDateComponentsRangeResolutionResult.success(with: range)
    precondition(rangeSuccess.outcome == .success)
    precondition((rangeSuccess.resolvedValue as? INDateComponentsRange)?.startDateComponents?.year == 2026)
    let rangeDisambiguate = INDateComponentsRangeResolutionResult.disambiguation(with: [range])
    precondition(rangeDisambiguate.outcome == .disambiguation)
    let rangeConfirm = INDateComponentsRangeResolutionResult.confirmationRequired(with: range)
    precondition(rangeConfirm.outcome == .confirmationRequired)
    precondition(INDateComponentsRangeResolutionResult.needsValue().outcome == .needsValue)
    precondition(INDateComponentsRangeResolutionResult.unsupported().outcome == .unsupported)
    precondition(INDateComponentsRangeResolutionResult.notRequired().outcome == .notRequired)

    let handle = INPersonHandle(value: "ada@example.com", type: .emailAddress)
    let person = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil
    )
    let personSuccess = INPersonResolutionResult.success(with: person)
    precondition(personSuccess.outcome == .success)
    let personDisambiguate = INPersonResolutionResult.disambiguation(with: [person])
    precondition(personDisambiguate.outcome == .disambiguation)
    let personConfirm = INPersonResolutionResult.confirmationRequired(with: person)
    precondition(personConfirm.outcome == .confirmationRequired)
    precondition(INPersonResolutionResult.needsValue().outcome == .needsValue)
    precondition(INPersonResolutionResult.unsupported().outcome == .unsupported)
    precondition(INPersonResolutionResult.notRequired().outcome == .notRequired)
}

func testINMessagePropertiesAndCoding() {
    let handle = INPersonHandle(value: "ada@example.com", type: .emailAddress)
    let person = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil
    )
    let spoken = INSpeakableString(spokenPhrase: "Team")
    let message = INMessage(
        identifier: "m1",
        conversationIdentifier: "c1",
        content: "Hello",
        dateSent: Date(timeIntervalSince1970: 0),
        sender: person,
        recipients: [person],
        groupName: spoken,
        messageType: .text,
        serviceName: "iMessage"
    )
    precondition(message.identifier == "m1")
    precondition(message.content == "Hello")
    precondition(message.conversationIdentifier == "c1")
    precondition(message.serviceName == "iMessage")
    precondition(message.messageType == .text)
    precondition(message.dateSent == Date(timeIntervalSince1970: 0))
    precondition(message.groupName?.spokenPhrase == "Team")
    precondition(message.recipients?.count == 1)
    precondition(message.sender?.displayName == "Ada")
    precondition(INMessageAttribute.unread.rawValue == 2)
    precondition(INMessageAttribute.flagged.rawValue == 3)
    let restored = depthArchiveRoundTrip(message)
    precondition(restored.identifier == "m1")
    precondition(restored.content == "Hello")
    precondition(INMessage.supportsSecureCoding)
    let reaction = INMessageReaction(reactionType: .emoji, reactionDescription: "like", emoji: "👍")
    precondition(reaction.emoji == "👍")
    let restoredReaction = depthArchiveRoundTrip(reaction)
    precondition(restoredReaction.emoji == "👍")
    let metadata = INMessageLinkMetadata(
        siteName: "Example",
        summary: "Sum",
        title: "Title",
        openGraphType: "article",
        linkURL: URL(fileURLWithPath: "/tmp/link")
    )
    precondition(metadata.siteName == "Example")
    let restoredMeta = depthArchiveRoundTrip(metadata)
    precondition(restoredMeta.title == "Title")
}

func testIntentSubclassPropertiesAndResponses() {
    let handle = INPersonHandle(value: "ada@example.com", type: .emailAddress)
    let person = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil
    )
    let spoken = INSpeakableString(spokenPhrase: "Team")
    let search = INSearchForMessagesIntent(
        recipients: [person],
        senders: [person],
        searchTerms: ["hello"],
        attributes: [.unread],
        dateTimeRange: nil,
        identifiers: ["m1"],
        notificationIdentifiers: ["n1"],
        speakableGroupNames: [spoken],
        conversationIdentifiers: ["c1"]
    )
    precondition(search.recipients?.count == 1)
    precondition(search.senders?.count == 1)
    precondition(search.searchTerms == ["hello"])
    precondition(search.attributes.contains(.unread))
    precondition(search.identifiers == ["m1"])
    precondition(search.notificationIdentifiers == ["n1"])
    precondition(search.conversationIdentifiers == ["c1"])
    precondition(search.speakableGroupNames?.first?.spokenPhrase == "Team")
    let activity = NSUserActivity(activityType: "com.openuikit.intents.search")
    let searchResponse = INSearchForMessagesIntentResponse(code: .success, userActivity: activity)
    searchResponse.messages = []
    precondition(searchResponse.code == .success)
    precondition(searchResponse.messages?.isEmpty == true)
    precondition(searchResponse.userActivity?.activityType == "com.openuikit.intents.search")
    let restoredResponse = depthArchiveRoundTrip(searchResponse)
    precondition(restoredResponse.userActivity?.activityType == "com.openuikit.intents.search")

    let send = INSendMessageIntent(
        recipients: [person],
        outgoingMessageType: .outgoingMessageText,
        content: "Hello",
        speakableGroupName: spoken,
        conversationIdentifier: "c1",
        serviceName: "iMessage",
        sender: person
    )
    precondition(send.content == "Hello")
    precondition(send.recipients?.count == 1)
    precondition(send.speakableGroupName?.spokenPhrase == "Team")
    precondition(send.conversationIdentifier == "c1")
    precondition(send.serviceName == "iMessage")
    precondition(send.sender?.displayName == "Ada")
    precondition(send.outgoingMessageType == .outgoingMessageText)
    let sendResponse = INSendMessageIntentResponse(code: .failure, userActivity: nil)
    precondition(sendResponse.code == .failure)

    let start = INStartCallIntent(
        callRecordFilter: nil,
        callRecordToCallBack: nil,
        audioRoute: .speakerphoneAudioRoute,
        destinationType: .normal,
        contacts: [person],
        callCapability: .audioCall
    )
    precondition(start.contacts?.count == 1)
    precondition(start.audioRoute == .speakerphoneAudioRoute)
    precondition(start.destinationType == .normal)
    precondition(start.callCapability == .audioCall)
    let startResponse = INStartCallIntentResponse(code: .continueInApp, userActivity: activity)
    precondition(startResponse.code == .continueInApp)
    precondition(startResponse.userActivity === activity)
}

func testCarPowerAndRideFailClosed() {
    let carName = INSpeakableString(spokenPhrase: "Red")
    let carIntent = INGetCarPowerLevelStatusIntent(carName: carName)
    precondition(carIntent.carName?.spokenPhrase == "Red")
    let carResponse = INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil)
    precondition(carResponse.code == .failure)
    carResponse.carIdentifier = "vin-1"
    carResponse.chargePercentRemaining = 0.4
    carResponse.fuelPercentRemaining = 0.2
    carResponse.charging = false
    precondition(carResponse.carIdentifier == "vin-1")
    precondition(carResponse.chargePercentRemaining == 0.4)
    precondition(carResponse.fuelPercentRemaining == 0.2)
    precondition(carResponse.charging == false)

    let rideStatus = INGetRideStatusIntent()
    let rideResponse = INGetRideStatusIntentResponse(code: .failure, userActivity: nil)
    precondition(rideResponse.code == .failure)
    let status = INRideStatus()
    status.rideIdentifier = "ride-1"
    rideResponse.rideStatus = status
    precondition(rideResponse.rideStatus?.rideIdentifier == "ride-1")
    let restoredStatus = depthArchiveRoundTrip(status)
    precondition(restoredStatus.rideIdentifier == "ride-1")

    let listResponse = INListRideOptionsIntentResponse(code: .failure, userActivity: nil)
    precondition(listResponse.code == .failure)
    let option = INRideOption(name: "Pool", estimatedPickupDate: Date(timeIntervalSince1970: 0))
    precondition(option.name == "Pool")
    precondition(depthArchiveRoundTrip(option).name == "Pool")
    let statusPhase = INRideStatus()
    statusPhase.phase = .unknown
    precondition(statusPhase.phase == .unknown)
    let request = INRequestRideIntent()
    request.rideOptionName = carName
    precondition(request.rideOptionName?.spokenPhrase == "Red")
    let requestResponse = INRequestRideIntentResponse(code: .failure, userActivity: nil)
    precondition(requestResponse.code == .failure)
    let completed = INRideCompletionStatus.completed()
    precondition(completed.isCompleted)
    precondition(!completed.isCanceled)
    let canceled = INRideCompletionStatus.canceledByService()
    precondition(canceled.isCanceled)
    let restoredCompletion = depthArchiveRoundTrip(completed)
    precondition(restoredCompletion.isCompleted)
    _ = rideStatus
}

func testHostDispatcherRoutesHandlers() {
    let handle = INPersonHandle(value: "ada@example.com", type: .emailAddress)
    let person = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil
    )
    let send = INSendMessageIntent(
        recipients: [person],
        content: "Hello",
        speakableGroupName: nil,
        conversationIdentifier: "c1",
        serviceName: "iMessage",
        sender: person
    )
    let sendHandler = DepthSendHandler()
    let handled = INHostIntentDispatcher.handle(send, handler: sendHandler) as? INSendMessageIntentResponse
    precondition(handled?.code == .success)
    let confirmed = INHostIntentDispatcher.confirm(send, handler: sendHandler) as? INSendMessageIntentResponse
    precondition(confirmed?.code == .ready)
    let resolved = INHostIntentDispatcher.resolve(send, handler: sendHandler)
    precondition(resolved.contains { $0.outcome == .success })
    precondition(resolved.contains { $0.outcome == .notRequired })

    let search = INSearchForMessagesIntent()
    let searchHandler = DepthSearchHandler()
    let searchHandled = INHostIntentDispatcher.handle(search, handler: searchHandler) as? INSearchForMessagesIntentResponse
    precondition(searchHandled?.code == .success)
    let searchConfirmed = INHostIntentDispatcher.confirm(search, handler: searchHandler) as? INSearchForMessagesIntentResponse
    precondition(searchConfirmed?.code == .ready)
    let searchResolved = INHostIntentDispatcher.resolve(search, handler: searchHandler)
    precondition(searchResolved.contains { $0.outcome == .success })
    precondition(searchResolved.contains { $0.outcome == .needsValue })

    let start = INStartCallIntent(
        audioRoute: .unknown,
        destinationType: .unknown,
        contacts: [person],
        recordTypeForRedialing: .unknown,
        callCapability: .audioCall
    )
    let startHandler = DepthStartCallHandler()
    let startHandled = INHostIntentDispatcher.handle(start, handler: startHandler) as? INStartCallIntentResponse
    precondition(startHandled?.code == .continueInApp)
    let startConfirmed = INHostIntentDispatcher.confirm(start, handler: startHandler) as? INStartCallIntentResponse
    precondition(startConfirmed?.code == .ready)
    let startResolved = INHostIntentDispatcher.resolve(start, handler: startHandler)
    precondition(startResolved.count == 2)

    let carIntent = INGetCarPowerLevelStatusIntent()
    let carHandler = DepthCarPowerHandler()
    let carHandled = INHostIntentDispatcher.handle(carIntent, handler: carHandler) as? INGetCarPowerLevelStatusIntentResponse
    precondition(carHandled?.code == .failure)
    precondition(carHandled?.carIdentifier == "none")
    let carConfirmed = INHostIntentDispatcher.confirm(carIntent, handler: carHandler) as? INGetCarPowerLevelStatusIntentResponse
    precondition(carConfirmed?.code == .ready)
    let carResolved = INHostIntentDispatcher.resolve(carIntent, handler: carHandler)
    precondition(carResolved.first?.outcome == .needsValue)

    let rideIntent = INGetRideStatusIntent()
    let rideHandler = DepthRideStatusHandler()
    let rideHandled = INHostIntentDispatcher.handle(rideIntent, handler: rideHandler) as? INGetRideStatusIntentResponse
    precondition(rideHandled?.code == .failure)
    let rideConfirmed = INHostIntentDispatcher.confirm(rideIntent, handler: rideHandler) as? INGetRideStatusIntentResponse
    precondition(rideConfirmed?.code == .ready)

    let listIntent = INListRideOptionsIntent()
    let listHandler = DepthListRideHandler()
    let listHandled = INHostIntentDispatcher.handle(listIntent, handler: listHandler) as? INListRideOptionsIntentResponse
    precondition(listHandled?.code == .failure)
    let listConfirmed = INHostIntentDispatcher.confirm(listIntent, handler: listHandler) as? INListRideOptionsIntentResponse
    precondition(listConfirmed?.code == .ready)

    let requestIntent = INRequestRideIntent()
    let requestHandler = DepthRequestRideHandler()
    let requestHandled = INHostIntentDispatcher.handle(requestIntent, handler: requestHandler) as? INRequestRideIntentResponse
    precondition(requestHandled?.code == .failure)
    let requestConfirmed = INHostIntentDispatcher.confirm(requestIntent, handler: requestHandler) as? INRequestRideIntentResponse
    precondition(requestConfirmed?.code == .ready)
    let requestResolved = INHostIntentDispatcher.resolve(requestIntent, handler: requestHandler)
    precondition(requestResolved.contains { $0.outcome == .needsValue })
    precondition(requestResolved.contains { $0.outcome == .notRequired })

    let extensionPoint = INExtension()
    extensionPoint.hostHandler = sendHandler
    let routed = extensionPoint.handler(for: send)
    precondition((routed as AnyObject?) === sendHandler)
    let fallback = INExtension()
    precondition((fallback.handler(for: send) as AnyObject?) === fallback)
    let provider: any INIntentHandlerProviding = fallback
    precondition((provider.handler(for: send) as AnyObject?) === fallback)
}

func testInteractionHostStoreDateInterval() {
    INInteraction.deleteAll()
    let intent = INSearchForMessagesIntent()
    intent.identifier = "search-1"
    let response = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)
    let interaction = INInteraction(intent: intent, response: response)
    interaction.identifier = "interaction-depth"
    interaction.groupIdentifier = "group-depth"
    interaction.direction = .incoming
    interaction.dateInterval = DateInterval(start: Date(timeIntervalSince1970: 10), duration: 5)
    precondition(interaction.intent === intent)
    precondition(interaction.intentResponse === response)
    interaction.donate()
    precondition(INInteraction.donatedInteractions.count == 1)
    let restored = depthArchiveRoundTrip(interaction)
    precondition(restored.identifier == "interaction-depth")
    precondition(restored.groupIdentifier == "group-depth")
    precondition(restored.direction == .incoming)
    precondition(restored.dateInterval?.duration == 5)
    var error: Error? = NSError(domain: "unset", code: 1)
    INInteraction.delete(with: "group-depth") { error = $0 }
    precondition(error == nil)
    precondition(INInteraction.donatedInteractions.isEmpty)
}

func testShortcutAndVoiceCenterFailClosed() {
    INVoiceShortcutCenter.shared.removeAll()
    var observed: [INVoiceShortcut] = []
    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, error in
        observed = values ?? []
        precondition(error == nil)
    }
    precondition(observed.isEmpty)
    let intent = INIntent()
    intent.suggestedInvocationPhrase = "Erase"
    let shortcut = INShortcut(intent: intent)
    let restoredShortcut = depthArchiveRoundTrip(shortcut)
    precondition(restoredShortcut.intent?.suggestedInvocationPhrase == "Erase")
    let installed = INVoiceShortcutCenter.shared.install(shortcut, invocationPhrase: "Erase")
    let restoredVoice = depthArchiveRoundTrip(installed)
    precondition(restoredVoice.invocationPhrase == "Erase")
    precondition(INVoiceShortcut.supportsSecureCoding)
    var storeError: Error? = NSError(domain: "unset", code: 1)
    INRelevantShortcutStore.default.setRelevantShortcuts(
        [INRelevantShortcut(shortcut: shortcut)]
    ) { storeError = $0 }
    precondition(storeError == nil)
    precondition(INRelevantShortcutStore.default.storedShortcuts.count == 1)
    INRelevantShortcutStore.default.setRelevantShortcuts([]) { storeError = $0 }
    precondition(INRelevantShortcutStore.default.storedShortcuts.isEmpty)
}

func testNSCodingRoundTrips() {
    let airline = INAirline(name: "OpenAir", iataCode: "OA", icaoCode: "OAI")
    precondition(depthArchiveRoundTrip(airline).name == "OpenAir")
    let airport = INAirport(name: "SFO", iataCode: "SFO", icaoCode: "KSFO")
    precondition(depthArchiveRoundTrip(airport).iataCode == "SFO")
    let gate = INAirportGate(airport: airport, terminal: "2", gate: "G1")
    precondition(depthArchiveRoundTrip(gate).gate == "G1")
    _ = depthArchiveRoundTrip(INBalanceAmount())
    precondition(INBalanceAmount.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INBillDetails())
    precondition(INBillDetails.supportsSecureCoding)
    let payee = INBillPayee()
    payee.accountNumber = "123"
    precondition(depthArchiveRoundTrip(payee).accountNumber == "123")
    _ = depthArchiveRoundTrip(INBoatTrip())
    precondition(INBoatTrip.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INBusTrip())
    precondition(INBusTrip.supportsSecureCoding)
    let group = INCallGroup(groupName: "Team", groupId: "g1")
    precondition(depthArchiveRoundTrip(group).groupId == "g1")
    let record = INCallRecord(identifier: "call-1")
    precondition(depthArchiveRoundTrip(record).identifier == "call-1")
    _ = depthArchiveRoundTrip(INCallRecordFilter(participants: nil, callTypes: [], callCapability: .unknown))
    precondition(INCallRecordFilter.supportsSecureCoding)
    let car = INCar()
    car.make = "Open"
    precondition(depthArchiveRoundTrip(car).make == "Open")
    let head = INCar.HeadUnit(bluetoothIdentifier: "bt", iAP2Identifier: "iap")
    let restoredHead = depthArchiveRoundTrip(head)
    precondition(restoredHead.bluetoothIdentifier == "bt")
    precondition(restoredHead.iAP2Identifier == "iap")
    let amount = INCurrencyAmount(amount: NSDecimalNumber(value: 5), currencyCode: "USD")
    precondition(depthArchiveRoundTrip(amount).currencyCode == "USD")
    var start = DateComponents()
    start.year = 2026
    var end = DateComponents()
    end.year = 2027
    let range = INDateComponentsRange(start: start, end: end)
    precondition(depthArchiveRoundTrip(range).startDateComponents?.year == 2026)
    let card = INDefaultCardTemplate(title: "Library")
    precondition(depthArchiveRoundTrip(card).title == "Library")
    let file = INFile(data: Data([0x01]), filename: "a.bin", typeIdentifier: "public.data")
    precondition(depthArchiveRoundTrip(file).filename == "a.bin")
    let flight = INFlight()
    flight.flightNumber = "OA1"
    precondition(depthArchiveRoundTrip(flight).flightNumber == "OA1")
    let focus = INFocusStatus(isFocused: false)
    precondition(depthArchiveRoundTrip(focus).isFocused == false)
    _ = depthArchiveRoundTrip(INIntentDonationMetadata())
    precondition(INIntentDonationMetadata.supportsSecureCoding)
    let response = INIntentResponse()
    _ = depthArchiveRoundTrip(response)
    precondition(INIntentResponse.supportsSecureCoding)
    let mediaSearch = INMediaSearch(mediaName: "Song")
    precondition(depthArchiveRoundTrip(mediaSearch).mediaName == "Song")
    let object = INObject(identifier: "id", display: "Ada")
    precondition(depthArchiveRoundTrip(object).displayString == "Ada")
    let collection = INObjectCollection(items: [object])
    precondition(INObjectCollection<INObject>.supportsSecureCoding)
    _ = depthArchiveRoundTrip(collection)
    let section = INObjectSection(title: "A", items: [object])
    precondition(depthArchiveRoundTrip(section).title == "A")
    let parameter = INParameter(for: INIntent.self, keyPath: "identifier")
    precondition(depthArchiveRoundTrip(parameter).parameterKeyPath == "identifier")
    _ = depthArchiveRoundTrip(INPaymentAccount())
    precondition(INPaymentAccount.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INPaymentAmount())
    precondition(INPaymentAmount.supportsSecureCoding)
    let method = INPaymentMethod(type: .unknown, name: "Card", identificationHint: "hint", icon: nil)
    precondition(depthArchiveRoundTrip(method).name == "Card")
    _ = depthArchiveRoundTrip(INPaymentRecord())
    precondition(INPaymentRecord.supportsSecureCoding)
    let handle = INPersonHandle(value: "a@b.c", type: .emailAddress, label: .work)
    precondition(depthArchiveRoundTrip(handle).value == "a@b.c")
    let option = INRideOption(name: "Pool", estimatedPickupDate: Date(timeIntervalSince1970: 0))
    precondition(depthArchiveRoundTrip(option).name == "Pool")
    _ = depthArchiveRoundTrip(INPriceRange())
    precondition(INPriceRange.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INRecurrenceRule())
    precondition(INRecurrenceRule.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INRelevanceProvider())
    precondition(INRelevanceProvider.supportsSecureCoding)
    let shortcut = INShortcut(intent: INIntent())
    let relevant = INRelevantShortcut(shortcut: shortcut)
    relevant.widgetKind = "W"
    precondition(depthArchiveRoundTrip(relevant).widgetKind == "W")
    let rental = INRentalCar(rentalCompanyName: "Open", type: "sedan", make: "X", model: "Y", rentalCarDescription: "d")
    precondition(depthArchiveRoundTrip(rental).rentalCompanyName == "Open")
    let reservation = INReservation()
    reservation.reservationNumber = "r1"
    precondition(depthArchiveRoundTrip(reservation).reservationNumber == "r1")
    _ = depthArchiveRoundTrip(INReservationAction())
    precondition(INReservationAction.supportsSecureCoding)
    let restaurant = INRestaurant()
    restaurant.name = "Cafe"
    precondition(depthArchiveRoundTrip(restaurant).name == "Cafe")
    _ = depthArchiveRoundTrip(INRestaurantGuestDisplayPreferences())
    precondition(INRestaurantGuestDisplayPreferences.supportsSecureCoding)
    let offer = INRestaurantOffer()
    offer.offerTitleText = "Deal"
    precondition(depthArchiveRoundTrip(offer).offerTitleText == "Deal")
    let booking = INRestaurantReservationBooking()
    booking.bookingDescription = "book"
    precondition(depthArchiveRoundTrip(booking).bookingDescription == "book")
    _ = depthArchiveRoundTrip(INRideFareLineItem())
    precondition(INRideFareLineItem.supportsSecureCoding)
    let party = INRidePartySizeOption()
    party.sizeDescription = "2"
    precondition(depthArchiveRoundTrip(party).sizeDescription == "2")
    let vehicle = INRideVehicle()
    vehicle.model = "Car"
    precondition(depthArchiveRoundTrip(vehicle).model == "Car")
    let seat = INSeat(seatSection: "A", seatRow: "1", seatNumber: "2", seatingType: "window")
    precondition(depthArchiveRoundTrip(seat).seatNumber == "2")
    _ = depthArchiveRoundTrip(INSpatialEventTrigger())
    precondition(INSpatialEventTrigger.supportsSecureCoding)
    let sticker = INSticker(type: .emoji, emoji: "⭐")
    precondition(depthArchiveRoundTrip(sticker).emoji == "⭐")
    _ = depthArchiveRoundTrip(INTask())
    precondition(INTask.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INTaskList())
    precondition(INTaskList.supportsSecureCoding)
    _ = depthArchiveRoundTrip(INTemporalEventTrigger())
    precondition(INTemporalEventTrigger.supportsSecureCoding)
    let terms = INTermsAndConditions(
        localizedTermsAndConditionsText: "terms",
        privacyPolicyURL: nil,
        termsAndConditionsURL: nil
    )
    precondition(depthArchiveRoundTrip(terms).localizedTermsAndConditionsText == "terms")
    _ = depthArchiveRoundTrip(INTicketedEvent())
    precondition(INTicketedEvent.supportsSecureCoding)
    let train = INTrainTrip()
    train.trainNumber = "1"
    precondition(depthArchiveRoundTrip(train).trainNumber == "1")
    _ = depthArchiveRoundTrip(INUserContext())
    precondition(INUserContext.supportsSecureCoding)
    let voice = INVoiceShortcut(invocationPhrase: "Erase", shortcut: shortcut)
    precondition(depthArchiveRoundTrip(voice).invocationPhrase == "Erase")
}

func testPreferencesAndSiriAuthorizationFailClosed() {
    precondition(INPreferences.siriAuthorizationStatus() == .denied)
    var seen: INSiriAuthorizationStatus?
    INPreferences.requestSiriAuthorization { seen = $0 }
    precondition(seen == .denied)
    precondition(INSiriAuthorizationStatus.denied.rawValue == 2)
    precondition(INSiriAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(INSiriAuthorizationStatus.restricted.rawValue == 1)
    precondition(INSiriAuthorizationStatus.authorized.rawValue == 3)
}
