import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testHighlightCenterEmptyHighlights() {
    let center = SWHighlightCenter()
    swRequire(center.highlights.isEmpty, "empty highlights")
}

func testHighlightCenterDelegateProperty() {
    final class Probe: NSObject, SWHighlightCenterDelegate {
        func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
            _ = highlightCenter
        }
    }
    let center = SWHighlightCenter()
    let probe = Probe()
    center.delegate = probe
    swRequire(center.delegate === probe, "delegate")
}

func testHighlightCollectionTitleEmpty() {
    swRequire(SWHighlightCenter.highlightCollectionTitle.isEmpty, "no catalog")
}

func testSystemCollaborationSupportUnavailable() {
    swRequire(SWHighlightCenter.isSystemCollaborationSupportAvailable == false, "unavailable")
}

func testCollaborationHighlightForIdentifierThrows() {
    let center = SWHighlightCenter()
    do {
        _ = try center.collaborationHighlight(forIdentifier: "missing")
        fatalError("expected accessDenied")
    } catch let error as SWHighlightCenterErrorCode {
        swRequire(error == .accessDenied, "accessDenied")
    } catch {
        fatalError("unexpected \(error)")
    }
}

func testCollaborationHighlightForIdentifierStringThrows() {
    let center = SWHighlightCenter()
    var thrown: SWHighlightCenterErrorCode?
    do {
        _ = try center.collaborationHighlight(forIdentifier: "also-missing")
    } catch let error as SWHighlightCenterErrorCode {
        thrown = error
    } catch {
        fatalError("unexpected \(error)")
    }
    swRequire(thrown == .accessDenied, "string overlay")
}

func testGetHighlightForCompletesAccessDenied() {
    let center = SWHighlightCenter()
    var highlight: SWHighlight? = swSampleHighlight("sentinel")
    var error: (any Error)?
    center.getHighlightFor(swSampleURL("missing")) { found, seen in
        highlight = found
        error = seen
    }
    swRequire(highlight == nil, "no highlight")
    swRequire(
        (error as? SWHighlightCenterErrorCode) == .accessDenied,
        "denied"
    )
}

func testGetSignedIdentityProofFailsClosed() {
    let center = SWHighlightCenter()
    let collab = swSampleCollaboration("proof")
    var proof: SWPerson.SignedIdentityProof? = SWPerson.SignedIdentityProof(
        signatureData: Data([0x01])
    )
    var error: (any Error)?
    center.getSignedIdentityProof(for: collab, using: Data([0x02])) { signed, seen in
        proof = signed
        error = seen
    }
    swRequire(proof == nil, "no proof")
    swRequire(
        (error as? SWHighlightCenterErrorCode) == .accessDenied,
        "denied"
    )
}

func testPostNoticeRecordsLocally() {
    let center = SWHighlightCenter()
    let highlight = swSampleHighlight("notice")
    let event = SWHighlightChangeEvent(highlight: highlight, trigger: .edit)
    center.postNotice(for: event)
    swRequire(SharedWithYouHostControl.postedNoticeCount(center) == 1, "posted")
}

func testClearNoticesRemovesMatching() {
    let center = SWHighlightCenter()
    let collab = swSampleCollaboration("clear")
    let event = SWHighlightPersistenceEvent(highlight: collab, trigger: .created)
    center.postNotice(for: event)
    center.clearNotices(for: collab)
    swRequire(SharedWithYouHostControl.postedNoticeCount(center) == 0, "cleared")
}

func testClearNoticesLeavesOtherURLs() {
    let center = SWHighlightCenter()
    let kept = swSampleHighlight("kept")
    let dropped = swSampleCollaboration("dropped")
    center.postNotice(for: SWHighlightChangeEvent(highlight: kept, trigger: .comment))
    center.postNotice(for: SWHighlightMembershipEvent(highlight: dropped, trigger: .addedCollaborator))
    center.clearNotices(for: dropped)
    swRequire(SharedWithYouHostControl.postedNoticeCount(center) == 1, "kept other")
}

func testHighlightCenterDelegateProtocolCall() {
    final class Recorder: NSObject, SWHighlightCenterDelegate {
        var seen: SWHighlightCenter?
        func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
            seen = highlightCenter
        }
    }
    let center = SWHighlightCenter()
    let recorder = Recorder()
    recorder.highlightCenterHighlightsDidChange(center)
    swRequire(recorder.seen === center, "delegate call")
}
