import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func testMusicPlayerStateMachine() {
    MPMediaLibrary.openuikit_resetLibrary()
    let player = MPMusicPlayerController.applicationMusicPlayer
    player.stop()
    player.setQueue(with: MPMediaItemCollection(items: []))
    precondition(player.playbackState == .stopped)
    precondition(player.repeatMode == .none)
    precondition(player.shuffleMode == .off)
    precondition(player.currentPlaybackRate == 0)
    precondition(player.currentPlaybackTime == 0)
    precondition(player.indexOfNowPlayingItem == 0)
    precondition(!player.isPreparedToPlay)
    player.play()
    precondition(player.playbackState == .stopped)
    player.prepareToPlay()
    precondition(!player.isPreparedToPlay)

    var returned = false
    let sem = DispatchSemaphore(value: 0)
    var sawError = false
    player.prepareToPlay { error in
        precondition(returned)
        precondition(MPError.notSupported ~= (error ?? MPError(.unknown)))
        sawError = true
        sem.signal()
    }
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(sawError)

    let a = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "One",
        MPMediaItemPropertyPersistentID: UInt64(1),
    ])
    let b = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Two",
        MPMediaItemPropertyPersistentID: UInt64(2),
    ])
    player.setQueue(with: MPMediaItemCollection(items: [a, b]))
    precondition(player.nowPlayingItem === a)
    player.play()
    precondition(player.playbackState == .playing)
    precondition(player.currentPlaybackRate == 1)
    precondition(player.isPreparedToPlay)
    player.pause()
    precondition(player.playbackState == .paused)
    player.play()
    player.beginSeekingForward()
    precondition(player.playbackState == .seekingForward)
    player.endSeeking()
    precondition(player.playbackState == .playing)
    player.beginSeekingBackward()
    precondition(player.playbackState == .seekingBackward)
    player.endSeeking()
    player.skipToNextItem()
    precondition(player.nowPlayingItem === b)
    precondition(player.indexOfNowPlayingItem == 1)
    player.skipToPreviousItem()
    precondition(player.nowPlayingItem === a)
    player.skipToBeginning()
    precondition(player.currentPlaybackTime == 0)
    player.stop()
    precondition(player.playbackState == .stopped)

    let system = MPMusicPlayerController.systemMusicPlayer
    system.openToPlay(MPMusicPlayerStoreQueueDescriptor(storeIDs: ["1"]))
    precondition(system.playbackState == .stopped)
    precondition(
        (MPMusicPlayerController.iPodMusicPlayer as AnyObject)
            === (MPMusicPlayerController.systemMusicPlayer as AnyObject)
    )
    _ = MPMusicPlayerController.applicationQueuePlayer.repeatMode
}

func testMusicPlayerNotifications() {
    let player = MPMusicPlayerController.applicationMusicPlayer
    let a = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "One"])
    let b = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "Two"])
    player.setQueue(with: MPMediaItemCollection(items: [a, b]))
    final class NoteBox: @unchecked Sendable {
        var stateNotes = 0
        var itemNotes = 0
    }
    let box = NoteBox()
    let nc = NotificationCenter.default
    let s1 = nc.addObserver(
        forName: .MPMusicPlayerControllerPlaybackStateDidChange,
        object: player,
        queue: nil
    ) { _ in box.stateNotes += 1 }
    let s2 = nc.addObserver(
        forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
        object: player,
        queue: nil
    ) { _ in box.itemNotes += 1 }
    player.play()
    precondition(box.stateNotes == 0)
    player.beginGeneratingPlaybackNotifications()
    player.play()
    player.skipToNextItem()
    player.stop()
    player.endGeneratingPlaybackNotifications()
    nc.removeObserver(s1)
    nc.removeObserver(s2)
    precondition(box.stateNotes > 0)
    precondition(box.itemNotes > 0)
}

func testMusicPlayerQueueDescriptors() {
    let a = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "One"])
    let b = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "Two"])
    let player = MPMusicPlayerController.applicationMusicPlayer
    let desc = MPMusicPlayerMediaItemQueueDescriptor(
        itemCollection: MPMediaItemCollection(items: [a, b])
    )
    desc.startItem = a
    desc.setStartTime(1, for: a)
    desc.setEndTime(2, for: a)
    precondition(desc.itemCollection.count == 2)
    player.setQueue(with: desc)
    player.append(desc)
    player.prepend(desc)
    player.setQueue(with: MPMediaQuery.songs())
    let qdesc = MPMusicPlayerMediaItemQueueDescriptor(query: MPMediaQuery.songs())
    precondition(qdesc.query.groupingType == .title)
    let store = MPMusicPlayerStoreQueueDescriptor(storeIDs: ["x"])
    store.startItemID = "x"
    store.setStartTime(0, forItemWithStoreID: "x")
    store.setEndTime(1, forItemWithStoreID: "x")
    precondition(store.storeIDs == ["x"])
    player.setQueue(with: store)
    precondition(MPMusicPlayerPlayParameters(dictionary: [:]) == nil)
    let params = MPMusicPlayerPlayParameters(dictionary: ["id": "1"])
    precondition(params != nil)
    precondition(params?.dictionary["id"] as? String == "1")
    let pq = MPMusicPlayerPlayParametersQueueDescriptor(playParametersQueue: [params!])
    pq.startItemPlayParameters = params
    pq.setStartTime(0, forItemWith: params!)
    pq.setEndTime(1, forItemWith: params!)
    precondition(pq.playParametersQueue.count == 1)
    let mutable = MPMusicPlayerControllerMutableQueue()
    mutable.insert(desc, after: a)
    mutable.remove(a)
    _ = mutable.items
    let queue = MPMusicPlayerControllerQueue()
    precondition(queue.items.isEmpty)

    let txSem = DispatchSemaphore(value: 0)
    var txFailed = false
    Task {
        do {
            _ = try await MPMusicPlayerController.applicationQueuePlayer.perform { queue in
                queue.insert(desc, after: nil)
            }
            fatalError("queue transaction should fail closed")
        } catch {
            txFailed = MPError.notSupported ~= error
            txSem.signal()
        }
    }
    precondition(txSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(txFailed)
}
