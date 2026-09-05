import Foundation
import ShazamKit

func testSHMatchedMediaItemType() {
    let (_, matched, _) = shazamKitMatchedFixture()
    precondition(type(of: matched) == SHMatchedMediaItem.self)
}

func testSHMatchedMediaItemConfidence() {
    let (_, matched, _) = shazamKitMatchedFixture()
    precondition(matched.confidence == Float(0.9))
}

func testSHMatchedMediaItemFrequencySkew() {
    let (_, matched, _) = shazamKitMatchedFixture()
    precondition(matched.frequencySkew == Float(0.05))
}

func testSHMatchedMediaItemMatchOffset() {
    let (_, matched, _) = shazamKitMatchedFixture()
    precondition(matched.matchOffset == 1.25)
}

func testSHMatchedMediaItemPredictedCurrentMatchOffset() {
    let (_, matched, _) = shazamKitMatchedFixture()
    precondition(matched.predictedCurrentMatchOffset >= matched.matchOffset)
}

func testSHMatchType() {
    let (match, _, _) = shazamKitMatchedFixture()
    precondition(type(of: match) == SHMatch.self)
}

func testSHMatchMediaItems() {
    let (match, _, _) = shazamKitMatchedFixture()
    precondition(match.mediaItems.count == 1)
    precondition(match.mediaItems[0].title == "Matched")
}

func testSHMatchQuerySignature() {
    let (match, _, signature) = shazamKitMatchedFixture()
    precondition(match.querySignature.dataRepresentation == signature.dataRepresentation)
}

func testSHMatchInitCoder() {
    precondition(SHMatch(coder: NSCoder()) == nil)
}
