import Foundation
import ShazamKit

final class ShazamKitRecordingDelegate: NSObject, SHSessionDelegate {
    var match: SHMatch?
    var noMatchSignature: SHSignature?
    var noMatchError: (any Error)?

    func session(_ session: SHSession, didFind match: SHMatch) {
        self.match = match
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: (any Error)?) {
        self.noMatchSignature = signature
        self.noMatchError = error
    }
}

func shazamKitSignature(_ bytes: [UInt8] = [0xA1, 0xB2, 0xC3]) -> SHSignature {
    try! SHSignature(dataRepresentation: Data(bytes))
}

func shazamKitMatchedFixture() -> (SHMatch, SHMatchedMediaItem, SHSignature) {
    let signature = shazamKitSignature()
    let item = SHMediaItem(properties: [
        .title: "Matched",
        .artist: "Fixture",
        .matchOffset: 1.25,
        .frequencySkew: Float(0.05),
        .confidence: Float(0.9),
    ])
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(signature, representing: [item])
    let session = SHSession(catalog: catalog)
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    session.match(signature)
    guard let match = delegate.match, let matched = match.mediaItems.first else {
        preconditionFailure("custom catalog must produce a match")
    }
    return (match, matched, signature)
}

func testSHSessionType() {
    precondition(type(of: SHSession()) == SHSession.self)
}

func testSHSessionInit() {
    let session = SHSession()
    precondition(session.catalog.maximumQuerySignatureDuration == 0)
    precondition(session.catalog.minimumQuerySignatureDuration == 0)
}

func testSHSessionInitCatalog() {
    let catalog = SHCustomCatalog()
    let session = SHSession(catalog: catalog)
    precondition(session.catalog === catalog)
}

func testSHSessionCatalog() {
    let session = SHSession()
    precondition(type(of: session.catalog) == SHCatalog.self)
}

func testSHSessionDelegate() {
    let session = SHSession()
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    precondition(session.delegate === delegate)
    session.delegate = nil
    precondition(session.delegate == nil)
}

func testSHSessionMatchCustomCatalogHit() {
    let (match, matched, signature) = shazamKitMatchedFixture()
    precondition(match.querySignature.dataRepresentation == signature.dataRepresentation)
    precondition(matched.title == "Matched")
}

func testSHSessionMatchCustomCatalogMiss() {
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(shazamKitSignature([0x01]), representing: [
        SHMediaItem(properties: [.title: "Other"]),
    ])
    let session = SHSession(catalog: catalog)
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    let query = shazamKitSignature([0x02])
    session.match(query)
    precondition(delegate.match == nil)
    precondition(delegate.noMatchSignature?.dataRepresentation == query.dataRepresentation)
    precondition(delegate.noMatchError == nil)
}

func testSHSessionMatchAppleCatalogFailClosed() {
    let session = SHSession()
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    let query = shazamKitSignature()
    session.match(query)
    precondition(delegate.match == nil)
    precondition(SHError.Code.matchAttemptFailed ~= (delegate.noMatchError ?? SHError(.internalError)))
}

func testSHSessionResults() {
    let results = SHSession().results
    precondition(type(of: results) == SHSession.Results.self)
}

func testSHSessionResultsElement() {
    precondition(SHSession.Results.Element.self == SHSession.Result.self)
}

func testSHSessionResultsAsyncIterator() {
    precondition(SHSession.Results.AsyncIterator.self == SHSession.Results.Iterator.self)
}

func testSHSessionResultsMakeAsyncIterator() {
    _ = SHSession().results.makeAsyncIterator()
}

func testSHSessionResultsIteratorType() {
    let iterator = SHSession().results.makeAsyncIterator()
    precondition(type(of: iterator) == SHSession.Results.Iterator.self)
}

func testSHSessionResultsIteratorElement() {
    precondition(SHSession.Results.Iterator.Element.self == SHSession.Result.self)
}

func testSHSessionResultType() {
    _ = SHSession.Result.self
}

func testSHSessionResultMatchCase() {
    let (match, _, _) = shazamKitMatchedFixture()
    if case .match(let value) = SHSession.Result.match(match) {
        precondition(value.mediaItems.count == 1)
    } else {
        preconditionFailure("match case")
    }
}

func testSHSessionResultNoMatchCase() {
    let signature = shazamKitSignature()
    if case .noMatch(let value) = SHSession.Result.noMatch(signature) {
        precondition(value.dataRepresentation == signature.dataRepresentation)
    } else {
        preconditionFailure("noMatch case")
    }
}

func testSHSessionResultErrorCase() {
    let signature = shazamKitSignature()
    if case .error(let error, let query) = SHSession.Result.error(SHError(.matchAttemptFailed), signature) {
        precondition(SHError.Code.matchAttemptFailed ~= error)
        precondition(query.dataRepresentation == signature.dataRepresentation)
    } else {
        preconditionFailure("error case")
    }
}

func testSHSessionDelegateType() {
    let delegate: any SHSessionDelegate = ShazamKitRecordingDelegate()
    _ = delegate
}
