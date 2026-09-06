import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func swRequire(_ value: Bool, _ message: String) {
    if !value {
        fatalError(message)
    }
}

func swSampleURL(_ path: String = "doc") -> URL {
    URL(string: "https://example.invalid/shared/\(path)")!
}

func swSampleHighlight(_ path: String = "doc") -> SWHighlight {
    SharedWithYouHostControl.makeHighlight(url: swSampleURL(path), identifier: path)
}

func swSampleCollaboration(_ path: String = "collab") -> SWCollaborationHighlight {
    SharedWithYouHostControl.makeCollaborationHighlight(
        url: swSampleURL(path),
        identifier: path,
        collaborationIdentifier: "collab.\(path)"
    )
}

func swMismatchedCoder() -> NSCoder {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "mismatch" as NSString,
            requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        return unarchiver
    } catch {
        fatalError("coder fixture failed: \(error)")
    }
}

func testEnumRawValues() {
    swRequire(SWAttributionView.BackgroundStyle.default.rawValue == 0, "bg default")
    swRequire(SWAttributionView.BackgroundStyle.color.rawValue == 1, "bg color")
    swRequire(SWAttributionView.BackgroundStyle.material.rawValue == 2, "bg material")
    swRequire(SWAttributionView.BackgroundStyle(rawValue: 0) == .default, "bg init 0")
    swRequire(SWAttributionView.BackgroundStyle(rawValue: 99) == nil, "bg init nil")
    swRequire(SWAttributionView.BackgroundStyle.default != .color, "bg !=")
    var bgHasher = Hasher()
    SWAttributionView.BackgroundStyle.color.hash(into: &bgHasher)
    swRequire(
        SWAttributionView.BackgroundStyle.color.hashValue
            == SWAttributionView.BackgroundStyle.color.hashValue,
        "bg hashValue"
    )

    swRequire(SWAttributionView.DisplayContext.summary.rawValue == 0, "ctx summary")
    swRequire(SWAttributionView.DisplayContext.detail.rawValue == 1, "ctx detail")
    swRequire(SWAttributionView.DisplayContext(rawValue: 1) == .detail, "ctx init")
    swRequire(SWAttributionView.DisplayContext(rawValue: -1) == nil, "ctx nil")
    swRequire(SWAttributionView.DisplayContext.summary != .detail, "ctx !=")
    var ctxHasher = Hasher()
    SWAttributionView.DisplayContext.detail.hash(into: &ctxHasher)
    swRequire(
        SWAttributionView.DisplayContext.detail.hashValue
            == SWAttributionView.DisplayContext.detail.hashValue,
        "ctx hashValue"
    )

    swRequire(SWAttributionView.HorizontalAlignment.default.rawValue == 0, "align default")
    swRequire(SWAttributionView.HorizontalAlignment.leading.rawValue == 1, "align leading")
    swRequire(SWAttributionView.HorizontalAlignment.center.rawValue == 2, "align center")
    swRequire(SWAttributionView.HorizontalAlignment.trailing.rawValue == 3, "align trailing")
    swRequire(SWAttributionView.HorizontalAlignment(rawValue: 2) == .center, "align init")
    swRequire(SWAttributionView.HorizontalAlignment(rawValue: 8) == nil, "align nil")
    swRequire(SWAttributionView.HorizontalAlignment.leading != .trailing, "align !=")
    var alignHasher = Hasher()
    SWAttributionView.HorizontalAlignment.center.hash(into: &alignHasher)
    swRequire(
        SWAttributionView.HorizontalAlignment.center.hashValue
            == SWAttributionView.HorizontalAlignment.center.hashValue,
        "align hashValue"
    )

    swRequire(SWHighlightCenterErrorCode.noError.rawValue == 0, "err none")
    swRequire(SWHighlightCenterErrorCode.internalError.rawValue == 1, "err internal")
    swRequire(SWHighlightCenterErrorCode.invalidURL.rawValue == 2, "err url")
    swRequire(SWHighlightCenterErrorCode.accessDenied.rawValue == 3, "err denied")
    swRequire(SWHighlightCenterErrorCode(rawValue: 3) == .accessDenied, "err init")
    swRequire(SWHighlightCenterErrorCode(rawValue: 4) == nil, "err nil")
    swRequire(SWHighlightCenterErrorCode.noError != .accessDenied, "err !=")
    var errHasher = Hasher()
    SWHighlightCenterErrorCode.invalidURL.hash(into: &errHasher)
    swRequire(
        SWHighlightCenterErrorCode.invalidURL.hashValue
            == SWHighlightCenterErrorCode.invalidURL.hashValue,
        "err hashValue"
    )
    swRequire(
        SWHighlightCenterErrorCode.errorDomain == SWHighlightErrorDomain,
        "err domain"
    )
    swRequire(SWHighlightCenterErrorCode.accessDenied.errorCode == 3, "err code")

    swRequire(SWHighlightChangeEventTrigger.edit.rawValue == 1, "change edit")
    swRequire(SWHighlightChangeEventTrigger.comment.rawValue == 2, "change comment")
    swRequire(SWHighlightChangeEventTrigger(rawValue: 1) == .edit, "change init")
    swRequire(SWHighlightChangeEventTrigger(rawValue: 0) == nil, "change nil")
    swRequire(SWHighlightChangeEventTrigger.edit != .comment, "change !=")
    var changeHasher = Hasher()
    SWHighlightChangeEventTrigger.edit.hash(into: &changeHasher)
    swRequire(
        SWHighlightChangeEventTrigger.edit.hashValue
            == SWHighlightChangeEventTrigger.edit.hashValue,
        "change hashValue"
    )

    swRequire(SWHighlightMembershipEventTrigger.addedCollaborator.rawValue == 1, "mem add")
    swRequire(SWHighlightMembershipEventTrigger.removedCollaborator.rawValue == 2, "mem remove")
    swRequire(
        SWHighlightMembershipEventTrigger(rawValue: 2) == .removedCollaborator,
        "mem init"
    )
    swRequire(SWHighlightMembershipEventTrigger(rawValue: 0) == nil, "mem nil")
    swRequire(
        SWHighlightMembershipEventTrigger.addedCollaborator != .removedCollaborator,
        "mem !="
    )
    var memHasher = Hasher()
    SWHighlightMembershipEventTrigger.addedCollaborator.hash(into: &memHasher)
    swRequire(
        SWHighlightMembershipEventTrigger.addedCollaborator.hashValue
            == SWHighlightMembershipEventTrigger.addedCollaborator.hashValue,
        "mem hashValue"
    )

    swRequire(SWHighlightPersistenceEventTrigger.created.rawValue == 1, "pers created")
    swRequire(SWHighlightPersistenceEventTrigger.deleted.rawValue == 2, "pers deleted")
    swRequire(SWHighlightPersistenceEventTrigger.renamed.rawValue == 3, "pers renamed")
    swRequire(SWHighlightPersistenceEventTrigger.moved.rawValue == 4, "pers moved")
    swRequire(SWHighlightPersistenceEventTrigger(rawValue: 4) == .moved, "pers init")
    swRequire(SWHighlightPersistenceEventTrigger(rawValue: 0) == nil, "pers nil")
    swRequire(SWHighlightPersistenceEventTrigger.created != .moved, "pers !=")
    var persHasher = Hasher()
    SWHighlightPersistenceEventTrigger.renamed.hash(into: &persHasher)
    swRequire(
        SWHighlightPersistenceEventTrigger.renamed.hashValue
            == SWHighlightPersistenceEventTrigger.renamed.hashValue,
        "pers hashValue"
    )
}
