import Foundation
import MusicKit

func testSubscriptionUpdates() {
    let updates = MusicSubscription.subscriptionUpdates
    let iterator = updates.makeAsyncIterator()
    let asyncIterator: MusicSubscription.Updates.AsyncIterator = iterator
    _ = asyncIterator
    let elementType: MusicSubscription.Updates.Element.Type = MusicSubscription.self
    let iteratorElement: MusicSubscription.Updates.Iterator.Element.Type = MusicSubscription.self
    precondition(elementType == MusicSubscription.self)
    precondition(iteratorElement == MusicSubscription.self)
    _ = MusicSubscription.Updates()
    _ = MusicSubscription.Updates.Iterator()
}
