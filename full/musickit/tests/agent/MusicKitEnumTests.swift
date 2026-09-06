import Foundation
import MusicKit

func testEnumRawValues() {
    precondition(MusicAuthorization.Status.notDetermined.rawValue == "notDetermined")
    precondition(MusicAuthorization.Status.denied.rawValue == "denied")
    precondition(MusicAuthorization.Status.restricted.rawValue == "restricted")
    precondition(MusicAuthorization.Status.authorized.rawValue == "authorized")
    precondition(MusicAuthorization.Status(rawValue: "denied") == .denied)
    precondition(MusicAuthorization.Status.authorized.description == "authorized")
    precondition(MusicAuthorization.Status.denied != .authorized)

    precondition(MusicPlayer.RepeatMode.none != .one)
    precondition(MusicPlayer.RepeatMode.one != .all)
    precondition(MusicPlayer.ShuffleMode.off != .songs)
    precondition(MusicPlayer.PlaybackStatus.stopped != .playing)
    precondition(MusicPlayer.PlaybackStatus.paused != .interrupted)
    precondition(MusicPlayer.PlaybackStatus.seekingForward != .seekingBackward)
    precondition(MusicPlayer.Queue.EntryInsertionPosition.tail != .afterCurrentEntry)

    var ratingHasher = Hasher()
    ContentRating.explicit.hash(into: &ratingHasher)
    _ = ContentRating.explicit.hashValue
    MusicPlayer.RepeatMode.none.hash(into: &ratingHasher)
    _ = MusicPlayer.RepeatMode.none.hashValue
    MusicPlayer.ShuffleMode.off.hash(into: &ratingHasher)
    _ = MusicPlayer.ShuffleMode.off.hashValue
    MusicPlayer.PlaybackStatus.stopped.hash(into: &ratingHasher)
    _ = MusicPlayer.PlaybackStatus.stopped.hashValue
    MusicPlayer.Queue.EntryInsertionPosition.tail.hash(into: &ratingHasher)
    _ = MusicPlayer.Queue.EntryInsertionPosition.tail.hashValue
    AudioVariant.lossless.hash(into: &ratingHasher)
    _ = AudioVariant.lossless.hashValue
    MusicCatalogChartKind.mostPlayed.hash(into: &ratingHasher)
    _ = MusicCatalogChartKind.mostPlayed.hashValue
    Playlist.Kind.editorial.hash(into: &ratingHasher)
    _ = Playlist.Kind.editorial.hashValue
    Curator.Kind.editorial.hash(into: &ratingHasher)
    _ = Curator.Kind.editorial.hashValue
    MusicPropertySource.catalog.hash(into: &ratingHasher)
    _ = MusicPropertySource.catalog.hashValue
    precondition(ContentRating.clean != .explicit)
    let explicit = try! JSONDecoder().decode(ContentRating.self, from: Data(#""explicit""#.utf8))
    precondition(explicit == .explicit)
    let encodedRating = try! JSONEncoder().encode(ContentRating.clean)
    precondition(String(data: encodedRating, encoding: .utf8) == "\"clean\"")

    precondition(AudioVariant.allCases.count == 6)
    precondition(AudioVariant.lossless.description == "lossless")
    let atmos = try! JSONDecoder().decode(AudioVariant.self, from: Data(#""dolby-atmos""#.utf8))
    precondition(atmos == .dolbyAtmos)
    precondition(AudioVariant.highResolutionLossless != .lossyStereo)

    precondition(MusicCatalogChartKind.allCases == [.mostPlayed, .dailyGlobalTop, .cityTop])
    precondition(MusicCatalogChartKind.mostPlayed.description == "mostPlayed")

    precondition(Playlist.Kind.editorial != .userShared)
    precondition(Playlist.Kind.personalMix != .replay)
    precondition(Playlist.Kind.external != .editorial)
    precondition(Curator.Kind.editorial != .external)

    precondition(MusicPropertySource.allCases == [.catalog, .library])

    precondition(MusicTokenRequestError.unknown.rawValue == "unknown")
    precondition(MusicTokenRequestError.userNotSignedIn.rawValue == "userNotSignedIn")
    precondition(MusicTokenRequestError.permissionDenied.rawValue == "permissionDenied")
    precondition(MusicTokenRequestError.privacyAcknowledgementRequired.rawValue == "privacyAcknowledgementRequired")
    precondition(MusicTokenRequestError.developerTokenRequestFailed.rawValue == "developerTokenRequestFailed")
    precondition(MusicTokenRequestError.userTokenRequestFailed.rawValue == "userTokenRequestFailed")
    precondition(MusicTokenRequestError.userTokenRevoked.rawValue == "userTokenRevoked")
    precondition(MusicTokenRequestError(rawValue: "unknown") == .unknown)
    precondition(MusicTokenRequestError.unknown.errorDescription == "unknown")
    precondition(MusicTokenRequestError.unknown.failureReason == "unknown")
    precondition(MusicTokenRequestError.unknown.helpAnchor == nil)
    precondition(MusicTokenRequestError.unknown.recoverySuggestion == nil)
    precondition(MusicTokenRequestError.unknown.description == "unknown")

    precondition(MusicLibrary.Error.permissionDenied.rawValue == "permissionDenied")
    precondition(MusicLibrary.Error.unknown.rawValue == "unknown")
    precondition(MusicLibrary.Error.itemAlreadyAdded.rawValue == "itemAlreadyAdded")
    precondition(MusicLibrary.Error.unableToAddItem.rawValue == "unableToAddItem")
    precondition(MusicLibrary.Error.playlistNotInLibrary.rawValue == "playlistNotInLibrary")
    precondition(MusicLibrary.Error.createPlaylistFailed.rawValue == "createPlaylistFailed")
    precondition(MusicLibrary.Error.addToPlaylistFailed.rawValue == "addToPlaylistFailed")
    precondition(MusicLibrary.Error.editPlaylistFailed.rawValue == "editPlaylistFailed")
    precondition(MusicLibrary.Error.permissionDenied.errorDescription == "permissionDenied")

    precondition(MusicSubscription.Error.permissionDenied.rawValue == "permissionDenied")
    precondition(MusicSubscription.Error.privacyAcknowledgementRequired.rawValue == "privacyAcknowledgementRequired")
    precondition(MusicSubscription.Error.unknown.rawValue == "unknown")
    precondition(MusicSubscription.Error(rawValue: "unknown") == .unknown)

    let source = MusicDataRequest.Error.Source.parameter("term")
    precondition(source.description == "term")
    precondition(source == .parameter("term"))

    precondition(MusicTokenRequestOptions.ignoreCache.rawValue == 1)
    precondition(MusicTokenRequestOptions(rawValue: 1).contains(.ignoreCache))
    precondition(MusicTokenRequestOptions().isEmpty)
}
