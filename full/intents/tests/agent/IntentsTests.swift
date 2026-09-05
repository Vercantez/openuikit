import Foundation
@_spi(OpenIntentsHost) import Intents

func testIntentPhraseAndIdentifier() {
    let intent = INIntent()
    intent.suggestedInvocationPhrase = "Erase"
    intent.identifier = "intent.erase"
    intent.intentDescription = "Clear browsing data"
    precondition(intent.suggestedInvocationPhrase == "Erase")
    precondition(intent.identifier == "intent.erase")
    precondition(intent.intentDescription == "Clear browsing data")
    precondition(intent.keyImage() == nil)
}

func testIntentResponseStoresUserActivity() {
    let activity = NSUserActivity(activityType: "com.openuikit.intents.test")
    activity.suggestedInvocationPhrase = "Hello"
    let response = INIntentResponse()
    response.userActivity = activity
    precondition(response.userActivity === activity)
    precondition(response.userActivity?.suggestedInvocationPhrase == "Hello")
}

func testInteractionDonateAndDelete() {
    INInteraction.deleteAll()
    let intent = INIntent()
    intent.identifier = "donate-1"
    let interaction = INInteraction(intent: intent, response: nil)
    interaction.direction = .outgoing
    interaction.identifier = "interaction-1"
    var donateError: Error? = NSError(domain: "unset", code: 1)
    interaction.donate { donateError = $0 }
    precondition(donateError == nil)
    precondition(INInteraction.donatedInteractions.count == 1)
    precondition(INInteraction.donatedInteractions[0] === interaction)
    INInteraction.delete(with: ["interaction-1"])
    precondition(INInteraction.donatedInteractions.isEmpty)
    interaction.donate()
    INInteraction.deleteAll()
    precondition(INInteraction.donatedInteractions.isEmpty)
    precondition(INInteractionDirection.unspecified.rawValue == 0)
    precondition(INInteractionDirection.outgoing.rawValue == 1)
    precondition(INInteractionDirection.incoming.rawValue == 2)
}

func testVoiceShortcutInstallUpdateRemove() {
    INVoiceShortcutCenter.shared.removeAll()
    let intent = INIntent()
    intent.suggestedInvocationPhrase = "Erase"
    let shortcut = INShortcut(intent: intent)
    let installed = INVoiceShortcutCenter.shared.install(shortcut, invocationPhrase: "Erase")
    var observed: [INVoiceShortcut] = []
    var observedError: Error?
    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, error in
        observed = values ?? []
        observedError = error
    }
    precondition(observedError == nil)
    precondition(observed.count == 1)
    precondition(observed[0] === installed)
    precondition(observed[0].shortcut.intent === intent)
    let updated = INVoiceShortcutCenter.shared.update(installed, invocationPhrase: "Clear browsing data")
    precondition(updated.identifier == installed.identifier)
    precondition(updated.invocationPhrase == "Clear browsing data")
    INVoiceShortcutCenter.shared.setShortcutSuggestions([shortcut])
    precondition(INVoiceShortcutCenter.shared.shortcutSuggestions.count == 1)
    precondition(INVoiceShortcutCenter.shared.remove(identifier: updated.identifier))
    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, _ in
        precondition(values?.isEmpty == true)
    }
}

func testStringResolutionResultRetainsValue() {
    let resolved = INStringResolutionResult.success(with: "portable")
    precondition(resolved.outcome == .success)
    precondition(resolved.resolvedValue as? String == "portable")
    let needs = INStringResolutionResult.needsValue()
    precondition(needs.outcome == .needsValue)
    let unsupported = INIntentResolutionResult.unsupported()
    precondition(unsupported.outcome == .unsupported)
    let boolean = INBooleanResolutionResult.success(with: true)
    precondition(boolean.resolvedValue as? Bool == true)
    let integer = INIntegerResolutionResult.success(with: 7)
    precondition(integer.resolvedValue as? Int == 7)
    let double = INDoubleResolutionResult.success(with: 1.5)
    precondition(double.resolvedValue as? Double == 1.5)
}

func testObjectCollectionAndSpeakableString() {
    let spoken = INSpeakableString(spokenPhrase: "Library")
    precondition(spoken.spokenPhrase == "Library")
    let object = INObject(identifier: "id", display: spoken)
    precondition(object.displayString == "Library")
    let collection = INObjectCollection(items: [object])
    precondition(collection.items.count == 1)
    let section = INObjectSection(title: "A", items: [object])
    let sectioned = INObjectCollection(sections: [section])
    precondition(sectioned.items.count == 1)
    precondition(sectioned.sections.count == 1)
}

func testFocusStatusIsRestricted() {
    precondition(INFocusStatusCenter.default.authorizationStatus == .restricted)
    precondition(INFocusStatusCenter.default.focusStatus.isFocused == nil)
    var authorization: INFocusStatusAuthorizationStatus?
    INFocusStatusCenter.default.requestAuthorization { authorization = $0 }
    precondition(authorization == .restricted)
}

func testImageNamedDataAndURL() {
    let named = INImage(named: "glyph")
    precondition(named.namedImage == "glyph")
    let data = INImage(imageData: Data([0xFF]))
    precondition(data.imageData == Data([0xFF]))
    let url = URL(fileURLWithPath: "/tmp/intents-image")
    precondition(INImage(url: url) != nil)
    precondition(INImage(URL: url) != nil)
    let system = INImage.systemImageNamed("star")
    precondition(system.namedImage == "star")
}

func testPersonHandleAndPerson() {
    let handle = INPersonHandle(value: "a@b.c", type: .emailAddress, label: .work)
    precondition(handle.value == "a@b.c")
    precondition(handle.type == .emailAddress)
    precondition(handle.label == .work)
    let person = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: "c1",
        customIdentifier: "x"
    )
    precondition(person.displayName == "Ada")
    let success = INPersonResolutionResult.success(with: person)
    precondition(success.outcome == .success)
}

func testAccountTypeAndCallCapabilityOptions() {
    precondition(INAccountType.unknown.rawValue == 0)
    precondition(INAccountType.checking != .credit)
    var hasher = Hasher()
    hasher.combine(INAccountType.checking)
    _ = hasher.finalize()
    precondition(INAccountType(rawValue: 1) != nil)
    var options: INCallCapabilityOptions = [.audioCall]
    precondition(options.contains(.audioCall))
    precondition(!options.contains(.videoCall))
    options.insert(.videoCall)
    precondition(options.contains(.videoCall))
    precondition(!options.isEmpty)
    let union = INCallCapabilityOptions.audioCall.union(.videoCall)
    precondition(union.contains(.audioCall) && union.contains(.videoCall))
}

func testIntentErrorDomainAndCodes() {
    precondition(INIntentErrorDomain == "INIntentErrorDomain")
    let error = INIntentError(.permissionDenied)
    precondition(error.code == .permissionDenied)
    precondition(error.errorCode == INIntentError.Code.permissionDenied.rawValue)
    precondition(INIntentError.errorDomain == INIntentErrorDomain)
    precondition(INIntentError.permissionDenied == .permissionDenied)
    precondition(error != INIntentError(.requestTimedOut))
}

func testMediaDestinationOverlay() {
    let library = INMediaDestination.library
    precondition(library.playlistName == nil)
    let playlist = INMediaDestination.playlist("Favorites")
    precondition(playlist.playlistName == "Favorites")
    precondition(library != playlist)
}

func testGeneratedIntentStubsFailClosed() {
    let send = INSendMessageIntent()
    _ = send
    let response = INSendMessageIntentResponse(
        code: .failure,
        userActivity: nil
    )
    response.code = .failure
    precondition(response.code == .failure)
    INPreferences.requestSiriAuthorization { status in
        precondition(status == .denied)
    }
    precondition(INPreferences.siriAuthorizationStatus() == .denied)
}

func testIntentIdentifierConstants() {
    precondition(INStartAudioCallIntentIdentifier.contains("StartAudioCall"))
    precondition(INSendMessageIntentIdentifier.contains("SendMessage") || INSendMessageIntentIdentifier == "INSendMessageIntentIdentifier")
}
