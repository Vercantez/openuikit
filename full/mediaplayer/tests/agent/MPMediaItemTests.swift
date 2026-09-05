import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func testMediaItemProperties() {
    let added = Date(timeIntervalSince1970: 100)
    let last = Date(timeIntervalSince1970: 200)
    let released = Date(timeIntervalSince1970: 50)
    let url = URL(string: "file:///tmp/song.m4a")!
    let pid: MPMediaEntityPersistentID = 11
    let item = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Karma Police",
        MPMediaItemPropertyArtist: "Radiohead",
        MPMediaItemPropertyAlbumTitle: "OK Computer",
        MPMediaItemPropertyAlbumArtist: "Radiohead",
        MPMediaItemPropertyComposer: "Yorke",
        MPMediaItemPropertyGenre: "Rock",
        MPMediaItemPropertyLyrics: "karma",
        MPMediaItemPropertyComments: "note",
        MPMediaItemPropertyPersistentID: pid,
        MPMediaItemPropertyAlbumPersistentID: UInt64(1),
        MPMediaItemPropertyAlbumArtistPersistentID: UInt64(2),
        MPMediaItemPropertyArtistPersistentID: UInt64(3),
        MPMediaItemPropertyComposerPersistentID: UInt64(4),
        MPMediaItemPropertyGenrePersistentID: UInt64(5),
        MPMediaItemPropertyPodcastPersistentID: UInt64(6),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyPlayCount: 4,
        MPMediaItemPropertySkipCount: 1,
        MPMediaItemPropertyRating: 5,
        MPMediaItemPropertyAlbumTrackNumber: 6,
        MPMediaItemPropertyAlbumTrackCount: 12,
        MPMediaItemPropertyDiscNumber: 1,
        MPMediaItemPropertyDiscCount: 1,
        MPMediaItemPropertyBeatsPerMinute: 75,
        MPMediaItemPropertyBookmarkTime: 1.5,
        MPMediaItemPropertyPlaybackDuration: 260.0,
        MPMediaItemPropertyIsCloudItem: false,
        MPMediaItemPropertyIsCompilation: false,
        MPMediaItemPropertyIsExplicit: false,
        MPMediaItemPropertyIsPreorder: false,
        MPMediaItemPropertyHasProtectedAsset: false,
        MPMediaItemPropertyDateAdded: added,
        MPMediaItemPropertyLastPlayedDate: last,
        MPMediaItemPropertyReleaseDate: released,
        MPMediaItemPropertyPlaybackStoreID: "store",
        MPMediaItemPropertyUserGrouping: "fav",
        MPMediaItemPropertyAssetURL: url,
    ])
    precondition(item.title == "Karma Police")
    precondition(item.artist == "Radiohead")
    precondition(item.albumTitle == "OK Computer")
    precondition(item.albumArtist == "Radiohead")
    precondition(item.composer == "Yorke")
    precondition(item.genre == "Rock")
    precondition(item.lyrics == "karma")
    precondition(item.comments == "note")
    precondition(item.persistentID == 11)
    precondition(item.albumPersistentID == 1)
    precondition(item.albumArtistPersistentID == 2)
    precondition(item.artistPersistentID == 3)
    precondition(item.composerPersistentID == 4)
    precondition(item.genrePersistentID == 5)
    precondition(item.podcastPersistentID == 6)
    precondition(item.mediaType.contains(.music))
    precondition(item.playCount == 4)
    precondition(item.skipCount == 1)
    precondition(item.rating == 5)
    precondition(item.albumTrackNumber == 6)
    precondition(item.albumTrackCount == 12)
    precondition(item.discNumber == 1)
    precondition(item.discCount == 1)
    precondition(item.beatsPerMinute == 75)
    precondition(item.bookmarkTime == 1.5)
    precondition(item.playbackDuration == 260)
    precondition(item.isCloudItem == false)
    precondition(item.isCompilation == false)
    precondition(item.isExplicitItem == false)
    precondition(item.isPreorder == false)
    precondition(item.hasProtectedAsset == false)
    precondition(item.dateAdded == added)
    precondition(item.lastPlayedDate == last)
    precondition(item.releaseDate == released)
    precondition(item.playbackStoreID == "store")
    precondition(item.userGrouping == "fav")
    precondition(item.assetURL == url)
    precondition(item.value(forProperty: MPMediaItemPropertyTitle) as? String == "Karma Police")
    precondition(item["title"] as? String == "Karma Police")
    var enumerated = 0
    item.enumerateValues(forProperties: [MPMediaItemPropertyTitle, MPMediaItemPropertyArtist]) { _, _, _ in
        enumerated += 1
    }
    precondition(enumerated == 2)
    let empty = MPMediaItem()
    precondition(empty.title == nil)
    precondition(empty.persistentID == 0)
    precondition(MPMediaEntity.supportsSecureCoding)
    let copy = empty.copy() as! MPMediaItem
    precondition(copy === empty)
}

func testMediaItemArtwork() {
    let image = UIImage(size: CGSize(width: 10, height: 8))
    let fromImage = MPMediaItemArtwork(image: image)
    precondition(fromImage.bounds.size.width == 10)
    precondition(fromImage.bounds.size.height == 8)
    precondition(fromImage.imageCropRect.size.width == 10)
    let art = MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 80)) { size in
        UIImage(size: size)
    }
    precondition(art.bounds.width == 100 && art.bounds.height == 80)
    let at50 = art.image(at: CGSize(width: 50, height: 40))
    precondition(at50?.size.width == 50 && at50?.size.height == 40)
    let item = MPMediaItem(hostProperties: [MPMediaItemPropertyArtwork: art])
    precondition(item.artwork === art)
    let content = MPContentItem(identifier: "art")
    content.artwork = art
    precondition(content.artwork === art)
}

func testMediaItemCollection() {
    let a = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "A",
        MPMediaItemPropertyMediaType: MPMediaType.music,
    ])
    let b = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "B",
        MPMediaItemPropertyMediaType: MPMediaType.podcast,
    ])
    let collection = MPMediaItemCollection(items: [a, b])
    precondition(collection.count == 2)
    precondition(collection.items.count == 2)
    precondition(collection.representativeItem === a)
    precondition(collection.mediaTypes.contains(.music))
    precondition(collection.mediaTypes.contains(.podcast))
    let section = MPMediaQuerySection(title: "R", range: NSRange(location: 0, length: 2))
    precondition(section.title == "R")
    precondition(section.range.length == 2)
}

func testMediaItemCanFilterAndGroupingMaps() {
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyTitle))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaEntityPropertyPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumTitle))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtist))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyGenre))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyMediaType))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPlayCount))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAssetURL))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumArtist))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumArtistPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtistPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyComposer))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyComposerPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyDateAdded))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyGenrePersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyHasProtectedAsset))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsCloudItem))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsCompilation))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsExplicit))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsPreorder))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPodcastPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPodcastTitle))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyRating))
    precondition(!MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtwork))
    precondition(!MPMediaItem.canFilter(byProperty: MPMediaItemPropertyLyrics))
    precondition(MPMediaEntity.canFilter(byProperty: MPMediaEntityPropertyPersistentID))
    precondition(!MPMediaEntity.canFilter(byProperty: MPMediaItemPropertyTitle))
    precondition(MPMediaItem.titleProperty(forGroupingType: .title) == MPMediaItemPropertyTitle)
    precondition(MPMediaItem.titleProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumTitle)
    precondition(MPMediaItem.titleProperty(forGroupingType: .artist) == MPMediaItemPropertyArtist)
    precondition(MPMediaItem.titleProperty(forGroupingType: .albumArtist) == MPMediaItemPropertyAlbumArtist)
    precondition(MPMediaItem.titleProperty(forGroupingType: .composer) == MPMediaItemPropertyComposer)
    precondition(MPMediaItem.titleProperty(forGroupingType: .genre) == MPMediaItemPropertyGenre)
    precondition(MPMediaItem.titleProperty(forGroupingType: .playlist) == MPMediaPlaylistPropertyName)
    precondition(MPMediaItem.titleProperty(forGroupingType: .podcastTitle) == MPMediaItemPropertyPodcastTitle)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .title) == MPMediaItemPropertyPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .artist) == MPMediaItemPropertyArtistPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .albumArtist) == MPMediaItemPropertyAlbumArtistPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .composer) == MPMediaItemPropertyComposerPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .genre) == MPMediaItemPropertyGenrePersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .playlist) == MPMediaPlaylistPropertyPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .podcastTitle) == MPMediaItemPropertyPodcastPersistentID)
}
