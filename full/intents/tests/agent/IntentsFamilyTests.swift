import Foundation
@_spi(OpenIntentsHost) import Intents

private func inArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(
            withRootObject: value, requiringSecureCoding: true
        )
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data)
        else {
            preconditionFailure("expected restored \(T.self)")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

func testIntentSecureCodingRoundTrip() {
    let intent = INIntent()
    intent.identifier = "intent.erase"
    intent.suggestedInvocationPhrase = "Erase"
    intent.intentDescription = "Clear browsing data"
    let restored = inArchiveRoundTrip(intent)
    precondition(restored.identifier == "intent.erase")
    precondition(restored.suggestedInvocationPhrase == "Erase")
    precondition(restored.intentDescription == "Clear browsing data")
    precondition(INIntent.supportsSecureCoding)
    let response = INIntentResponse()
    _ = inArchiveRoundTrip(response)
    precondition(INIntentResponse.supportsSecureCoding)
}

func testPreferencesDeniedOnLinux() {
    precondition(INPreferences.siriAuthorizationStatus() == .denied)
    precondition(INSiriAuthorizationStatus.denied.rawValue == 2)
    precondition(INSiriAuthorizationStatus.restricted.rawValue == 1)
    precondition(INSiriAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(INSiriAuthorizationStatus.authorized.rawValue == 3)
    var seen: INSiriAuthorizationStatus?
    INPreferences.requestSiriAuthorization { seen = $0 }
    precondition(seen == .denied)
    precondition(INPreferences.siriLanguageCode() == "")
    _ = INPreferences()
}

func testSpeakableStringInits() {
    let spoken = INSpeakableString(spokenPhrase: "Library")
    precondition(spoken.spokenPhrase == "Library")
    let identified = INSpeakableString(
        identifier: "vocab.library",
        spokenPhrase: "Library",
        pronunciationHint: "LYE-brer-ee"
    )
    precondition(identified.vocabularyIdentifier == "vocab.library")
    precondition(identified.pronunciationHint == "LYE-brer-ee")
    let vocab = INSpeakableString(
        vocabularyIdentifier: "vocab.library",
        spokenPhrase: "Library",
        pronunciationHint: "hint"
    )
    precondition(vocab.spokenPhrase == "Library")
    let restored = inArchiveRoundTrip(spoken)
    precondition(restored.spokenPhrase == "Library")
    precondition(INSpeakableString.supportsSecureCoding)
}

func testPersonHandleLabelsAndInits() {
    precondition(INPersonHandleLabel.school.rawValue == "school")
    precondition(INPersonHandleLabel("work") == .work)
    precondition(INPersonHandleLabel(rawValue: "home") == .home)
    let handle = INPersonHandle(value: "a@b.c", type: .emailAddress, label: .work)
    precondition(handle.value == "a@b.c")
    precondition(handle.type == .emailAddress)
    precondition(handle.label == .work)
    let unknown = INPersonHandle(value: "+1555", type: .phoneNumber)
    precondition(unknown.label == nil)
    let restored = inArchiveRoundTrip(handle)
    precondition(restored.value == "a@b.c")
    precondition(INPersonHandle.supportsSecureCoding)
}

func testPersonValueSemantics() {
    let handle = INPersonHandle(value: "ada@example.com", type: .emailAddress)
    let person = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: "c1",
        customIdentifier: "x"
    )
    precondition(person.displayName == "Ada")
    precondition(person.contactIdentifier == "c1")
    precondition(person.customIdentifier == "x")
    precondition(person.handle == "ada@example.com")
    precondition(person.isMe == false)
    precondition(person.isContactSuggestion == false)
    precondition(person.suggestionType == .none)
    let byHandle = INPerson(handle: "sms:+1", displayName: "Lin", contactIdentifier: "c2")
    precondition(byHandle.displayName == "Lin")
    let withAliases = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: "c1",
        customIdentifier: "x",
        aliases: [handle],
        suggestionType: .socialProfile
    )
    precondition(withAliases.aliases?.count == 1)
    precondition(withAliases.suggestionType == .socialProfile)
    let me = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Me",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil,
        isMe: true
    )
    precondition(me.isMe)
    let related = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil,
        relationship: .friend
    )
    precondition(related.relationship == .friend)
    person.siriMatches = [me]
    precondition(person.siriMatches?.count == 1)
    let restored = inArchiveRoundTrip(person)
    precondition(restored.displayName == "Ada")
    let success = INPersonResolutionResult.success(with: person)
    precondition(success.outcome == .success)
    precondition(success.resolvedValue as? INPerson === person)
    let disambiguate = INPersonResolutionResult.disambiguation(with: [person])
    precondition(disambiguate.outcome == .disambiguation)
    let confirm = INPersonResolutionResult.confirmationRequired(with: person)
    precondition(confirm.outcome == .confirmationRequired)
}

func testMediaItemAndSearch() {
    let artwork = INImage(named: "cover")
    let item = INMediaItem(
        identifier: "song-1",
        title: "Helplessness Blues",
        type: .song,
        artwork: artwork,
        artist: "Fleet Foxes"
    )
    precondition(item.identifier == "song-1")
    precondition(item.title == "Helplessness Blues")
    precondition(item.type == .song)
    precondition(item.artist == "Fleet Foxes")
    precondition(INMediaItemType.music.rawValue == 18)
    precondition(INMediaItemType.algorithmicRadioStation.rawValue == 19)
    precondition(INMediaItemType.news.rawValue == 20)
    let short = INMediaItem(identifier: "a", title: "Album", type: .album, artwork: nil)
    precondition(short.artist == nil)
    let search = INMediaSearch(
        mediaType: .song,
        sortOrder: .newest,
        mediaName: "Helplessness Blues",
        artistName: "Fleet Foxes",
        albumName: "Helplessness Blues",
        genreNames: ["Folk"],
        moodNames: ["Calm"],
        releaseDate: nil,
        reference: .my,
        mediaIdentifier: "song-1"
    )
    precondition(search.mediaName == "Helplessness Blues")
    precondition(search.artistName == "Fleet Foxes")
    precondition(search.albumName == "Helplessness Blues")
    precondition(search.mediaType == .song)
    precondition(search.sortOrder == .newest)
    precondition(search.genreNames == ["Folk"])
    precondition(search.moodNames == ["Calm"])
    precondition(search.reference == .my)
    precondition(search.mediaIdentifier == "song-1")
    search.activityNames = ["Run"]
    precondition(search.activityNames == ["Run"])
    let restored = inArchiveRoundTrip(item)
    precondition(restored.title == "Helplessness Blues")
    precondition(INMediaItem.supportsSecureCoding)
}

func testCallRecordValueSemantics() {
    let handle = INPersonHandle(value: "+15551212", type: .phoneNumber)
    let caller = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: "Ada",
        image: nil,
        contactIdentifier: nil,
        customIdentifier: nil
    )
    let record = INCallRecord(
        identifier: "call-1",
        dateCreated: Date(timeIntervalSince1970: 0),
        caller: caller,
        callRecordType: .missed,
        callCapability: .audioCall,
        callDuration: 12.5,
        unseen: true,
        numberOfCalls: 2
    )
    precondition(record.identifier == "call-1")
    precondition(record.callRecordType == .missed)
    precondition(record.callCapability == .audioCall)
    precondition(record.callDuration == 12.5)
    precondition(record.unseen == true)
    precondition(record.numberOfCalls == 2)
    precondition(record.caller?.displayName == "Ada")
    let filter = INCallRecordFilter(
        participants: [caller],
        callTypes: [.missed, .voicemail],
        callCapability: .audioCall
    )
    precondition(filter.callTypes.contains(.missed))
    precondition(filter.callCapability == .audioCall)
    let resolved = INCallRecordResolutionResult.success(with: record)
    precondition(resolved.outcome == .success)
    precondition(resolved.resolvedValue as? INCallRecord === record)
}

func testParameterKeyPathEquality() {
    let parameter = INParameter(for: INIntent.self, keyPath: "identifier")
    precondition(parameter.parameterKeyPath == "identifier")
    precondition(parameter.parameterClass == INIntent.self)
    let duplicate = INParameter(forClass: INIntent.self, keyPath: "identifier")
    precondition(parameter.isEqual(to: duplicate))
    let other = INParameter(for: INIntent.self, keyPath: "suggestedInvocationPhrase")
    precondition(!parameter.isEqual(to: other))
    parameter.setIndex(3, forSubKeyPath: "recipients")
    precondition(parameter.index(forSubKeyPath: "recipients") == 3)
    precondition(parameter.index(forSubKeyPath: "missing") == NSNotFound)
}

func testInteractionGroupDeleteAndParameterValue() {
    INInteraction.deleteAll()
    let intent = INIntent()
    intent.identifier = "donate-group"
    intent.suggestedInvocationPhrase = "Erase"
    let interaction = INInteraction(intent: intent, response: nil)
    interaction.identifier = "interaction-group"
    interaction.groupIdentifier = "group-a"
    interaction.dateInterval = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 1)
    interaction.intentHandlingStatus = .success
    interaction.donate()
    let parameter = INParameter(for: INIntent.self, keyPath: "identifier")
    precondition(interaction.parameterValue(for: parameter) as? String == "donate-group")
    let phrase = INParameter(for: INIntent.self, keyPath: "suggestedInvocationPhrase")
    precondition(interaction.parameterValue(for: phrase) as? String == "Erase")
    let unknown = INParameter(for: INIntent.self, keyPath: "missing")
    precondition(interaction.parameterValue(for: unknown) == nil)
    var groupError: Error? = NSError(domain: "unset", code: 1)
    INInteraction.delete(with: "group-a") { groupError = $0 }
    precondition(groupError == nil)
    precondition(INInteraction.donatedInteractions.isEmpty)
    let restored = inArchiveRoundTrip(interaction)
    precondition(restored.identifier == "interaction-group")
    precondition(INInteraction.supportsSecureCoding)
}

func testVoiceShortcutSuggestionsAndEmptyGet() {
    INVoiceShortcutCenter.shared.removeAll()
    var observed: [INVoiceShortcut] = []
    var observedError: Error?
    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, error in
        observed = values ?? []
        observedError = error
    }
    precondition(observedError == nil)
    precondition(observed.isEmpty)
    let intent = INIntent()
    intent.suggestedInvocationPhrase = "Erase"
    let shortcut = INShortcut(intent: intent)
    INVoiceShortcutCenter.shared.setShortcutSuggestions([shortcut])
    precondition(INVoiceShortcutCenter.shared.shortcutSuggestions.count == 1)
    let installed = INVoiceShortcutCenter.shared.install(shortcut, invocationPhrase: "Erase")
    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, _ in
        precondition(values?.count == 1)
        precondition(values?[0].identifier == installed.identifier)
    }
    var asyncAll: [INVoiceShortcut] = []
    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, error in
        precondition(error == nil)
        asyncAll = values ?? []
    }
    precondition(asyncAll.count == 1)
    var asyncOne: INVoiceShortcut?
    var oneError: Error?
    INVoiceShortcutCenter.shared.getVoiceShortcut(with: installed.identifier) { value, error in
        asyncOne = value
        oneError = error
    }
    precondition(oneError == nil)
    precondition(asyncOne?.identifier == installed.identifier)
    var missingError: Error?
    INVoiceShortcutCenter.shared.getVoiceShortcut(with: UUID()) { value, error in
        precondition(value == nil)
        missingError = error
    }
    precondition((missingError as? INIntentError)?.code == .voiceShortcutGetFailed)
    _ = INShortcut.supportsSecureCoding
    _ = inArchiveRoundTrip(shortcut)
}

func testRelevantShortcutStore() {
    let intent = INIntent()
    intent.suggestedInvocationPhrase = "Library"
    let shortcut = INShortcut(intent: intent)
    let relevant = INRelevantShortcut(shortcut: shortcut)
    relevant.shortcutRole = .information
    relevant.widgetKind = "LibraryWidget"
    relevant.watchTemplate = INDefaultCardTemplate(title: "Library")
    precondition(relevant.shortcut === shortcut)
    precondition(relevant.shortcutRole == .information)
    precondition(relevant.widgetKind == "LibraryWidget")
    precondition(relevant.watchTemplate?.title == "Library")
    var storedError: Error? = NSError(domain: "unset", code: 1)
    INRelevantShortcutStore.default.setRelevantShortcuts([relevant]) { storedError = $0 }
    precondition(storedError == nil)
    let values = INRelevantShortcutStore.default.storedShortcuts
    precondition(values.count == 1)
    precondition(values[0].widgetKind == "LibraryWidget")
}

func testImageFailClosedRendering() {
    let named = INImage(named: "glyph")
    precondition(named.namedImage == "glyph")
    precondition(named.imageData == nil)
    let data = INImage(imageData: Data([0xFF, 0xD8]))
    precondition(data.imageData == Data([0xFF, 0xD8]))
    precondition(data.namedImage == nil)
    let restored = inArchiveRoundTrip(named)
    precondition(restored.namedImage == "glyph")
    precondition(INImage.supportsSecureCoding)
    precondition(INImage.systemImageNamed("star").namedImage == "star")
}

func testUserActivityInteractionBridging() {
    let activity = NSUserActivity(activityType: "com.openuikit.intents.bridge")
    activity.suggestedInvocationPhrase = "Erase"
    activity.isEligibleForPrediction = true
    activity.isEligibleForSearch = true
    activity.persistentIdentifier = "note.1"
    activity.title = "Erase"
    let intent = INIntent()
    intent.identifier = "bridge"
    let interaction = INInteraction(intent: intent, response: nil)
    activity.interaction = interaction
    precondition(activity.interaction === interaction)
    precondition(activity.suggestedInvocationPhrase == "Erase")
    precondition(activity.persistentIdentifier == "note.1")
    precondition(INUserActivityOverlayKey.interaction == "OpenUIKit.Intents.interaction")
    precondition(INUserActivityOverlayKey.suggestedInvocationPhrase == "OpenUIKit.Intents.suggestedInvocationPhrase")
    precondition(INUserActivityOverlayKey.persistentIdentifier == "OpenUIKit.Intents.persistentIdentifier")
    precondition(INUserActivityOverlayKey.eligibleForPrediction == "OpenUIKit.Intents.isEligibleForPrediction")
}

func testSearchSendPlayStartFamilies() {
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
    precondition(search.speakableGroupNames?.first?.spokenPhrase == "Team")
    precondition(search.conversationIdentifiers == ["c1"])
    let searchResponse = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)
    precondition(searchResponse.code == .success)

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
    precondition(send.outgoingMessageType == .outgoingMessageText)
    precondition(send.serviceName == "iMessage")
    precondition(send.sender?.displayName == "Ada")
    precondition(send.conversationIdentifier == "c1")
    let sendResponse = INSendMessageIntentResponse(code: .success, userActivity: nil)
    precondition(sendResponse.code == .success)

    let media = INMediaItem(identifier: "s1", title: "Song", type: .song, artwork: nil)
    let mediaSearch = INMediaSearch(mediaType: .song, mediaName: "Song")
    let play = INPlayMediaIntent(
        mediaItems: [media],
        mediaContainer: media,
        playShuffled: false,
        playbackRepeatMode: .all,
        resumePlayback: true,
        playbackQueueLocation: .now,
        playbackSpeed: 1.0,
        mediaSearch: mediaSearch
    )
    precondition(play.mediaItems?.count == 1)
    precondition(play.playShuffled == false)
    precondition(play.playbackRepeatMode == .all)
    precondition(play.resumePlayback == true)
    precondition(play.playbackQueueLocation == .now)
    precondition(play.playbackSpeed == 1.0)
    precondition(play.mediaSearch?.mediaName == "Song")
    let playResponse = INPlayMediaIntentResponse(code: .success, userActivity: nil)
    precondition(playResponse.code == .success)
    let playItems = INPlayMediaMediaItemResolutionResult.successes(with: [media])
    precondition(playItems.count == 1)

    let record = INCallRecord(identifier: "call-1", caller: person, callRecordType: .outgoing)
    let filter = INCallRecordFilter(participants: [person], callTypes: [.outgoing], callCapability: .audioCall)
    let start = INStartCallIntent(
        callRecordFilter: filter,
        callRecordToCallBack: record,
        audioRoute: .speakerphoneAudioRoute,
        destinationType: .normal,
        contacts: [person],
        callCapability: .audioCall
    )
    precondition(start.audioRoute == .speakerphoneAudioRoute)
    precondition(start.destinationType == .normal)
    precondition(start.contacts?.count == 1)
    precondition(start.callCapability == .audioCall)
    precondition(start.callRecordToCallBack?.identifier == "call-1")
    precondition(INCallDestinationType.normalDestination == .normal)
    precondition(INCallDestinationType.emergencyDestination == .emergency)
    precondition(INCallDestinationType.redialDestination == .redial)
    precondition(INCallDestinationType.voicemailDestination == .voicemail)
    let startResponse = INStartCallIntentResponse(code: .continueInApp, userActivity: nil)
    precondition(startResponse.code == .continueInApp)
}

func testResolutionResultsRetainValues() {
    let spoken = INSpeakableString(spokenPhrase: "Library")
    let success = INSpeakableStringResolutionResult.success(with: spoken)
    precondition(success.outcome == .success)
    precondition((success.resolvedValue as? INSpeakableString)?.spokenPhrase == "Library")
    let needs = INSpeakableStringResolutionResult.needsValue()
    precondition(needs.outcome == .needsValue)
    let boolean = INBooleanResolutionResult.confirmationRequired(with: NSNumber(value: true))
    precondition(boolean.outcome == .confirmationRequired)
    let media = INMediaItem(identifier: "s1", title: "Song", type: .song, artwork: nil)
    let items = INMediaItemResolutionResult.successes(with: [media])
    precondition(items.count == 1)
    let unsupported = INPlayMediaMediaItemResolutionResult.unsupported(forReason: .loginRequired)
    precondition(unsupported.outcome == .unsupported)
}

func testShortcutUserActivityInit() {
    let activity = NSUserActivity(activityType: "com.openuikit.intents.shortcut")
    let shortcut = INShortcut(userActivity: activity)
    precondition(shortcut.userActivity === activity)
    precondition(shortcut.intent == nil)
}
