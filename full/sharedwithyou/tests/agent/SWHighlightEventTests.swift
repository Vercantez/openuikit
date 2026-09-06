import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testChangeEventInit() {
    let highlight = swSampleHighlight("change")
    let event = SWHighlightChangeEvent(highlight: highlight, trigger: .comment)
    swRequire(event.changeEventTrigger == .comment, "trigger")
}

func testChangeEventHighlightURL() {
    let highlight = swSampleHighlight("change-url")
    let event = SWHighlightChangeEvent(highlight: highlight, trigger: .edit)
    swRequire(event.highlightURL == highlight.url, "url")
}

func testChangeEventCoderRoundTrip() {
    let event = SWHighlightChangeEvent(highlight: swSampleHighlight("chg-arc"), trigger: .edit)
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: event,
            requiringSecureCoding: true
        )
        let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: SWHighlightChangeEvent.self,
            from: data
        )
        swRequire(decoded?.changeEventTrigger == .edit, "decoded trigger")
        swRequire(decoded?.highlightURL == event.highlightURL, "decoded url")
    } catch {
        fatalError("archive failed: \(error)")
    }
}

func testChangeEventCoderRejectsEmpty() {
    swRequire(SWHighlightChangeEvent(coder: swMismatchedCoder()) == nil, "empty")
}

func testMembershipEventInit() {
    let event = SWHighlightMembershipEvent(
        highlight: swSampleHighlight("mem"),
        trigger: .removedCollaborator
    )
    swRequire(event.membershipEventTrigger == .removedCollaborator, "trigger")
}

func testMembershipEventCoderRoundTrip() {
    let event = SWHighlightMembershipEvent(
        highlight: swSampleHighlight("mem-arc"),
        trigger: .addedCollaborator
    )
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: event,
            requiringSecureCoding: true
        )
        let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: SWHighlightMembershipEvent.self,
            from: data
        )
        swRequire(decoded?.membershipEventTrigger == .addedCollaborator, "decoded")
    } catch {
        fatalError("archive failed: \(error)")
    }
}

func testMembershipEventCoderRejectsEmpty() {
    swRequire(SWHighlightMembershipEvent(coder: swMismatchedCoder()) == nil, "empty")
}

func testMentionEventHandleInit() {
    let event = SWHighlightMentionEvent(
        highlight: swSampleHighlight("mention"),
        mentionedPersonCloudKitShareHandle: "ck:handle"
    )
    swRequire(event.mentionedPersonHandle == "ck:handle", "handle")
}

func testMentionEventIdentityInit() {
    let identity = SWPerson.Identity(rootHash: Data([0x0A, 0x0B]))
    let event = SWHighlightMentionEvent(
        highlight: swSampleHighlight("ident"),
        mentionedPersonIdentity: identity
    )
    swRequire(!event.mentionedPersonHandle.isEmpty, "identity handle")
    swRequire(event.highlightURL == swSampleURL("ident"), "url")
}

func testMentionEventCoderRoundTrip() {
    let event = SWHighlightMentionEvent(
        highlight: swSampleHighlight("men-arc"),
        mentionedPersonCloudKitShareHandle: "ck:arc"
    )
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: event,
            requiringSecureCoding: true
        )
        let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: SWHighlightMentionEvent.self,
            from: data
        )
        swRequire(decoded?.mentionedPersonHandle == "ck:arc", "decoded")
    } catch {
        fatalError("archive failed: \(error)")
    }
}

func testMentionEventCoderRejectsEmpty() {
    swRequire(SWHighlightMentionEvent(coder: swMismatchedCoder()) == nil, "empty")
}

func testPersistenceEventInit() {
    let event = SWHighlightPersistenceEvent(
        highlight: swSampleHighlight("pers"),
        trigger: .renamed
    )
    swRequire(event.persistenceEventTrigger == .renamed, "trigger")
}

func testPersistenceEventCoderRoundTrip() {
    let event = SWHighlightPersistenceEvent(
        highlight: swSampleHighlight("pers-arc"),
        trigger: .moved
    )
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: event,
            requiringSecureCoding: true
        )
        let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: SWHighlightPersistenceEvent.self,
            from: data
        )
        swRequire(decoded?.persistenceEventTrigger == .moved, "decoded")
    } catch {
        fatalError("archive failed: \(error)")
    }
}

func testPersistenceEventCoderRejectsEmpty() {
    swRequire(SWHighlightPersistenceEvent(coder: swMismatchedCoder()) == nil, "empty")
}

func testHighlightEventProtocolURL() {
    let event: any SWHighlightEvent = SWHighlightChangeEvent(
        highlight: swSampleHighlight("proto"),
        trigger: .edit
    )
    swRequire(event.highlightURL == swSampleURL("proto"), "protocol url")
}
