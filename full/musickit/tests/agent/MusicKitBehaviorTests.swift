import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MusicKit

func testPlayerStateMachine() {
    let player = ApplicationMusicPlayer.shared
    precondition(player.state.playbackStatus == .stopped)
    precondition(player.playbackTime == 0)
    precondition(player.isPreparedToPlay == false)
    precondition(player.state.playbackRate == 1)
    player.beginSeekingForward()
    precondition(player.state.playbackStatus == .seekingForward)
    player.endSeeking()
    precondition(player.state.playbackStatus == .paused)
    player.beginSeekingBackward()
    precondition(player.state.playbackStatus == .seekingBackward)
    player.pause()
    precondition(player.state.playbackStatus == .paused)
    player.playbackTime = 12.5
    player.restartCurrentEntry()
    precondition(player.playbackTime == 0)
    player.stop()
    precondition(player.state.playbackStatus == .stopped)
    precondition(player.playbackTime == 0)
    player.state.repeatMode = .all
    player.state.shuffleMode = .songs
    precondition(player.state.repeatMode == .all)
    precondition(player.state.shuffleMode == .songs)
    _ = player.state.objectWillChange
}

func testPlayerQueue() {
    let song = Song(id: "1", title: "White Winter Hymnal", artistName: "Fleet Foxes")
    let video = MusicVideo(id: "2", title: "Video", artistName: "Fleet Foxes")
    let queue = ApplicationMusicPlayer.Queue(for: [song], startingAt: song)
    precondition(queue.currentEntry?.title == "White Winter Hymnal")
    precondition(queue.entries.count == 1)
    var entries = ApplicationMusicPlayer.Queue.Entries()
    entries.append(MusicPlayer.Queue.Entry(song))
    entries.append(MusicPlayer.Queue.Entry(video))
    precondition(entries.count == 2)
    precondition(entries[0].title == "White Winter Hymnal")
    precondition(entries.index(after: 0) == 1)
    let literal: ApplicationMusicPlayer.Queue.Entries = [MusicPlayer.Queue.Entry(song)]
    precondition(literal.count == 1)
    let playerQueue = MusicPlayer.Queue(arrayLiteral: song)
    precondition(playerQueue.currentEntry?.id == "1")
    let inserted = MusicPlayer.Queue.Entry(song, startTime: 1, endTime: 10)
    precondition(inserted.startTime == 1)
    precondition(inserted.endTime == 10)
    precondition(inserted.isTransient == true)
}

func testPlayerTransition() {
    let none = MusicPlayer.Transition.none
    let fade = MusicPlayer.Transition.crossfade(duration: nil)
    let timed = MusicPlayer.Transition.crossfade(duration: 4)
    precondition(none != fade)
    precondition(timed.description.contains("4"))
    precondition(fade == MusicPlayer.Transition.crossfade(options: .init()))
    let options = MusicPlayer.Transition.CrossfadeOptions(duration: 2)
    precondition(options.duration == 2)
    ApplicationMusicPlayer.shared.transition = timed
    precondition(ApplicationMusicPlayer.shared.transition == timed)
}

func testApplicationAndSystemPlayers() {
    let app = ApplicationMusicPlayer.shared
    let system = SystemMusicPlayer.shared
    precondition(ObjectIdentifier(app) == ObjectIdentifier(ApplicationMusicPlayer.shared))
    precondition(ObjectIdentifier(system) == ObjectIdentifier(SystemMusicPlayer.shared))
    _ = system.queue
    _ = app.queue
}

func testAuthorizationStatus() {
    MusicAuthorization._openuikit_setCurrentStatus(.notDetermined)
    precondition(MusicAuthorization.currentStatus == .notDetermined)
    MusicAuthorization._openuikit_setCurrentStatus(.denied)
    precondition(MusicAuthorization.currentStatus == .denied)
    MusicAuthorization._openuikit_setCurrentStatus(.restricted)
    precondition(MusicAuthorization.currentStatus == .restricted)
    MusicAuthorization._openuikit_setCurrentStatus(.authorized)
    precondition(MusicAuthorization.currentStatus == .authorized)
    MusicAuthorization._openuikit_setCurrentStatus(.notDetermined)
}

func testCatalogSearchRequest() {
    var request = MusicCatalogSearchRequest(term: "fleet foxes", types: [Song.self, Album.self])
    request.limit = 25
    request.offset = 10
    request.includeTopResults = false
    precondition(request.term == "fleet foxes")
    precondition(request.limit == 25)
    precondition(request.offset == 10)
    precondition(request.includeTopResults == false)
    precondition(request.types.count == 2)
    var charts = MusicCatalogChartsRequest(kinds: [.mostPlayed, .cityTop], types: [Song.self])
    charts.limit = 5
    precondition(charts.kinds.contains(.cityTop))
    precondition(charts.limit == 5)
    var suggestions = MusicCatalogSearchSuggestionsRequest(term: "help", includingTopResultsOfTypes: [Song.self])
    suggestions.limit = 3
    precondition(suggestions.term == "help")
    let resource = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID("1"))
    _ = resource.limit
}

func testLibraryRequestBuilder() {
    var request = MusicLibraryRequest<Song>()
    request.limit = 20
    request.offset = 5
    request.includeOnlyDownloadedContent = true
    request.filter(text: "helpless")
    request.filter(matching: \.title, equalTo: "Helplessness Blues")
    request.filter(matching: \.title, contains: "Blue")
    request.sort(by: \.title, ascending: true)
    precondition(request.limit == 20)
    precondition(request.offset == 5)
    precondition(request.includeOnlyDownloadedContent)
    let search = MusicLibrarySearchRequest(term: "fleet", types: [Song.self])
    precondition(search.term == "fleet")
    precondition(MusicLibrary.shared === MusicLibrary.shared)
}

func testSubscriptionOffer() {
    precondition(MusicSubscriptionOffer.MessageIdentifier.join.rawValue == "join")
    precondition(MusicSubscriptionOffer.MessageIdentifier.addMusic.rawValue == "addMusic")
    precondition(MusicSubscriptionOffer.MessageIdentifier.playMusic.rawValue == "playMusic")
    precondition(MusicSubscriptionOffer.Action.subscribe.rawValue == "subscribe")
    let options = MusicSubscriptionOffer.Options(
        action: .subscribe,
        messageIdentifier: .playMusic,
        itemID: "1440742676",
        affiliateToken: "aff",
        campaignToken: "camp"
    )
    precondition(options.itemID?.rawValue == "1440742676")
    precondition(options.affiliateToken == "aff")
    precondition(options.campaignToken == "camp")
    precondition(MusicSubscriptionOffer.Options.default.action == .subscribe)
    precondition(options == options)
    precondition(options.description.contains("playMusic"))
    let subscription = MusicSubscription(
        canBecomeSubscriber: false,
        canPlayCatalogContent: false,
        hasCloudLibraryEnabled: false
    )
    precondition(subscription.canPlayCatalogContent == false)
    precondition(subscription.canBecomeSubscriber == false)
    precondition(subscription.hasCloudLibraryEnabled == false)
}

func testMusicDataRequest() {
    var urlRequest = URLRequest(url: URL(string: "https://api.music.apple.com/v1/catalog/us/search")!)
    urlRequest.httpMethod = "GET"
    let request = MusicDataRequest(urlRequest: urlRequest)
    precondition(request.urlRequest.url?.path.contains("search") == true)
    precondition(request.description.contains("search"))
    precondition(request == request)
    let options: MusicTokenRequestOptions = [.ignoreCache]
    precondition(options.contains(.ignoreCache))
    precondition(MusicTokenRequestOptions(rawValue: 1).rawValue == 1)
    _ = DefaultMusicTokenProvider()
    _ = MusicUserTokenProvider()
}

func testArtworkImage() {
    let artwork = Artwork(urlTemplate: "https://ex/{w}x{h}.jpg", maximumWidth: 100, maximumHeight: 80)
    let both = ArtworkImage(artwork, width: 50, height: 40)
    precondition(both.width == 50)
    precondition(both.height == 40)
    let byWidth = ArtworkImage(artwork, width: 20)
    precondition(byWidth.height == nil)
    let byHeight = ArtworkImage(artwork, height: 10)
    precondition(byHeight.width == nil)
    _ = both.body
    var presented = true
    let binding = Binding(wrappedValue: presented)
    _ = EmptyView().musicSubscriptionOffer(isPresented: binding)
    presented = binding.wrappedValue
}
